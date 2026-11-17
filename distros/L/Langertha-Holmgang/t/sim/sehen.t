#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();
use JSON::PP ();
use YAML::XS ();

use Langertha::Holmgang::Sim::Sehen;
use Langertha::Holmgang::Expectation qw( condition );
use Holmgang::TestSim qw( sims clone );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Sehen als Antwortwelt ohne Geraet (k27, neu, kein Vorbild in cai-platform).
# Behauptet wird: jedes Werkzeug legt seine Abgabe roh und normalisiert ab; ein
# erneuter Aufruf ersetzt die fruehere Abgabe desselben Werkzeugs ganz, ein
# abgelehnter Aufruf aendert nichts; Text wird NFC, casefold, ss/Umlaute
# transkribiert, Leerraum, Striche und Anfuehrungszeichen vereinheitlicht;
# Daten werden ISO, mehrdeutige Daten und Betraege neutral abgelehnt; Betraege
# stehen in Cent, IBAN kompakt gross; Regeln am Endzustand greifen auf norm.
# Die Daten hier sind ausgedacht (keine Faelle einer Suite).

my $S = 'Langertha::Holmgang::Sim::Sehen';
my %f = map { ( $_ => $S->can($_) ) } qw( norm_text norm_date norm_amount norm_number norm_iban norm_currency );

subtest 'Vertrag' => sub {
  ok( $S->does('Langertha::Holmgang::Role::AnswerWorld'), 'eine Antwortwelt' );
  is( $S->device_type, 'sehen', 'Typ sehen' );
  ok( sims()->is_answer_world('sehen'), 'eingebaut in der Registry' );
  is_deeply(
    [ sort keys %{ sims()->world_tools('sehen') } ],
    [qw( ablauf_abgeben befund_abgeben bild_melden felder_abgeben graph_abgeben tabelle_abgeben werte_abgeben )],
    'die sieben Werkzeuge',
  );
  is_deeply( sims()->world_tools('sehen')->{graph_abgeben}, [qw( gerichtet knoten kanten )], 'Pflichtparameter graph_abgeben' );
  is_deeply(
    sims()->world_tools('sehen')->{felder_abgeben},
    [qw( belegart nummer datum lieferdatum betrag_brutto betrag_netto waehrung iban positionen )],
    'Pflichtparameter felder_abgeben',
  );
};

subtest 'Text' => sub {
  my $t = $f{norm_text};
  is( $t->('Straße'), 'strasse', 'ß wird ss' );
  is( $t->('STRASSE'), 'strasse', 'casefold' );
  is( $t->('STRAẞE'), 'strasse', 'grosses ẞ' );
  is( $t->('Müller'), $t->('Mueller'), 'ü gleich ue' );
  is( $t->('ÄÖÜ'), 'aeoeue', 'grosse Umlaute' );
  is( $t->("Mu\x{0308}ller"), 'mueller', 'zerlegtes ü (NFD) wird NFC, dann ue' );
  is( $t->("  a \t\n b\x{00A0}c  "), 'a b c', 'Leerraum, auch NBSP, zusammengefasst und getrimmt' );
  is( $t->("A\x{2013}B\x{2014}C\x{2212}D\x{2011}E"), 'a-b-c-d-e', 'Striche und Minus werden -' );
  is( $t->("„Süd“ «x» ‚y‘ it’s"), q{"sued" "x" 'y' it's}, 'Anfuehrungszeichen und Apostroph' );
  is( $t->("Trenn\x{00AD}strich\x{200B}"), 'trennstrich', 'weiches Trennzeichen und Nullbreite entfallen' );
  is( $t->(42), '42', 'Zahl als Text' );
  is( $t->(undef), undef, 'undef' );
  is( $t->( [] ), undef, 'Referenz' );
};

subtest 'Datum' => sub {
  my $d = sub { [ $f{norm_date}->(@_) ] };
  is_deeply( $d->('2024-04-03'),      ['2024-04-03'], 'ISO' );
  is_deeply( $d->('2024/4/3'),        ['2024-04-03'], 'Jahr zuerst, Schraegstrich' );
  is_deeply( $d->('3.4.2024'),        ['2024-04-03'], 'deutsch mit Punkten, Tag zuerst' );
  is_deeply( $d->('03. 04. 2024'),    ['2024-04-03'], '... mit Leerzeichen' );
  is_deeply( $d->('13/04/2024'),      ['2024-04-13'], 'Schraegstrich, Tag ueber 12: eindeutig' );
  is_deeply( $d->('04/13/2024'),      ['2024-04-13'], 'Schraegstrich, Monat zuerst: eindeutig' );
  is_deeply( $d->('04-04-2024'),      ['2024-04-04'], 'beide gleich: eindeutig' );
  is_deeply( $d->('3. April 2024'),   ['2024-04-03'], 'deutscher Monatsname' );
  is_deeply( $d->('3. März 2024'),    ['2024-03-03'], 'März' );
  is_deeply( $d->('3. Jänner 2024'),  ['2024-01-03'], 'Jänner' );
  is_deeply( $d->('April 3rd, 2024'), ['2024-04-03'], 'englisch, Monat zuerst' );
  is_deeply( $d->('3 Apr 2024'),      ['2024-04-03'], 'Kurzform' );
  is_deeply( $d->('29.02.2024'),      ['2024-02-29'], 'Schalttag' );
  is_deeply( $d->('03/04/2024'),      [ undef, 'mehrdeutig' ], 'Tag/Monat offen: mehrdeutig' );
  is_deeply( $d->('03-04-2024'),      [ undef, 'mehrdeutig' ], '... auch mit Bindestrich' );
  is_deeply( $d->('03.04.24'),        [ undef, 'mehrdeutig' ], 'zweistelliges Jahr: mehrdeutig' );
  is_deeply( $d->('3. April 24'),     [ undef, 'mehrdeutig' ], '... auch mit Monatsname' );
  is_deeply( $d->('30.02.2024'),      [ undef, 'ungültig' ],   '30. Februar' );
  is_deeply( $d->('29.02.2023'),      [ undef, 'ungültig' ],   'kein Schaltjahr' );
  is_deeply( $d->('13/14/2024'),      [ undef, 'ungültig' ],   'kein Monat moeglich' );
  is_deeply( $d->('Anfang April'),    [ undef, 'nicht lesbar' ], 'kein Datum' );
  is_deeply( $d->('01.-05.03.2024'),  [ undef, 'nicht lesbar' ], 'Zeitraum' );
};

subtest 'Betrag' => sub {
  my $a = sub { [ $f{norm_amount}->(@_) ] };
  is_deeply( $a->(12.5),            [1250],   'Zahl' );
  is_deeply( $a->(119),             [11900],  'ganze Zahl' );
  is_deeply( $a->('12,50'),         [1250],   'Komma' );
  is_deeply( $a->('12.5'),          [1250],   'Punkt, eine Stelle' );
  is_deeply( $a->('1.234,56'),      [123456], 'deutsch mit Tausenderpunkt' );
  is_deeply( $a->('1,234.56'),      [123456], 'englisch mit Tausenderkomma' );
  is_deeply( $a->("1\x{00A0}234,56 €"), [123456], 'Leerraum als Tausender, Euro dahinter' );
  is_deeply( $a->('EUR 1.234.567'), [123456700], 'Code davor, mehrere Gruppen' );
  is_deeply( $a->('-12,50'),        [-1250],  'negativ (Gutschrift)' );
  is_deeply( $a->("\x{2212}3"),     [-300],   'Minuszeichen' );
  is_deeply( $a->('0,05'),          [5],      'fuenf Cent' );
  is_deeply( $a->('1.234'),         [ undef, 'mehrdeutig' ], 'Punkt mit drei Stellen: mehrdeutig' );
  is_deeply( $a->('1,234'),         [ undef, 'mehrdeutig' ], 'Komma mit drei Stellen: mehrdeutig' );
  is_deeply( $a->('12,3456'),       [ undef, 'nicht lesbar' ], 'mehr als zwei Nachkommastellen' );
  is_deeply( $a->('1.234.56'),      [ undef, 'nicht lesbar' ], 'Trenner wild' );
  is_deeply( $a->('1,234,56'),      [ undef, 'nicht lesbar' ], 'Gruppe und Dezimal gleich' );
  is_deeply( $a->('zwölf'),         [ undef, 'nicht lesbar' ], 'Wort' );
  is( $f{norm_number}->('1,5'), 1.5, 'norm_number mit Komma' );
  is( $f{norm_number}->('1.234,5'), undef, 'norm_number ohne Tausender' );
  is( $f{norm_iban}->(" de89 3704\x{00A0}0044 0532 0130 00 "), 'DE89370400440532013000', 'IBAN kompakt gross' );
  is( $f{norm_iban}->('  '), undef, 'leere IBAN' );
  is( $f{norm_currency}->(' eur '), 'EUR', 'Waehrung gross' );
  is( $f{norm_currency}->('€'), 'EUR', 'Eurozeichen' );
};

my $state;
sub fresh { $state = { sehen => { type => 'sehen' } } }
sub t { my ( $name, %a ) = @_; return sims()->tool_call( $state, sehen => $name, \%a ) }
sub rule { my ( $path, %exp ) = @_; return ( condition( $state, { path => $path, %exp } ) )[0] }

subtest 'graph_abgeben' => sub {
  fresh();
  my ( $o, $ok ) = t(
    graph_abgeben => gerichtet => JSON::MaybeXS::true(),
    knoten => [ 'Start', 'Prüfung', 'Ende', ' start ' ],
    kanten => [
      { von => 'start', nach => 'Pruefung' },
      { von => 'Prüfung', nach => 'Ende', text => '„OK“' },
      { von => 'Prüfung', nach => 'Start', text => 'Fehler' },
    ],
  );
  ok( $ok, 'angenommen' );
  is( $o, 'Graph abgegeben: gerichtet, 3 Knoten, 3 Kanten.', '... Ausgabe ohne Wertung' );
  is_deeply(
    $state->{sehen}{graph}{norm},
    {
      gerichtet      => 1,
      knoten         => [qw( ende pruefung start )],
      kanten         => [ 'pruefung -> ende', 'pruefung -> start', 'start -> pruefung' ],
      beschriftungen => [ 'pruefung -> ende: "ok"', 'pruefung -> start: fehler' ],
    },
    'normalisiert',
  );
  is( $state->{sehen}{graph}{roh}{knoten}[1], 'Prüfung', 'roh bleibt wie gesendet' );
  ok( rule( 'sehen.graph.norm.kanten', contains => ['start -> pruefung'] ), 'Regel contains auf kanten' );
  ok( rule( 'sehen.graph.norm.gerichtet', equals => JSON::MaybeXS::true() ), 'Regel equals true auf gerichtet' );

  ( $o, $ok ) = t( graph_abgeben => gerichtet => 'nein', knoten => [qw( B A )], kanten => [ { von => 'B', nach => 'A' } ] );
  ok( $ok, 'ungerichtet' );
  is( $o, 'Graph abgegeben: ungerichtet, 2 Knoten, 1 Kanten. Die frühere Abgabe ist ersetzt.', '... ersetzt die erste' );
  is_deeply( $state->{sehen}{graph}{norm}{kanten}, ['a -- b'], 'Enden sortiert' );
  is_deeply( $state->{sehen}{graph}{norm}{beschriftungen}, [], 'keine Reste der ersten Abgabe' );
  ok( !rule( 'sehen.graph.norm.kanten', contains => ['start -> pruefung'] ), 'alte Kante nicht mehr da' );

  my $before = clone($state);
  ( $o, $ok ) = t( graph_abgeben => gerichtet => 1, knoten => ['A'], kanten => [ { von => 'A', nach => 'C' } ] );
  is_deeply( [ $o, $ok ], [ "Fehler: kanten[0].nach nennt 'C', das nicht in knoten steht.", 0 ], 'unbekannter Knoten' );
  is_deeply( $state, $before, '... Zustand unveraendert' );
  ( $o, $ok ) = t( graph_abgeben => gerichtet => 'vielleicht', knoten => [], kanten => [] );
  is_deeply( [ $o, $ok ], [ 'Fehler: gerichtet muss true oder false sein.', 0 ], 'gerichtet kein Wahrheitswert' );
  ( $o, $ok ) = t( graph_abgeben => gerichtet => 1, knoten => [ 'A', '' ], kanten => [] );
  is_deeply( [ $o, $ok ], [ 'Fehler: knoten[1] muss ein nicht leerer Text sein.', 0 ], 'leerer Knoten' );
  is_deeply( $state, $before, 'nach allen Fehlern unveraendert' );
};

subtest 'graph_abgeben: gerichtet als Wahrheitswert jeder Herkunft' => sub {
  # Ein false aus YAML (Kernboolean, kein Ref) oder JSON (Objekt) gilt wie
  # die Textformen; die Schemapruefung nimmt alle Wahrheitswerte an.
  my %yaml = %{ YAML::XS::Load("f: false\nt: true\n") };
  my @cases = (
    [ 'YAML false',      $yaml{f},                 0 ],
    [ 'YAML true',       $yaml{t},                 1 ],
    [ 'JSON false',      JSON::MaybeXS::false(),   0 ],
    [ 'JSON::PP false',  $JSON::PP::false,         0 ],
    [ 'Perl !!0',        !!0,                      0 ],
    [ '0',               0,                        0 ],
    [ '"false"',         'false',                  0 ],
    [ '"nein"',          'nein',                   0 ],
    [ '"no"',            'no',                     0 ],
    [ '"true"',          'true',                   1 ],
    [ '"ja"',            'ja',                     1 ],
  );
  for my $c (@cases) {
    my ( $label, $v, $want ) = @$c;
    fresh();
    my ( $o, $ok ) = t( graph_abgeben => gerichtet => $v, knoten => [qw( A B )], kanten => [ { von => 'A', nach => 'B' } ] );
    ok( $ok, "$label angenommen" ) or diag $o;
    is( $state->{sehen}{graph}{norm}{gerichtet}, $want, "... $label ergibt $want" );
    is_deeply( $state->{sehen}{graph}{norm}{kanten}, [ $want ? 'a -> b' : 'a -- b' ], "... $label Kantenform" );
  }
  fresh();
  my ( $o, $ok ) = t( graph_abgeben => gerichtet => '', knoten => [], kanten => [] );
  is_deeply( [ $o, $ok ], [ 'Fehler: gerichtet muss true oder false sein.', 0 ], 'leerer Text bleibt kein Wahrheitswert' );
};

subtest 'ablauf_abgeben' => sub {
  fresh();
  my ( $o, $ok ) = t(
    ablauf_abgeben => teilnehmer => [ 'Client', 'Server', 'client' ],
    nachrichten => [
      { von => 'Client', an => 'Server', text => 'GET /index' },
      { von => 'Server', an => 'Client', text => '200  OK' },
      { von => 'Client', an => 'Client', text => '' },
    ],
  );
  ok( $ok, 'angenommen' );
  is( $o, 'Ablauf abgegeben: 2 Teilnehmer, 3 Nachrichten.', '... Ausgabe' );
  is_deeply( $state->{sehen}{ablauf}{norm}{teilnehmer}, [qw( client server )], 'Reihenfolge wie gegeben, doppelt entfernt' );
  is_deeply(
    $state->{sehen}{ablauf}{norm}{nachrichten},
    [ 'client -> server: get /index', 'server -> client: 200 ok', 'client -> client' ],
    'Nachrichten in Reihenfolge',
  );
  ok( rule( 'sehen.ablauf.norm.nachrichten', before => [ '^client -> server', '^server -> client' ] ), 'Regel before' );
  ( $o, $ok ) = t( ablauf_abgeben => teilnehmer => ['A'], nachrichten => [ { von => 'A', an => 'B', text => 'x' } ] );
  is_deeply( [ $o, $ok ], [ "Fehler: nachrichten[0].an nennt 'B', der nicht in teilnehmer steht.", 0 ], 'unbekannter Teilnehmer' );
  is( scalar @{ $state->{sehen}{ablauf}{norm}{nachrichten} }, 3, '... alte Abgabe steht' );
};

subtest 'felder_abgeben' => sub {
  fresh();
  my %rechnung = (
    belegart      => 'Rechnung',
    nummer        => 'RE–2024/0815',
    datum         => '3.4.2024',
    lieferdatum   => undef,
    betrag_brutto => '1.190,00 €',
    betrag_netto  => 1000,
    waehrung      => '€',
    iban          => 'de89 3704 0044 0532 0130 00',
    positionen    => [ { text => 'Beratung  Süd', menge => '2,5', betrag => '400,00' }, 'Pauschale' ],
  );
  my ( $o, $ok ) = t( felder_abgeben => %rechnung );
  ok( $ok, 'angenommen' );
  is( $o, 'Felder abgegeben: 2 Positionen.', '... Ausgabe' );
  is_deeply(
    $state->{sehen}{felder}{norm},
    {
      belegart      => 'rechnung',
      nummer        => 're-2024/0815',
      datum         => '2024-04-03',
      lieferdatum   => undef,
      betrag_brutto => 119000,
      betrag_netto  => 100000,
      waehrung      => 'EUR',
      iban          => 'DE89370400440532013000',
      positionen    => [ { text => 'beratung sued', menge => 2.5, betrag => 40000 }, { text => 'pauschale' } ],
    },
    'normalisiert',
  );
  is( $state->{sehen}{felder}{roh}{betrag_brutto}, '1.190,00 €', 'roh bleibt' );
  ok( rule( 'sehen.felder.norm.betrag_brutto', equals => 119000 ), 'Regel equals auf Cent' );
  ok( rule( 'sehen.felder.norm.datum', equals => '2024-04-03' ), 'Regel equals auf ISO-Datum' );
  ok( rule( 'sehen.felder.norm.lieferdatum', absent => 1 ), 'Regel absent auf null' );
  ok( rule( 'sehen.felder.norm.positionen', any => { text => '^beratung', betrag => { equals => 40000 } } ), 'Regel any auf Position' );

  my $before = clone($state);
  ( $o, $ok ) = t( felder_abgeben => %rechnung, datum => '03/04/2024' );
  is_deeply( [ $o, $ok ], [ "Fehler: datum '03/04/2024' ist mehrdeutig — bitte als JJJJ-MM-TT angeben.", 0 ], 'mehrdeutiges Datum neutral abgelehnt' );
  ( $o, $ok ) = t( felder_abgeben => %rechnung, lieferdatum => '31.04.2024' );
  is_deeply( [ $o, $ok ], [ "Fehler: lieferdatum '31.04.2024' ist kein gültiges Datum.", 0 ], 'unmoegliches Datum' );
  ( $o, $ok ) = t( felder_abgeben => %rechnung, betrag_netto => '1.000' );
  is_deeply( [ $o, $ok ], [ "Fehler: betrag_netto '1.000' ist mehrdeutig — bitte als Zahl angeben, z. B. 1234.56.", 0 ], 'mehrdeutiger Betrag' );
  ( $o, $ok ) = t( felder_abgeben => %rechnung, positionen => [ { text => 'x', betrag => 'viel' } ] );
  is_deeply( [ $o, $ok ], [ "Fehler: positionen[0].betrag 'viel' ist nicht lesbar — bitte als Zahl angeben, z. B. 1234.56.", 0 ], 'Positionsbetrag' );
  ( $o, $ok ) = t( felder_abgeben => %rechnung, iban => [] );
  is_deeply( [ $o, $ok ], [ 'Fehler: iban muss ein Text oder null sein.', 0 ], 'IBAN keine Liste' );
  is_deeply( $state, $before, 'abgelehnte Aufrufe aendern nichts' );

  ( $o, $ok ) = t( felder_abgeben => belegart => 'Quittung', datum => '2024-05-01', betrag_brutto => 9.5, iban => undef, positionen => [] );
  ok( $ok, 'zweite Abgabe, fehlende Felder als null' );
  like( $o, qr/Die frühere Abgabe ist ersetzt\.\z/, '... ersetzt' );
  is_deeply(
    $state->{sehen}{felder}{norm},
    {
      belegart => 'quittung', nummer => undef, datum => '2024-05-01', lieferdatum => undef,
      betrag_brutto => 950, betrag_netto => undef, waehrung => undef, iban => undef, positionen => [],
    },
    '... nichts von der ersten bleibt',
  );
  ok( !exists $state->{sehen}{felder}{roh}{nummer}, 'roh ist die zweite Abgabe' );
};

subtest 'tabelle_abgeben' => sub {
  fresh();
  my ( $o, $ok ) = t( tabelle_abgeben => kopf => [ 'Stadt', 'Einwohner' ], zeilen => [ [ 'München', '1.512.491' ], [ 'Köln', undef ] ] );
  ok( $ok, 'angenommen' );
  is( $o, 'Tabelle abgegeben: 2 Spalten, 2 Zeilen.', '... Ausgabe' );
  is_deeply(
    $state->{sehen}{tabelle}{norm},
    {
      kopf        => [qw( stadt einwohner )],
      zeilen      => [ [ 'muenchen', '1.512.491' ], [ 'koeln', '' ] ],
      zeilen_text => [ 'muenchen | 1.512.491', 'koeln | ' ],
    },
    'normalisiert, null als leere Zelle',
  );
  ok( rule( 'sehen.tabelle.norm.zeilen_text', contains => ['muenchen | 1.512.491'] ), 'Regel contains auf Zeile' );
  ( $o, $ok ) = t( tabelle_abgeben => kopf => ['a'], zeilen => ['a'] );
  is_deeply( [ $o, $ok ], [ 'Fehler: zeilen[0] muss eine Liste von Texten sein.', 0 ], 'Zeile keine Liste' );
};

subtest 'werte_abgeben' => sub {
  fresh();
  my ( $o, $ok ) = t(
    werte_abgeben => reihen => [
      { name => 'Umsatz', punkte => [ { x => 2023, y => '12,5' }, { x => '2024', y => 14 } ] },
      { name => 'Kosten', punkte => [ { x => 'Jan', y => -3 } ] },
    ],
  );
  ok( $ok, 'angenommen' );
  is( $o, 'Werte abgegeben: 2 Reihen, 3 Punkte.', '... Ausgabe' );
  is_deeply( $state->{sehen}{werte}{norm}, { reihen => { umsatz => { 2023 => 12.5, 2024 => 14 }, kosten => { jan => -3 } } }, 'normalisiert' );
  ok( rule( 'sehen.werte.norm.reihen.umsatz.2023', equals => 12.5 ), 'Regel auf einen Punkt' );
  ( $o, $ok ) = t( werte_abgeben => reihen => [ { name => 'a', punkte => [] }, { name => 'A', punkte => [] } ] );
  is_deeply( [ $o, $ok ], [ "Fehler: reihen[1].name 'A' kommt doppelt vor.", 0 ], 'doppelte Reihe' );
  ( $o, $ok ) = t( werte_abgeben => reihen => [ { name => 'a', punkte => [ { x => 1, y => 'hoch' } ] } ] );
  is_deeply( [ $o, $ok ], [ 'Fehler: reihen[0].punkte[0].y muss eine Zahl sein.', 0 ], 'y keine Zahl' );
  ( $o, $ok ) = t( werte_abgeben => reihen => [ { name => 'a', punkte => [ { x => '1,0', y => 1 }, { x => 1, y => 2 } ] } ] );
  is_deeply( [ $o, $ok ], [ "Fehler: reihen[0].punkte[1].x '1' kommt doppelt vor.", 0 ], 'x numerisch gleich' );
};

subtest 'befund_abgeben und bild_melden' => sub {
  fresh();
  my ( $o, $ok ) = t( befund_abgeben => befehl => 'Make  install', fehlercode => 2, datei => 'src/Main.c', zeile => '042' );
  ok( $ok, 'angenommen' );
  is( $o, 'Befund abgegeben.', '... Ausgabe' );
  is_deeply( $state->{sehen}{befund}{norm}, { befehl => 'make install', fehlercode => '2', datei => 'src/main.c', zeile => 42 }, 'normalisiert' );
  ( $o, $ok ) = t( befund_abgeben => befehl => 'x', fehlercode => undef, datei => undef, zeile => 0 );
  is_deeply( [ $o, $ok ], [ 'Fehler: zeile muss eine ganze Zahl ab 1 oder null sein.', 0 ], 'Zeile 0' );
  ( $o, $ok ) = t( befund_abgeben => befehl => 'x', fehlercode => undef, datei => undef, zeile => undef );
  ok( $ok, 'nulls angenommen' );
  is_deeply( $state->{sehen}{befund}{norm}, { befehl => 'x', fehlercode => undef, datei => undef, zeile => undef }, '... ersetzt' );

  ( $o, $ok ) = t( bild_melden => grund => 'Teilweise unlesbar', notiz => ' unten  abgeschnitten ' );
  ok( $ok, 'Meldung' );
  is( $o, 'Meldung abgegeben: teilweise_unlesbar.', '... Ausgabe' );
  is_deeply( $state->{sehen}{meldung}{norm}, { grund => 'teilweise_unlesbar', notiz => 'unten abgeschnitten' }, 'normalisiert' );
  ok( $state->{sehen}{befund}, 'Befund bleibt neben der Meldung stehen' );
  ( $o, $ok ) = t( bild_melden => grund => 'kaputt', notiz => '' );
  is_deeply( [ $o, $ok ], [ 'Fehler: grund muss kein_diagramm, unlesbar oder teilweise_unlesbar sein.', 0 ], 'unbekannter Grund' );
  is( $state->{sehen}{meldung}{norm}{grund}, 'teilweise_unlesbar', '... Meldung bleibt' );
};

subtest 'eine Suite auf der Welt laedt, Lint bewertet am Endzustand' => sub {
  require Holmgang::SuiteDir;
  my $head = <<'Y';
format: 2
id: __ID__
version: 1
title: Sehen
tools:
  - name: felder_abgeben
    description: Hands in the fields of a receipt.
    simulator: sehen
    parameters:
      type: object
      required: [belegart, nummer, datum, lieferdatum, betrag_brutto, betrag_netto, waehrung, iban, positionen]
      properties:
        belegart: { type: string }
        nummer: { type: string }
        datum: { type: string }
        lieferdatum: { description: date or null }
        betrag_brutto: { description: amount }
        betrag_netto: { description: amount or null }
        waehrung: { type: string }
        iban: { description: IBAN or null }
        positionen: { type: array }
  - name: bild_melden
    description: Reports that the image cannot be read as asked.
    simulator: sehen
    parameters: { type: object, required: [grund, notiz], properties: { grund: { type: string }, notiz: { type: string } } }
Y
  my $case = <<'Y';
id: c1
title: A made-up receipt
messages: [ { role: user, content: "Hand in the fields of the receipt." } ]
state: { sehen: { type: sehen } }
rules:
  - { title: date, state: sehen.felder.norm.datum, equals: "2031-02-01" }
  - { title: gross, state: sehen.felder.norm.betrag_brutto, equals: 2380 }
  - { title: iban, state: sehen.felder.norm.iban, equals: "XX00TEST0000" }
solution:
  - { tool: felder_abgeben, args: { belegart: Quittung, nummer: "7", datum: "1.2.2031", lieferdatum: null, betrag_brutto: "23,80 €", betrag_netto: null, waehrung: EUR, iban: "xx00 test 0000", positionen: [] } }
alternatives:
  - title: ISO and a number, after a first try
    calls:
      - { tool: felder_abgeben, args: { belegart: Quittung, nummer: "7", datum: "2031-02-02", lieferdatum: null, betrag_brutto: 1, betrag_netto: null, waehrung: EUR, iban: null, positionen: [] } }
      - { tool: felder_abgeben, args: { belegart: quittung, nummer: "7", datum: "2031-02-01", lieferdatum: null, betrag_brutto: 23.8, betrag_netto: null, waehrung: eur, iban: XX00TEST0000, positionen: [] } }
wrong_solutions:
  - title: ambiguous date only
    calls:
      - { tool: felder_abgeben, args: { belegart: Quittung, nummer: "7", datum: "01/02/2031", lieferdatum: null, betrag_brutto: "23,80", betrag_netto: null, waehrung: EUR, iban: "XX00TEST0000", positionen: [] } }
  - title: reports instead
    calls: [ { tool: bild_melden, args: { grund: unlesbar, notiz: "" } } ]
Y
  my ( $s, $err ) = Holmgang::SuiteDir::try_load( $case, head => $head );
  ok( $s, 'laedt: die Loesung erfuellt die Regeln auf norm, die falschen nicht' ) or diag $err;
};

subtest 'unbekanntes Werkzeug' => sub {
  fresh();
  my ( $o, $ok ) = t( bild_beschreiben => () );
  ok( !$ok, 'abgelehnt' );
  is_deeply( $state, { sehen => { type => 'sehen' } }, 'nichts geaendert' );
};

done_testing;
