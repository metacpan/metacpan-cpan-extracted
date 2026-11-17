#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Sim::Denken;
use Holmgang::TestSim qw( sims clone diff );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Denken als Welt ohne Geraet (ported from cai-platform t/eval_sim_denken.t).
# Behauptet wird: antwort_abgeben antwortet immer neutral, bewertet sofort und
# schreibt antwort/abgaben/ergebnis/befund in den Zustand; ein erneuter Aufruf
# ersetzt; ein gescheiterter Aufruf aendert nichts; prepare weist unbekannte
# Aufgaben und fehlende Pruefdaten ab; jeder Pruefer gibt nur der vollen
# Punktzahl von score_answer "richtig" und nimmt andere richtige Formen an.
# Die Raetsel hier sind ausgedacht (keine Faelle der Suite, ADR 0003); den
# Abgleich mit den Python-Urteilen macht t/sim/denken_vectors.t.

my $D = 'Langertha::Holmgang::Sim::Denken';
my $pruefe = $D->can('pruefe');

subtest 'Vertrag' => sub {
  ok( $D->does('Langertha::Holmgang::Role::AnswerWorld'), 'eine Antwortwelt' );
  is( $D->device_type, 'denken', 'Typ denken' );
  ok( sims()->is_answer_world('denken'), 'eingebaut in der Registry' );
  is_deeply( sims()->world_tools('denken'), { antwort_abgeben => ['antwort'] }, 'nur antwort_abgeben, Pflicht antwort' );
  is_deeply(
    [ $D->can('arten')->() ],
    [qw( calendar_arithmetic countdown course_schedule cryptarithm family_relationships graph_color jugs knights_knaves
         maze mini_sudoku propositional_logic self_reference shortest_path syllogism time_intervals zebra_puzzles )],
    'die sechzehn Aufgaben',
  );
};

# [ art, pruefung, [ antwort, richtig, name ] ... ]
my @checks = (
  [ zebra_puzzles => { antwort => 'wren' },
    [ 'wren', 1, 'gleich' ], [ 'Wren', 1, 'ohne Gross/klein' ], [ "wr\nen", 1, 'ohne Zeilenumbruch' ],
    [ ' wren', 0, 'Leerzeichen zaehlt' ], [ 'robin', 0, 'anderer Name' ] ],
  [ knights_knaves => { antwort => 'Mira is a knight, and Tobi is a knave.' },
    [ 'Mira is a knight, and Tobi is a knave.', 1, 'gleich' ],
    [ 'Tobi is a knave and Mira is a knight', 1, 'andere Reihenfolge und Satzbau' ],
    [ 'Mira is a knave, and Tobi is a knight.', 0, 'vertauscht' ],
    [ 'Mira is a knight.', 0, 'unvollstaendig' ], [ '', 0, 'leer' ] ],
  [ propositional_logic => { premissen => [ 'P → Q', 'P' ], variablen => [qw( P Q )] },
    [ '(P ∧ Q)', 1, 'folgt, nicht trivial' ], [ 'P ∧ Q', 1, 'ohne Klammern' ],
    [ 'Q', 0, 'einzelnes Atom' ], [ '(Q ∨ ¬Q)', 0, 'Tautologie' ], [ '¬Q', 0, 'folgt nicht' ],
    [ '(P ∧ R)', 0, 'fremdes Atom' ] ],
  [ syllogism => { antwort => 'Yes' }, [ 'Yes', 1, 'gleich' ], [ 'yes', 0, 'Gross/klein zaehlt' ], [ 'Yes ', 0, 'Leerraum zaehlt' ] ],
  [ course_schedule => { antwort => 'False' }, [ 'False', 1, 'gleich' ], [ 'True', 0, 'anders' ] ],
  [ maze => { antwort => '7' }, [ '7', 1, 'gleich' ], [ '07', 0, 'genau gleich, nicht als Zahl' ] ],
  [ self_reference => { antwort => '2' }, [ '2', 1, 'gleich' ], [ '3', 0, 'anders' ] ],
  [ shortest_path => { antwort => 'right right down down', matrix => [ [ "*", "O", "O" ], [ "O", "X", "O" ], [ "O", "O", "#" ] ] },
    [ 'right right down down', 1, 'gleich' ], [ ' right right down down ', 1, 'getrimmt' ],
    [ 'down down right right', 1, 'anderer kuerzester Weg' ],
    [ 'right down down right', 0, 'durch X' ], [ 'up right right down down down', 0, 'verlaesst das Gitter' ],
    [ 'down down right right up down', 0, 'gueltig, aber laenger' ], [ 'right right down', 0, 'endet nicht am Ziel' ],
    [ 'right right down south', 0, 'keine Richtung' ], [ '', 0, 'leer' ] ],
  [ graph_color => { knoten => [ 0, 1, 2 ], kanten => [ [ 0, 1 ], [ 1, 2 ] ], farben => [ 1, 2, 3 ] },
    [ '{"0": 1, "1": 2, "2": 1}', 1, 'gueltig' ], [ '{"0": 3, "1": 2, "2": 3}', 1, 'andere gueltige Faerbung' ],
    [ '{"0": 1, "1": 1, "2": 2}', 0, 'Kante gleich gefaerbt' ], [ '{"0": 1, "1": 2}', 0, 'Knoten ohne Farbe' ],
    [ '{"0": 4, "1": 2, "2": 1}', 0, 'unerlaubte Farbe' ], [ '{"0": "1", "1": 2, "2": 1}', 0, 'Farbe als Text' ],
    [ 'rot, gruen, rot', 0, 'kein JSON' ], [ '"1"', 0, 'kein JSON-Objekt' ] ],
  [ calendar_arithmetic => { antwort => 'Tuesday', form => 'weekday_offset' },
    [ ' Tuesday ', 1, 'Wochentag getrimmt' ], [ 'tuesday', 0, 'Wochentag mit Gross/klein' ] ],
  [ calendar_arithmetic => { antwort => '12', form => 'count_days' },
    [ '12', 1, 'Zahl' ], [ ' 012 ', 1, 'Zahl wie int()' ], [ '1_2', 1, 'Zahl mit _' ], [ 'twelve', 0, 'keine Zahl' ],
    [ '13', 0, 'andere Zahl' ] ],
  [ calendar_arithmetic => { antwort => 'Yes', form => 'is_leap_year' }, [ 'yes', 1, 'Schaltjahr ohne Gross/klein' ], [ 'No', 0, 'anders' ] ],
  [ calendar_arithmetic => { antwort => 'Yes', form => 'moon_phase' }, [ 'Yes', 0, 'unbekannte Form' ] ],
  [ time_intervals => { antwort => '01:30', form => 'time' },
    [ '1:30', 1, 'gleiche Dauer' ], [ '01:30:00', 1, 'mit Sekunden' ], [ '01:31', 0, 'andere Dauer' ], [ '90', 0, 'ohne Minuten' ] ],
  [ time_intervals => { antwort => '00:00:01.500', form => 'time_ms' },
    [ '0:0:1.500', 1, 'Millisekunden' ], [ '0:0:1.501', 0, 'andere Millisekunden' ] ],
  [ time_intervals => { antwort => '15 days', form => 'date' },
    [ '15', 1, 'erste Zahl' ], [ '16 days', 0, 'andere Zahl' ] ],
  [ time_intervals => { antwort => '2 days, 03:00:00', form => 'datetime' },
    [ '2 days, 3:00', 1, 'gleiche Dauer' ], [ '1 days, 27:00:00', 1, 'dieselben Sekunden' ], [ 'zwei Tage', 0, 'nicht auswertbar' ] ],
  [ cryptarithm => { woerter => [qw( AB C )], ergebnis => 'AD' },
    [ 'A=1,B=2,C=3,D=5', 1, 'Summe stimmt' ], [ 'D=8, C=6, B=2, A=4', 1, 'andere Loesung, andere Reihenfolge' ],
    [ 'A=1,B=2,C=3,D=6', 0, 'Summe stimmt nicht' ], [ 'A=1,B=2,C=3', 0, 'Buchstabe fehlt' ],
    [ 'A=1,B=2,C=3,D=5,E=7', 0, 'Buchstabe zu viel' ], [ 'A=1,B=2,C=2,D=4', 0, 'Ziffer doppelt' ],
    [ 'A=0,B=2,C=3,D=5', 0, 'fuehrende Null' ], [ 'A=1;B=2;C=3;D=5', 0, 'nicht lesbar' ] ],
  [ cryptarithm => { woerter => [qw( AB C )], ergebnis => 'AD', fuehrende_null => 1 },
    [ 'A=0,B=2,C=3,D=5', 1, 'fuehrende Null erlaubt' ] ],
  [ mini_sudoku => { antwort => "1 2 \n2 1" },
    [ "1 2\n2 1", 1, 'ohne Leerraum am Zeilenende' ], [ "1 2 \n2 1", 1, 'gleich' ],
    [ "1 2  \n2 1", 0, 'laenger als die Loesung' ], [ "2 1\n1 2", 0, 'anderes Gitter' ], [ '', 0, 'leer' ] ],
  [ family_relationships => { antwort => 'aunt' }, [ ' Aunt ', 1, 'getrimmt, ohne Gross/klein' ], [ 'uncle', 0, 'anders' ] ],
  [ countdown => { zahlen => [ 2, 3, 4 ], ziel => 20 },
    [ '(2+3)*4', 1, 'ergibt das Ziel' ], [ '4 * (3 + 2)', 1, 'andere Form' ], [ '2+3+4', 0, 'anderes Ergebnis' ],
    [ '(2+3)*4*1', 0, 'Zahl zu viel' ], [ '(2+3)*4 == 20', 0, 'Vergleich nicht erlaubt' ], [ 'max(2,3)*4', 0, 'Funktion nicht erlaubt' ],
    [ '(2+3', 0, 'Klammer offen' ], [ '', 0, 'leer' ] ],
  [ countdown => { zahlen => [ 3, 4 ], ziel => 10 }, [ '3!+4', 1, 'Fakultaet' ], [ '3**2+4', 0, 'Zahl 2 nicht gegeben' ] ],
  [ countdown => { zahlen => [ 2, 3, 6 ], ziel => 1 }, [ '6/(3*2)', 1, 'Bruch' ], [ '6//(3+2)', 1, 'Ganzzahldivision' ], [ '6/(3-3)*2', 0, 'Division durch null' ] ],
  [ jugs => { kruege => [ 3, 5 ], ziel => 4 },
    [ '["fill B","pour B->A","empty A","pour B->A","fill B","pour B->A"]', 1, 'Ziel erreicht' ],
    [ '["fill A","pour A->B","fill A","pour A->B","empty B","pour A->B","fill A","pour A->B"]', 1, 'anderer Weg' ],
    [ '["fill B"]', 0, 'Ziel nicht erreicht' ], [ '["fill C"]', 0, 'unbekannter Krug' ], [ '["pour B-A"]', 0, 'Form X->Y' ],
    [ '["drink A"]', 0, 'unbekannter Zug' ], [ '{"fill B": 1}', 0, 'keine Liste' ], [ 'fill B', 0, 'kein JSON' ] ],
);

for my $c (@checks) {
  my ( $art, $p, @answers ) = @$c;
  for my $a (@answers) {
    my ( $ans, $want, $name ) = @$a;
    my ( $ok, $why ) = $pruefe->( $art, $p, $ans );
    is( $ok, $want, "$art: $name" ) or diag $why;
  }
}

subtest 'pruefe ohne Aufgabe oder Antwort' => sub {
  is_deeply( [ $pruefe->( 'schach', {}, 'e4' ) ], [ 0, 'unbekannte Aufgabe' ], 'unbekannte Aufgabe' );
  is_deeply( [ $pruefe->( 'maze', { antwort => '1' }, undef ) ], [ 0, 'keine Antwort' ], 'keine Antwort' );
  my ( $ok, $why ) = $pruefe->( 'countdown', { zahlen => [ 2 ], ziel => 2 }, '2**99999' );
  ok( !$ok, 'zu grosser Exponent' );
  like( $why, qr/Exponent zu gross/, '… mit Grund' );
};

subtest 'Werkzeug: speichert, ersetzt, verraet nichts' => sub {
  my $state = { aufgabe => { type => 'denken', art => 'countdown', pruefung => { zahlen => [ 2, 3, 4 ], ziel => 20 } } };
  my $before = clone($state);
  my ( $out, $ok ) = sims()->tool_call( $state, denken => antwort_abgeben => { antwort => '2+3+4' } );
  is( $out, 'Antwort gespeichert.', 'neutrale Ausgabe bei falscher Antwort' );
  ok( $ok, 'Aufruf gelingt' );
  is( $state->{aufgabe}{ergebnis}, 'falsch', 'falsch bewertet' );
  is( $state->{aufgabe}{befund}, 'ergibt 9', 'Befund im Zustand' );
  ( $out, $ok ) = sims()->tool_call( $state, denken => antwort_abgeben => { antwort => '(2+3)*4' } );
  is( $out, 'Antwort gespeichert.', 'neutrale Ausgabe bei richtiger Antwort' );
  is_deeply( [ @{ $state->{aufgabe} }{qw( antwort abgaben ergebnis )} ], [ '(2+3)*4', 2, 'richtig' ], 'ersetzt, zaehlt Abgaben' );
  is_deeply(
    [ sort map { join '.', @{ $_->{path} } } diff( $before, $state ) ],
    [qw( aufgabe.abgaben aufgabe.antwort aufgabe.befund aufgabe.ergebnis )],
    'aendert nur die vier Schluessel der Abgabe',
  );
  my $mid = clone($state);
  ( $out, $ok ) = sims()->tool_call( $state, denken => antwort_abgeben => {} );
  ok( !$ok, 'ohne antwort gescheitert' );
  is( $out, 'Fehler: antwort fehlt (Text).', '… mit Meldung' );
  ( $out, $ok ) = sims()->tool_call( $state, denken => antwort_abgeben => { antwort => [ 20 ] } );
  ok( !$ok, 'antwort keine Zeichenkette: gescheitert' );
  is_deeply( $state, $mid, 'gescheiterte Aufrufe aendern nichts' );
  ( $out, $ok ) = $D->new->tool( $state->{aufgabe}, loesung_lesen => {} );
  is_deeply( [ $out, $ok ], [ "Fehler: unbekanntes Werkzeug 'loesung_lesen'", 0 ], 'unbekanntes Werkzeug' );
};

subtest 'Laden prueft art und pruefung' => sub {
  my $w = $D->new;
  ok( !eval { $w->prepare( { type => 'denken', art => 'schach', pruefung => {} } ); 1 }, 'unbekannte Aufgabe' );
  like( $@, qr/unbekannte Aufgabe 'schach'/, '… mit Grund' );
  ok( !eval { $w->prepare( { type => 'denken', art => 'maze', pruefung => '5' } ); 1 }, 'pruefung kein Hash' );
  like( $@, qr/pruefung fehlt \(Hash\)/, '… mit Grund' );
  ok( !eval { $w->prepare( { type => 'denken', art => 'jugs', pruefung => { kruege => [ 3, 5, 8 ] } } ); 1 }, 'Feld fehlt' );
  like( $@, qr/pruefung\.ziel fehlt \(jugs\)/, '… mit Grund' );
  my $state = { aufgabe => { type => 'denken', art => 'maze', pruefung => { antwort => '5' } } };
  my $before = clone($state);
  ok( eval { sims()->prepare($state); 1 }, 'vollstaendig, ueber die Registry' ) or diag $@;
  is_deeply( $state, $before, 'prepare aendert nichts' );
};

done_testing;
