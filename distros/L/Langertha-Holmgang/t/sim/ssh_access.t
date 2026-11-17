#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );
use Langertha::Holmgang::Sim::Linux::SshAccess ();

# Anmeldung per SSH. Behauptet wird: die Pruefung folgt sshd —
# geladene Konfiguration (eine Aenderung wirkt erst nach reload), Match-
# Abschnitte fuer diese Verbindung, Konto, Allow/Deny, authorized_keys mit
# StrictModes und from=, Port und Firewall; das Journal zeigt die Zeilen von sshd.

my $KEY  = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHannaLaptopKey0000000000000000000000000000';
my $KEY2 = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFremderSchluessel000000000000000000000000';

sub world {
    my (%o) = @_;
    return { srv => {
        type => 'linux',
        interfaces => { eth1 => { addr => ['10.1.0.20/24'], state => 'UP' } },
        users => { anna => { uid => 1001, groups => [ 'anna', 'devs' ], home => '/home/anna', shell => '/bin/bash' } },
        dirs  => { '/home/anna' => { owner => 'anna', group => 'anna', mode => '0755' },
            '/home/anna/.ssh' => { owner => 'anna', group => 'anna', mode => '0700' } },
        files => {
            '/etc/ssh/sshd_config' => $o{conf} // "Include /etc/ssh/sshd_config.d/*.conf\nPasswordAuthentication no\n",
            '/home/anna/.ssh/authorized_keys' => { owner => 'anna', group => 'anna', mode => '0600', content => "$KEY anna\@laptop\n" },
            %{ $o{files} || {} },
        },
        services => { ssh => { active => JSON::MaybeXS::true(), effective => {} } },
        ( $o{nft} ? ( nft => $o{nft} ) : () ),
        ssh_tries => [ { user => 'anna', from => '10.1.0.77', key => $KEY, iif => 'eth1', daddr => '10.1.0.20' } ],
    } };
}
my %try = ( user => 'anna', from => '10.1.0.77', key => $KEY, iif => 'eth1', daddr => '10.1.0.20' );
sub can_login { my ( $st, %t ) = @_; return ( Langertha::Holmgang::Sim::Linux::SshAccess::check( $st->{srv}, { %try, %t }, 'srv' ) )[0] }
sub sh { my ( $st, $c ) = @_; return ( run_command( $st, 'srv', $c ) )[0] }

subtest 'Schluessel und Rechte' => sub {
    my $st = world();
    ok( can_login($st), 'Schluessel in authorized_keys: Anmeldung geht' );
    ok( !can_login( $st, key => $KEY2 ), 'fremder Schluessel: nein' );
    $st->{srv}{dirs}{'/home/anna'}{mode} = '0775';
    ok( !can_login($st), 'Heimatverzeichnis gruppenschreibbar: StrictModes verweigert' );
    like( join( "\n", sh( $st, 'journalctl -u ssh' ) ), qr/Authentication refused: bad ownership or modes for directory \/home\/anna/, 'Journal nennt den Grund' );
    sh( $st, 'chmod 755 /home/anna' );
    ok( can_login($st), 'chmod 755: geht wieder' );
    sh( $st, 'chmod 666 /home/anna/.ssh/authorized_keys' );
    ok( !can_login($st), 'authorized_keys fuer alle schreibbar: nein' );
    sh( $st, 'chmod 600 /home/anna/.ssh/authorized_keys; chown root /home/anna/.ssh' );
    ok( can_login($st), '.ssh gehoert root (erlaubt)' );
    $st->{srv}{files}{'/home/anna/.ssh/authorized_keys'}{owner} = 'bert';
    ok( !can_login($st), 'authorized_keys gehoert einem anderen Benutzer: nein' );
};

subtest 'from= und Konto' => sub {
    my $st = world();
    $st->{srv}{files}{'/home/anna/.ssh/authorized_keys'}{content} = qq{from="10.9.0.0/24,!10.9.0.66" $KEY anna\@laptop\n};
    ok( !can_login($st), 'from= passt nicht' );
    like( join( "\n", sh( $st, 'journalctl -u ssh' ) ), qr/correct key but not from a permitted host/, 'Journal' );
    ok( can_login( $st, from => '10.9.0.5' ), 'from= passt' );
    ok( !can_login( $st, from => '10.9.0.66' ), 'verneint' );
    $st = world();
    $st->{srv}{users}{anna}{shell} = '/usr/sbin/nologin';
    ok( !can_login($st), 'nologin' );
    $st = world();
    ok( !can_login( $st, user => 'bert' ), 'unbekannter Benutzer' );
};

subtest 'geladene Konfiguration, Match, AllowUsers' => sub {
    if ( my $why = need_parts('Sshd') ) { plan skip_all => $why }
    my $st = world( conf => "AllowUsers admin\n" );
    ok( !can_login($st), 'AllowUsers ohne anna' );
    sh( $st, 'true' );    # erster Befehl: geladener Stand festgehalten
    sh( $st, q{sed -i 's/AllowUsers admin/AllowUsers admin anna/' /etc/ssh/sshd_config} );
    ok( !can_login($st), 'nur die Datei geaendert: sshd hat noch die alte' );
    sh( $st, 'systemctl reload ssh' );
    ok( can_login($st), 'nach reload' );

    $st = world( conf => "AuthorizedKeysFile /etc/ssh/keys/%u\nMatch Group devs\n    AuthorizedKeysFile .ssh/authorized_keys\n" );
    ok( can_login($st), 'Match Group devs: eigene authorized_keys' );
    $st->{srv}{users}{anna}{groups} = ['anna'];
    ok( !can_login($st), 'ohne Gruppe devs: /etc/ssh/keys/anna (fehlt)' );

    $st = world( conf => "PasswordAuthentication no\nMatch Address 10.1.0.0/24\n    PasswordAuthentication yes\n" );
    $st->{srv}{users}{anna}{password} = 1;
    ok( can_login( $st, auth => 'password' ), 'Passwort aus 10.1.0.0/24' );
    ok( !can_login( $st, auth => 'password', from => '203.0.113.5' ), 'sonst nicht' );
};

subtest 'Port und Firewall' => sub {
    my $nft = { 'inet filter' => { chains => { input => { type => 'filter', hook => 'input', priority => '0', policy => 'drop',
        rules => ['tcp dport 2222 accept'] } } } };
    my $st = world( conf => "Port 2222\n", nft => $nft );
    ok( !can_login($st), 'Port 22 ist zu (sshd lauscht auf 2222)' );
    ok( can_login( $st, port => 2222 ), '2222 geht' );
    $st->{srv}{nft}{'inet filter'}{chains}{input}{rules} = [];
    ok( !can_login( $st, port => 2222 ), 'Firewall verwirft' );
    $st->{srv}{services}{ssh}{active} = JSON::MaybeXS::false();
    ok( !can_login( $st, port => 2222 ), 'sshd laeuft nicht' );
};

subtest 'sshd -T -C und ss' => sub {
    if ( my $why = need_parts('Sshd') ) { plan skip_all => $why }
    my $st = world( conf => "Include /etc/ssh/sshd_config.d/*.conf\nPasswordAuthentication no\nPort 2222\nMatch Address 10.50.0.0/24 User anna\n    PasswordAuthentication yes\n" );
    $st->{srv}{files}{'/etc/ssh/ssh_host_ed25519_key'} = { mode => '0600', content => 'x' };
    like( sh( $st, 'sshd -T' ), qr/^passwordauthentication no$/m, 'sshd -T: global' );
    like( sh( $st, 'sshd -T -C user=anna,addr=10.50.0.7' ), qr/^passwordauthentication yes$/m, 'sshd -T -C: Match fuer anna aus 10.50.0.0/24' );
    like( sh( $st, 'sshd -T -C user=anna,addr=10.1.0.77' ), qr/^passwordauthentication no$/m, '... sonst global' );
    like( sh( $st, 'ss -tlnp' ), qr/0\.0\.0\.0:2222\s.*"sshd"/, 'ss zeigt sshd auf dem geladenen Port' );
};

subtest 'namei, type, base64' => sub {
    my $st = world();
    $st->{srv}{dirs}{'/home/anna'}{mode} = '0775';
    my $o = sh( $st, 'namei -l /home/anna/.ssh/authorized_keys' );
    like( $o, qr{^drwxrwxr-x anna\s+anna\s+anna$}m, 'namei: Heim mit Gruppen-Schreibrecht' );
    like( $o, qr{^-rw------- anna\s+anna\s+authorized_keys$}m, '... und die Datei' );
    like( sh( $st, 'type nft' ), qr{\Anft is /usr/sbin/nft\z}, 'type' );
    is( sh( $st, 'echo aGFsbG8= | base64 -d' ), 'hallo', 'base64 -d' );
};

subtest 'cp wie coreutils (Besitzer der Kopie)' => sub {
    if ( my $why = need_parts('Backup') ) { plan skip_all => $why }
    my $st = world();
    sh( $st, 'cp /home/anna/.ssh/authorized_keys /root/ak' );
    is( $st->{srv}{files}{'/root/ak'}{owner} // 'root', 'root', 'neue Kopie gehoert root (wer kopiert)' );
    sh( $st, 'cp -p /home/anna/.ssh/authorized_keys /root/ak2' );
    is( $st->{srv}{files}{'/root/ak2'}{owner}, 'anna', 'cp -p behaelt den Besitzer' );
    $st->{srv}{files}{'/root/ak'} = { owner => 'bert', mode => '0640', content => 'alt' };
    sh( $st, 'cp /home/anna/.ssh/authorized_keys /root/ak' );
    is_deeply( [ @{ $st->{srv}{files}{'/root/ak'} }{qw( owner mode )} ], [ 'bert', '0640' ], 'vorhandenes Ziel behaelt Besitzer und Rechte' );
    like( $st->{srv}{files}{'/root/ak'}{content}, qr/anna\@laptop/, '... mit neuem Inhalt' );
};

subtest 'mkdir, cp und mv mit Verzeichnissen' => sub {
    if ( my $why = need_parts('Backup') ) { plan skip_all => $why }
    my $st = world();
    my $d = $st->{srv}{dirs};
    sh( $st, 'mkdir -m 700 /home/anna/neu' );
    is( $d->{'/home/anna/neu'}{mode}, '0700', 'mkdir -m setzt die Rechte' );
    ok( !exists $d->{700}, '... und legt kein Verzeichnis 700 an' );
    like( sh( $st, 'mkdir /home/anna/neu' ), qr/cannot create directory '\/home\/anna\/neu': File exists/, 'vorhanden: File exists' );
    is( sh( $st, 'mkdir -p /home/anna/neu /data/home/anna' ), '', '-p: vorhanden ist kein Fehler' );
    ok( $d->{'/data/home/anna'} && $d->{'/data'}, '... Eltern mit angelegt (wie mkdir -p)' );
    sh( $st, 'cp /home/anna/.ssh/authorized_keys /data/home/anna/' );
    ok( exists $st->{srv}{files}{'/data/home/anna/authorized_keys'}, 'cp in ein Verzeichnis mit / am Ende' );
    ok( !grep( {m{//}} keys %{ $st->{srv}{files} } ), '... ohne doppelten Schraegstrich' );
    like( sh( $st, 'cp /home/anna/.ssh /data/home/anna/' ), qr/-r not specified; omitting directory/, 'cp ohne -r: Verzeichnis nicht' );
    sh( $st, 'cp -a /home/anna/.ssh /data/home/anna/' );
    is_deeply( [ @{ $d->{'/data/home/anna/.ssh'} }{qw( owner mode )} ], [ 'anna', '0700' ], 'cp -a: Verzeichnis mit Besitzer und Rechten' );
    is( $st->{srv}{files}{'/data/home/anna/.ssh/authorized_keys'}{owner}, 'anna', '... und die Dateien darin' );
    sh( $st, 'cp -r /home/anna/.ssh /root/kopie' );
    ok( ( $d->{'/root/kopie'}{owner} // 'root' ) eq 'root' && ( $st->{srv}{files}{'/root/kopie/authorized_keys'}{owner} // 'root' ) eq 'root', 'cp -r: Kopie gehoert root' );
    is( $st->{srv}{files}{'/root/kopie/authorized_keys'}{mode}, '0600', '... die Rechte bleiben' );
    sh( $st, 'mv /root/kopie /root/weg' );
    ok( !_dir( $st, '/root/kopie' ) && $d->{'/root/weg'} && exists $st->{srv}{files}{'/root/weg/authorized_keys'}, 'mv eines Verzeichnisses' );
    sh( $st, 'chown -R anna:anna /data/home/anna' );
    is( $st->{srv}{files}{'/data/home/anna/authorized_keys'}{owner}, 'anna', 'chown -R ueber der Kopie' );
    sh( $st, 'usermod -d /srv/anna -m anna' );
    is( $st->{srv}{users}{anna}{home}, '/srv/anna', 'usermod -d setzt das Heimatverzeichnis' );
    ok( exists $st->{srv}{files}{'/srv/anna/.ssh/authorized_keys'} && !_dir( $st, '/home/anna' ), '... -m nimmt den Inhalt mit' );
};
sub _dir { my ( $st, $p ) = @_; return exists $st->{srv}{dirs}{$p} || grep { index( $_, "$p/" ) == 0 } keys %{ $st->{srv}{files} } }

subtest 'Werkzeuge rund um SSH: ssh, ssh-keygen, find -exec, xargs, install, file, who, env, dpkg' => sub {
    if ( my $why = need_parts('Sshd') ) { plan skip_all => $why }
    my $st = world();
    $st->{srv}{users}{admin} = { uid => 1000, groups => ['admin'], home => '/home/admin', shell => '/bin/bash' };
    $st->{srv}{ssh_login} = { user => 'admin', from => '10.1.0.50' };
    my $gap = sub { ( run_command( $st, 'srv', $_[0] ) )[2] };
    like( sh( $st, 'ssh -o BatchMode=yes anna@localhost true' ), qr/\Aanna\@localhost: Permission denied \(publickey\)\.\z/, 'ssh auf sich selbst: ohne Schluessel abgewiesen, Verfahren wie sshd' );
    ok( !defined $gap->('ssh -o BatchMode=yes anna@localhost true'), '... keine Luecke' );
    $st->{srv}{files}{'/etc/ssh/sshd_config.d/50-pw.conf'} = "PasswordAuthentication yes\n";
    sh( $st, 'systemctl reload ssh' );
    like( sh( $st, 'ssh -o BatchMode=yes -p 22 anna@10.1.0.20 true' ), qr/Permission denied \(publickey,password\)/, '... nach reload: Passwort angeboten' );
    ok( defined $gap->('ssh ci1 hostname'), 'fremder Name: Luecke (der Fall bildet das Geraet nicht nach)' );
    ok( defined $gap->('ssh 10.9.9.9 true'), 'fremde Adresse: Luecke' );
    like( sh( $st, 'ssh-keygen -lf /home/anna/.ssh/authorized_keys' ), qr/\A256 SHA256:\S{43} anna\@laptop \(ED25519\)\z/, 'ssh-keygen -l je Schluessel' );
    sh( $st, q{ssh-keygen -q -t ed25519 -N '' -C test -f /tmp/k1} );
    ok( exists $st->{srv}{files}{'/tmp/k1'} && $st->{srv}{files}{'/tmp/k1.pub'}{content} =~ /\Assh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI\S+ test\n\z/, 'ssh-keygen -t: Schluesselpaar' );
    is( sh( $st, 'ssh-keygen -y -f /tmp/k1' ), $st->{srv}{files}{'/tmp/k1.pub'}{content} =~ s/\n\z//r, 'ssh-keygen -y: oeffentlicher Teil' );
    like( sh( $st, 'find /home -name authorized_keys -exec ls -l {} \;' ), qr{^-rw------- 1 anna\s+anna\s.* /home/anna/\.ssh/authorized_keys$}m, 'find -exec ... {} \;' );
    like( sh( $st, 'find /home -name authorized_keys | xargs grep -l laptop' ), qr{\A/home/anna/\.ssh/authorized_keys\z}, 'xargs' );
    sh( $st, 'install -o anna -g anna -m 600 /tmp/k1.pub /home/anna/.ssh/neu' );
    is_deeply( [ @{ $st->{srv}{files}{'/home/anna/.ssh/neu'} }{qw( owner group mode )} ], [ 'anna', 'anna', '0600' ], 'install -o -g -m' );
    sh( $st, 'install -d -o anna -g anna -m 700 /home/anna/neu.d' );
    is( $st->{srv}{dirs}{'/home/anna/neu.d'}{mode}, '0700', 'install -d' );
    sh( $st, 'find /tmp -name "k1*" -delete' );
    ok( !exists $st->{srv}{files}{'/tmp/k1'}, 'find -delete' );
    like( sh( $st, 'file /home/anna/.ssh/authorized_keys /home/anna/.ssh' ), qr{authorized_keys: OpenSSH ED25519 public key\n/home/anna/\.ssh: directory}, 'file' );
    like( sh( $st, 'who' ), qr/\Aadmin\s+pts\/0\s+\S+ \S+ \(10\.1\.0\.50\)\z/, 'who: die eigene Sitzung' );
    like( sh( $st, 'env' ), qr/^SSH_CONNECTION=10\.1\.0\.50 \d+ 10\.1\.0\.20 22$/m, 'env' );
    like( sh( $st, 'dpkg -l openssh-server' ), qr/^ii  openssh-server\s+1:9\.2p1/m, 'dpkg -l' );
    ok( defined $gap->('dpkg -s fehlt-paket'), 'dpkg -s: unbekanntes Paket ist eine Luecke (es kann es geben)' );
};

subtest 'Regelart login: login_check des Linux-Simulators' => sub {
    # die Regel selbst (Loader, Grader) kommt mit k2; hier der Vertrag, auf dem sie steht
    my $st = world();
    my ( $ok, $client, @log ) = Holmgang::TestSim::sims()->login_check( $st->{srv}, {%try}, 'srv' );
    is( $ok, 1, 'allowed' );
    like( $log[0], qr/\AAccepted publickey for anna from 10\.1\.0\.77 port \d+ ssh2: ED25519 SHA256:/, '... mit der Zeile von sshd' );
    ( $ok, $client ) = Holmgang::TestSim::sims()->login_check( $st->{srv}, { %try, key => $KEY2 }, 'srv' );
    is( $ok, 0, 'fremder Schluessel: denied' );
    is( $client, 'anna@srv: Permission denied (publickey).', '... Meldung des Clients' );
};

done_testing;
