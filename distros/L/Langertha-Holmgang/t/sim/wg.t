#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# WireGuard im Linux-Simulator. Behauptet wird: eine AllowedIP
# gehoert genau einem Peer (wie wg); wg-quick up/down und die Unit wg-quick@
# setzen Address, MTU und Routen zu den AllowedIPs, fuehren PostUp/PostDown aus,
# und SaveConfig = true schreibt beim Herunterfahren die laufende Konfiguration
# zurueck; eine kaputte Datei laesst den Dienst failed zurueck, mit Grund im Journal.

my ( $A, $B, $C ) = ( 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
    'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=' );
my $conf = <<"C";
[Interface]
Address = 10.66.0.1/24
ListenPort = 51820
PrivateKey = (geheim)
MTU = 1380
PostUp = nft add rule inet filter forward iifname "%i" accept
PostDown = nft flush chain inet filter forward

[Peer]
# Laptop Weber
PublicKey = $A
AllowedIPs = 10.66.0.10/32

[Peer]
# Filiale
PublicKey = $B
AllowedIPs = 10.66.0.2/32, 10.2.0.0/24
C

sub fresh {
    my (%o) = @_;
    return { gw => {
        type       => 'linux',
        interfaces => { eth0 => { addr => ['198.51.100.10/24'], mtu => 1500, state => 'UP' } },
        routes     => [ { dst => 'default', via => '198.51.100.1', dev => 'eth0' } ],
        nft        => { 'inet filter' => { chains => { forward => { type => 'filter', hook => 'forward', priority => '0', policy => 'drop', rules => [] } } } },
        files      => { '/etc/wireguard/wg0.conf' => $o{conf} // $conf },
        services   => { 'wg-quick@wg0' => { active => JSON::MaybeXS::false() } },
    } };
}

subtest 'wg-quick up und down' => sub {
    my $st = fresh();
    my $sh = sub { [ run_command( $st, 'gw', $_[0] ) ] };
    ok( $sh->('wg-quick up wg0')->[1], 'up' ) or diag explain $sh->('wg-quick up wg0');
    my $gw = $st->{gw};
    is_deeply( $gw->{interfaces}{wg0}{addr}, ['10.66.0.1/24'], 'Address' );
    is( $gw->{interfaces}{wg0}{mtu}, 1380, 'MTU' );
    ok( ( grep { $_->{dst} eq '10.2.0.0/24' && $_->{dev} eq 'wg0' } @{ $gw->{routes} } ), 'Route zu AllowedIPs' );
    ok( ( grep { $_->{dst} eq '10.66.0.0/24' && $_->{dev} eq 'wg0' } @{ $gw->{routes} } ), 'Route des eigenen Netzes' );
    is_deeply( $gw->{nft}{'inet filter'}{chains}{forward}{rules}, ['iifname "wg0" accept'], 'PostUp ausgefuehrt (%i ersetzt)' );
    ok( !$gw->{services}{'wg-quick@wg0'}{active}, 'von Hand: die Unit bleibt, wie sie war' );
    ok( !$sh->('wg-quick up wg0')->[1], 'zweimal up: already exists' );
    ok( $sh->('wg-quick down wg0')->[1], 'down' );
    ok( !( grep { ( $_->{dev} // '' ) eq 'wg0' } @{ $gw->{routes} } ), 'Routen weg' );
    is_deeply( $gw->{nft}{'inet filter'}{chains}{forward}{rules}, [], 'PostDown ausgefuehrt' );
};

subtest 'AllowedIPs gehoeren genau einem Peer' => sub {
    my $st = fresh();
    my $sh = sub { [ run_command( $st, 'gw', $_[0] ) ] };
    $sh->('wg-quick up wg0');
    $sh->("wg set wg0 peer $C allowed-ips 10.66.0.2/32,10.2.0.0/24");
    is_deeply( $st->{gw}{wg}{wg0}{peers}{$B}{allowed_ips}, [], 'dem alten Peer genommen' );
    is_deeply( $st->{gw}{wg}{wg0}{peers}{$C}{allowed_ips}, [ '10.66.0.2/32', '10.2.0.0/24' ], 'der neue hat sie' );
    my $dup = $conf . "\n[Peer]\nPublicKey = $C\nAllowedIPs = 10.66.0.10/32\n";
    $st = fresh( conf => $dup );
    run_command( $st, 'gw', 'wg-quick up wg0' );
    is_deeply( $st->{gw}{wg}{wg0}{peers}{$A}{allowed_ips}, [], 'in der Datei gewinnt der spaetere Peer' );
};

subtest 'SaveConfig = true schreibt beim Herunterfahren zurueck' => sub {
    my $st = fresh( conf => $conf =~ s/MTU = 1380\n/MTU = 1380\nSaveConfig = true\n/r );
    my $sh = sub { [ run_command( $st, 'gw', $_[0] ) ] };
    $sh->('systemctl start wg-quick@wg0');
    ok( $st->{gw}{services}{'wg-quick@wg0'}{active}, 'gestartet' );
    # Kollege traegt einen Peer nur in die Datei ein und startet neu
    my $f = $st->{gw}{files}{'/etc/wireguard/wg0.conf'};
    $st->{gw}{files}{'/etc/wireguard/wg0.conf'} = $f . "\n[Peer]\n# Neu\nPublicKey = $C\nAllowedIPs = 10.66.0.30/32\n";
    $sh->('systemctl restart wg-quick@wg0');
    ok( !exists $st->{gw}{wg}{wg0}{peers}{$C}, 'neuer Peer weg: down hat die laufende Konfiguration gespeichert' );
    unlike( $st->{gw}{files}{'/etc/wireguard/wg0.conf'}, qr/\Q$C\E/, '... auch aus der Datei' );
    like( $st->{gw}{files}{'/etc/wireguard/wg0.conf'}, qr/\A\[Interface\]\nAddress = 10\.66\.0\.1\/24.*SaveConfig = true/s, 'Interface-Abschnitt bleibt' );
    is( $st->{gw}{services}{'wg-quick@wg0'}{restarts}, 1, 'Neustart gezaehlt' );
};

subtest 'kaputte Datei: Dienst failed, Grund im Journal' => sub {
    my $st = fresh( conf => $conf =~ s/AllowedIPs = 10.66.0.10\/32/AllowedIP = 10.66.0.10\/32/r );
    my $r = [ run_command( $st, 'gw', 'systemctl start wg-quick@wg0' ) ];
    ok( !$r->[1], 'start scheitert' );
    ok( $st->{gw}{services}{'wg-quick@wg0'}{failed}, 'failed' );
    like( ( run_command( $st, 'gw', 'journalctl -u wg-quick@wg0' ) )[0], qr/Line unrecognized: `AllowedIP=10\.66\.0\.10\/32'/, 'Journal nennt die Zeile' );
    is( ( $st->{gw}{interfaces}{wg0} || {} )->{state} // 'DOWN', 'DOWN', 'Schnittstelle nicht oben' );
};

subtest 'stop' => sub {
    my $st = fresh();
    run_command( $st, 'gw', 'systemctl start wg-quick@wg0' );
    run_command( $st, 'gw', 'systemctl stop wg-quick@wg0' );
    is( $st->{gw}{interfaces}{wg0}{state}, 'DOWN', 'unten' );
    ok( !( grep { ( $_->{dev} // '' ) eq 'wg0' } @{ $st->{gw}{routes} } ), 'Routen weg' );
};

subtest 'Shell: 2>/dev/null, 2>&1, $?' => sub {
    my $st  = fresh();
    my $out = sub { ( run_command( $st, 'gw', $_[0] ) )[0] };
    like( $out->('cat /etc/wireguard/wg0.conf 2>/dev/null'), qr/ListenPort = 51820/, '2>/dev/null laesst die Ausgabe' );
    like( $out->('cat /fehlt 2>&1 | head -1'), qr/No such file/, '2>&1' );
    like( $out->('cat /fehlt; echo "rc=$?"'), qr/rc=1\z/, '$?' );
    like( $out->('timeout 5 cat /etc/wireguard/wg0.conf'), qr/ListenPort/, 'timeout DAUER befehl' );
    $out->("cat > /etc/wireguard/wg9.conf <<'EOF'\n[Interface]\nListenPort = 51999\nEOF\necho fertig");
    is( $st->{gw}{files}{'/etc/wireguard/wg9.conf'}, "[Interface]\nListenPort = 51999\n", 'Heredoc: cat > datei' );
    $out->("cat >> /etc/wireguard/wg9.conf <<-EOF\n\t# Ende\n\tEOF");
    like( $st->{gw}{files}{'/etc/wireguard/wg9.conf'}, qr/51999\n# Ende\n\z/, 'Heredoc <<- und >>' );
    like( $out->("grep -c Listen <<EOF\nListenPort = 1\nEOF"), qr/\A1\z/, 'Heredoc als Eingabe eines Filters' );
    like( $out->('timeout -s KILL 2s cat /etc/wireguard/wg0.conf'), qr/ListenPort/, 'timeout mit Signal und Einheit' );
    $out->(q{sed -i 's/51820/51821/; s/^MTU = 1380$/MTU = 1400/;/^# Filiale$/d' /etc/wireguard/wg0.conf});
    like( $st->{gw}{files}{'/etc/wireguard/wg0.conf'}, qr/ListenPort = 51821\n.*MTU = 1400\n/s, 'sed: mehrere Befehle mit ;' );
    unlike( $st->{gw}{files}{'/etc/wireguard/wg0.conf'}, qr/^# Filiale$/m, '... auch /re/d' );
    $out->(q{sed -i '1i # verwaltet von Ansible' /etc/wireguard/wg0.conf});
    like( $st->{gw}{files}{'/etc/wireguard/wg0.conf'}, qr/\A# verwaltet von Ansible\n\[Interface\]/, 'sed 1i' );
    $out->(q{sed -i '$a # Ende' /etc/wireguard/wg0.conf});
    like( $st->{gw}{files}{'/etc/wireguard/wg0.conf'}, qr/\n# Ende\n\z/, 'sed $a' );
    $out->(q{sed -i '/^ListenPort/a FwMark = 0x1' /etc/wireguard/wg0.conf});
    like( $st->{gw}{files}{'/etc/wireguard/wg0.conf'}, qr/ListenPort = 51821\nFwMark = 0x1\n/, 'sed /re/a' );
    $out->(q{sed -i '/AllowedIPs = 10.66.0.1+/d' /etc/wireguard/wg0.conf});
    like( $st->{gw}{files}{'/etc/wireguard/wg0.conf'}, qr/AllowedIPs = 10\.66\.0\.10/, 'sed /re/d liest BRE (+ woertlich)' );
    $out->("cat > /etc/wireguard/t.conf <<'EOF'\n[Interface]\nA = 1\n# alt\nB = 2\n\n[Peer]\nC = 3\nD = 3\nEOF");
    $out->(q{sed -i '/^# alt$/,/^$/d' /etc/wireguard/t.conf});
    is( $st->{gw}{files}{'/etc/wireguard/t.conf'}, "[Interface]\nA = 1\n[Peer]\nC = 3\nD = 3\n", 'sed /a/,/b/d: Bereich' );
    $out->(q{sed -i '/^C/s/3/4/' /etc/wireguard/t.conf});
    like( $st->{gw}{files}{'/etc/wireguard/t.conf'}, qr/C = 4\nD = 3\n/, 'sed /re/s///: nur auf passenden Zeilen' );
    $out->(q{sed -i '/^\[Peer\]/,$d' /etc/wireguard/t.conf});
    is( $st->{gw}{files}{'/etc/wireguard/t.conf'}, "[Interface]\nA = 1\n", 'sed /re/,$d: bis zum Ende' );
    $out->(q{sed -i '2,$d' /etc/wireguard/t.conf});
    is( $st->{gw}{files}{'/etc/wireguard/t.conf'}, "[Interface]\n", 'sed 2,$d' );
};

subtest 'wg show: latest-handshakes, persistent-keepalive, dump; date +%s' => sub {
    my $st = fresh();
    my $out = sub { ( run_command( $st, 'gw', $_[0] ) )[0] };
    $st->{gw}{wg}{wg0} = { public_key => $C, listen_port => 51820, peers => {
        $A => { allowed_ips => ['10.66.0.10/32'], handshake => '2 days, 3 hours, 1 minute ago', endpoint => '203.0.113.5:4000' },
        $B => { allowed_ips => [ '10.66.0.2/32', '10.2.0.0/24' ], keepalive => 25 } } };
    my $now = $out->('date +%s');
    is( $now, '1792576800', 'date +%s: fester Zeitpunkt (Tue Oct 21 12:00:00 CEST 2026)' );
    is( $out->('wg show wg0 latest-handshakes'), "$A\t" . ( 1792576800 - ( 2 * 86400 + 3 * 3600 + 60 ) ) . "\n$B\t0" =~ s/\n\z//r,
        'latest-handshakes: Sekunden seit 1970, nie = 0' );
    is( $out->('wg show wg0 persistent-keepalive'), "$A\toff\n$B\t25", 'persistent-keepalive' );
    my @d = split /\n/, $out->('wg show wg0 dump');
    is( $d[0], "(hidden)\t$C\t51820\toff", 'dump: Schnittstelle' );
    is( $d[2], "$B\t(none)\t(none)\t10.66.0.2/32,10.2.0.0/24\t0\t0\t0\t25", 'dump: Peer ohne Handshake' );
    like( $out->('wg show all latest-handshakes'), qr/\Awg0\t\Q$A\E\t\d+\n/, 'show all: mit Schnittstelle vorn' );
    # wg syncconf <(wg-quick strip wg0): der Name kommt aus dem Aufruf, nicht aus einer frueheren Suche ($1)
    $st->{gw}{files}{'/etc/wireguard/wg0.conf'} = "[Interface]\nAddress = 10.66.0.1/24\nListenPort = 51820\n\n[Peer]\nPublicKey = $A\nAllowedIPs = 10.66.0.99/32\n";
    'fall-15' =~ /(\d+)/;
    $out->('wg syncconf wg0 <(wg-quick strip wg0)');
    is_deeply( $st->{gw}{wg}{wg0}{peers}{$A}{allowed_ips}, ['10.66.0.99/32'], 'syncconf liest wg0.conf, auch mit $1 von aussen' );
    $out->('sysctl net.ipv4.ip_forward');
    ok( !exists $st->{gw}{sysctl}, 'sysctl lesen legt keinen Zustand an' );
};

done_testing;
