#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command need_parts );

use Langertha::Holmgang::Sim::Linux::Dns ();
use Langertha::Holmgang::Sim::Linux ();

# BIND und Postfix auf dem Linux-Simulator. Behauptet wird:
# Zonendateien werden wie von named gelesen (relative Namen, $ORIGIN, Klammern,
# geerbter Besitzer, TXT in Teilen) und wie von named-checkzone geprueft; erst
# rndc reload bzw. systemctl reload laedt, eine fehlerhafte Zone behaelt den
# alten Stand, ein Neustart laedt sie nicht; dig antwortet aus dem Geladenen;
# eine Sekundaere uebernimmt nur mit hoeherer Seriennummer und erlaubtem
# Transfer; named.conf-Fehler lassen reload scheitern. Postfix: postconf
# schreibt die Datei, erst reload wirkt; Zahlen ohne Einheit; postmap baut die
# .db mit den Rechten der Quelle; postqueue -f stellt nur zu, was deliver_when
# erfuellt; postsuper loescht.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $T = JSON::MaybeXS::true();

my $zone = <<'EOT';
$TTL 3600
@   IN SOA ns1.example.com. hostmaster.example.com. (
        2026102001 ; serial
        3600 900 1209600 300 )
    IN NS  ns1
    IN NS  ns2.example.com.
    IN MX  10 mail
ns1 IN A   192.0.2.53
ns2 IN A   192.0.2.54
mail      IN A 192.0.2.25
www  300  IN CNAME web
web       IN A 192.0.2.80
@         IN TXT "v=spf1 " "mx -all"
EOT

my $conf_local = <<'EOT';
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-transfer { 192.0.2.54; };
};
EOT
my $conf = qq{include "/etc/bind/named.conf.options";\ninclude "/etc/bind/named.conf.local";\n};
my $opts = qq{options {\n    directory "/var/cache/bind";\n    recursion no;\n};\n};

sub world {
    my %o = @_;
    my $s = {
        ns1 => {
            type => 'linux', interfaces => { eth0 => { addr => ['192.0.2.53/24'], state => 'UP' } },
            files => { '/etc/bind/named.conf' => $conf, '/etc/bind/named.conf.options' => $opts,
                '/etc/bind/named.conf.local' => $o{local} // $conf_local, '/etc/bind/db.example.com' => $zone,
                '/etc/resolv.conf' => "nameserver 127.0.0.1\n" },
            services => { named => { active => $T, description => 'BIND Domain Name Server' } },
            bind => {},
        },
        ns2 => {
            type => 'linux', interfaces => { eth0 => { addr => ['192.0.2.54/24'], state => 'UP' } },
            files => { '/etc/bind/named.conf' => qq{zone "example.com" { type slave; masters { 192.0.2.53; }; file "/var/cache/bind/db.example.com"; };\n} },
            services => { named => { active => $T } },
            bind => { source => { 'example.com' => $zone } },
        },
    };
    for my $h ( sort keys %$s ) { Langertha::Holmgang::Sim::Linux->prepare( $s->{$h}, { host => $h, state => $s } ) }
    return $s;
}
sub run { my ( $s, $h, $c ) = @_; my ( $o, $ok ) = run_command( $s, $h, $c ); return wantarray ? ( $o, $ok ) : $o }
sub recs { my ( $s, $h ) = @_; return $s->{$h}{bind}{zones}{'example.com'}{records} }

subtest 'Zone lesen' => sub {
    my $p = Langertha::Holmgang::Sim::Linux::Dns::parse_zone( $zone, 'example.com' );
    ok( $p->{ok}, 'laedt' ) or diag explain $p;
    is( $p->{serial}, 2026102001, 'Seriennummer' );
    my %r = map { $_ => 1 } @{ $p->{records} };
    ok( $r{'example.com. 3600 IN MX 10 mail.example.com.'}, 'MX relativ ergaenzt' );
    ok( $r{'www.example.com. 300 IN CNAME web.example.com.'}, 'TTL je Eintrag' );
    ok( $r{'example.com. 3600 IN TXT "v=spf1 mx -all"'}, 'TXT-Teile zusammengefuegt' );
    ok( $r{'example.com. 3600 IN NS ns2.example.com.'}, 'geerbter Besitzer' );

    my $bad = Langertha::Holmgang::Sim::Linux::Dns::parse_zone( $zone . "www IN TXT \"x\"\n", 'example.com' );
    ok( !$bad->{ok}, 'CNAME und andere Daten: laedt nicht' );
    like( "@{ $bad->{errors} }", qr/www\.example\.com: CNAME and other data/, '… mit Meldung von named' );
    my $ns = Langertha::Holmgang::Sim::Linux::Dns::parse_zone( $zone =~ s/^ns2 IN A.*\n//mr =~ s/ns2\.example\.com\./ns3/r, 'example.com' );
    like( "@{ $ns->{errors} }", qr/NS 'ns3\.example\.com' has no address records/, 'NS ohne Adresse' );
    my $long = Langertha::Holmgang::Sim::Linux::Dns::parse_zone( $zone . 'k._domainkey IN TXT "' . ( 'A' x 300 ) . "\"\n", 'example.com' );
    like( "@{ $long->{errors} }", qr/ran out of space/, 'TXT ueber 255 Zeichen' );
    my $split = Langertha::Holmgang::Sim::Linux::Dns::parse_zone( $zone . 'k._domainkey IN TXT ( "' . ( 'A' x 200 ) . "\"\n  \"" . ( 'B' x 100 ) . "\" )\n", 'example.com' );
    ok( $split->{ok}, 'TXT in Teilen ueber Zeilen' );
    my $out = Langertha::Holmgang::Sim::Linux::Dns::parse_zone( $zone . "mail.example.org. IN A 192.0.2.99\n", 'example.com' );
    ok( $out->{ok}, 'Daten ausserhalb: laedt' );
    like( "@{ $out->{warnings} }", qr/ignoring out-of-zone data \(mail\.example\.org\)/, '… mit Warnung' );
    ok( !Langertha::Holmgang::Sim::Linux::Dns::parse_zone( $zone . "x IN A 192.0.2.300\n", 'example.com' )->{ok}, 'falsche Adresse' );
};

subtest 'Laden und dig' => sub {
    my $s = world();
    is( run( $s, 'ns1', 'dig +short example.com MX' ), '10 mail.example.com.', 'dig aus dem Geladenen (Server aus resolv.conf)' );
    is( run( $s, 'ns1', 'dig +short MX example.com' ), '10 mail.example.com.', 'dig: Typ vor dem Namen (vorher Name und Typ vertauscht)' );
    like( run( $s, 'ns1', 'dig MX example.com' ), qr/^;example\.com\.\t+IN\tMX$/m, '... Frage mit Name und Typ' );
    is( run( $s, 'ns1', 'dig @192.0.2.54 www.example.com +short' ), "web.example.com.\n192.0.2.80", 'CNAME verfolgt, an der Sekundaeren' );
    like( run( $s, 'ns1', 'dig nix.example.com' ), qr/status: NXDOMAIN/, 'NXDOMAIN' );
    like( run( $s, 'ns1', 'host -t TXT example.com' ), qr/descriptive text "v=spf1 " "mx -all"/, 'host zeigt die Teile' );

    $s->{ns1}{files}{'/etc/bind/db.example.com'} =~ s/192\.0\.2\.80/192.0.2.81/;
    is( run( $s, 'ns1', 'dig +short web.example.com' ), '192.0.2.80', 'nur Datei geaendert: alter Stand' );
    is( ( run( $s, 'ns1', 'rndc reload' ) )[0], 'server reload successful', 'rndc reload' );
    is( run( $s, 'ns1', 'dig +short web.example.com' ), '192.0.2.81', 'geladen' );
    is( run( $s, 'ns2', 'dig @127.0.0.1 +short web.example.com' ), '192.0.2.80', 'Sekundaere: Seriennummer gleich, kein Transfer' );

    $s->{ns1}{files}{'/etc/bind/db.example.com'} =~ s/2026102001/2026102002/;
    run( $s, 'ns1', 'systemctl reload named' );
    is( run( $s, 'ns2', 'dig @127.0.0.1 +short web.example.com' ), '192.0.2.81', 'hoehere Seriennummer: NOTIFY und Transfer' );
    is( $s->{ns2}{bind}{zones}{'example.com'}{serial}, 2026102002, 'Seriennummer der Sekundaeren' );

    $s->{ns1}{files}{'/etc/bind/db.example.com'} .= "web IN CNAME mail\n";
    my ( $o, $ok ) = run( $s, 'ns1', 'rndc reload example.com' );
    ok( !$ok, 'fehlerhafte Zone: rndc reload zone scheitert' );
    is( run( $s, 'ns1', 'dig +short web.example.com' ), '192.0.2.81', '… alter Stand bleibt' );
    ( $o, $ok ) = run( $s, 'ns1', 'named-checkzone example.com /etc/bind/db.example.com' );
    ok( !$ok, 'named-checkzone meldet' );
    like( $o, qr/CNAME and other data/, '… den Grund' );
    run( $s, 'ns1', 'systemctl restart named' );
    like( run( $s, 'ns1', 'dig web.example.com' ), qr/status: SERVFAIL/, 'Neustart: Zone nicht geladen' );
    is( $s->{ns1}{services}{named}{restarts}, 1, 'Neustart gezaehlt' );
};

subtest 'Transfer erlaubt?' => sub {
    my $s = world( local => $conf_local =~ s/192\.0\.2\.54/192.0.2.99/r );
    $s->{ns1}{files}{'/etc/bind/db.example.com'} =~ s/2026102001/2026102002/;
    $s->{ns1}{files}{'/etc/bind/db.example.com'} .= "neu IN A 192.0.2.7\n";
    run( $s, 'ns1', 'rndc reload' );
    is( $s->{ns2}{bind}{zones}{'example.com'}{serial}, 2026102001, 'nicht erlaubt: kein Transfer' );
    like( "@{ $s->{ns2}{bind}{log} }", qr/REFUSED/, '… REFUSED im Log der Sekundaeren' );
    $s->{ns1}{files}{'/etc/bind/named.conf.local'} = $conf_local;
    run( $s, 'ns1', 'rndc reconfig' );
    run( $s, 'ns2', 'rndc retransfer example.com' );
    is( run( $s, 'ns2', 'dig @127.0.0.1 +short neu.example.com' ), '192.0.2.7', 'erlaubt und retransfer: neu' );
    like( run( $s, 'ns1', 'dig @192.0.2.53 example.com AXFR' ), qr/Transfer failed/, 'AXFR vom Primaeren selbst: nicht erlaubt' );
};

subtest 'named.conf' => sub {
    my $s = world();
    $s->{ns1}{files}{"/etc/bind/named.conf.local"} = "zone \"example.com\" {\n type master;\n file \"/etc/bind/db.example.com\"\n};\n";
    my ( $o, $ok ) = run( $s, 'ns1', 'named-checkconf' );
    ok( !$ok, 'fehlendes ; erkannt' );
    like( $o, qr{named\.conf\.local:4: missing ';' before '\}'}, '… mit Zeile' );
    ( $o, $ok ) = run( $s, 'ns1', 'rndc reload' );
    ok( !$ok, 'rndc reload scheitert' );
    ( $o, $ok ) = run( $s, 'ns1', 'systemctl restart named' );
    ok( !$ok, 'Neustart scheitert' );
    my $rel = world();
    $rel->{ns1}{files}{"/etc/bind/named.conf.local"} = $conf_local =~ s{/etc/bind/db\.example\.com}{db.example.com}r;
    ( $o, $ok ) = run( $rel, 'ns1', 'named-checkconf -z' );
    ok( !$ok, 'relative Datei unter /var/cache/bind: nicht gefunden' );
    like( $o, qr/file not found/, '… Meldung' );
    is( run( world(), 'ns1', 'named-checkconf -z' ), 'zone example.com/IN: loaded serial 2026102001', 'named-checkconf -z ok' );
    my ( $x, $k ) = run( { h => { type => 'linux' } }, 'h', 'dig example.com' );
    like( $x, qr/dig: command not found/, 'ohne bind/dnsutils kein dig' );
};

my $main = <<'EOT';
myhostname = mail.example.com
relayhost =
mynetworks = 127.0.0.0/8 [::1]/128
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
EOT

sub mail {
    my $s = { mx => {
        type => 'linux', interfaces => { eth0 => { addr => ['10.20.0.25/24'], state => 'UP' } },
        files => { '/etc/postfix/main.cf' => $main,
            '/etc/postfix/sasl_passwd' => { content => "[smtp.example.net]:587 relay\@example.com:geheim\n", owner => 'root', group => 'root', mode => '0600' },
            '/etc/aliases' => "postmaster: root\n" },
        services => { postfix => { active => $T } },
        postfix => { queue => [
            { id => 'A1B2C3D4E5', from => 'shop@example.com', to => ['kunde@example.org'], size => 2048, reason => 'connect to example.org[203.0.113.5]:25: Connection timed out',
              deliver_when => [ { path => [qw( postfix running relayhost )], equals => '[smtp.example.net]:587' },
                                { path => [ 'files', '/etc/postfix/sasl_passwd.db', 'content' ], regex => 'relay@example\.com' } ] },
            { id => 'F6A7B8C9D0', from => 'MAILER-DAEMON', to => ['spam@example.invalid'], size => 1024, reason => 'Host not found' },
        ] },
    } };
    Langertha::Holmgang::Sim::Linux->prepare( $s->{mx}, { host => 'mx', state => $s } );
    return $s;
}

subtest 'Postfix' => sub {
    my $s = mail();
    is( $s->{mx}{postfix}{running}{relayhost}, '', 'prepare liest main.cf' );
    run( $s, 'mx', "postconf -e 'relayhost = [smtp.example.net]:587'" );
    like( $s->{mx}{files}{'/etc/postfix/main.cf'}, qr/^relayhost = \[smtp\.example\.net\]:587$/m, 'postconf -e schreibt die Datei' );
    is( run( $s, 'mx', 'postconf -h relayhost' ), '[smtp.example.net]:587', 'postconf liest die Datei' );
    is( $s->{mx}{postfix}{running}{relayhost}, '', '… laufend noch nicht' );
    # deliver_when sind Erwartungen am Zustand: die wertet Expectation (k2) aus
    my $why = need_parts('+Expectation');
    SKIP: {
        skip $why, 1 if $why;
        run( $s, 'mx', 'postqueue -f' );
        is( scalar @{ $s->{mx}{postfix}{queue} }, 2, 'ohne reload: nichts zugestellt' );
    }
    run( $s, 'mx', 'postfix reload' );
    SKIP: {
        skip $why, 1 if $why;
        run( $s, 'mx', 'postqueue -f' );
        is( scalar @{ $s->{mx}{postfix}{queue} }, 2, 'ohne .db: nichts zugestellt' );
    }
    my ( $o, $ok ) = run( $s, 'mx', 'postmap -q "[smtp.example.net]:587" hash:/etc/postfix/sasl_passwd' );
    ok( !$ok, 'postmap -q ohne .db scheitert' );
    run( $s, 'mx', 'postmap /etc/postfix/sasl_passwd' );
    is( $s->{mx}{files}{'/etc/postfix/sasl_passwd.db'}{mode}, '0600', '.db mit den Rechten der Quelle' );
    is( run( $s, 'mx', 'postmap -q "[smtp.example.net]:587" hash:/etc/postfix/sasl_passwd' ), 'relay@example.com:geheim', 'postmap -q' );
    SKIP: {
        skip $why, 4 if $why;
        run( $s, 'mx', 'postqueue -f' );
        is_deeply( $s->{mx}{postfix}{delivered}, ['A1B2C3D4E5'], 'zugestellt, was deliver_when erfuellt' );
        like( run( $s, 'mx', 'mailq' ), qr/F6A7B8C9D0\s+1024 .*MAILER-DAEMON/, 'mailq zeigt den Rest' );
        is( run( $s, 'mx', 'postsuper -d F6A7B8C9D0' ), 'postsuper: Deleted: 1 message', 'postsuper -d' );
        is( run( $s, 'mx', 'mailq' ), 'Mail queue is empty', 'leer' );
    }

    run( $s, 'mx', 'postconf -e message_size_limit=50M' );
    ( $o, $ok ) = run( $s, 'mx', 'postfix reload' );
    ok( !$ok, 'Zahl mit Einheit: reload scheitert' );
    like( $o, qr/bad numerical configuration: message_size_limit = 50M/, '… wie Postfix' );
    ( $o, $ok ) = run( $s, 'mx', 'systemctl reload postfix' );
    ok( !$ok, '… auch ueber systemctl' );
    ok( !exists $s->{mx}{postfix}{running}{message_size_limit}, 'laufend unveraendert' );
    run( $s, 'mx', 'postconf -e message_size_limit=52428800' );
    run( $s, 'mx', 'systemctl reload postfix' );
    is( $s->{mx}{postfix}{running}{message_size_limit}, '52428800', 'reload uebernimmt' );
    is( $s->{mx}{services}{postfix}{restarts} // 0, 0, 'reload zaehlt nicht als Neustart' );

    run( $s, 'mx', 'echo "root: ops@example.com" >> /etc/aliases' );
    ok( !exists $s->{mx}{files}{'/etc/aliases.db'}, 'ohne newaliases keine .db' );
    run( $s, 'mx', 'newaliases' );
    like( $s->{mx}{files}{'/etc/aliases.db'}{content}, qr/root: ops\@example\.com/, 'newaliases baut /etc/aliases.db' );
    like( run( { h => { type => 'linux' } }, 'h', 'postconf' ), qr/postconf: command not found/, 'ohne postfix nicht installiert' );
};

done_testing;
