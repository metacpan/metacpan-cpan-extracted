#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Shell ();
use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );

# Shell der Simulatoren: Umleitungen des Fehlerkanals. Modelle
# haengen gern 2>&1 oder 2>/dev/null an. Behauptet wird: 2>&1, 1>&2, 2>/dev/null
# und 2>>datei aendern weder Ausgabe noch Zustand (die Simulation trennt die
# Kanaele nicht); &>datei leitet wie > um; ein >& mitten in einem Wort bleibt Text.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

is_deeply( [ Langertha::Holmgang::Shell::shell_words('ls -l /opt 2>&1') ], [ 'ls', '-l', '/opt' ], '2>&1 entfaellt' );
is_deeply( [ Langertha::Holmgang::Shell::shell_words('ls /x 2>/dev/null | head') ], [ 'ls', '/x', { op => '|' }, 'head' ], '2>/dev/null entfaellt' );
is_deeply( [ Langertha::Holmgang::Shell::shell_words('echo a 2> /tmp/err; echo b') ], [ 'echo', 'a', { op => ';' }, 'echo', 'b' ], '2> datei (mit Leerzeichen) entfaellt' );
is_deeply( [ Langertha::Holmgang::Shell::shell_words('echo a 1>&2') ], [ 'echo', 'a' ], '1>&2 entfaellt' );
is_deeply( [ Langertha::Holmgang::Shell::shell_words('echo a &>/tmp/x') ], [ 'echo', 'a', { op => '>' }, '/tmp/x' ], '&> wie >' );
is_deeply( [ Langertha::Holmgang::Shell::shell_words('a && b') ], [ 'a', { op => '&&' }, 'b' ], '&& unberuehrt' );
is_deeply( [ Langertha::Holmgang::Shell::shell_words('echo x2>&1') ], [ 'echo', 'x2', { op => '>' }, '&1' ], 'mitten im Wort keine Sonderbehandlung' );

my $state = clone( { srv => { type => 'linux', files => { '/opt/app/bin/app' => "x\n" } } } );
my ( $o, $ok ) = run_command( $state, 'srv', 'ls -la /opt/app/bin/ 2>&1; echo ---' );
ok( $ok, 'Befehl mit 2>&1 gelingt' );
like( $o, qr/\bapp\n---\z/, 'Ausgabe wie ohne Umleitung' );
ok( !exists $state->{srv}{files}{'&1'}, 'keine Datei namens &1' );

done_testing;
