#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# srv meldet sich per ssh_login an: jeder Befehl dort geht durch Sim::Linux::SshAccess
my $NO_SSH = need_parts('SshAccess');

# Linux-Simulator fuer Haertungs-Faelle.
# Behauptet wird: sshd liest seine Konfiguration wie OpenSSH (Include an Ort und
# Stelle, erster Wert gewinnt, Listen sammeln sich, Fehler wie sshd -t); reload
# mit kaputter Datei scheitert und behaelt die alte Konfiguration, restart
# hinterlaesst sshd failed; wer sich dabei aussperrt (Dienst weg, AllowGroups,
# abgelaufenes Konto), kommt nicht mehr an den Server. Dazu Konten (sperren,
# ablaufen, Gruppen entfernen, loeschen), SUID-Bits (chmod, ls -l, find -perm),
# sudo-Regeln (visudo -c, sudo -l), grep -r und 2>/dev/null.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $T = JSON::MaybeXS::true();
my $start = {
    srv => {
        type      => 'linux',
        ssh_login => { user => 'ops', from => '10.10.99.15' },
        users     => {
            ops    => { uid => 1000, groups => [qw( ops sudo admins )], shell => '/bin/bash' },
            mmeier => { uid => 1004, groups => [qw( mmeier sudo docker developers )], shell => '/bin/bash' },
            deploy => { uid => 1010, groups => [qw( deploy ci )], shell => '/bin/bash' },
        },
        groups => { sudo => { gid => 27 }, docker => { gid => 998 }, developers => { gid => 1100 }, admins => { gid => 1200 }, ci => { gid => 1300 } },
        files  => {
            '/etc/ssh/sshd_config' => "Include /etc/ssh/sshd_config.d/*.conf\n\nPermitRootLogin no\nPasswordAuthentication no\nAllowGroups admins\n",
            '/etc/ssh/sshd_config.d/50-cloud-init.conf' => "PasswordAuthentication yes\n",
            '/etc/ssh/sshd_config.d/10-crypto.conf'     => "Ciphers chacha20-poly1305\@openssh.com\n",
            '/etc/ssh/ssh_host_ed25519_key'     => { content => '', mode => '0600' },
            '/etc/ssh/ssh_host_ed25519_key.pub' => { content => '', mode => '0644' },
            '/usr/bin/passwd'                   => { content => '', mode => '4755' },
            '/usr/local/bin/helper'             => { content => '', mode => '4755' },
            '/usr/bin/ls'                       => { content => '', mode => '0755' },
            '/home/mmeier/notizen.txt'          => { content => "x\n", owner => 'mmeier', group => 'mmeier', mode => '0600' },
            '/etc/sudoers' => { content => "Defaults env_reset\nroot ALL=(ALL:ALL) ALL\n%sudo ALL=(ALL:ALL) ALL\n\@includedir /etc/sudoers.d\n", mode => '0440' },
            '/etc/sudoers.d/deploy'   => { content => "deploy ALL=(ALL) NOPASSWD: ALL\n", mode => '0440' },
            '/etc/sudoers.d/90-ci'    => { content => "%ci ALL=(root) NOPASSWD: /usr/bin/systemctl restart shop\n", mode => '0440' },
            '/etc/sudoers.d/alt.conf' => { content => "deploy ALL=(ALL) NOPASSWD: ALL\n", mode => '0440' },
        },
        services => {
            ssh => { active => $T, description => 'OpenBSD Secure Shell server', exec => 'sshd',
                effective => { permitrootlogin => 'no', passwordauthentication => 'yes', allowgroups => ['admins'], ciphers => 'chacha20-poly1305@openssh.com' } },
        },
    },
};

my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok, $gap ) = run_command( $state, 'srv', $cmd );
    return wantarray ? ( $o, $ok, $gap ) : $o;
}
sub srv { $state->{srv} }

subtest 'Shell: 2>/dev/null und 2>&1 lenken nur die Fehlerausgabe um' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    my ( $o, $ok ) = sh('find /usr -perm -4000 -type f 2>/dev/null');
    is( $o, "/usr/bin/passwd\n/usr/local/bin/helper", 'Ausgabe bleibt, keine 2 als Pfad' );
    ok( $ok, 'gelungen' );
    like( sh('sshd -t 2>&1'), qr/\A\z/, 'sshd -t 2>&1: still' );
    like( sh('ls /fehlt; echo "rc=$?"; true; echo "rc=$?"'), qr/rc=1\nrc=0\z/, '$? des vorigen Befehls' );
    sh('cat /etc/ssh/sshd_config.d/50-cloud-init.conf &>/root/a');
    like( sh('cat /root/a'), qr/\APasswordAuthentication yes/, '&> leitet um' );
    is( sh('which systemctl visudo'), "/usr/bin/systemctl\n/usr/sbin/visudo", 'which: Pfade wie Debian 12' );
    is( sh('command -v sshd'), '/usr/sbin/sshd', 'command -v' );
    is( sh('type echo'), 'echo is a shell builtin', 'type: eingebaut' );
    ( $o, $ok ) = sh('which iptables');
    ok( !$ok && $o eq '', 'which: nicht installiert -> leer, Fehler' );
    is( sh('whereis curl'), 'curl:', 'whereis: nicht installiert' );
    is( sh('command echo hallo'), 'hallo', 'command ohne -v fuehrt aus' );
    is( sh('date'), 'Tue Oct 20 14:00:00 CEST 2026', 'date: Simulationszeit in Ortszeit' );
    is( sh('date -u +%F_%H:%M'), '2026-10-20_12:00', 'date -u mit Format' );
    is( sh('echo $(date +%Y-%m-%d)'), '2026-10-20', 'date in $(...)' );
    # Vergleichswerte von GNU date (coreutils, TZ=Europe/Berlin)
    my $f = q{'+%s %F %T %Z %z'};
    is( sh("date -d '2026-10-21 05:00:00 UTC' $f"), '1792558800 2026-10-21 07:00:00 CEST +0200', 'date -d mit UTC' );
    is( sh("date -d '2026-10-21 07:00:00 CEST' $f"), '1792558800 2026-10-21 07:00:00 CEST +0200', 'date -d mit CEST' );
    is( sh("date -d '2026-10-21 05:00' $f"), '1792551600 2026-10-21 05:00:00 CEST +0200', 'date -d Ortszeit' );
    is( sh("date -d '2026-10-25 05:00 UTC' $f"), '1792904400 2026-10-25 06:00:00 CET +0100', 'date -d nach der Zeitumstellung' );
    is( sh("date -d '2026-10-26 06:00' $f"), '1792990800 2026-10-26 06:00:00 CET +0100', 'date -d Winterzeit' );
    is( sh("date -d \@1792468800 $f"), '1792468800 2026-10-20 06:00:00 CEST +0200', 'date -d @Epoche' );
    is( sh("date -d 2026-10-21T05:00:00 $f"), '1792551600 2026-10-21 05:00:00 CEST +0200', 'date -d mit T' );
    is( sh(q{TZ=UTC date -d '2026-10-21 05:00:00' '+%s %F %T %Z'}), '1792558800 2026-10-21 05:00:00 UTC', 'TZ=UTC vor date' );
    ( $o, $ok ) = sh(q{date -d 'morgen 5 Uhr'});
    ok( !$ok && $o eq "date: invalid date \x{2018}morgen 5 Uhr\x{2019}", 'date -d ungueltig' );
    is( sh('date -d tomorrow +%F'), '2026-10-21', 'date -d tomorrow' );
};

subtest 'sshd: Include, erster Wert gewinnt, Listen' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    my ( $o, $ok ) = sh('sshd -T');
    ok( $ok, 'sshd -T gelingt' );
    like( $o, qr/^passwordauthentication yes$/m, 'Drop-in (vor der Hauptdatei) gewinnt' );
    like( $o, qr/^permitrootlogin no$/m, 'Hauptdatei fuer den Rest' );
    like( $o, qr/^ciphers chacha20-poly1305\@openssh\.com$/m, '10-crypto.conf eingelesen' );
    like( $o, qr/^allowgroups admins$/m, 'Liste' );
    like( sh('sshd -T | grep -i passwordauth'), qr/\Apasswordauthentication yes\z/, 'mit Filter' );
    is( sh('sshd -t'), '', 'sshd -t still' );
};

subtest 'sshd -t: Fehler wie OpenSSH' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    sh(q{echo 'PermitRootLogn no' >> /etc/ssh/sshd_config});
    my ( $o, $ok ) = sh('sshd -t');
    ok( !$ok, 'gescheitert' );
    like( $o, qr{^/etc/ssh/sshd_config: line 6: Bad configuration option: PermitRootLogn$}m, 'Zeile und Schluesselwort' );
    like( $o, qr{terminating, 1 bad configuration options}, 'Abschluss' );
    fresh();
    sh(q{echo 'PasswordAuthentication nein' > /etc/ssh/sshd_config.d/50-cloud-init.conf});
    like( sh('sshd -t'), qr{50-cloud-init\.conf line 1: unsupported option "nein"}, 'ungueltiger Wert' );
};

subtest 'reload und restart: Wirkung und Scheitern' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    sh('rm /etc/ssh/sshd_config.d/50-cloud-init.conf');
    is( srv()->{services}{ssh}{effective}{passwordauthentication}, 'yes', 'Datei allein wirkt nicht' );
    my ( $o, $ok ) = sh('systemctl reload ssh');
    ok( $ok, 'reload gelingt' );
    is( srv()->{services}{ssh}{effective}{passwordauthentication}, 'no', 'nach reload wirksam' );
    ok( !srv()->{services}{ssh}{restarts}, 'reload zaehlt nicht als Neustart' );

    fresh();
    sh(q{echo 'PermitRootLogn no' >> /etc/ssh/sshd_config});
    ( $o, $ok ) = sh('systemctl reload ssh');
    ok( !$ok, 'reload mit kaputter Datei scheitert' );
    ok( srv()->{services}{ssh}{active}, 'sshd laeuft weiter' );
    is( srv()->{services}{ssh}{effective}{passwordauthentication}, 'yes', '... mit der alten Konfiguration' );
    ( $o, $ok ) = sh('journalctl -u ssh');
    ( $o, $ok ) = sh('systemctl restart ssh');
    ok( !$ok, 'restart mit kaputter Datei scheitert' );
    ok( !srv()->{services}{ssh}{active}, 'sshd ist weg' );
    like( sh('id'), qr/Connection refused/, 'ausgesperrt: keine Verbindung mehr' );
    my ( $w, $wok ) = write_file( $state, 'srv', '/tmp/x', 'y' );
    ok( !$wok, 'auch write_file geht nicht mehr' );
};

subtest 'Aussperren ueber AllowGroups und Konto' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    sh(q{sed -i 's/^AllowGroups admins$/AllowGroups sshusers/' /etc/ssh/sshd_config});
    my ( $o, $ok ) = sh('systemctl reload ssh');
    ok( $ok, 'reload gelingt' );
    like( sh('id'), qr/ops\@srv: Permission denied \(publickey\)/, 'ops nicht in sshusers: ausgesperrt' );
    fresh();
    sh('usermod -aG sshusers ops') ;
    fresh();
    sh('usermod -s /usr/sbin/nologin ops');
    like( sh('id'), qr/Permission denied/, 'eigene Shell weg: ausgesperrt' );
};

subtest 'Host-Schluessel zu offen' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    sh('chmod 644 /etc/ssh/ssh_host_ed25519_key');
    my ( $o, $ok ) = sh('sshd -t');
    ok( !$ok, 'sshd -t scheitert' );
    like( $o, qr/Permissions 0644 for '\/etc\/ssh\/ssh_host_ed25519_key' are too open/, 'Meldung' );
    like( $o, qr/no hostkeys available/, 'kein Schluessel ladbar' );
};

subtest 'Konten: sperren, ablaufen, Gruppen, loeschen' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    my ( $o, $ok ) = sh('usermod -L -e 1 -s /usr/sbin/nologin mmeier');
    ok( $ok, 'usermod gelingt' );
    my $u = srv()->{users}{mmeier};
    ok( $u->{locked}, 'gesperrt' );
    is( $u->{expire}, 1, 'Ablauf Tag 1' );
    ok( $u->{expired}, 'abgelaufen' );
    is( $u->{shell}, '/usr/sbin/nologin', 'Shell' );
    like( sh('getent shadow mmeier'), qr/\Ammeier:!\$y\$[^:]*:20332:0:99999:7::1:\z/, 'getent shadow' );
    like( sh('passwd -S mmeier'), qr/\Ammeier L /, 'passwd -S' );
    fresh();
    sh('passwd -l mmeier');
    ok( srv()->{users}{mmeier}{locked}, 'passwd -l' );
    sh('chage -E 0 mmeier');
    ok( srv()->{users}{mmeier}{expired}, 'chage -E 0' );
    like( sh('chage -l mmeier'), qr/Account expires\s*: Jan 01, 1970/, 'chage -l' );
    sh('chage -E 2027-01-01 mmeier');
    ok( !srv()->{users}{mmeier}{expired}, 'Ablauf in der Zukunft: nicht abgelaufen' );
    fresh();
    like( sh('gpasswd -d mmeier sudo'), qr/Removing user mmeier from group sudo/, 'gpasswd -d' );
    like( sh('deluser mmeier docker'), qr/Removing user `mmeier' from group `docker'/, 'deluser benutzer gruppe' );
    is_deeply( srv()->{users}{mmeier}{groups}, [qw( mmeier developers )], 'Gruppen' );
    ( $o, $ok ) = sh('gpasswd -d mmeier sudo');
    ok( !$ok, 'nicht Mitglied: Fehler' );
    fresh();
    sh('usermod -r -G sudo,docker mmeier');
    is_deeply( srv()->{users}{mmeier}{groups}, [qw( mmeier developers )], 'usermod -r -G' );
    fresh();
    sh('userdel -r mmeier');
    ok( !srv()->{users}{mmeier}, 'userdel' );
    ok( !srv()->{files}{'/home/mmeier/notizen.txt'}, '... -r loescht das Home' );
    fresh();
    sh('deluser mmeier');
    ok( srv()->{files}{'/home/mmeier/notizen.txt'}, 'deluser ohne --remove-home laesst das Home' );
};

subtest 'SUID: chmod, ls -l, find -perm' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    like( sh('ls -l /usr/local/bin/helper'), qr/\A-rwsr-xr-x /, 'ls zeigt s' );
    is( sh('find / -perm -4000'), "/usr/bin/passwd\n/usr/local/bin/helper", 'find -perm -4000' );
    is( sh('find / -perm /u=s,g=s -type f'), "/usr/bin/passwd\n/usr/local/bin/helper", 'find -perm /u=s,g=s' );
    like( sh('find /usr/local -perm -4000 -ls'), qr{\A-rwsr-xr-x 1 root\s+root .* /usr/local/bin/helper\z}, 'find -ls' );
    sh('chmod u-s /usr/local/bin/helper');
    is( srv()->{files}{'/usr/local/bin/helper'}{mode}, '0755', 'chmod u-s' );
    sh('chmod g+s,o+t /usr/bin/ls');
    is( srv()->{files}{'/usr/bin/ls'}{mode}, '3755', 'g+s,o+t' );
    like( sh('ls -l /usr/bin/ls'), qr/\A-rwxr-sr-t /, 'ls zeigt s und t' );
    sh('chmod 0755 /usr/bin/passwd');
    is( srv()->{files}{'/usr/bin/passwd'}{mode}, '0755', 'oktal' );
    is( sh('find / -type f -perm 0755'), "/usr/bin/passwd\n/usr/local/bin/helper", 'genaue Rechte' );
};

subtest 'sudo: visudo -c und sudo -l' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    my ( $o, $ok ) = sh('visudo -c');
    ok( $ok, 'visudo -c gelingt' );
    like( $o, qr{\A/etc/sudoers: parsed OK\n/etc/sudoers.d/90-ci: parsed OK\n/etc/sudoers.d/deploy: parsed OK\z}, 'Dateien mit Punkt liest sudo nicht' );
    like( sh('sudo -l -U deploy'), qr{\(root\) NOPASSWD: /usr/bin/systemctl restart shop\n    \(ALL\) NOPASSWD: ALL\z}, 'sudo -l: beide Regeln, in Lesereihenfolge' );
    sh(q{echo 'deploy ALL=(root) NOPASSWD: systemctl restart shop' > /etc/sudoers.d/deploy});
    ( $o, $ok ) = sh('visudo -c');
    ok( !$ok, 'Befehl ohne Pfad: Syntaxfehler' );
    like( $o, qr{>>> /etc/sudoers.d/deploy: syntax error near line 1 <<<}, 'Meldung' );
    like( sh('sudo -l -U deploy'), qr/parse error/, 'sudo kaputt' );
    fresh();
    sh('chmod 644 /etc/sudoers.d/deploy');
    like( sh('visudo -c'), qr{deploy: bad permissions, should be mode 0440}, 'Rechte' );
};

subtest 'grep -r mit Dateinamen' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    is( sh('grep -ri passwordauthentication /etc/ssh'),
        "/etc/ssh/sshd_config:PasswordAuthentication no\n/etc/ssh/sshd_config.d/50-cloud-init.conf:PasswordAuthentication yes", 'grep -r' );
    is( sh('grep -rl Ciphers /etc/ssh/'), '/etc/ssh/sshd_config.d/10-crypto.conf', 'grep -rl' );
    like( sh('grep PermitRoot /etc/ssh'), qr/Is a directory/, 'Verzeichnis ohne -r' );
    is( sh('grep -h Password /etc/ssh/sshd_config /etc/ssh/sshd_config.d/50-cloud-init.conf'), "PasswordAuthentication no\nPasswordAuthentication yes", 'mehrere Dateien, -h' );
};

# Runde 1: was die Modelle taten und der Simulator falsch beantwortete.
subtest 'for-Schleife' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    is( sh('for f in /etc/ssh/sshd_config.d/*.conf; do echo "== $f"; cat "$f"; done'),
        "== /etc/ssh/sshd_config.d/10-crypto.conf\nCiphers chacha20-poly1305\@openssh.com\n== /etc/ssh/sshd_config.d/50-cloud-init.conf\nPasswordAuthentication yes",
        'Glob, Rumpf mit $f' );
    is( sh('for u in ops deploy; do id -nG ${u} || echo kein; done | grep -c ci'), 1, 'done | Filter' );
    like( scalar sh('for x in a b; echo $x'), qr/syntax error/, 'ohne do/done: Syntaxfehler' );
};

subtest 'Programme mit Pfad, installierte Programme' => sub {
    my $why = need_parts('SshAccess', 'RedisService');
    plan skip_all => $why if $why;
    fresh();
    my ( $o, $ok ) = sh('/usr/bin/id ops');
    like( $o, qr/uid=1000\(ops\)/, '/usr/bin/id wie id' );
    ( $o, $ok ) = sh('/bin/systemctl is-active ssh');
    is( $o, 'active', '/bin -> /usr/bin (usrmerge)' );
    ( $o, $ok ) = sh('/usr/sbin/systemctl status ssh');
    like( $o, qr{No such file or directory}, 'falscher Pfad' );
    ( $o, $ok, my $gap ) = sh('/usr/local/bin/helper --version');
    like( $gap // '', qr{/usr/local/bin/helper}, 'Programm aus dem Zustand: Luecke, nicht "command not found"' );
    $state->{srv}{files}{'/usr/bin/redis-cli'} = { mode => '0755', content => '' };
    is( sh('which redis-cli'), '/usr/bin/redis-cli', 'which findet installierte Programme' );
    ( $o, $ok, $gap ) = sh('redis-cli ping');
    unlike( $o, qr/command not found/, 'installiert: nicht "command not found"' );
    ok( $gap, '... sondern Luecke' );
};

subtest 'sudo als Benutzer prueft die Regeln' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    like( sh('sudo -u deploy sudo -l'), qr/User deploy may run the following commands on srv:\n    \(root\) NOPASSWD/, 'sudo -u x sudo -l: Regeln von x' );
    my ( $o, $ok ) = sh('su - deploy -c "sudo -n /usr/bin/systemctl is-active ssh"');
    ok( $ok, 'erlaubt (deploy: NOPASSWD ALL)' );
    sh(q{sed -i 's#NOPASSWD: ALL#NOPASSWD: /usr/bin/true#' /etc/sudoers.d/deploy});
    ( $o, $ok ) = sh('su - deploy -c "sudo -n /usr/bin/systemctl restart shop"');
    unlike( $o, qr/password/, 'ueber %ci erlaubt: genau dieser Befehl' );
    sh('rm /etc/sudoers.d/90-ci');
    ( $o, $ok ) = sh('su - deploy -c "sudo -n /usr/bin/systemctl status ssh"');
    is( $o, 'sudo: a password is required', 'nicht erlaubt: sudo -n' );
    ok( !$ok, '... gescheitert' );
    ( $o, $ok ) = sh('sudo -u deploy sudo systemctl status ssh');
    like( $o, qr/a terminal is required to read the password/, 'ohne -n: kein Terminal' );
    ( $o, $ok ) = sh('sudo -u deploy sudo /usr/bin/true');
    ok( $ok, 'genau der erlaubte Befehl' );
    ( $o, $ok ) = sh('sudo systemctl is-active ssh');
    ok( $ok, 'root: sudo ohne Pruefung' );
};

subtest 'Standardverzeichnisse, crontab' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    my ( $o, $ok ) = sh('ls /etc/cron.daily /var/spool/cron/crontabs');
    ok( $ok, 'leere Debian-Verzeichnisse gibt es' );
    ( $o, $ok ) = sh('crontab -l');
    is( $o, 'no crontab for root', 'crontab -l ohne Eintrag' );
    ok( !$ok, '... Exit 1' );
    $state->{srv}{files}{'/var/spool/cron/crontabs/deploy'} = { content => "5 * * * * /usr/bin/true\n", owner => 'deploy', mode => '0600' };
    is( sh('crontab -l -u deploy'), '5 * * * * /usr/bin/true', 'crontab -l -u' );
};

subtest 'ss, ps, pkill, kill passen zusammen' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    my $ss = sh('ss -tlnp');
    my ($pid) = $ss =~ /0\.0\.0\.0:22\s.*pid=(\d+)/;
    ok( $pid, 'sshd lauscht auf 22' );
    like( sh('ps -C sshd -o pid,comm'), qr/\A\s*PID COMMAND\n\s*$pid sshd\z/, 'ps -C/-o: dieselbe PID' );
    like( sh("ps -p $pid -o pid,user,args"), qr/\A\s*PID USER\s+COMMAND\n\s*$pid root\s+sshd\z/, 'ps -p' );
    like( sh('systemctl status ssh'), qr/Main PID: $pid \(sshd\)/, 'systemctl status: dieselbe PID' );
    sh('pkill -HUP sshd');
    ok( srv()->{services}{ssh}{active}, 'HUP: sshd laeuft weiter' );
    like( sh('journalctl -u ssh -n 1'), qr/Reloaded ssh\.service/, '... und liest neu ein' );
    my ( $o, $ok ) = sh('kill 99999');
    like( $o, qr/\(99999\) - No such process/, 'kill: unbekannte PID' );
    sh("kill $pid");
    ok( !srv()->{services}{ssh}{active}, 'kill: sshd beendet' );
    ( $o, $ok ) = sh('pkill nichtda');
    ok( !$ok, 'pkill ohne Treffer: Exit 1' );
};

subtest 'nft: Version, Position ohne Schluesselwort, delete ohne handle' => sub {
    my $st = { gw => { type => 'linux', nft => { 'inet filter' => { chains => { input => { type => 'filter', hook => 'input', priority => '0', policy => 'drop',
        rules => [ 'ct state established,related accept', 'tcp dport 22 accept' ] } } } } } };
    my $run = sub { my @r = run_command( $st, 'gw', $_[0] ); return wantarray ? @r : $r[0] };
    is( $run->('nft --version'), 'nftables v1.0.6 (Lester Gooch #5)', 'nft --version' );
    my ( $o, $ok ) = $run->('nft insert rule inet filter input 3 tcp dport 22 drop');
    ok( !$ok, 'Zahl vor der Regel: Fehler' );
    like( $o, qr/unexpected number/, '... wie nft' );
    is( scalar @{ $st->{gw}{nft}{'inet filter'}{chains}{input}{rules} }, 2, '... keine Regel dazu' );
    ( $o, $ok ) = $run->('nft delete rule inet filter input 3');
    like( $o, qr/unexpected number, expecting handle/, 'delete ohne handle' );
};

subtest 'sshd: Journal nach Start und Neuladen' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    sh('systemctl reload ssh');
    like( sh('journalctl -u ssh -n 4'), qr/Received SIGHUP; restarting\.\n.*Server listening on 0\.0\.0\.0 port 22\.\n.*Server listening on :: port 22\.\n.*Reloaded ssh\.service/,
        'reload' );
    sh('systemctl restart ssh');
    like( sh('journalctl -u ssh -n 1'), qr/Started ssh\.service - OpenBSD Secure Shell server\./, 'restart' );
};

# Runde 2: find mit Klammern/Operatoren, awk mit Bedingungen.
subtest 'find: ( ), -o, -a, !, Vorrang und Aktionen' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    is( sh('find / -xdev \( -perm -4000 -o -perm -2000 \) -type f'), "/usr/bin/passwd\n/usr/local/bin/helper", 'Klammern' );
    is( sh('find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -print 2>/dev/null'), "/usr/bin/passwd\n/usr/local/bin/helper", 'mit -print' );
    like( sh('find /usr -type f \( -perm -4000 -o -perm -2000 \) -ls'), qr{\A-rwsr-xr-x .*/usr/bin/passwd\n-rwsr-xr-x .*/usr/local/bin/helper\z}, 'mit -ls' );
    sh('chmod 2755 /usr/bin/ls');
    is( sh('find /usr -type f -perm -4000 -o -perm -2000'), "/usr/bin/ls\n/usr/bin/passwd\n/usr/local/bin/helper", 'and vor or' );
    is( sh('find /usr -perm -2000 -o -type f -perm -4000 -print'), "/usr/bin/passwd\n/usr/local/bin/helper", '-print nur im zweiten Zweig (wie find)' );
    is( sh('find /usr -type f ! -perm -4000 -a -not -name passwd'), '/usr/bin/ls', '! und -not, -a' );
    is( sh('find /usr/local -type f -not \( -name helper -o -name x \)'), '', 'Negation einer Klammer' );
    my ( $o, $ok ) = sh('find / \( -perm -4000');
    like( $o, qr/too many '\('/, 'offene Klammer: Fehler wie find' );
    ok( !$ok, '... gescheitert' );
    ( $o, $ok ) = sh('find / -o -perm -4000');
    like( $o, qr/binary operator '-o' with nothing before it/, '-o am Anfang' );
};

subtest 'awk: Bedingungen und print' => sub {
    my @l = ( 'root:x:0:0:root:/root:/bin/bash', 'ops:x:1000:1000::/home/ops:/bin/bash', 'nobody:x:65534:65534::/nonexistent:/usr/sbin/nologin',
        'mmeier:x:1004:1004::/home/mmeier:/bin/bash' );
    my $awk = sub { ( Langertha::Holmgang::Shell::Filter::filter_output( join( "\n", @l ), [ 'awk', @_ ] ) )[0] };
    is( $awk->( '-F:', '$3>=1000 && $3<60000 {print $1}' ), "ops\nmmeier", 'Zahlvergleich mit &&' );
    is( $awk->( '-F', ':', '$7 ~ /nologin/ || $3 == 0 {print $1":"$7}' ), "root:/bin/bash\nnobody:/usr/sbin/nologin", '~, ||, Verkettung' );
    is( $awk->( '-F:', 'NR>1 && $1 !~ /^m/ {print NR, $1}' ), "2 ops\n3 nobody", 'NR, !~, Komma als OFS' );
    is( $awk->( '-F:', '!($3 < 1000) {print $NF}' ), "/bin/bash\n/usr/sbin/nologin\n/bin/bash", '! und Klammern, $NF' );
    is( $awk->( '-F:', '$1 == "ops"' ), 'ops:x:1000:1000::/home/ops:/bin/bash', 'Textvergleich ohne Aktion' );
    is( $awk->( 'BEGIN{FS=":"; OFS="|"} NF==7 && $3>999 {print $1,$3}' ), "ops|1000\nnobody|65534\nmmeier|1004", 'BEGIN mit FS/OFS' );
    is( $awk->( '-F:', '{printf "%s=%d\n", $1, $3}' ), "root=0\nops=1000\nnobody=65534\nmmeier=1004", 'printf' );
    is( $awk->( '-F:', '$4 ~ /1004/ {print $1": "$4}' ), 'mmeier: 1004', 'Feld ~ /re/ mit Literal' );
    # Variablen, Zuweisungen, END und einige Funktionen
    is( $awk->( '-F:', '{ n += $3 } END { print n }' ), '67538', 'Summe mit END' );
    is( $awk->( '-F:', '{print toupper($1)}' ), "ROOT\nOPS\nNOBODY\nMMEIER", 'toupper' );
    is( $awk->( '-F:', '{print substr($1, 1, 2)}' ), "ro\nop\nno\nmm", 'substr' );
    is( $awk->( '-F:', '{print n "|"}' ), "|\n|\n|\n|", 'nicht gesetzte Variable: leer' );
    is( $awk->( '-F:', '{print $1} END {print NR}' ), "root\nops\nnobody\nmmeier\n4", 'END mit NR' );
    is( $awk->( '-F:', 'END {print NR, $1}' ), '4 mmeier', 'nur END: liest die Eingabe, letzter Satz bleibt' );
    # weiterhin nicht nachgebildet: Luecke statt leerer Werte
    ok( !defined $awk->( '-F:', '{print $1 > "/tmp/x"}' ), 'print > datei: Luecke' );
    ok( !defined $awk->( '-F:', '{gsub(/o/, "0"); print}' ), 'gsub: Luecke' );
    ok( !defined $awk->( '-F:', '{ while (n < 3) n++ }' ), 'while: Luecke' );
    # length und Rechnen
    is( $awk->( '-F:', 'NR==2 {print length($1), length}' ), '3 36', 'length(feld) und length ohne Argument' );
    is( $awk->( '-F:', 'length($1) > 4 {print $1}' ), 'nobody\nmmeier' =~ s/\\n/\n/r, 'length im Muster' );
    is( $awk->( '-F:', 'length() == 31 {print NR}' ), '1', 'length()' );
    is( $awk->( '-F:', '$3 > 999 {print $1, $3 / 1000, $3 % 7, $3 * 2 - 1}' ), "ops 1 6 1999\nnobody 65.534 0 131067\nmmeier 1.004 3 2007", '+ - * / %' );
    is( $awk->( '-F:', '{print ($3 + 1) * 2}' ), "2\n2002\n131070\n2010", 'Klammern' );
    is( $awk->( '-v', 'k=1024', '-F:', 'NR==1 {print k * 2}' ), '2048', '-v Variable im Ausdruck' );
    is( ( Langertha::Holmgang::Shell::Filter::filter_output( "a 1\nb 2", [ 'awk', '{print $2, $1}' ] ) )[0], "1 a\n2 b", 'ohne -F: Leerraum' );
};

subtest 'awk BEGIN als Rechner' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    my $awk = sub { ( Langertha::Holmgang::Shell::Filter::filter_output( "x\ny", [ 'awk', @_ ] ) ) };
    is( ( $awk->('BEGIN { print 512 * 1024 }') )[0], '524288', 'print mit Zahl' );
    is( ( $awk->('BEGIN{printf "%.1f GiB\n", 3221225472/1024/1024/1024}') )[0], '3.0 GiB', 'printf' );
    is( ( $awk->('BEGIN { printf("%d%%\n", 45 * 100 / 60) }') )[0], '75%', 'printf( … ) mit Klammern' );
    is( ( $awk->('BEGIN { print 10 / 4, 1 / 3 }') )[0], '2.5 0.333333', 'Kommazahlen wie awk (%.6g)' );
    is( ( $awk->('BEGIN { print "a" "b", 1 + 2 }') )[0], 'ab 3', 'Text und Verkettung' );
    is( ( $awk->('BEGIN { print "start" } {print}') )[0], "start\nx\ny", 'BEGIN vor den Zeilen' );
    my ( $o, $ok ) = $awk->('BEGIN { print 1 / 0 }');
    like( $o, qr/division by zero/, 'Division durch 0: Fehler wie awk' );
    ok( !$ok, '... gescheitert' );
    is( ( $awk->('BEGIN { x = 5; x *= 2; print x }') )[0], '10', 'Zuweisung' );
    # in der Shell: Luecke der Simulation, keine leere Ausgabe
    fresh();
    my ( $so, $sok, $gap ) = sh(q{echo abc | awk '{print sprintf("%s", $1)}'});
    ok( $gap, 'echo | awk sprintf: Luecke' );
    is( scalar sh(q{echo 3 | awk '{print $1 * 1024, length($1)}'}), '3072 1', 'echo | awk mit Rechnen und length' );
};

subtest 'redis-cli: Verbindung nach bind, Anmeldung, roh wie ohne Terminal' => sub {
    my $why = need_parts('RedisService');
    plan skip_all => $why if $why;
    my $st = { r => { type => 'linux', interfaces => { eth0 => { addr => ['192.0.2.30/24'] } },
        files => { '/etc/redis/redis.conf' => "bind 127.0.0.1 -::1\nrequirepass geheim\nbind 0.0.0.0\n" },
        services => { 'redis-server' => { active => JSON::MaybeXS::true(), config => '/etc/redis/redis.conf',
            running => "bind 127.0.0.1 -::1\nrequirepass geheim\nbind 0.0.0.0\n" } } } };
    my $run = sub { my @r = run_command( $st, 'r', $_[0] ); return wantarray ? @r : $r[0] };
    is( $run->("redis-cli -h 127.0.0.1 -p 6379 --no-auth-warning -a 'geheim' ping"), 'PONG', 'richtiges Passwort' );
    is( $run->('redis-cli ping'), 'NOAUTH Authentication required.', 'ohne Passwort' );
    like( $run->('redis-cli -a falsch ping 2>&1 | tail -2'), qr/\AAUTH failed: WRONGPASS.*\nNOAUTH Authentication required\.\z/, 'falsches Passwort' );
    like( $run->('redis-cli -h 192.0.2.30 --no-auth-warning -a geheim ping'), qr/\APONG\z/, 'letzte bind-Zeile (0.0.0.0) gilt: Netzadresse' );
    like( $run->('redis-cli -h ::1 ping'), qr/Could not connect to Redis at ::1:6379: Connection refused/, '... aber nicht ::1' );
    is( $run->('redis-cli --no-auth-warning -a geheim CONFIG GET bind'), "bind\n0.0.0.0", 'CONFIG GET roh' );
    $st->{r}{files}{'/etc/redis/redis.conf'} = "bind 127.0.0.1 -::1\nrequirepass geheim\n";
    like( $run->('redis-cli -h 192.0.2.30 --no-auth-warning -a geheim ping'), qr/\APONG\z/, 'Datei allein wirkt nicht' );
    $run->('systemctl restart redis-server');
    like( $run->('redis-cli -h 192.0.2.30 ping'), qr/Connection refused/, 'nach Neustart: Netzadresse zu' );
    is( $run->('redis-cli -h ::1 --no-auth-warning -a geheim ping'), 'PONG', '... ::1 offen' );
    my ( $o, $ok, $gap ) = $run->('redis-cli --no-auth-warning -a geheim INFO server');
    ok( $gap, 'anderer Befehl: Luecke' );
    like( $run->('redis-server --test-config'), qr/FATAL CONFIG FILE ERROR.*\n.*\n>>> 'test-config'/s, 'redis-server --test-config wie Redis' );
    like( $run->('redis-server --version'), qr/\ARedis server v=7\./, 'redis-server --version' );
    $run->('systemctl stop redis-server');
    like( $run->('redis-cli ping'), qr/\ACould not connect to Redis at 127\.0\.0\.1:6379: Connection refused\z/, 'gestoppt' );
};

subtest 'getfacl' => sub {
    plan skip_all => $NO_SSH if $NO_SSH;
    fresh();
    is( sh('getfacl /usr/local/bin/helper'), "getfacl: Removing leading '/' from absolute path names\n# file: usr/local/bin/helper\n# owner: root\n# group: root\n# flags: s--\nuser::rwx\ngroup::r-x\nother::r-x",
        'Rechte als ACL' );
};

done_testing;
