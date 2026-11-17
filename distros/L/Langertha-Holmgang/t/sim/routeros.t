#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Sim::RouterOS ();
use Holmgang::TestSim qw( run_command write_file );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);
use Storable qw( dclone );

# Der RouterOS-Simulator der Test-Suites. Behauptet wird: print
# zeigt Nummern, Flags und Kommentare wie RouterOS; add/set/remove/move/
# disable/enable/comment aendern den Zustand und der naechste print zeigt es;
# move setzt Eintrag a VOR den Eintrag, der jetzt Nummer b hat; find-Varianten
# waehlen richtig aus; ein Menuewechsel gilt fuer die folgenden Zeilen;
# Einstellungs-Menues lesen und schreiben ihren Hash; Fehler sehen aus wie
# RouterOS, liefern ok falsch und lassen den Zustand dieses Befehls
# unberuehrt (vorige Zeilen bleiben ausgefuehrt); dynamische Leases sind
# loeschbar; reboot zaehlt; export schreibt add-Zeilen; ping folgt den Routen.

my $R = 'Langertha::Holmgang::Sim::RouterOS';

sub fresh {
    return {
        type     => 'routeros',
        identity => 'r1',
        menus    => {
            '/ip firewall filter' => [
                { chain => 'forward', action => 'accept', 'connection-state' => 'established,related', comment => 'LAN raus' },
                { chain => 'forward', action => 'drop', disabled => 'yes' },
                { chain => 'input', action => 'accept', protocol => 'icmp' },
            ],
            '/ip address' => [ { address => '192.168.88.1/24', interface => 'bridge', network => '192.168.88.0' },
                { address => '203.0.113.2/30', interface => 'ether1', network => '203.0.113.0' } ],
            '/ip route'   => [ { 'dst-address' => '0.0.0.0/0', gateway => '203.0.113.1', distance => '1' } ],
            '/ip dhcp-server lease' => [
                { address => '192.168.88.20', 'mac-address' => 'AA:BB:CC:00:00:01', server => 'dhcp1', dynamic => 'yes' },
                { address => '192.168.88.5',  'mac-address' => 'AA:BB:CC:00:00:02', server => 'dhcp1', comment => 'Drucker' },
                { address => '192.168.88.21', 'mac-address' => 'AA:BB:CC:00:00:03', server => 'dhcp1', dynamic => 'yes' },
            ],
            '/interface' => [ { name => 'ether1', type => 'ether', mtu => '1500', running => 'yes' } ],
        },
        settings => { '/ip dns' => { servers => '9.9.9.9', 'allow-remote-requests' => 'yes' } },
    };
}

sub run_ok {
    my ( $dev, $cmd ) = @_;
    my ( $out, $ok ) = $R->run( $dev, $cmd, { host => 'r1' } );
    ok $ok, "ok: $cmd" or diag $out;
    return $out;
}

sub run_fail {
    my ( $dev, $cmd, $re ) = @_;
    my ( $out, $ok ) = $R->run( $dev, $cmd, { host => 'r1' } );
    ok !$ok, "scheitert: $cmd";
    like $out, $re, "Meldung: $cmd";
    return $out;
}

sub chains { my ($d) = @_; return [ map { "$_->{chain}/$_->{action}" } @{ $d->{menus}{'/ip firewall filter'} } ] }

subtest 'print: Kopf, Nummern, Flags, Kommentar' => sub {
    my $d = fresh();
    my $out = run_ok( $d, '/ip firewall filter print' );
    is $out, join( "\n",
        'Flags: X - disabled, I - invalid, D - dynamic',
        ' 0    ;;; LAN raus',
        '      chain=forward action=accept connection-state=established,related',
        '',
        ' 1 X  chain=forward action=drop',
        '',
        ' 2    chain=input action=accept protocol=icmp' ), 'Format wie RouterOS';
    is run_ok( $d, 'ip firewall filter print' ), $out, 'ohne fuehrenden /';
    is run_ok( $d, '/ip/firewall/filter/print' ), $out, 'v7-Schreibweise mit /';
    is run_ok( $d, '/ip fi fi pr' ), $out, 'eindeutige Abkuerzungen';
    is run_ok( $d, '/ip firewall filter print detail' ), $out, 'detail';
    is run_ok( $d, '/ip firewall filter print count-only' ), 3, 'count-only';
    like run_ok( $d, '/ip firewall filter print terse' ), qr/^ 0    comment="LAN raus" chain=forward/m, 'terse';
    is run_ok( $d, '/ip firewall nat print' ), 'Flags: X - disabled, I - invalid, D - dynamic', 'leeres bekanntes Menue';
    ok !exists $d->{menus}{'/ip firewall nat'}, 'print legt kein Menue an';
    like run_ok( $d, '/ip dhcp-server lease print' ), qr/^ 0 D  address=192\.168\.88\.20 mac-address=AA:BB:CC:00:00:01 server=dhcp1$/m,
        'dynamisch als Flag, nicht als Paar';
    like run_ok( $d, '/interface print' ), qr/^ 0 R  name=ether1 type=ether mtu=1500$/m, 'running als R';
};

subtest 'print where' => sub {
    my $d = fresh();
    my $out = run_ok( $d, '/ip firewall filter print where chain=forward' );
    like $out, qr/^ 0 /m;
    like $out, qr/^ 1 X/m;
    unlike $out, qr/^ 2 /m, 'Nummern bleiben die der ganzen Liste';
    is run_ok( $d, '/ip firewall filter print count-only where disabled' ), 1, 'Flag ohne Wert';
    is run_ok( $d, '/ip firewall filter print count-only where !disabled and chain=forward' ), 1, '! und and';
    is run_ok( $d, '/ip firewall filter print count-only where comment~"LAN"' ), 1, 'regex';
    is run_ok( $d, '/ip firewall filter print count-only where chain=input or action=drop' ), 2, 'or';
    is run_ok( $d, '/ip firewall filter print count-only where action!=accept' ), 1, '!=';
};

subtest 'add, set, remove, disable, enable, comment' => sub {
    my $d = fresh();
    run_ok( $d, '/ip firewall filter add chain=forward action=drop src-address=10.0.0.0/8 comment="kein RFC1918"' );
    my $l = $d->{menus}{'/ip firewall filter'};
    is scalar @$l, 4, 'angehaengt';
    is_deeply $l->[3], { chain => 'forward', action => 'drop', 'src-address' => '10.0.0.0/8', comment => 'kein RFC1918' };
    like run_ok( $d, '/ip firewall filter print' ), qr/^ 3    ;;; kein RFC1918\n      chain=forward action=drop src-address=10\.0\.0\.0\/8$/m,
        'naechster print zeigt es';

    run_ok( $d, '/ip firewall filter add chain=input action=drop place-before=0' );
    is $l->[0]{chain}, 'input', 'place-before fuegt vor Eintrag 0 ein';
    is scalar @$l, 5;

    run_ok( $d, '/ip firewall filter set 0,1 log=yes' );
    is $l->[0]{log}, 'yes';
    is $l->[1]{log}, 'yes', 'mehrere Nummern';
    run_ok( $d, '/ip firewall filter set 0 !log' );
    ok !exists $l->[0]{log}, '!k entfernt';
    run_ok( $d, '/ip firewall filter set 1 log=""' );
    ok !exists $l->[1]{log}, 'k="" entfernt';
    run_ok( $d, '/ip firewall filter set [find comment="LAN raus"] action=fasttrack-connection' );
    is $l->[1]{action}, 'fasttrack-connection', 'set [find ...]';

    run_ok( $d, '/ip firewall filter enable 2' );
    is $l->[2]{disabled}, 'no', 'enable';
    run_ok( $d, '/ip firewall filter disable 3' );
    is $l->[3]{disabled}, 'yes', 'disable';
    run_ok( $d, '/ip firewall filter enable 3' );
    is $l->[3]{disabled}, 'no';
    run_ok( $d, '/ip firewall filter disable 0; /ip firewall filter enable 0' );
    is $l->[0]{disabled}, 'no';
    my $d2 = fresh();
    run_ok( $d2, '/ip firewall filter enable 0' );
    ok !exists $d2->{menus}{'/ip firewall filter'}[0]{disabled}, 'enable schreibt kein disabled=no dazu';

    run_ok( $d, '/ip firewall filter comment 0 comment="neu hier"' );
    is $l->[0]{comment}, 'neu hier';

    run_ok( $d, '/ip firewall filter remove 0,4' );
    is scalar @$l, 3;
    is_deeply chains($d), [ 'forward/fasttrack-connection', 'forward/drop', 'input/accept' ], 'remove mehrerer';
    run_ok( $d, '/ip firewall filter remove [find chain=input]' );
    is scalar @$l, 2, 'remove [find]';

    my $e = fresh();
    run_ok( $e, '/ip address add address=10.9.9.1/24 interface=bridge' );
    is $e->{menus}{'/ip address'}[2]{network}, '10.9.9.0', 'network wird berechnet';
    run_ok( $e, '/ip firewall nat add chain=srcnat action=masquerade out-interface=ether1' );
    is scalar @{ $e->{menus}{'/ip firewall nat'} }, 1, 'add legt bekanntes leeres Menue an';
};

subtest 'move: Eintrag a vor den Eintrag mit Nummer b' => sub {
    my $d = fresh();    # 0 forward/accept, 1 forward/drop, 2 input/accept
    run_ok( $d, '/ip firewall filter move 2 0' );
    is_deeply chains($d), [qw( input/accept forward/accept forward/drop )], 'move 2 0';
    $d = fresh();
    run_ok( $d, '/ip firewall filter move 0 2' );
    is_deeply chains($d), [qw( forward/drop forward/accept input/accept )], 'move 0 2: vor den bisherigen 2';
    $d = fresh();
    run_ok( $d, '/ip firewall filter move 0 1' );
    is_deeply chains($d), [qw( forward/accept forward/drop input/accept )], 'move 0 1 aendert nichts';
    $d = fresh();
    run_ok( $d, '/ip firewall filter move 0' );
    is_deeply chains($d), [qw( forward/drop input/accept forward/accept )], 'ohne Ziel ans Ende';
    $d = fresh();
    run_ok( $d, '/ip firewall filter move numbers=1 destination=0' );
    is_deeply chains($d), [qw( forward/drop forward/accept input/accept )], 'numbers= destination=';
    $d = fresh();
    run_fail( $d, '/ip firewall filter move 0 7', qr/\Ano such item\z/ );
    is_deeply chains($d), chains( fresh() ), 'Zustand unveraendert';
    run_fail( $d, '/ip address move 0 1', qr/\Abad command name move \(line 1 column 13\)\z/ );
};

subtest 'find-Varianten' => sub {
    my $d = fresh();
    run_ok( $d, '/ip firewall filter set [find] log=yes' );
    is scalar( grep { ( $_->{log} // '' ) eq 'yes' } @{ $d->{menus}{'/ip firewall filter'} } ), 3, '[find] = alle';
    $d = fresh();
    run_ok( $d, '/ip firewall filter set [find where chain=forward and action=drop] comment=x' );
    is $d->{menus}{'/ip firewall filter'}[1]{comment}, 'x', 'find where ... and ...';
    run_ok( $d, '/ip firewall filter remove [find comment~"^LAN"]' );
    is scalar @{ $d->{menus}{'/ip firewall filter'} }, 2, 'find comment~';
    run_ok( $d, '/ip firewall filter remove [find chain=nix]' );
    is scalar @{ $d->{menus}{'/ip firewall filter'} }, 2, 'leeres find tut nichts';
    is run_ok( $d, '/ip firewall filter find chain=forward' ), '', 'find allein gibt nichts aus';
};

subtest 'Menuewechsel ueber mehrere Zeilen' => sub {
    my $d = fresh();
    my $out = run_ok( $d, "/ip firewall filter\nadd chain=input action=drop\nprint count-only\n..\nnat\nprint count-only\n/\nip address print count-only" );
    is $out, "4\n0\n2", 'relativ, .., /';
    is $d->{menus}{'/ip firewall filter'}[3]{action}, 'drop';
    is run_ok( $d, "/ip firewall filter\n/ip address print count-only\nprint count-only" ), "2\n4",
        'absoluter Befehl wechselt das Menue nicht';
    is run_ok( $d, '# Kommentar' . "\n" . '/ip firewall filter print count-only' ), 4, 'Kommentarzeile';
};

subtest 'Einstellungs-Menue' => sub {
    my $d = fresh();
    is run_ok( $d, '/ip dns print' ), "                servers: 9.9.9.9\n  allow-remote-requests: yes", 'print';
    run_ok( $d, '/ip dns set servers=1.1.1.1,9.9.9.9 cache-size=4096' );
    is_deeply $d->{settings}{'/ip dns'}, { servers => '1.1.1.1,9.9.9.9', 'allow-remote-requests' => 'yes', 'cache-size' => '4096' };
    like run_ok( $d, '/ip dns print' ), qr/^\s+servers: 1\.1\.1\.1,9\.9\.9\.9$/m, 'naechster print zeigt es';
    run_fail( $d, '/ip dns set foo=1', qr/\Aexpected end of command \(line 1 column 13\)\z/ );
    is run_ok( $d, '/system identity print' ), '  name: r1';
    run_ok( $d, '/system identity set name=gw-a' );
    is $d->{identity}, 'gw-a';
    like run_ok( $d, '/system resource print' ), qr/^\s+version: 7\.\d+/m;
};

subtest 'Fehler wie RouterOS, Zustand unveraendert' => sub {
    my $d    = fresh();
    my $orig = dclone($d);
    run_fail( $d, '/ip foo print', qr/\Abad command name foo \(line 1 column 5\)\z/ );
    run_fail( $d, '/ip firewall filter frobnicate', qr/\Abad command name frobnicate \(line 1 column 21\)\z/ );
    run_fail( $d, '/ip firewall filter add chain=forward action=drop bogus=1',
        qr/\Aexpected end of command \(line 1 column 51\)\z/ );
    run_fail( $d, '/ip firewall filter add chain=forward action=dropp', qr/\Ainput does not match any value of action\z/ );
    run_fail( $d, '/ip firewall nat add chain=srcnat action=drop', qr/\Ainput does not match any value of action\z/ );
    run_fail( $d, '/ip firewall filter add action=drop', qr/\Afailure: chain not specified\z/ );
    run_fail( $d, '/ip firewall filter set 9 action=drop', qr/\Ano such item\z/ );
    run_fail( $d, '/ip firewall filter remove 0,9', qr/\Ano such item\z/ );
    run_fail( $d, '/ip firewall filter set action=drop', qr/\Amissing value\(s\) of argument\(s\) numbers\z/ );
    run_fail( $d, '/ip firewall filter add chain=forward comment="offen', qr/\Asyntax error/ );
    run_fail( $d, '/ip print', qr/\Abad command name print/ );
    run_fail( $d, ':put [find]', qr/\Abad command name :put/ );
    run_fail( $d, '/interface add name=x', qr/\Abad command name add/ );
    run_fail( $d, '/interface set ether1 type=vlan', qr/\Aexpected end of command/ );
    is_deeply $d, $orig, 'kein Fehler hat den Zustand beruehrt';

    my ( $out, $ok ) = $R->run( $d, "/ip firewall filter add chain=input action=drop\n/ip firewall filter add chain=x action=nein\n/ip firewall filter add chain=y action=drop" );
    ok !$ok, 'Zeile 2 scheitert';
    is $out, 'input does not match any value of action';
    is_deeply [ map { $_->{chain} } @{ $d->{menus}{'/ip firewall filter'} } ], [qw( forward forward input input )],
        'Zeile 1 bleibt ausgefuehrt, Zeile 3 laeuft nicht';
    ( $out, $ok ) = $R->run( $d, "/ip firewall filter print count-only\n/ip firewall filter bogus" );
    is $out, "4\nbad command name bogus (line 2 column 21)", 'Zeile im Fehler';
};

subtest 'dynamische Eintraege, Leases' => sub {
    my $d = fresh();
    run_fail( $d, '/ip dhcp-server lease set 0 comment=x', qr/\Afailure: can not change dynamic item\z/ );
    run_ok( $d, '/ip dhcp-server lease make-static 2' );
    ok !exists $d->{menus}{'/ip dhcp-server lease'}[2]{dynamic}, 'make-static';
    $d = fresh();
    run_ok( $d, '/ip dhcp-server lease remove [find dynamic=yes]' );
    is_deeply [ map { $_->{address} } @{ $d->{menus}{'/ip dhcp-server lease'} } ], ['192.168.88.5'],
        'dynamische Leases geloescht, statische bleiben';
    $d = fresh();
    $d->{menus}{'/ip firewall filter'}[0]{dynamic} = 'yes';
    run_fail( $d, '/ip firewall filter remove 0', qr/\Afailure: can not remove dynamic item\z/ );
};

subtest 'reboot, shutdown' => sub {
    my $d = fresh();
    my $out = run_ok( $d, "/system reboot\n/ip firewall filter remove 0" );
    like $out, qr/\AReboot, yes\? \[y\/N\]:/;
    is $d->{reboots}, 1, 'reboot zaehlt';
    is scalar @{ $d->{menus}{'/ip firewall filter'} }, 3, 'nach reboot laeuft nichts weiter';
    run_ok( $d, '/system reboot' );
    is $d->{reboots}, 2;
    run_ok( $d, '/system shutdown' );
    is $d->{shutdown}, 'yes';
    my ( $o, $ok ) = $R->run( $d, '/ip address print', { host => 'r1' } );
    ok !$ok, 'nach shutdown keine Antwort';
    like $o, qr/Connection timed out/;
};

subtest 'export' => sub {
    my $d = fresh();
    is run_ok( $d, '/ip firewall filter export' ), join( "\n",
        '# by RouterOS 7.16.2',
        '/ip firewall filter',
        'add action=accept chain=forward comment="LAN raus" connection-state=established,related',
        'add action=drop chain=forward disabled=yes',
        'add action=accept chain=input protocol=icmp' ), 'Menue-Export';
    my $all = run_ok( $d, '/export' );
    like $all, qr{^/ip dns\nset allow-remote-requests=yes servers=9\.9\.9\.9$}m, 'Einstellungen';
    like $all, qr{^/ip dhcp-server lease\nadd address=192\.168\.88\.5 comment=Drucker mac-address=AA:BB:CC:00:00:02 server=dhcp1$}m,
        'nur statische Leases';
    unlike $all, qr/192\.168\.88\.20/, 'dynamische fehlen';
    like $all, qr{^/system identity\nset name=r1$}m;
    like run_ok( $d, '/ip export terse' ), qr{^/ip firewall filter add action=drop chain=forward disabled=yes$}m, 'terse';
    like run_ok( $d, 'export compact' ), qr{^/ip address$}m;
};

subtest 'ping und traceroute folgen den Routen' => sub {
    my $d = fresh();
    my $out = run_ok( $d, '/ping 8.8.8.8 count=2' );
    like $out, qr/sent=2 received=2 packet-loss=0%/, 'ueber die Standardroute';
    like run_ok( $d, 'ping 192.168.88.50' ), qr/sent=3 received=3/, 'verbundenes Netz';
    $d->{menus}{'/ip route'} = [];
    $out = run_ok( $d, 'ping 8.8.8.8' );
    like $out, qr/no route to host/;
    like $out, qr/received=0 packet-loss=100%/;
    $d = fresh();
    $d->{menus}{'/ip route'}[0]{gateway} = '198.51.100.1';    # Gateway nicht erreichbar -> Route inaktiv
    like run_ok( $d, 'ping 8.8.8.8' ), qr/no route to host/;
    $d = fresh();
    like run_ok( $d, '/tool traceroute 8.8.8.8' ), qr/^1\s+203\.0\.113\.1\s.*\n2\s+8\.8\.8\.8\s/m, 'zwei Spruenge';
    run_fail( $d, 'ping nirgendwo', qr/\Ainvalid value for argument address\z/ );
};

{
    my $st = { r => { type => 'routeros', menus => {} } };
    my ( $o, $ok, $gap ) = run_command( $st, 'r', '/log print where topics~"dhcp"' );
    like( $gap, qr{/log print}, 'echtes Menue ohne Nachbildung: Luecke' );
    is( $o, '', '... neutrale (leere) Antwort' );
    ok( $ok, '... kein Fehler des Modells' );
    ( $o, $ok, $gap ) = run_command( $st, 'r', '/ip firewall filter print stats' );
    ok( $gap, 'print stats: Luecke' );
    ( $o, $ok, $gap ) = run_command( $st, 'r', '/ip firewal filter print' );
    is( $gap, undef, 'Tippfehler: keine Luecke' );
}

# Vertrag (ADR 0005): Typ routeros ist eingebaut, kein write_file, kein eigener Exit-Status
{
    my $sims = Holmgang::TestSim::sims();
    ok( ( grep { $_ eq 'routeros' } $sims->types ), 'routeros ist eingebaut' );
    my $st = { r => { type => 'routeros', menus => {} } };
    my ( $o, $ok ) = write_file( $st, 'r', '/flash/x.rsc', '/ip address print' );
    ok( !$ok, 'write_file abgelehnt' );
    like( $o, qr/\Ascp: r: /, '... wie scp' );
    is_deeply( $st, { r => { type => 'routeros', menus => {} } }, '... Zustand unveraendert' );
    my @r = $sims->run_command( $st, 'r', '/ip foo print' );
    is( scalar @r, 3, 'Ergebnis ( output, ok, gap ) ohne eigenen Exit-Status' );
}

done_testing;
