#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Sim::Uebersetzung;
use Holmgang::TestSim qw( sims clone diff );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Uebersetzung als Welt ohne Geraet (ported from cai-platform t/eval_sim_uebersetzung.t).
# Behauptet wird: die Welt normalisiert jede Abgabe (NFC, Anfuehrungszeichen,
# Leerzeichen) und legt Zahlen nach dem Format der Zielsprache, Codes, Platzhalter,
# Fehlendes gegen die Quelle und die Laengenklasse in den Zustand; eine erneute Abgabe
# ersetzt die vorige; die Antworten sind neutral ("angenommen") und verraten nichts
# ueber die Guete; unbekannte Segmente und leere Abgaben scheitern; eine Meldung
# braucht zwei Lesarten; Nachschlagen aendert nur die Laufzeitspur. Die Texte hier
# sind ausgedacht (keine Faelle einer Suite).

my $U = 'Langertha::Holmgang::Sim::Uebersetzung';
my $call = sub { sims()->tool_call( $_[0], uebersetzung => @_[ 1, 2 ] ) };

subtest 'Vertrag' => sub {
  ok( $U->does('Langertha::Holmgang::Role::AnswerWorld'), 'eine Antwortwelt' );
  is( $U->device_type, 'uebersetzung', 'Typ uebersetzung' );
  ok( sims()->is_answer_world('uebersetzung'), 'eingebaut in der Registry' );
  is_deeply(
    sims()->world_tools('uebersetzung'),
    {
      uebersetzung_abgeben => [qw( segment_id text )],
      mehrdeutig_melden    => [qw( segment_id lesarten frage )],
      glossar_nachschlagen => ['begriff'],
    },
    'die drei Werkzeuge mit Pflichtparametern',
  );
  my ( $out, $ok ) = $U->new->tool( {}, 'segment_loeschen', {} );
  ok( !$ok, 'unbekanntes Werkzeug scheitert' );
  is( $out, "Fehler: unbekanntes Werkzeug 'segment_loeschen'", 'mit dem Namen' );
};

subtest 'Normalisierung' => sub {
  my $n = $U->can('normalize');
  is( $n->("„Ahoi“\x{a0} Kai  ‚y‘ "), q{"Ahoi" Kai 'y'}, 'Anführungszeichen, Leerzeichen' );
  is( $n->("«a» ‹b› ″c″ ′d′"), q{"a" 'b' "c" 'd'}, 'Guillemets und Striche' );
  is( $n->("Fa\x{308}hre"), "F\x{e4}hre", 'NFC' );
  is( $n->("3\x{202f}480"), '3 480', 'schmales geschütztes Leerzeichen' );
  is( $n->("a\x{200b}b\x{feff}c"), 'abc', 'Breitenlose fallen weg' );
  is( $n->(undef), '', 'undef ist leer' );
};

subtest 'Zahlen nach Sprache' => sub {
  my $n = $U->can('numbers');
  is_deeply( [ $n->( 'Der Liegeplatz kostet 3.480,25 € für 9 Nächte.', 'de' ) ], [qw( 3480.25 9 )], 'de: Tausenderpunkt, Dezimalkomma' );
  is_deeply( [ $n->( 'The berth costs €3,480.25 for 9 nights.', 'en' ) ], [qw( 3480.25 9 )], 'en: Tausenderkomma, Dezimalpunkt' );
  is_deeply( [ $n->( 'The berth costs 3.480,25 €.', 'en' ) ], ['3.480,25'], 'deutsches Format im Englischen bleibt Text' );
  is_deeply( [ $n->( 'The berth costs 3,480.25 €.', 'de' ) ], ['3,480.25'], 'englisches Format im Deutschen bleibt Text' );
  is_deeply( [ $n->( '7,5 % von 8 Knoten', 'de' ) ], [qw( 7.5 8 )], 'Dezimalkomma ohne Tausender' );
  is_deeply( [ $n->( 'Firmware 2.7.1 am 5. Mai 2031 um 06:45', 'de' ) ], [qw( 2.7.1 5 2031 6 45 )], 'Version bleibt Text, Uhrzeit zerfällt' );
  is_deeply( [ $n->( 'Run `sleep 45` with {schiffe} and %2$s on IPv6', 'en' ) ], [], 'nichts aus Code, Platzhalter oder Wort' );
  is_deeply( [ $n->( 'ab 07.09.', 'de' ) ], ['07.09'], 'Datum mit Punkten ist keine Zahl' );
  is_deeply( [ $n->( 'Pier 007 and 4.10', 'en' ) ], [qw( 7 4.1 )], 'führende und nachgestellte Nullen fallen' );
  is_deeply( [ $n->( '0,0 und 12', undef ) ], [qw( 0 12 )], 'ohne Sprache deutsch; null bleibt null' );
};

subtest 'Codes und Platzhalter' => sub {
  is_deeply( [ $U->can('codes')->('Run `ferryctl status` then `ferryctl dock --pier 3`.') ], [ 'ferryctl status', 'ferryctl dock --pier 3' ], 'Backticks' );
  is_deeply(
    [ $U->can('placeholders')->('{schiffe} Fähren am <i>{hafen}</i>, %s, %2$d, {{ kapitaen }}, <br/>; `{nein}`') ],
    [ '{schiffe}', '<i>', '{hafen}', '</i>', '%s', '%2$d', '{{ kapitaen }}', '<br/>' ],
    'Platzhalter und Tags ausserhalb von Code',
  );
};

subtest 'Länge' => sub {
  my $l = $U->can('length_class');
  is( $l->( 'Ankern', 'Anchor' ), 'ok', 'gleich lang' );
  is( $l->( 'Schleuse', 'Go' ), 'ok', 'kurz, aber im Zuschlag' );
  is( $l->( 'Halt', 'Schleuse öffnen' ), 'ok', 'kurze Quelle, längere Übersetzung' );
  is( $l->( 'x' x 100, 'y' x 44 ), 'kurz', 'unter der Hälfte minus fünf' );
  is( $l->( 'x' x 100, 'y' x 45 ), 'ok', 'genau an der unteren Grenze' );
  is( $l->( 'x' x 40, 'y' x 91 ), 'lang', 'über dem Doppelten plus zehn' );
  is( $l->( 'x' x 40, 'y' x 90 ), 'ok', 'genau an der oberen Grenze' );
};

my $start = {
  auftrag => {
    type      => 'uebersetzung',
    quelle    => 'de',
    ziel      => 'en',
    segmente  => { s1 => 'Der Liegeplatz kostet 3.480,25 € für 9 Nächte.', s2 => 'Prüfen Sie `ferryctl status` für {hafen}.' },
    glossar   => [ { de => 'Gezeitentafel', en => 'tide table' }, { de => 'Lotse', en => 'pilot' } ],
    abgaben   => {},
    meldungen => {},
  },
};

subtest 'Abgeben' => sub {
  my $st = clone($start);
  my ( $out, $ok ) = $call->( $st, uebersetzung_abgeben => { segment_id => 's1', text => 'The berth costs 3.480,25 € for 9 nights.' } );
  ok( $ok, 'angenommen' );
  is( $out, 'Segment s1: angenommen.', 'neutrale Antwort, auch bei falschem Format' );
  my $a = $st->{auftrag}{abgaben}{s1};
  is_deeply( $a->{zahlen}, [ '3.480,25', '9' ], 'Zahlen der Abgabe' );
  is_deeply( $a->{fehlende_zahlen}, ['3480.25'], 'Betrag fehlt im englischen Format' );

  ( $out, $ok ) = $call->( $st, uebersetzung_abgeben => { segment_id => 's1', text => "The \x{201C}berth\x{201D} costs \x{20ac}3,480.25 for 9\x{a0}nights." } );
  $a = $st->{auftrag}{abgaben}{s1};
  is( $out, 'Segment s1: angenommen.', 'dieselbe Antwort' );
  is_deeply( $a->{fehlende_zahlen}, [], 'erneute Abgabe ersetzt: nichts fehlt' );
  is( $a->{text}, "The \x{201C}berth\x{201D} costs \x{20ac}3,480.25 for 9\x{a0}nights.", 'text wie abgegeben' );
  is( $a->{norm}, "The \"berth\" costs \x{20ac}3,480.25 for 9 nights.", 'norm' );
  is( $a->{laenge}, 'ok', 'Länge' );
  is_deeply( [ @{$a}{qw( codes platzhalter fehlende_codes fehlende_platzhalter )} ], [ [], [], [], [] ], 'keine Codes, keine Platzhalter' );

  ( undef, $ok ) = $call->( $st, uebersetzung_abgeben => { segment_id => ' [s2] ', text => 'Check ferryctl status for {hafen}.' } );
  ok( $ok, 'Kennung in Klammern angenommen' );
  is_deeply( $st->{auftrag}{abgaben}{s2}{fehlende_codes}, ['ferryctl status'], 'Code ohne Backticks fehlt' );
  is_deeply( $st->{auftrag}{abgaben}{s2}{fehlende_platzhalter}, [], 'Platzhalter da' );
  ( undef, $ok ) = $call->( $st, uebersetzung_abgeben => { segment_id => 's2', text => 'Check `ferryctl status` for {port} {port}.' } );
  is_deeply( $st->{auftrag}{abgaben}{s2}{fehlende_platzhalter}, ['{hafen}'], 'übersetzter Platzhalter fehlt' );
  is_deeply( $st->{auftrag}{abgaben}{s2}{platzhalter}, [ '{port}', '{port}' ], 'mit Vielfachheit' );

  ( $out, $ok ) = $call->( $st, uebersetzung_abgeben => { segment_id => 's9', text => 'x' } );
  ok( !$ok, 'unbekanntes Segment scheitert' );
  is( $out, "Fehler: Segment 's9' gibt es in diesem Auftrag nicht (s1, s2).", 'nennt die Segmente' );
  ( undef, $ok ) = $call->( $st, uebersetzung_abgeben => { segment_id => 's1', text => " \x{a0}\x{200b}" } );
  ok( !$ok, 'leere Abgabe scheitert' );
  is( $st->{auftrag}{abgaben}{s1}{norm}, $a->{norm}, 'und ändert nichts' );
  ( $out, $ok ) = $call->( $st, uebersetzung_abgeben => { segment_id => 's1', text => ['x'] } );
  is_deeply( [ $out, $ok ], [ 'Fehler: text ist leer.', 0 ], 'Liste statt Text scheitert' );
};

subtest 'Quelle englisch' => sub {
  my $st = clone($start);
  $st->{auftrag}{quelle} = 'en';
  $st->{auftrag}{ziel}   = 'de';
  $st->{auftrag}{segmente}{s3} = 'The pilot boards at 1,200.5 m.';
  $call->( $st, uebersetzung_abgeben => { segment_id => 's3', text => 'Der Lotse steigt bei 1.200,5 m zu.' } );
  is_deeply( $st->{auftrag}{abgaben}{s3}{fehlende_zahlen}, [], 'Zahlen je nach Sprache gelesen' );
  is_deeply( $st->{auftrag}{abgaben}{s3}{zahlen}, ['1200.5'], 'als Wert' );
};

subtest 'Melden und Nachschlagen' => sub {
  my $st = clone($start);
  my ( $out, $ok ) = $call->( $st, mehrdeutig_melden => { segment_id => 's1', lesarten => [ 'eine', " \x{a0}" ], frage => '?' } );
  ok( !$ok, 'eine Lesart reicht nicht (leere zählt nicht)' );
  is( $out, 'Fehler: mindestens zwei Lesarten angeben.', 'Meldung' );
  ( undef, $ok ) = $call->( $st, mehrdeutig_melden => { segment_id => 's1', lesarten => 'a, b', frage => '?' } );
  ok( !$ok, 'Lesarten als Text statt Liste scheitern' );
  ( $out, $ok ) = $call->( $st, mehrdeutig_melden => { segment_id => 's2', lesarten => [ 'Sie (Anrede)', "sie\x{a0} (Plural) " ], frage => '„Wer“ ist gemeint?' } );
  ok( $ok, 'Meldung angenommen' );
  is( $out, 'Meldung zu Segment s2: angenommen.', 'neutral' );
  is_deeply( $st->{auftrag}{meldungen}{s2}, { lesarten => [ 'Sie (Anrede)', 'sie (Plural)' ], frage => '"Wer" ist gemeint?' }, 'normalisiert im Zustand' );

  ( $out, $ok ) = $call->( $st, glossar_nachschlagen => { begriff => 'Gezeiten' } );
  ok( $ok, 'gefunden' );
  is( $out, 'de: Gezeitentafel | en: tide table', 'Eintrag' );
  ( $out, $ok ) = $call->( $st, glossar_nachschlagen => { begriff => 'PILOT' } );
  is( $out, 'de: Lotse | en: pilot', 'auch englisch, ohne Groß/Klein' );
  ( $out, $ok ) = $call->( $st, glossar_nachschlagen => { begriff => 't' } );
  is( $out, "de: Gezeitentafel | en: tide table\nde: Lotse | en: pilot", 'mehrere Treffer in Glossar-Reihenfolge' );
  ( $out, $ok ) = $call->( $st, glossar_nachschlagen => { begriff => ' Schleuse ' } );
  ok( $ok, 'kein Eintrag ist kein Fehler' );
  is( $out, 'Kein Eintrag für "schleuse".', 'neutral, normalisiert' );
  ( $out, $ok ) = $call->( $st, glossar_nachschlagen => { begriff => "\x{a0}" } );
  is_deeply( [ $out, $ok ], [ 'Fehler: begriff ist leer.', 0 ], 'leerer Begriff scheitert' );
  is_deeply( $st->{auftrag}{_nachschlagen}, [qw( gezeiten pilot t schleuse )], 'Laufzeitspur' );

  my @p = map { join '.', @{ $_->{path} } } diff( $start, $st );
  ok( @p && !grep( { !/\Aauftrag\.meldungen\.s2\b/ } @p ), 'Nachschlagen ist nur Laufzeitspur' ) or diag explain \@p;
};

done_testing;
