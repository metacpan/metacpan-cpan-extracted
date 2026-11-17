#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Linux-Simulator: which. Modelle pruefen gern, ob ein Programm
# da ist; bisher war which eine Luecke (leere Antwort), sie fragten dann
# immer wieder. Behauptet wird: nachgebildete Befehle und Programme im Zustand
# unter den PATH-Verzeichnissen werden gefunden, nicht installierte (curl,
# iptables) nicht — Exit-Status wie bei which.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $state = clone( { srv => { type => 'linux', files => { '/usr/local/bin/ingest' => { mode => '0755', content => '' } } } } );
sub sh { my ( $o, $ok, $gap ) = run_command( $state, 'srv', $_[0] ); return ( $o, $ok, $gap ) }

my ( $o, $ok, $gap ) = sh('which systemctl ip');
ok( $ok, 'which fuer nachgebildete Befehle gelingt' );
is( $o, "/usr/bin/systemctl\n/usr/sbin/ip", 'mit Pfad' );
ok( !defined $gap, 'keine Luecke der Simulation' );
( $o, $ok ) = sh('which ingest');
is( $o, '/usr/local/bin/ingest', 'Programm aus dem Zustand im PATH' );
( $o, $ok ) = sh('which curl');
ok( !$ok, 'nicht installiert: Exit 1' );
is( $o, '', 'ohne Ausgabe' );
( $o, $ok ) = sh('which iptables || echo fehlt');
is( $o, 'fehlt', 'in einer Kette nutzbar' );

# timeout DAUER befehl: fuehrt den Befehl aus (die Simulation wartet nie)
( $o, $ok, $gap ) = sh('timeout 5 systemctl is-active ssh || echo nein');
ok( !defined $gap, 'timeout ist keine Luecke mehr' );
is( $o, "inactive\nnein", 'Ausgabe und Exit-Status des Befehls' );
( $o, $ok ) = sh('timeout -s KILL 3s which ip');
is( $o, '/usr/sbin/ip', 'mit -s und Einheit' );
( $o, $ok ) = sh('timeout abc ls');
ok( !$ok, 'ungueltige Dauer scheitert' );

done_testing;
