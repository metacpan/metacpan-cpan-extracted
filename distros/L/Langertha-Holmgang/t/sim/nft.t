#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );
use Langertha::Holmgang::Sim::Linux::Nft ();

# Der nft-Auswerter. Behauptet wird: das Urteil fuer ein Paket
# folgt dem Weg durch die Basisketten wie im Kernel — Reihenfolge der Regeln,
# policy, mehrere Basisketten nach priority, jump/goto/return, benannte Sets,
# vmap; gleichwertige Schreibweisen (Dienstname, Menge, Bereich) urteilen
# gleich; was nicht verstanden wird, gibt kein Urteil, sondern einen Grund.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

sub dev {
    my (%c) = @_;
    return { type => 'linux', nft => { 'inet filter' => { chains => { input => { type => 'filter', hook => 'input',
        priority => '0', policy => 'drop', rules => [@{ $c{input} || [] }] }, %{ $c{chains} || {} } },
        ( $c{sets} ? ( sets => $c{sets} ) : () ) }, %{ $c{tables} || {} } } };
}
sub v { my ( $d, %p ) = @_; return ( Langertha::Holmgang::Sim::Linux::Nft::verdict( $d, { hook => 'input', iif => 'eth0', proto => 'tcp', %p } ) )[0] // 'undef' }

my %ssh_wan = ( saddr => '203.0.113.7', daddr => '198.51.100.2', dport => 22 );
my %ssh_lan = ( iif => 'eth1', saddr => '10.1.0.7', daddr => '10.1.0.1', dport => 22 );

subtest 'Reihenfolge und policy' => sub {
    my $d = dev( input => [ 'ct state established,related accept', 'iifname "eth1" tcp dport 22 accept' ] );
    is( v( $d, %ssh_lan ), 'accept', 'LAN -> ssh: Regel passt' );
    is( v( $d, %ssh_wan ), 'drop',   'WAN -> ssh: policy drop' );
    is( v( $d, %ssh_wan, ct => 'established' ), 'accept', 'Antwortpaket: established' );
    $d = dev( input => [ 'tcp dport 22 drop', 'iifname "eth1" tcp dport 22 accept' ] );
    is( v( $d, %ssh_lan ), 'drop', 'drop davor gewinnt (Reihenfolge)' );
    my ( undef, $why ) = Langertha::Holmgang::Sim::Linux::Nft::verdict( $d, { hook => 'input', proto => 'tcp', %ssh_lan } );
    like( $why, qr/tcp dport 22 drop/, 'Grund nennt die Regel' );
};

subtest 'gleichwertige Schreibweisen' => sub {
    for my $r ( 'iifname eth1 tcp dport ssh accept', 'meta iifname "eth1" tcp dport { 22, 443 } accept',
        'ip saddr 10.1.0.0/24 tcp dport 20-25 accept', 'ip saddr 10.1.0.1-10.1.0.9 th dport 22 counter accept',
        'iifname "eth*" ip saddr { 10.1.0.7, 10.9.9.9 } tcp dport 22 log prefix "ssh " accept',
        'meta l4proto tcp tcp dport 22 limit rate 10/minute burst 5 packets accept comment "Verwaltung"',
        'ip protocol tcp ip daddr 10.1.0.1 accept' ) {
        is( v( dev( input => [$r] ), %ssh_lan ), 'accept', $r );
    }
    is( v( dev( input => ['tcp dport 22 limit rate over 10/minute accept'] ), %ssh_lan ), 'drop', 'limit over passt nie' );
    is( v( dev( input => ['udp dport 22 accept'] ), %ssh_lan ), 'drop', 'udp-Regel passt nicht auf tcp' );
    is( v( dev( input => ['ip saddr != 10.1.0.0/24 drop'], ), %ssh_lan ), 'drop', '!= : LAN nicht verworfen, policy drop' );
    is( v( dev( input => [ 'ip saddr != 10.1.0.0/24 drop', 'accept' ] ), %ssh_lan ), 'accept', '!= laesst LAN durch' );
    is( v( dev( input => [ 'ip saddr != 10.1.0.0/24 drop', 'accept' ] ), %ssh_wan ), 'drop', '!= verwirft WAN' );
    is( v( dev( input => ['ip6 saddr fd00::/64 accept'] ), %ssh_lan ), 'drop', 'ip6-Ausdruck passt nicht auf IPv4' );
    is( v( dev( input => ['ip6 saddr fd00::/64 accept'] ), %ssh_lan, saddr => 'fd00::7', daddr => 'fd00::1' ), 'accept', '... aber auf IPv6' );
    is( v( dev( input => ['icmp type echo-request accept'] ), proto => 'icmp', saddr => '10.1.0.7', daddr => '10.1.0.1' ), 'accept', 'icmp' );
    is( v( dev( input => ['icmpv6 type { nd-neighbor-solicit, echo-request } accept'] ), proto => 'icmpv6', saddr => 'fe80::7', daddr => 'fe80::1',
        icmp_type => 'nd-neighbor-solicit' ), 'accept', 'icmpv6 Nachbarschaft' );
};

subtest 'vmap, Ketten, Sets' => sub {
    my $d = dev( input => [ 'ct state vmap { established : accept, related : accept, invalid : drop }', 'iifname vmap { "lo" : accept, "eth1" : jump lan }' ],
        chains => { lan => { rules => [ 'tcp dport 22 accept', 'return' ] } } );
    is( v( $d, %ssh_lan ), 'accept', 'vmap -> jump lan -> accept' );
    is( v( $d, %ssh_lan, dport => 80 ), 'drop', 'return -> zurueck -> policy' );
    is( v( $d, %ssh_wan, ct => 'invalid' ), 'drop', 'vmap invalid drop' );
    is( v( $d, %ssh_wan, ct => 'established' ), 'accept', 'vmap established' );

    $d = dev( input => [ 'ip saddr @admins tcp dport 22 accept' ], sets => { admins => { type => 'ipv4_addr', flags => ['interval'], elements => [ '10.1.0.7', '10.2.0.0/24' ] } } );
    is( v( $d, %ssh_lan ), 'accept', 'benanntes Set' );
    is( v( $d, %ssh_lan, saddr => '10.1.0.8' ), 'drop', 'nicht im Set' );
    is( v( $d, %ssh_lan, saddr => '10.2.0.99' ), 'accept', 'Intervall im Set' );
    is( v( dev( input => ['ip saddr @fehlt accept'] ), %ssh_lan ), 'undef', 'unbekanntes Set: kein Urteil' );
    $d = dev( input => [ 'tcp dport 22 ip saddr @addr-set-sshd drop', 'tcp dport 22 accept' ], sets => { 'addr-set-sshd' => { type => 'ipv4_addr', elements => ['10.1.0.7'] } } );
    is( v( $d, %ssh_lan ), 'drop', 'Set-Name mit Bindestrich (fail2ban)' );
};

subtest 'mehrere Basisketten, Familien' => sub {
    my $d = dev( input => ['accept'], tables => { 'ip early' => { chains => { in => { type => 'filter', hook => 'input',
        priority => 'filter - 10', policy => 'accept', rules => ['tcp dport 22 drop'] } } } } );
    is( v( $d, %ssh_lan ), 'drop', 'fruehere Basiskette verwirft, spaetere accept hilft nicht' );
    $d = dev( input => ['tcp dport 22 drop'], tables => { 'ip early' => { chains => { in => { type => 'filter', hook => 'input',
        priority => '-10', policy => 'accept', rules => ['tcp dport 22 accept'] } } } } );
    is( v( $d, %ssh_lan ), 'drop', 'accept beendet nur die eigene Basiskette' );
    is( v( $d, %ssh_lan, saddr => 'fd00::7', daddr => 'fd00::1' ), 'drop', 'Tabelle ip gilt nicht fuer IPv6, inet schon' );
    $d = dev( input => ['accept'], tables => { 'ip nat' => { chains => { pre => { type => 'nat', hook => 'input', priority => '100', rules => ['drop'] } } } } );
    is( v( $d, %ssh_lan ), 'accept', 'nat-Ketten urteilen nicht' );
    is( ( Langertha::Holmgang::Sim::Linux::Nft::verdict( dev( input => [] ), { hook => 'forward', proto => 'tcp', %ssh_lan } ) )[0], 'accept',
        'kein Hook forward: accept' );
};

subtest 'nicht auswertbar' => sub {
    for my $r ( 'tcp flags syn tcp dport 22 accept', 'fib daddr type local accept', 'meta mark 0x1 accept', 'tcp dport 22 accept drop' ) {
        ok( Langertha::Holmgang::Sim::Linux::Nft::parse_error($r), "nicht auswertbar: $r" );
    }
    is( v( dev( input => ['meta mark 0x1 accept'] ), %ssh_lan ), 'undef', 'Urteil undef' );
    ok( !Langertha::Holmgang::Sim::Linux::Nft::parse_error($_), "auswertbar: $_" )
        for 'reject with icmpx type admin-prohibited', 'reject with tcp reset', 'ct state invalid counter drop', 'iif lo accept',
        'udp dport 51820 accept', 'meta nfproto ipv6 icmpv6 type nd-router-advert accept';
};

subtest 'Linux-Simulator: Sets, nft -c, define, Luecke, Neustart' => sub {
    my $state = { fw => { %{ dev( input => [ 'ct state established,related accept', 'iifname "lo" accept' ] ) },
        files => { '/etc/nftables.conf' => "#!/usr/sbin/nft -f\nflush ruleset\ndefine LAN = 10.1.0.0/24\n"
            . "table inet filter {\n\tset admins {\n\t\ttype ipv4_addr\n\t\tflags interval\n\t\telements = { 10.1.0.7 }\n\t}\n"
            . "\tchain input {\n\t\ttype filter hook input priority filter; policy drop;\n\t\tip saddr \@admins tcp dport 22 accept\n"
            . "\t\tip saddr \$LAN udp dport 53 accept\n\t}\n}\n" } } };
    my $w = clone($state);
    my $sh = sub { my ( $o, $ok, $gap ) = run_command( $w, 'fw', $_[0] ); return wantarray ? ( $o, $ok, $gap ) : $o };
    my $fw = sub { $w->{fw} };

    my ( $o, $ok ) = $sh->('nft add rule inet filter input ip saddr @admins tcp dport 22 accept');
    ok( !$ok, 'Regel mit unbekanntem Set: Fehler' );
    ok( ( $sh->(q{nft add set inet filter admins '{ type ipv4_addr; flags interval; }'}) )[1], 'add set' );
    ok( ( $sh->('nft add element inet filter admins { 10.1.0.7, 10.2.0.0/24 }') )[1], 'add element' );
    ok( ( $sh->('nft add rule inet filter input ip saddr @admins tcp dport 22 accept') )[1], 'Regel mit Set' );
    is( v( $fw->(), %ssh_lan ), 'accept', 'wirkt' );
    ok( ( $sh->('nft add chain inet filter lan_in') )[1], 'add chain ohne Hook' );
    ok( ( $sh->('nft insert rule inet filter input iifname vmap { "eth1" : jump lan_in }') )[1], 'iifname vmap' );
    like( scalar $sh->('nft list chain inet filter input'), qr/iifname vmap \{ "?eth1"? : jump lan_in \}/, '... bleibt vmap (nicht "vmap")' );
    like( scalar $sh->('nft list set inet filter admins'), qr/elements = \{ 10\.1\.0\.7, 10\.2\.0\.0\/24 \}/, 'list set' );
    like( scalar $sh->('nft list ruleset'), qr/set admins \{.*type ipv4_addr.*flags interval/s, 'im Regelsatz' );
    ok( ( $sh->('nft delete element inet filter admins { 10.1.0.7 }') )[1], 'delete element' );
    is( v( $fw->(), %ssh_lan ), 'drop', '... weg' );
    ok( !( $sh->('nft delete set inet filter admins') )[1], 'benutztes Set laesst sich nicht loeschen' );
    $sh->(q{nft add set inet filter einzeln '{ type ipv4_addr; }'});
    like( ( $sh->('nft add element inet filter einzeln { 10.0.0.0/8 }') )[0], qr/flags interval/, 'Praefix ohne interval: Fehler wie nft' );

    my $before = clone( $fw->()->{nft} );
    ok( ( $sh->('nft -c -f /etc/nftables.conf') )[1], 'nft -c -f: Datei gueltig' );
    is_deeply( $fw->()->{nft}, $before, '... und nichts geladen' );
    is( ( Langertha::Holmgang::Sim::Linux::Nft::boot_verdict( $fw->(), { hook => 'input', iif => 'eth1', proto => 'udp', saddr => '10.1.0.9',
        daddr => '10.1.0.1', dport => 53 } ) )[0], 'accept', 'nach Neustart: define aufgeloest' );
    is( ( Langertha::Holmgang::Sim::Linux::Nft::boot_verdict( $fw->(), { hook => 'input', iif => 'eth1', proto => 'tcp', %ssh_lan, saddr => '10.2.0.5' } ) )[0],
        'drop', 'nach Neustart: Set aus der Datei (ohne 10.2.0.0/24)' );
    ok( ( $sh->('nft -f /etc/nftables.conf') )[1], 'nft -f laedt' );
    is_deeply( $fw->()->{nft}{'inet filter'}{sets}{admins}{elements}, ['10.1.0.7'], '... Set aus der Datei' );

    ( $o, $ok, my $gap ) = $sh->('nft add rule inet filter input meta mark 0x1 accept');
    ok( $ok, 'unbekannte Regel wird angelegt' );
    like( $gap // '', qr/nicht auswertbar/, '... als Luecke der Simulation vermerkt' );
    ( undef, undef, $gap ) = $sh->('nft add rule inet filter input tcp dport 80 accept');
    ok( !defined $gap, 'verstandene Regel: keine Luecke' );
    my $n = @{ $fw->()->{nft}{'inet filter'}{chains}{input}{rules} };
    ( $o, $ok, $gap ) = $sh->('nft insert rule inet filter input 6 ip saddr 10.20.0.0/24 tcp dport 5432 accept');
    ok( !$ok, 'Zahl ohne position: Syntaxfehler wie nft' );
    like( $o, qr/syntax error, unexpected number/, '... mit Meldung' );
    is( scalar @{ $fw->()->{nft}{'inet filter'}{chains}{input}{rules} }, $n, '... nichts angelegt' );
    ( $o, $ok ) = $sh->('nft add rule inet filter input icmpv6 type { echo-request, neighbor-solicit } accept');
    ok( !$ok, 'unbekannter ICMPv6-Typ: Fehler wie nft (keine Luecke)' );
    like( $o, qr/Could not parse ICMPv6 type/, '... mit Meldung' );
    ok( !( $sh->('nft add rule inet filter input tcp dport sshh accept') )[1], 'unbekannter Dienstname: Fehler' );
    like( scalar $sh->('which nft wg'), qr{\A/usr/sbin/nft\n/usr/bin/wg\z}, 'which' );
    ok( !( $sh->('which iptables') )[1], 'which: nicht installiert' );
    like( scalar $sh->('wc -c /etc/nftables.conf'), qr{\A\d+ /etc/nftables\.conf\z}, 'wc -c datei' );
    $sh->('nft list ruleset > /root/a.nft; nft list ruleset > /root/b.nft');
    ok( ( $sh->('diff /root/a.nft /root/b.nft') )[1], 'diff: gleich' );
    $sh->('echo "# neu" >> /root/b.nft');
    ( $o, $ok ) = $sh->('diff /root/a.nft /root/b.nft');
    ok( !$ok, 'diff: verschieden (Exit 1)' );
    like( $o, qr/^> # neu$/m, '... zeigt die neue Zeile' );
    like( scalar $sh->('md5sum /root/a.nft'), qr{\A[0-9a-f]{32}  /root/a\.nft\z}, 'md5sum' );
};

subtest 'Handles bleiben fest wie in nft' => sub {
    my $state = { fw => dev( input => [ 'ct state established,related accept', 'tcp dport 22 accept' ] ) };
    my $sh = sub { ( run_command( $state, 'fw', $_[0] ) )[0] };
    like( $sh->('nft -a list chain inet filter input'), qr/tcp dport 22 accept # handle 4/, 'Handle aus der Reihenfolge' );
    $sh->('nft insert rule inet filter input position 4 tcp dport 80 accept');
    my $l = $sh->('nft -a list chain inet filter input');
    like( $l, qr/tcp dport 80 accept # handle 5\n\t\ttcp dport 22 accept # handle 4/, 'neue Regel: naechste Nummer, alte behaelt ihre' );
    $sh->('nft delete rule inet filter input handle 4');
    is_deeply( $state->{fw}{nft}{'inet filter'}{chains}{input}{rules}, [ 'ct state established,related accept', 'tcp dport 80 accept' ],
        'delete handle 4 trifft die alte Regel' );
    $sh->('nft add rule inet filter input tcp dport 443 accept');
    like( $sh->('nft -a list chain inet filter input'), qr/443 accept # handle 6/, 'weiter hochgezaehlt' );
    like( $sh->('nft list ruleset -a'), qr/443 accept # handle 6/, 'Option hinter dem Befehl (getopt)' );
    like( $sh->(q{nft 'list chain inet filter input -a'}), qr/# handle 6/, '... auch in einem Argument' );
    $sh->(q{nft add chain inet filter frueh '{ type filter hook input priority -10; policy accept; }'});
    is( $state->{fw}{nft}{'inet filter'}{chains}{frueh}{priority}, '-10', 'priority -10 ist keine Option' );
    is_deeply( [ diff( { a => 1, _x => 1 }, { a => 1, _x => 2 } ) ], [], 'Buchfuehrung (_…) nicht im Diff' );
};

subtest 'Aussperren ueber die eigene Firewall' => sub {
    my $state = { fw => { %{ dev( input => [ 'ct state established,related accept', 'iifname "eth1" tcp dport 22 accept' ] ) },
        nft_login => { iif => 'eth1', saddr => '10.1.0.50', daddr => '10.1.0.1' } } };
    my $sh = sub { [ run_command( $state, 'fw', $_[0] ) ] };
    ok( $sh->('nft list ruleset')->[1], 'erreichbar' );
    ok( $sh->('nft flush chain inet filter input')->[1], 'flush laeuft noch durch' );
    my $r = $sh->('nft list ruleset');
    ok( !$r->[1], 'danach: kein Zugang' );
    like( $r->[0], qr/fw port 22: Connection timed out/, 'wie ssh' );
    ok( $state->{fw}{locked_out}, 'locked_out im Zustand' );
    ok( !( write_file( $state, 'fw', '/etc/x', 'y' ) )[1], 'write_file auch nicht' );

    $state = { fw => { %{ dev( input => ['tcp dport 22 accept'], chains => { output => { type => 'filter', hook => 'output',
        priority => '0', policy => 'accept', rules => [] } } ) }, nft_login => { iif => 'eth1', saddr => '10.1.0.50', daddr => '10.1.0.1' } } };
    ok( $sh->(q{nft add chain inet filter output '{ policy drop; }'})->[1], 'output policy drop laeuft durch' );
    ok( !$sh->('true')->[1], 'danach: die Antworten der Sitzung kommen nicht hinaus — weg' );
};

# Kolon's nft_verdict in observations belongs to the World/Template (k2); the loader's
# shape check of packet rules to the loader (k2). Here: the rule kind packet as the
# Grader asks it, through the registry.
subtest 'Regelart packet: packet_verdict ueber die Registry' => sub {
    my $sims = Holmgang::TestSim::sims();
    my $dev  = dev( input => ['iifname "eth1" tcp dport 22 accept'] );
    my %pkt  = ( hook => 'input', iif => 'eth1', saddr => '10.1.0.7', daddr => '10.1.0.1', proto => 'tcp', dport => 22 );
    my ( $v, $why ) = $sims->packet_verdict( $dev, \%pkt );
    is( $v, 'accept', 'accept' );
    like( $why, qr/accept/, 'Begruendung nennt die Stelle' );
    is( ( $sims->packet_verdict( $dev, { %pkt, iif => 'eth0' } ) )[0], 'drop', 'anderes Interface: drop' );
    ( $v, $why ) = $sims->packet_verdict( $dev, \%pkt, '/etc/nftables.conf' );
    is( $v, 'accept', 'boot ohne eigene Datei: der laufende Regelsatz ist die Datei' ) or diag $why;
    ( $v, $why ) = $sims->packet_verdict( $dev, \%pkt, '/etc/nft-fehlt.conf' );
    ok( !defined $v, 'boot mit fehlender Datei: kein Urteil' );
    like( $why, qr{/etc/nft-fehlt\.conf}, '... mit Grund' );
};

done_testing;
