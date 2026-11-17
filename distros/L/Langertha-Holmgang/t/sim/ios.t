#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Sim::IOS ();
use Holmgang::TestSim qw( run_command write_file );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Simulator einer Cisco-IOS-Switch-CLI fuer die Test-Suites.
# Behauptet wird: (1) show running-config, show interfaces trunk und show vlan brief
# haben das echte IOS-Format und zeigen den Zustand; (2) allowed vlan add/remove und das
# Ersetzen der Liste (die klassische Falle) aendern den Zustand, der naechste show zeigt
# es; (3) Abkuerzungen von Befehlen und Schnittstellen wirken wie bei IOS; (4) eine
# fehlerhafte Zeile meldet IOS-typisch mit ^ an der richtigen Stelle, aendert nichts,
# $ok wird falsch, der Rest laeuft weiter; (5) do show, reload, shutdown, Filter.

my $IOS = 'Langertha::Holmgang::Sim::IOS';

sub fresh {
    return {
        type     => 'ios',
        hostname => 'sw-core',
        vlans    => { 1 => { name => 'default' }, 10 => { name => 'BUERO' }, 30 => { name => 'GAST' } },
        interfaces => {
            'GigabitEthernet1/0/24' => {
                description   => 'Uplink zum Router',
                mode          => 'trunk',
                trunk_allowed => [ 10, 20 ],
                native_vlan   => 1,
                access_vlan   => 1,
                shutdown      => 0,
                status        => 'connected',
            },
            'GigabitEthernet1/0/1' => { mode => 'access', access_vlan => 10, status => 'connected' },
            'GigabitEthernet1/0/2' => { access_vlan => 30, status => 'notconnect' },
            'GigabitEthernet1/0/3' => { status => 'connected' },
        },
    };
}

sub run_ios {
    my ( $dev, $cmd ) = @_;
    return $IOS->run( $dev, $cmd, { host => 'sw-core', state => { 'sw-core' => $dev } } );
}

# --- (1) Formate ---------------------------------------------------------------

{
    my $dev = fresh();
    my ( $out, $ok ) = run_ios( $dev, 'show running-config' );
    ok( $ok, 'show running-config gelingt' );
    like( $out, qr/\ABuilding configuration\.\.\.\n\nCurrent configuration : \d+ bytes\n!/, 'Kopf wie IOS' );
    like( $out, qr/^hostname sw-core$/m, 'hostname' );
    like( $out, qr/^vlan 10\n name BUERO\n!\nvlan 30\n name GAST\n!$/m, 'VLAN-Abschnitte' );
    like(
        $out,
        qr/^interface GigabitEthernet1\/0\/24\n description Uplink zum Router\n switchport trunk allowed vlan 10,20\n switchport mode trunk\n!$/m,
        'Schnittstellenblock in IOS-Reihenfolge'
    );
    like( $out, qr/^interface GigabitEthernet1\/0\/1\n switchport access vlan 10\n switchport mode access\n!$/m,
        'Access-Port mit VLAN' );
    like( $out, qr/^interface GigabitEthernet1\/0\/3\n!$/m, 'Port ohne Konfiguration' );
    like( $out, qr/\nend\z/, 'endet mit end' );
    my ($n) = $out =~ /Current configuration : (\d+) bytes/;
    my ($body) = $out =~ /bytes\n(.*)\z/s;
    is( $n, length($body) + 1, 'Byte-Zahl stimmt' );
    ok( index( $out, 'GigabitEthernet1/0/1' ) < index( $out, 'GigabitEthernet1/0/24' ), 'natuerlich sortiert' );

    ( $out, $ok ) = run_ios( $dev, 'show interfaces trunk' );
    ok( $ok, 'show interfaces trunk gelingt' );
    is( $out, join( "\n",
        '',
        'Port        Mode             Encapsulation  Status        Native vlan',
        'Gi1/0/24    on               802.1q         trunking      1',
        '',
        'Port        Vlans allowed on trunk',
        'Gi1/0/24    10,20',
        '',
        'Port        Vlans allowed and active in management domain',
        'Gi1/0/24    10',
        '',
        'Port        Vlans in spanning tree forwarding state and not pruned',
        'Gi1/0/24    10' ), 'show interfaces trunk: vier Abschnitte, aktiv = erlaubt geschnitten mit vorhandenen' );

    ( $out, $ok ) = run_ios( $dev, 'show vlan brief' );
    ok( $ok, 'show vlan brief gelingt' );
    like( $out, qr/^VLAN Name                             Status    Ports$/m, 'Kopf' );
    like( $out, qr/^1    default                          active    Gi1\/0\/3$/m,  'VLAN 1 mit Port ohne Einstellung' );
    like( $out, qr/^10   BUERO                            active    Gi1\/0\/1$/m,  'VLAN 10 mit Access-Port' );
    like( $out, qr/^30   GAST                             active    Gi1\/0\/2$/m,  'VLAN 30 (Port down zaehlt mit)' );
    unlike( $out, qr/Gi1\/0\/24/, 'Trunk-Port nicht in show vlan brief' );
    like( $out, qr/^1002 fddi-default\s+act\/unsup$/m, 'Standard-VLANs 1002-1005' );

    ( $out, $ok ) = run_ios( $dev, 'show interfaces status' );
    like( $out, qr/^Gi1\/0\/24  Uplink zum Router  connected    trunk\s+a-full a-1000 10\/100\/1000BaseTX$/m,
        'show interfaces status' );
    like( $out, qr/^Gi1\/0\/2 \s+notconnect   30\s+auto   auto/m, 'notconnect und VLAN' );

    ( $out, $ok ) = run_ios( $dev, 'show interfaces Gi1/0/24 switchport' );
    like( $out, qr/^Administrative Mode: trunk$/m,           'switchport: Modus' );
    like( $out, qr/^Trunking VLANs Enabled: 10,20$/m,        'switchport: erlaubte VLANs' );
    ( $out, $ok ) = run_ios( $dev, 'show interfaces Gi1/0/1 switchport' );
    like( $out, qr/^Access Mode VLAN: 10 \(BUERO\)$/m,       'switchport: Access-VLAN mit Namen' );

    ( $out, $ok ) = run_ios( $dev, 'show version' );
    ok( $ok && $out =~ /Cisco IOS XE Software/ && $out =~ /sw-core uptime is/, 'show version plausibel' );

    ( $out, $ok ) = run_ios( $dev, 'show running-config interface Gi1/0/24' );
    like( $out, qr/!\ninterface GigabitEthernet1\/0\/24\n description Uplink zum Router\n.*\nend\z/s,
        'show running-config interface' );
    unlike( $out, qr/hostname/, 'nur die Schnittstelle' );

    ( $out, $ok ) = run_ios( $dev, 'show run | include allowed' );
    is( $out, ' switchport trunk allowed vlan 10,20', '| include' );
    ( $out, $ok ) = run_ios( $dev, 'sh run | sec 1/0/24' );
    like( $out, qr/\Ainterface GigabitEthernet1\/0\/24\n description .*\n switchport mode trunk\z/s, '| section' );
    ( $out, $ok ) = run_ios( $dev, 'show run | begin interface' );
    like( $out, qr/\Ainterface GigabitEthernet1\/0\/1\n/, '| begin' );
    ( $out, $ok ) = run_ios( $dev, "terminal length 0\nenable\nshow vlan brief | include GAST" );
    ok( $ok, 'terminal length 0 und enable ohne Wirkung' );
    like( $out, qr/\A30\s+GAST/, 'nur die gefilterte Ausgabe' );
    is_deeply( $dev, fresh(), 'Lesebefehle aendern nichts' );
}

# --- (2) allowed vlan: add, remove, ersetzen --------------------------------

{
    my $dev = fresh();
    my ( $out, $ok ) = run_ios( $dev, "configure terminal\ninterface GigabitEthernet1/0/24\nswitchport trunk allowed vlan add 30\nend" );
    ok( $ok, 'add gelingt' );
    is( $out, 'Enter configuration commands, one per line.  End with CNTL/Z.', 'nur der Hinweis von conf t' );
    is_deeply( $dev->{interfaces}{'GigabitEthernet1/0/24'}{trunk_allowed}, [ 10, 20, 30 ], 'add ergaenzt' );
    ( $out, $ok ) = run_ios( $dev, 'show interfaces trunk' );
    like( $out, qr/allowed on trunk\nGi1\/0\/24    10,20,30\n/, 'show zeigt die neue Liste' );
    like( $out, qr/management domain\nGi1\/0\/24    10,30\n/,     'aktiv jetzt mit 30' );

    run_ios( $dev, "conf t\nint gi1/0/24\nsw tr al vl remove 20\nend" );
    is_deeply( $dev->{interfaces}{'GigabitEthernet1/0/24'}{trunk_allowed}, [ 10, 30 ], 'remove nimmt heraus' );

    my $trap = fresh();
    ( $out, $ok ) = run_ios( $trap, "conf t\ninterface Gi1/0/24\nswitchport trunk allowed vlan 30\nend" );
    ok( $ok, 'Ersetzen gelingt (IOS fragt nicht nach)' );
    is_deeply( $trap->{interfaces}{'GigabitEthernet1/0/24'}{trunk_allowed}, [30], 'Falle: Liste ersetzt, 10 und 20 weg' );
    ( $out, $ok ) = run_ios( $trap, 'sh run int gi1/0/24' );
    like( $out, qr/^ switchport trunk allowed vlan 30$/m, 'show run zeigt die ersetzte Liste' );

    my $d = fresh();
    run_ios( $d, "conf t\nint Gi1/0/24\nswitchport trunk allowed vlan 10,20,30-32\nend" );
    is_deeply( $d->{interfaces}{'GigabitEthernet1/0/24'}{trunk_allowed}, [ 10, 20, 30, 31, 32 ], 'Liste mit Bereich' );
    ( $out, $ok ) = run_ios( $d, 'sh run | i allowed' );
    is( $out, ' switchport trunk allowed vlan 10,20,30-32', 'Bereich wie IOS zusammengefasst' );
    run_ios( $d, "conf t\nint Gi1/0/24\nswitchport trunk allowed vlan all\nend" );
    is( $d->{interfaces}{'GigabitEthernet1/0/24'}{trunk_allowed}, 'all', 'all' );
    run_ios( $d, "conf t\nint Gi1/0/24\nswitchport trunk allowed vlan except 1-9\nswitchport trunk allowed vlan add 1-9\nend" );
    is( $d->{interfaces}{'GigabitEthernet1/0/24'}{trunk_allowed}, 'all', 'except + add ergibt wieder all' );
    run_ios( $d, "conf t\nint Gi1/0/24\nswitchport trunk allowed vlan none\nend" );
    is_deeply( $d->{interfaces}{'GigabitEthernet1/0/24'}{trunk_allowed}, [], 'none' );
}

# --- (3) Abkuerzungen, mehrzeilige Konfiguration ----------------------------

{
    my $dev = fresh();
    my ( $out, $ok ) = run_ios( $dev, join "\n",
        'conf t', 'vlan 40', ' name DRUCKER', 'exit',
        'interface range Gi1/0/1 - 3', ' sw mo acc', ' sw acc vl 40', ' desc Drucker Etage 2',
        'interface GigabitEthernet 1/0/24', ' switchport trunk native vlan 99', 'end' );
    ok( $ok, 'mehrzeilige Konfiguration gelingt' ) or diag $out;
    is( $dev->{vlans}{40}{name}, 'DRUCKER', 'vlan + name' );
    for my $p ( 1 .. 3 ) {
        my $if = $dev->{interfaces}{"GigabitEthernet1/0/$p"};
        is( $if->{access_vlan}, 40, "range: Gi1/0/$p in VLAN 40" );
        is( $if->{description}, 'Drucker Etage 2', "range: Beschreibung mit Leerzeichen" );
        is( $if->{mode} // 'access', 'access', 'range: mode (fehlt = access, nichts angelegt)' );
    }
    is( $dev->{interfaces}{'GigabitEthernet1/0/24'}{native_vlan}, 99, 'Untermodus -> interface wechselt (Name mit Leerzeichen)' );

    ( $out, $ok ) = run_ios( $dev, "conf t\nint gi1/0/2\nswitchport access vlan 50\nend" );
    ok( $ok, 'access vlan auf fehlendes VLAN gelingt' );
    like( $out, qr/^% Access VLAN does not exist\. Creating vlan 50$/m, 'IOS legt das VLAN an' );
    ok( $dev->{vlans}{50}, 'VLAN 50 angelegt' );

    ( $out, $ok ) = run_ios( $dev, 'sh i' );
    ok( !$ok, 'mehrdeutig' );
    is( $out, qq{sw-core#sh i\n% Ambiguous command:  "sh i"}, 'Ambiguous wie IOS' );

    ( $out, $ok ) = run_ios( $dev, 'show interfaces' . ' ' );
    ok( $ok, 'show interfaces gesamt' );
    ( $out, $ok ) = run_ios( $dev, 'show interfaces Gi1/0/24' );
    like( $out, qr/\AGigabitEthernet1\/0\/24 is up, line protocol is up \(connected\)/, 'show interfaces X' );

    ( $out, $ok ) = run_ios( $dev, "conf t\nint Gi1/0/24\nswitchport trunk allowed vlan" );
    ok( !$ok, 'unvollstaendig' );
    is( $out, "Enter configuration commands, one per line.  End with CNTL/Z.\nsw-core(config-if)#switchport trunk allowed vlan\n% Incomplete command.",
        'Incomplete wie IOS' );
}

# --- (4) Fehlerzeile mit ^, Rest laeuft ------------------------------------------

{
    my $dev = fresh();
    my ( $out, $ok ) = run_ios( $dev,
        "configure terminal\ninterface Gi1/0/24\nswitchport trunk alowed vlan add 30\ndescription Neu\nend" );
    ok( !$ok, 'Fehlerzeile -> $ok falsch' );
    my $expect = "sw-core(config-if)#switchport trunk alowed vlan add 30\n"
        . ( ' ' x length('sw-core(config-if)#switchport trunk al') ) . "^\n"
        . "% Invalid input detected at '^' marker.";
    like( $out, qr/\Q$expect\E/, '^ unter dem ersten falschen Zeichen' );
    is_deeply( $dev->{interfaces}{'GigabitEthernet1/0/24'}{trunk_allowed}, [ 10, 20 ], 'Fehlerzeile aendert nichts' );
    is( $dev->{interfaces}{'GigabitEthernet1/0/24'}{description}, 'Neu', 'die folgende Zeile lief' );

    ( $out, $ok ) = run_ios( $dev, 'show running-config foo' );
    is( $out, "sw-core#show running-config foo\n" . ( ' ' x length('sw-core#show running-config ') )
            . "^\n% Invalid input detected at '^' marker.", '^ am Wortanfang, wenn nichts passt' );

    ( $out, $ok ) = run_ios( $dev, "conf t\nint Gi1/0/24\nswitchport trunk allowed vlan add 5000\nend" );
    like( $out, qr/\n {53}\^\n/, '^ unter der ungueltigen VLAN-Nummer' );
    ok( !$ok, 'VLAN ausserhalb 1-4094 abgelehnt' );

    ( $out, $ok ) = run_ios( $dev, "conf t\nshow vlan brief\nend" );
    like( $out, qr/sw-core\(config\)#show vlan brief\n {16}\^\n% Invalid input/, 'show im Konfig-Modus ohne do: ungueltig' );

    ( $out, $ok ) = run_ios( $dev, 'show interfaces Gi1/0/99 switchport' );
    like( $out, qr/\n {26}\^\n/, 'unbekannte Schnittstelle: ^ unter der Nummer' );
    ok( !$ok, 'unbekannte Schnittstelle scheitert' );

    ( $out, $ok ) = run_ios( $dev, 'switchport mode trunk' );
    ok( !$ok, 'Konfig-Befehl im Exec-Modus scheitert' );
    unlike( $out, qr/configure|conf t/i, 'kein Hinweis auf die Loesung' );
}

# --- (5) do show, reload, shutdown, write --------------------------------------

{
    my $dev = fresh();
    my ( $out, $ok ) = run_ios( $dev, "conf t\nint Gi1/0/24\nsw tr al vl add 30\ndo show interfaces trunk | include ^Gi1/0/24    10\nend" );
    ok( $ok, 'do show gelingt' );
    like( $out, qr/^Gi1\/0\/24    10,20,30$/m, 'do show sieht die Aenderung' );

    ( $out, $ok ) = run_ios( $dev, "write memory" );
    is( $out, "Building configuration...\n[OK]", 'write memory' );
    ( $out, $ok ) = run_ios( $dev, "copy running-config startup-config" );
    like( $out, qr/Building configuration\.\.\.\n\[OK\]\z/, 'copy run start' );
    ok( !exists $dev->{reloads}, 'write aendert den Zustand nicht' );

    ( $out, $ok ) = run_ios( $dev, "reload\nshow version" );
    ok( $ok, 'reload gelingt' );
    is( $dev->{reloads}, 1, 'reload zaehlt' );
    unlike( $out, qr/uptime/, 'Sitzung nach reload zu' );
    run_ios( $dev, 'reload' );
    is( $dev->{reloads}, 2, 'reload zaehlt weiter' );

    my $s = fresh();
    run_ios( $s, "conf t\nint Gi1/0/24\nshutdown\nend" );
    ok( $s->{interfaces}{'GigabitEthernet1/0/24'}{shutdown}, 'shutdown gesetzt' );
    is( $s->{interfaces}{'GigabitEthernet1/0/24'}{status}, 'disabled', 'shutdown -> disabled' );
    ( $out, $ok ) = run_ios( $s, 'show interfaces trunk' );
    is( $out, '', 'abgeschalteter Trunk nicht mehr in show interfaces trunk' );
    ( $out, $ok ) = run_ios( $s, 'sh int status | i Gi1/0/24' );
    like( $out, qr/disabled/, 'show interfaces status: disabled' );
    run_ios( $s, "conf t\nint Gi1/0/24\nno shutdown\nend" );
    ok( !$s->{interfaces}{'GigabitEthernet1/0/24'}{shutdown}, 'no shutdown' );
    is( $s->{interfaces}{'GigabitEthernet1/0/24'}{status}, 'connected', 'wieder connected' );

    my $u = fresh();
    run_ios( $u, "conf t\nint Gi1/0/24\nno shutdown\nswitchport mode trunk\nexit\nexit" );
    is_deeply( $u, fresh(), 'Befehle ohne Aenderung legen nichts an' );

    ( $out, $ok ) = run_ios( $u, 'ping 10.0.0.1' );
    ok( $ok, 'ping gelingt' );
    like( $out, qr/^!!!!!\nSuccess rate is 100 percent \(5\/5\)/m, 'ping Normalfall' );
    ( $out, $ok ) = run_ios( $u, 'ping irgendwo' );
    ok( !$ok, 'ping ohne Adresse scheitert' );

    my $v = fresh();
    ( $out, $ok ) = run_ios( $v, "conf t\nno vlan 30\nno vlan 1\nend" );
    ok( !exists $v->{vlans}{30}, 'no vlan loescht' );
    ok( !$ok, 'VLAN 1 nicht loeschbar' );
    like( $out, qr/%Default VLAN 1 may not be deleted\./, 'IOS-Meldung' );
}

{
    my $st = { sw => { type => 'ios', hostname => 'sw', interfaces => {} } };
    my ( $o, $ok, $gap ) = run_command( $st, 'sw', 'show mac address-table' );
    is( $gap, 'show mac address-table', 'echter show-Befehl ohne Nachbildung: Luecke' );
    ok( $ok, '... kein Fehler des Modells' );
    ( $o, $ok, $gap ) = run_command( $st, 'sw', 'shw run' );
    is( $gap, undef, 'Tippfehler: keine Luecke' );
}

# Vertrag (ADR 0005): Typ ios ist eingebaut, kein write_file
{
    my $sims = Holmgang::TestSim::sims();
    ok( ( grep { $_ eq 'ios' } $sims->types ), 'ios ist eingebaut' );
    my $st = { sw => { type => 'ios', hostname => 'sw', interfaces => {} } };
    my ( $o, $ok ) = write_file( $st, 'sw', 'flash:startup-config', 'hostname x' );
    ok( !$ok, 'write_file abgelehnt' );
    is_deeply( $st, { sw => { type => 'ios', hostname => 'sw', interfaces => {} } }, '... Zustand unveraendert' );
    ( $o, $ok ) = run_command( $st, 'sw', 'show mac address-table' );
    is( $o, '', 'Luecke: neutrale (leere) Antwort' );
}

done_testing;
