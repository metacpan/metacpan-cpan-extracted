#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Shell ();
use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Der Linux-Simulator. Behauptet wird: gaengige Lese- und
# Aenderungsbefehle (ip, wg, nft, sysctl, systemctl, nmcli, Dateien) laufen
# wirklich auf dem Zustand, der naechste Lesebefehl zeigt die Aenderung; was
# nicht geht, antwortet wie Debian (command not found, RTNETLINK, nft-Fehler)
# und laesst den Zustand unveraendert; Ketten (&&, ;) und Filter (| grep)
# wirken; nichts verraet eine Loesung.

my $KEY = 'xXzI5m7S4qHDvy9bDDQWtBZGai8J3s7iT0Fm2ga3wak=';
my $start = {
    gw => {
        type       => 'linux',
        interfaces => {
            eth0 => { addr => ['198.51.100.10/29'], mtu => 1500, state => 'UP' },
            eth1 => { addr => ['10.1.0.1/24'],      mtu => 1500, state => 'UP' },
            wg0  => { addr => ['10.255.0.1/30'],    mtu => 1420, state => 'UP' },
        },
        routes => [
            { dst => 'default', via => '198.51.100.9', dev => 'eth0' },
            { dst => '10.1.0.0/24', dev => 'eth1', proto => 'kernel', scope => 'link', src => '10.1.0.1' },
            { dst => '198.51.100.8/29', dev => 'eth0', proto => 'kernel', scope => 'link', src => '198.51.100.10' },
            { dst => '10.255.0.0/30', dev => 'wg0', proto => 'kernel', scope => 'link', src => '10.255.0.1' },
        ],
        sysctl => { 'net.ipv4.ip_forward' => '0', 'net.netfilter.nf_conntrack_max' => '65536' },
        nft    => { 'inet filter' => { chains => { forward => { type => 'filter', hook => 'forward', priority => '0',
            policy => 'drop', rules => ['ct state established,related accept'] } } },
            'ip nat' => { chains => { postrouting => { type => 'nat', hook => 'postrouting', priority => 'srcnat', policy => 'accept', rules => [] } } } },
        wg => { wg0 => { address => '10.255.0.1/30', listen_port => 51820, public_key => 'uyhtpkJZpF/fK4j5Fzj03nQ4HZS6X9rzozM8u6OQw50=',
            peers => { $KEY => { allowed_ips => ['10.255.0.2/32'], endpoint => '203.0.113.50:40112' } } } },
        files    => { '/etc/dnsmasq.conf' => "dhcp-range=10.1.0.100,10.1.0.199,12h\ndhcp-option=option:dns-server,10.1.0.1\n" },
        services => { dnsmasq => { active => JSON::MaybeXS::true(), config => '/etc/dnsmasq.conf',
            running => "dhcp-range=10.1.0.100,10.1.0.199,12h\ndhcp-option=option:dns-server,10.1.0.1\n" },
            'wg-quick@wg0' => { active => JSON::MaybeXS::true() } },
        nm => { connections => { lte => { device => 'wwan0', default_metric => 700, props => { 'ipv4.route-metric' => '-1' } } } },
    },
};
use JSON::MaybeXS ();

my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok ) = run_command( $state, 'gw', $cmd );
    return wantarray ? ( $o, $ok ) : $o;
}
sub unchanged { is_deeply( $state, clone($start), $_[0] ) }

fresh();

# --- unbekannt, Shell -------------------------------------------------------
{
    my ( $o, $ok ) = sh('iptables -t nat -L');
    is( $o, 'bash: iptables: command not found', 'iptables fehlt (nftables-System)' );
    ok( !$ok, '... gescheitert' );
    ( $o, $ok ) = run_command( $state, 'nix', 'ip route' );
    like( $o, qr/Could not resolve hostname nix/, 'unbekanntes Geraet wie ssh' );
    ( $o, $ok ) = sh(q{echo "offen});
    like( $o, qr/unexpected EOF/, 'offenes Anfuehrungszeichen' );
    is( sh('sudo ip route | grep default'), 'default via 198.51.100.9 dev eth0', 'sudo und | grep' );
    is( sh('ip route | wc -l'), 4, '| wc -l' );
    unchanged('Lesen aendert nichts');
}

# --- ip route ---------------------------------------------------------------
{
    my ( $o, $ok ) = sh('ip route add 10.2.0.0/24 via 10.9.9.9');
    is( $o, 'Error: Nexthop has invalid gateway.', 'Gateway nicht im verbundenen Netz' );
    ( $o, $ok ) = sh('ip route add 10.2.0.0/24 dev eth9');
    is( $o, 'Cannot find device "eth9"', 'unbekannte Schnittstelle' );
    ( $o, $ok ) = sh('ip route add 10.2.0.0/24 vai 10.1.0.2');
    like( $o, qr/"vai" is a garbage/, 'Tippfehler wie iproute2' );
    unchanged('Fehler aendern nichts');

    ( $o, $ok ) = sh('ip route add 10.2.0.0/24 via 10.1.0.2 metric 50');
    ok( $ok, 'Route angelegt' );
    like( sh('ip r'), qr{^10\.2\.0\.0/24 via 10\.1\.0\.2 dev eth1 metric 50$}m, 'dev aus dem Gateway, Kurzform ip r' );
    ( $o, $ok ) = sh('ip route add 10.2.0.0/24 via 10.1.0.2 metric 50');
    is( $o, 'RTNETLINK answers: File exists', 'doppelt' );
    like( sh('ip route get 10.2.0.7'), qr/\A10\.2\.0\.7 via 10\.1\.0\.2 dev eth1 src 10\.1\.0\.1 /, 'route get' );
    sh('ip route replace 10.2.0.0/24 via 10.1.0.3 metric 50');
    like( sh('ip route show 10.2.0.0/24'), qr/via 10\.1\.0\.3/, 'replace' );
    ok( ( sh('ip route del 10.2.0.0/24') )[1], 'del' );
    is( ( sh('ip route del 10.2.0.0/24') )[0], 'RTNETLINK answers: No such process', 'del ohne Route' );

    sh('ip rule add from 10.1.0.0/25 table 200 priority 100');
    sh('ip route add default via 198.51.100.11 table 200');
    like( sh('ip rule'), qr/^100:\tfrom 10\.1\.0\.0\/25 lookup 200$/m, 'ip rule' );
    like( sh('ip route get 8.8.8.8 from 10.1.0.5'), qr/via 198\.51\.100\.11 dev eth0 table 200/, 'Policy-Routing wirkt in route get' );
    like( sh('ip route get 8.8.8.8 from 10.1.0.200'), qr/via 198\.51\.100\.9 /, '... nur fuer passende Quelle' );
    like( sh('ip route show table 200'), qr/^default via 198\.51\.100\.11 dev eth0$/m, 'Tabelle 200' );
}

# --- ip link / addr ---------------------------------------------------------
{
    fresh();
    like( sh('ip link show wg0'), qr/^\d+: wg0: <[^>]+> mtu 1420 /, 'ip link show' );
    my ( $o, $ok ) = sh('ip link set dev wg0 mtu 1380');
    ok( $ok, 'mtu gesetzt' );
    is( $state->{gw}{interfaces}{wg0}{mtu}, 1380, '... im Zustand (Zahl)' );
    like( sh('ip -br link'), qr/^wg0\s+UP/m, '-br' );
    is( ( sh('ip link set wg0 mtu viel') )[0], 'Error: argument "viel" is wrong: Invalid "mtu" value', 'mtu kaputt' );
    sh('ip addr add 10.1.0.2/24 dev eth1');
    like( sh('ip a show eth1'), qr/inet 10\.1\.0\.2\/24/, 'Adresse dazu' );
}

# --- WireGuard --------------------------------------------------------------
{
    fresh();
    like( sh('wg'), qr/peer: \Q$KEY\E\n  endpoint: 203\.0\.113\.50:40112\n  allowed ips: 10\.255\.0\.2\/32/, 'wg show' );
    sh("wg set wg0 peer $KEY allowed-ips 10.255.0.2/32,10.2.0.0/24");
    is_deeply( $state->{gw}{wg}{wg0}{peers}{$KEY}{allowed_ips}, [ '10.255.0.2/32', '10.2.0.0/24' ], 'wg set ersetzt die Liste' );
    like( sh('cat /etc/wireguard/wg0.conf'), qr/AllowedIPs = 10\.255\.0\.2\/32, 10\.2\.0\.0\/24/, 'Datei aus dem Zustand' );
    my ( $o, $ok ) = sh('wg set wg0 peer kaputt allowed-ips 10.0.0.0/8');
    like( $o, qr/Key is not the correct length or format/, 'kaputter Schluessel' );
    sh('wg set wg0 peer uyhtpkJZpF/fK4j5Fzj03nQ4HZS6X9rzozM8u6OQw50= allowed-ips 10.9.0.0/24');
    is( scalar keys %{ $state->{gw}{wg}{wg0}{peers} }, 2, 'unbekannter Schluessel legt (wie wg) einen neuen Peer an' );

    fresh();
    sh(q{wg showconf wg0 > /etc/wireguard/wg0.conf && sed -i 's#^AllowedIPs = .*#AllowedIPs = 10.255.0.2/32, 10.3.0.0/24#' /etc/wireguard/wg0.conf});
    is_deeply( $state->{gw}{wg}{wg0}{peers}{$KEY}{allowed_ips}, ['10.255.0.2/32'], 'nur Datei: Laufzeit unveraendert' );
    ok( ( sh('wg syncconf wg0 <(wg-quick strip wg0)') )[1], 'syncconf' );
    is_deeply( $state->{gw}{wg}{wg0}{peers}{$KEY}{allowed_ips}, [ '10.255.0.2/32', '10.3.0.0/24' ], '... uebernommen' );
}

# --- nftables -------------------------------------------------------------
{
    fresh();
    my ( $o, $ok ) = sh('nft add rule ip nat postrouting ip saddr 10.99.0.0/24 oifname eth0 masquerade');
    ok( $ok, 'Regel angehaengt' );
    is_deeply( $state->{gw}{nft}{'ip nat'}{chains}{postrouting}{rules}, ['ip saddr 10.99.0.0/24 oifname "eth0" masquerade'],
        'Schnittstellenname in Anfuehrungszeichen wie nft' );
    like( sh('nft list ruleset'), qr/chain postrouting \{\n\t\ttype nat hook postrouting priority srcnat; policy accept;\n\t\tip saddr/, 'list ruleset' );
    ( $o, $ok ) = sh('nft add rule ip nat POSTROUTING masquerade');
    like( $o, qr/\AError: Could not process rule: No such file or directory/, 'Kette gibt es nicht' );
    ( $o, $ok ) = sh(q{nft 'insert rule inet filter forward iifname "wg0" accept'});
    is( $state->{gw}{nft}{'inet filter'}{chains}{forward}{rules}[0], 'iifname "wg0" accept', 'insert vorn (ein Argument)' );
    like( sh('nft -a list chain inet filter forward'), qr/ct state established,related accept # handle (\d+)/, 'Handles' );
    my ($h) = sh('nft -a list chain inet filter forward') =~ /ct state established,related accept # handle (\d+)/;
    ok( ( sh("nft delete rule inet filter forward handle $h") )[1], 'delete per handle' );
    is_deeply( $state->{gw}{nft}{'inet filter'}{chains}{forward}{rules}, ['iifname "wg0" accept'], '... weg' );
    sh('nft flush ruleset');
    is_deeply( $state->{gw}{nft}, {}, 'flush ruleset leert alles (Nebenschaden sichtbar)' );
}

# --- sysctl, Dateien, Dienste ----------------------------------------------
{
    fresh();
    is( sh('sysctl net.ipv4.ip_forward'), 'net.ipv4.ip_forward = 0', 'sysctl lesen' );
    is( sh('sysctl -w net.ipv4.ip_forward=1'), 'net.ipv4.ip_forward = 1', 'sysctl -w' );
    is( sh('cat /proc/sys/net/ipv4/ip_forward'), '1', '/proc/sys' );
    my ( $o, $ok ) = sh('sysctl -w net.ipv4.gibtsnicht=1');
    like( $o, qr/cannot stat \/proc\/sys\/net\/ipv4\/gibtsnicht/, 'unbekannter Schluessel' );
    sh('echo 131072 > /proc/sys/net/netfilter/nf_conntrack_max');
    is( $state->{gw}{sysctl}{'net.netfilter.nf_conntrack_max'}, '131072', 'echo > /proc/sys' );
    sh(q{echo 'net.ipv4.ip_forward = 0' > /etc/sysctl.d/99-test.conf});
    sh('sysctl --system');
    is( $state->{gw}{sysctl}{'net.ipv4.ip_forward'}, '0', 'sysctl --system liest sysctl.d' );

    sh(q{sed -i 's/dns-server,10.1.0.1/dns-server,10.1.0.53/' /etc/dnsmasq.conf});
    unlike( $state->{gw}{services}{dnsmasq}{running}, qr/10\.1\.0\.53/, 'Datei geaendert, Dienst noch alt' );
    ok( ( sh('systemctl restart dnsmasq') )[1], 'Neustart' );
    like( $state->{gw}{services}{dnsmasq}{running}, qr/dns-server,10\.1\.0\.53/, '... liest die Datei' );
    ( $o, $ok ) = sh('systemctl restart gibtsnicht');
    is( $o, 'Failed to restart gibtsnicht.service: Unit gibtsnicht.service not found.', 'unbekannter Dienst' );
    sh('systemctl stop dnsmasq');
    ok( !$state->{gw}{services}{dnsmasq}{active}, 'stop sichtbar im Zustand' );

    my ( $w, $wok ) = write_file( $state, 'gw', '/etc/dnsmasq.conf', "x=1\n" );
    ok( $wok, 'write_file' );
    is( sh('cat /etc/dnsmasq.conf'), 'x=1', '... gelesen' );
    is( ( sh('cat /etc/nix') )[0], 'cat: /etc/nix: No such file or directory', 'Datei fehlt' );
    sh('reboot');
    is( $state->{gw}{reboots}, 1, 'Neustart zaehlt' );
}

# --- nmcli ------------------------------------------------------------------
{
    fresh();
    push @{ $state->{gw}{routes} }, { dst => 'default', via => '10.64.0.1', dev => 'wwan0', proto => 'dhcp', metric => 50 };
    $state->{gw}{interfaces}{wwan0} = { addr => ['10.64.0.2/30'], mtu => 1500, state => 'UP' };
    sh('nmcli connection modify lte ipv4.route-metric 700');
    is( $state->{gw}{routes}[-1]{metric}, 50, 'modify allein wirkt nicht' );
    sh('nmcli con up lte');
    is( $state->{gw}{routes}[-1]{metric}, 700, 'nach con up: Metrik auf der Route' );
}

# --- Filter, ip -j, ss --------------------------------------------------------
{
    fresh();
    is( sh(q{ip route | awk '{print $1}'}), "default\n10.1.0.0/24\n198.51.100.8/29\n10.255.0.0/30", 'awk {print $1}' );
    is( sh(q{ip route | awk '/default/ {print $3}'}), '198.51.100.9', 'awk mit Muster' );
    is( sh(q{ip route | awk 'NR>=2 && NR<=3 {printf "%d: %s\n", NR, $1}'}), "2: 10.1.0.0/24\n3: 198.51.100.8/29", 'awk NR-Bereich mit printf' );
    is( sh(q{ip route | awk 'NR==1 || /10\.255/ {print $1}'}), "default\n10.255.0.0/30", 'awk mit ||' );
    is( sh(q{cut -d, -f1 /etc/dnsmasq.conf | head -n 1}), 'dhcp-range=10.1.0.100', 'cut auf einer Datei, head' );
    my $j = JSON::MaybeXS->new->decode( sh('ip -j route') );
    is( $j->[0]{gateway}, '198.51.100.9', 'ip -j route' );
    $j = JSON::MaybeXS->new->decode( sh('ip -j addr show') );
    is( ( grep { $_->{ifname} eq 'eth1' } @$j )[0]{addr_info}[0]{local}, '10.1.0.1', 'ip -j addr' );
    like( sh('ss -tlnp'), qr/\ANetid\s+State/, 'ss mit Kopf' );

    # sed als Leser: Modelle lesen lange Ausgaben abschnittweise
    is( sh(q{sed -n '2p' /etc/dnsmasq.conf}), 'dhcp-option=option:dns-server,10.1.0.1', 'sed -n Np' );
    is( sh(q{sed -n '1,1p' /etc/dnsmasq.conf}), 'dhcp-range=10.1.0.100,10.1.0.199,12h', 'sed -n N,Mp' );
    is( sh(q{sed -n '2,$p' /etc/dnsmasq.conf}), 'dhcp-option=option:dns-server,10.1.0.1', 'sed -n N,$p' );
    is( sh(q{sed -n '/dns-server/p' /etc/dnsmasq.conf}), 'dhcp-option=option:dns-server,10.1.0.1', 'sed -n /re/p' );
    is( sh(q{ip route | sed -n '1,2p'}), "default via 198.51.100.9 dev eth0\n10.1.0.0/24 dev eth1 proto kernel scope link src 10.1.0.1", 'sed liest stdin der Pipe' );
    is( sh(q{ip route | sed 's/eth0/ETH0/' | head -n 1}), 'default via 198.51.100.9 dev ETH0', 'sed s/// auf stdin' );
    is( sh(q{sed '1d' /etc/dnsmasq.conf}), 'dhcp-option=option:dns-server,10.1.0.1', 'sed Nd unveraendert' );
    is( sh(q{sed -n '1p;2p' /etc/dnsmasq.conf}), "dhcp-range=10.1.0.100,10.1.0.199,12h\ndhcp-option=option:dns-server,10.1.0.1", 'sed mehrere Befehle mit ;' );
    is( sh(q{echo 'zone { x }' | sed 's/{ x }/{ y }/'}), 'zone { y }', 'BRE: blanke { } sind Zeichen' );
    is( sh(q{echo 'ab12' | sed 's/\([a-z]*\)\([0-9]\+\)/\2\1/'}), '12ab', 'BRE: \( \) und \+ sind Operatoren' );
    is( sh(q{echo 'ab12' | sed -E 's/([a-z]+)([0-9]+)/\2\1/'}), '12ab', 'sed -E: ERE' );
    is( sh(q{echo 'f(x)' | sed 's/(x)/[x]/'}), 'f[x]', 'BRE: blanke ( ) sind Zeichen' );
    # sed i/a/c und $ (Pruefung des Leitstands)
    is( sh(q{printf 'a\nb\n' | sed '$i X'}), "a\nX\nb", 'sed $i: vor der letzten Zeile einfuegen' );
    is( sh(q{printf 'a\nb\n' | sed '/a/a Y'}), "a\nY\nb", 'sed /re/a: nach dem Treffer' );
    is( sh(q{printf 'a\nb\n' | sed '1c Z'}), "Z\nb", 'sed Nc: Zeile ersetzen' );
    is( sh(q{printf 'a\nb\n' | sed '$a\\
ende'}), "a\nb\nende", 'sed $a\\ mit Text auf der naechsten Zeile' );
    unchanged('sed ohne -i aendert nichts');

    # grep mit Kontext und Zeilennummern
    is( sh(q{ip route | grep -A 1 default}), "default via 198.51.100.9 dev eth0\n10.1.0.0/24 dev eth1 proto kernel scope link src 10.1.0.1", 'grep -A N (getrennt)' );
    is( sh(q{ip route | grep -A1 default}), "default via 198.51.100.9 dev eth0\n10.1.0.0/24 dev eth1 proto kernel scope link src 10.1.0.1", 'grep -AN' );
    is( sh(q{ip route | grep -B1 '^198'}), "10.1.0.0/24 dev eth1 proto kernel scope link src 10.1.0.1\n198.51.100.8/29 dev eth0 proto kernel scope link src 198.51.100.10", 'grep -B' );
    is( sh(q{ip route | grep -C 0 -e default -e '^10.255'}), "default via 198.51.100.9 dev eth0\n--\n10.255.0.0/30 dev wg0 proto kernel scope link src 10.255.0.1", 'grep -C 0: Trenner zwischen Gruppen' );
    is( sh(q{grep -n dns-server /etc/dnsmasq.conf}), '2:dhcp-option=option:dns-server,10.1.0.1', 'grep -n Zeilennummer' );
    is( sh(q{grep -n -A1 dhcp-range /etc/dnsmasq.conf}), "1:dhcp-range=10.1.0.100,10.1.0.199,12h\n2-dhcp-option=option:dns-server,10.1.0.1", 'grep -n mit Kontext: N- fuer Kontextzeilen' );
    is( sh(q{ip route | grep -m 1 dev}), 'default via 198.51.100.9 dev eth0', 'grep -m N' );
    is( sh(q{grep -A 10 range /etc/dnsmasq.conf | wc -l}), '2', 'Kontext endet am Dateiende' );

    # ls /proc/sys, Prozesse, date/sleep
    like( sh('ls /proc/sys/net/ipv4/'), qr/\bip_forward\b/, 'ls /proc/sys/net/ipv4/ aus sysctl' );
    like( sh('ls /proc/sys/net'), qr/\bipv4\b.*\bnetfilter\b/s, 'ls /proc/sys/net: Unterverzeichnisse' );
    like( sh('ps aux'), qr/\A USER\s+PID/x, 'ps aux mit Kopf' );
    like( sh('ps aux | grep -c dnsmasq'), qr/\A1\z/, '... laufender Dienst als Prozess' );
    my ( $o, $ok ) = sh('pgrep -a dnsmasq');
    like( $o, qr/\A\d+ dnsmasq\z/, 'pgrep -a' );
    ( $o, $ok ) = sh('pgrep nginx');
    ok( !$ok && $o eq '', 'pgrep ohne Treffer: Exit 1, leer' );
    ok( ( sh('sleep 3') )[1], 'sleep' );
    like( sh('date'), qr/2026/, 'date' );
    unchanged('Lesebefehle aendern nichts');

    # stderr-Umleitungen: nur ein Ausgabestrom
    is( sh(q{cat /proc/sys/net/ipv4/ip_forward 2>&1 | head -n 1}), '0', '2>&1 entfaellt (keine Datei "&1")' );
    is( sh(q{cat /proc/sys/net/ipv4/ip_forward 2>/dev/null}), '0', '2>/dev/null entfaellt' );
    ok( !exists $state->{gw}{files}{'&1'}, '... keine Datei &1' );
    sh(q{cat /proc/sys/net/ipv4/ip_forward &> /tmp/x.txt});
    is( sh('cat /tmp/x.txt'), '0', '&> wirkt wie >' );
    delete $state->{gw}{files}{'/tmp/x.txt'};

    # grep ueber Verzeichnisse und mehrere Dateien, sed mit mehreren Befehlen
    sh(q{echo 'DATABASE_URL=postgres://db1/appdb' > /etc/app/app.env});
    sh(q{echo 'LOG=info' > /etc/app/log.env});
    is( sh(q{grep -rn DATABASE_URL /etc/app/}), '/etc/app/app.env:1:DATABASE_URL=postgres://db1/appdb', 'grep -rn ueber ein Verzeichnis' );
    is( sh(q{grep -rl = /etc/app}), "/etc/app/app.env\n/etc/app/log.env", 'grep -rl' );
    is( sh(q{grep LOG /etc/app/app.env /etc/app/log.env}), '/etc/app/log.env:LOG=info', 'mehrere Dateien: mit Namen' );
    my ( $go, $gok ) = sh(q{grep LOG /etc/app});
    is( $go, 'grep: /etc/app: Is a directory', 'Verzeichnis ohne -r: echte Meldung' );
    is( sh(q{echo abc | sed 's/a/A/; s/c/C/'}), 'AbC', 'sed: mehrere s-Befehle mit ;' );
    is( sh(q{echo abc | sed -e 's/a/A/' -e 's/c/C/'}), 'AbC', 'sed: mehrere -e' );
    delete $state->{gw}{files}{$_} for '/etc/app/app.env', '/etc/app/log.env';

    # nft: unbekannte ICMP-Typnamen lehnt nft ab
    {
        my $st = clone($state);
        my ( $o, $ok ) = run_command( $st, 'gw', q{nft add rule inet filter forward icmpv6 type { router-solicitation, neighbor-solicitation } accept} );
        ok( !$ok, 'icmpv6 type router-solicitation: gibt es nicht' );
        like( $o, qr/Could not parse ICMPv6 type/, '... echte Fehlermeldung' );
        is_deeply( [ diff( $state->{gw}{nft}, $st->{gw}{nft} ) ], [], '... Regelsatz unveraendert (ohne Buchfuehrung _…)' );
        ( $o, $ok ) = run_command( $st, 'gw', q{nft add rule inet filter forward icmpv6 type { nd-router-solicit, nd-neighbor-solicit, nd-neighbor-advert } accept} );
        ok( $ok, 'gueltige ICMPv6-Namen' ) or diag $o;
        ( $o, $ok ) = run_command( $st, 'gw', q{nft add rule inet filter forward icmp type echo-request accept} );
        ok( $ok, 'icmp type echo-request' ) or diag $o;
    }

    # readlink
    $state->{gw}{files}{'/etc/resolv.conf'} = { link => '../run/systemd/resolve/stub-resolv.conf' };
    is( sh('readlink /etc/resolv.conf'), '../run/systemd/resolve/stub-resolv.conf', 'readlink: Ziel wie gespeichert' );
    is( sh('readlink -f /etc/resolv.conf'), '/run/systemd/resolve/stub-resolv.conf', 'readlink -f: aufgeloest' );
    my ( $rl, $rlok ) = sh('readlink /etc/dnsmasq.conf');
    ok( !$rlok && $rl eq '', 'readlink auf eine normale Datei: leer, Exit 1' );
    delete $state->{gw}{files}{'/etc/resolv.conf'};

    # base64: Secrets von Hand kodieren
    is( sh(q{echo -n 'Vq8-Lm3r' | base64}), 'VnE4LUxtM3I=', 'base64 von stdin' );
    is( sh(q{printf '%s' 'Vq8-Lm3r' | base64 -w0}), 'VnE4LUxtM3I=', 'base64 -w0' );
    is( sh(q{echo 'VnE4LUxtM3I=' | base64 -d}), 'Vq8-Lm3r', 'base64 -d' );
    is( sh(q{echo test | base64}), 'dGVzdAo=', 'echo ohne -n: Zeilenende wird mitkodiert' );

    write_file( $state, 'gw', '/tmp/w.txt', 'abc' );
    is( sh(q{wc -c /tmp/w.txt}), '3 /tmp/w.txt', 'wc -c: Bytes der Datei, mit Namen wie GNU wc' );
    is( sh(q{echo 'a b c' | wc -w}), '3', 'wc -w' );
    delete $state->{gw}{files}{'/tmp/w.txt'};

    # $? und nft nur lesen
    is( sh(q{cat /etc/nix; echo "rc=$?"}), "cat: /etc/nix: No such file or directory\nrc=1", '$? nach Fehler' );
    is( sh(q{true; echo $?}), '0', '$? nach Erfolg' );
    {
        my $st = { h => { type => 'linux', interfaces => {} } };
        run_command( $st, 'h', 'nft list ruleset' );
        ok( !exists $st->{h}{nft}, 'nft list legt keinen leeren Regelsatz an' );
    }

    # Befehlsersetzung
    is( sh(q{echo $(cat /proc/sys/net/ipv4/ip_forward)}), '0', '$(...) wird ersetzt' );
    is( sh(q{echo "forward=$(cat /proc/sys/net/ipv4/ip_forward)"}), 'forward=0', '... in doppelten Anfuehrungszeichen' );
    is( sh(q{echo '$(hostname)'}), '$(hostname)', '... nicht in einfachen' );
    is( sh(q{echo `hostname`}), 'gw', 'Backticks' );
    is( sh(q{echo $(grep dns-server /etc/dnsmasq.conf | cut -d, -f2)}), '10.1.0.1', 'Pipe in $(...)' );
    is( sh(q{echo $(echo 'a;b|c')}), 'a;b|c', 'Ausgabe wird nicht erneut als Befehl gelesen' );
    my ( $o2, $ok2, $gap2 ) = run_command( $state, 'gw', 'X=1; echo $X' );
    is( $o2, '1', 'Variablenzuweisung wie bash (Sim::Shell)' );
    ok( !defined $gap2, '... ohne Luecke' );
    unchanged('Ersetzung aendert nichts');
}

# --- Luecken der Simulation ------------------------------------------------
{
    fresh();
    my ( $o, $ok, $gap ) = run_command( $state, 'gw', 'iptables -L' );
    is( $gap, undef, 'iptables gibt es hier nicht: keine Luecke, sondern die Wahrheit' );
    ( $o, $ok, $gap ) = run_command( $state, 'gw', 'vi /etc/dnsmasq.conf' );
    is( $o, 'Error opening terminal: unknown.', 'interaktiv: neutrale Antwort' );
    is( $gap, 'vi /etc/dnsmasq.conf', '... als Luecke gemeldet' );
    ( $o, $ok, $gap ) = run_command( $state, 'gw', 'ethtool eth0 | grep Speed' );
    is( $o, '', 'echter Befehl ohne Nachbildung: leer' );
    is( $gap, 'ethtool eth0', '... Luecke' );
    ( $o, $ok, $gap ) = run_command( $state, 'gw', 'nft -j list ruleset' );
    like( $gap, qr/nft -j/, 'nft -j: Luecke' );
    ( $o, $ok, $gap ) = run_command( $state, 'gw', 'ipp route' );
    is( $o, 'bash: ipp: command not found', 'Tippfehler: command not found' );
    is( $gap, undef, '... keine Luecke' );
    unchanged('Luecken aendern nichts');
}

# --- nftables.conf, nft -f, dnsmasq reload, ip -6 ---------------------------
{
    fresh();
    like( sh('cat /etc/nftables.conf'), qr/\A#!\/usr\/sbin\/nft -f\n\nflush ruleset\n\ntable inet filter \{/, 'nftables.conf aus dem Zustand' );
    sh(q{sed -i 's/policy drop;/policy drop;\n\t\tiifname "wg0" accept/' /etc/nftables.conf});
    is_deeply( $state->{gw}{nft}{'inet filter'}{chains}{forward}{rules}, ['ct state established,related accept'], 'nur Datei: Regelsatz alt' );
    ok( ( sh('nft -f /etc/nftables.conf') )[1], 'nft -f laedt' );
    is_deeply( $state->{gw}{nft}{'inet filter'}{chains}{forward}{rules}, [ 'iifname "wg0" accept', 'ct state established,related accept' ],
        '... und der Regelsatz ist der aus der Datei' );
    sh('nft flush ruleset');
    $state->{gw}{services}{nftables} = { active => JSON::MaybeXS::true() };
    sh('systemctl restart nftables');
    ok( $state->{gw}{nft}{'ip nat'}, 'systemctl restart nftables laedt die Datei' );
    my ( $o, $ok ) = write_file( $state, 'gw', '/etc/nftables.conf', "table inet x {\n chain y {\n" );
    ( $o, $ok ) = sh('nft -f /etc/nftables.conf');
    ok( !$ok, 'kaputte Datei: Fehler' );
    ok( $state->{gw}{nft}{'ip nat'}, '... Regelsatz unveraendert (alles oder nichts)' );

    fresh();
    sh(q{sed -i 's/dns-server,10.1.0.1/dns-server,10.1.0.53/' /etc/dnsmasq.conf});
    sh('systemctl reload dnsmasq');
    unlike( $state->{gw}{services}{dnsmasq}{running}, qr/10\.1\.0\.53/, 'reload liest dhcp-option nicht neu (wie dnsmasq)' );
    sh('systemctl restart dnsmasq');
    like( $state->{gw}{services}{dnsmasq}{running}, qr/10\.1\.0\.53/, 'restart schon' );

    push @{ $state->{gw}{routes} }, { dst => '2001:db8:1::/64', dev => 'eth1', proto => 'kernel' };
    is( sh('ip -6 route'), '2001:db8:1::/64 dev eth1 proto kernel', 'ip -6 route zeigt nur IPv6' );
    unlike( sh('ip route'), qr/2001:db8/, 'ip route nur IPv4' );
}

# Umleitungen der Fehlerausgabe und der Eingabe: frueher wurde
# aus 2>&1 eine Datei „&1“ und aus </dev/null ein Argument.
{
    fresh();
    my ( $o, $ok ) = sh('cat /etc/dnsmasq.conf 2>&1 | head -1');
    ok( $ok, '2>&1 vor einer Pipe gelingt' );
    like( $o, qr/\S/, '... und liefert die Ausgabe' );
    ( $o, $ok ) = sh('cat /etc/dnsmasq.conf 2>/dev/null | wc -l');
    ok( $ok && $o =~ /\A\d+\z/, '2>/dev/null verwirft nur die Fehlerausgabe' );
    ( $o, $ok ) = sh('cat /etc/dnsmasq.conf </dev/null >/dev/null');
    ok( $ok, '</dev/null ist Eingabe, kein Argument' );
    ( $o, $ok ) = sh('cat /etc/dnsmasq.conf &>/dev/null');
    ok( $ok && $o eq '', '&>/dev/null verwirft alles' );
    unchanged('keine Datei "&1" oder "/dev/null" angelegt');
    # sed: BRE/ERE wie GNU sed — ${…} und Klammern sind in BRE woertlich
    $state->{gw}{files}{'/tmp/c.yaml'} = qq{ports:\n  - "\${WEB_PORT:-80}:8080"\nimage: a/b:1.2 # (x)\n};
    sh(q{sed -i 's/${WEB_PORT:-80}:8080/8081:8080/' /tmp/c.yaml});
    like( $state->{gw}{files}{'/tmp/c.yaml'}, qr/"8081:8080"/, 'sed: $ und { } mitten im BRE-Muster sind woertlich' );
    sh(q{sed -i 's/b:1\.2 # (x)/b:1.3/' /tmp/c.yaml});
    like( $state->{gw}{files}{'/tmp/c.yaml'}, qr/image: a\/b:1\.3\n/, 'sed: ( ) woertlich in BRE' );
    sh(q{sed -i 's/\(image: a\/b\):1\.3$/\1:2.0/' /tmp/c.yaml});
    like( $state->{gw}{files}{'/tmp/c.yaml'}, qr/image: a\/b:2\.0\n/, 'sed: \( \) Gruppe, \/ im Muster und $ am Ende' );
    sh(q{sed -E -i 's/(a\/b):([0-9]+)\.0/\1:\2.1/' /tmp/c.yaml});
    like( $state->{gw}{files}{'/tmp/c.yaml'}, qr/image: a\/b:2\.1\n/, 'sed -E: ERE-Gruppen und +' );
    sh(q{sed -i 's|a/b:2.1|registry.example.com\/a\/b:2.2|' /tmp/c.yaml});
    like( $state->{gw}{files}{'/tmp/c.yaml'}, qr{image: registry\.example\.com/a/b:2\.2\n}, 'sed: \/ im Ersatz wird /' );
    sh(q{sed -i 's/^ports:/ports: # ^x/' /tmp/c.yaml});
    like( $state->{gw}{files}{'/tmp/c.yaml'}, qr/\Aports: # \^x\n/, 'sed: ^ nur am Anfang ein Anker' );
    is_deeply( [ Langertha::Holmgang::Shell::shell_words('a 2>&1 | b <x 1>y') ],
        [ 'a', { op => '|' }, 'b', { op => '<' }, 'x', { op => '>' }, 'y' ], 'shell_words: Umleitungen als Operatoren' );
}

done_testing;
