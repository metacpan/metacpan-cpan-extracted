#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Sim::Kueche;
use Holmgang::TestSim qw( sims clone diff );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Kueche als Welt ohne Geraet (ported from cai-platform t/eval_sim_kueche.t).
# Behauptet wird: Mengen kommen in jeder Form der Masstabelle an ("2 EL" wie
# "30 g", "0,5 l", "2 Eier") und stehen danach in der Grundeinheit der Zutat;
# Gewicht und Raum werden nie ineinander umgerechnet; auf_liste_setzen addiert,
# von_liste_nehmen zieht ab oder streicht; der Wochenplan nimmt nur bekannte
# Rezepte und Tage; ein Lesewerkzeug aendert den Zustand nicht. Die Rezepte hier
# sind ausgedacht (keine Fremdtexte, keine Faelle einer Suite).

my $K = 'Langertha::Holmgang::Sim::Kueche';
my $parse = $K->can('parse_amount');

subtest 'Vertrag' => sub {
  ok( $K->does('Langertha::Holmgang::Role::AnswerWorld'), 'eine Antwortwelt' );
  is( $K->device_type, 'kueche', 'Typ kueche' );
  ok( sims()->is_answer_world('kueche'), 'eingebaut in der Registry' );
  is_deeply(
    [ sort keys %{ sims()->world_tools('kueche') } ],
    [qw( auf_liste_setzen liste_lesen plan_lesen plan_setzen rezept_lesen rezepte_suchen von_liste_nehmen vorrat_lesen )],
    'die acht Werkzeuge',
  );
  is_deeply( sims()->world_tools('kueche')->{plan_setzen}, [qw( tag rezept portionen )], 'Pflichtparameter von plan_setzen' );
  is( sims()->world_tools('linux'), undef, 'linux hat keine Welt-Werkzeuge' );
};

subtest 'Masstabelle' => sub {
  is_deeply( [ $parse->( '2 EL', 'g' ) ],       [ 30, 'g' ],       '2 EL Mehl = 30 g' );
  is_deeply( [ $parse->( '1 TL', 'ml' ) ],      [ 5, 'ml' ],       '1 TL = 5 ml' );
  is_deeply( [ $parse->( '0,5 l', 'ml' ) ],     [ 500, 'ml' ],     '0,5 l = 500 ml' );
  is_deeply( [ $parse->( '1,5 kg', 'g' ) ],     [ 1500, 'g' ],     '1,5 kg' );
  is_deeply( [ $parse->( '3', 'Stück' ) ],      [ 3, 'Stück' ],    'blosse Zahl bei Stueck' );
  is_deeply( [ $parse->( '2 Dosen', 'Dose' ) ], [ 2, 'Dose' ],     'Mehrzahl einer Zaehleinheit' );
  is_deeply( [ $parse->( '½ l', 'ml' ) ],       [ 500, 'ml' ],     'halber Liter' );
  is_deeply( [ $parse->( '1/2 TL', 'g' ) ],     [ 2.5, 'g' ],      'Bruch' );
  is_deeply( [ $parse->('250 g') ],             [ 250, 'g' ],      'ohne Grundeinheit: die der Angabe' );
  like( ( $parse->( '200 ml', 'g' ) )[2],  qr/wird in g geführt/, 'Raum zu Gewicht: abgelehnt' );
  like( ( $parse->( '250', 'g' ) )[2],     qr/ohne Einheit/,      'Gewicht ohne Einheit: abgelehnt' );
  like( ( $parse->( '1 Prise', 'g' ) )[2], qr/unbekannt/,         'Prise kennt die Tabelle nicht' );
  like( ( $parse->( 'etwas', 'g' ) )[2],   qr/nicht lesbar/,      'etwas: nicht lesbar' );
  like( ( $parse->( '2 EL', 'Dose' ) )[2], qr/Löffelmaß passt nicht zu Dose/, 'Loeffel bei Zaehleinheit: abgelehnt' );
  is( $K->can('show_number')->(1.5), '1,5', 'show_number mit Komma' );
  is( $K->can('portions')->(1), '1 Portion', 'portions Einzahl' );
  is( $K->can('portions')->(3), '3 Portionen', 'portions Mehrzahl' );
};

my $start = {
  kueche => {
    type    => 'kueche',
    zutaten => {
      Ei    => { einheit => 'Stück', namen => ['Eier'] },
      Mehl  => { einheit => 'g' },
      Milch => { einheit => 'ml' },
      Mais  => { einheit => 'Dose' },
    },
    rezepte => {
      pfannkuchen => {
        titel => 'Pfannkuchen', portionen => 4, zeit => 20, vegetarisch => 'ja',
        zutaten => [
          { zutat => 'Mehl',  menge => 200, text => '200 g Mehl' },
          { zutat => 'Ei',    menge => 2,   text => '2 Eier' },
          { zutat => 'Milch', menge => 400, text => '0,4 l Milch' },
        ],
      },
      maistaler => {
        titel => 'Maistaler', portionen => 2, zeit => 30, vegetarisch => 'vegan',
        zutaten => [ { zutat => 'Mais', menge => 1, text => '1 Dose Mais' } ],
      },
    },
    vorrat => { Mehl => 1000, Ei => 1 },
    liste  => {},
    plan   => {},
  },
};

my $state;
sub fresh { $state = clone($start) }
sub t { my ( $name, %a ) = @_; return sims()->tool_call( $state, kueche => $name, \%a ) }

subtest 'Einkaufsliste' => sub {
  fresh();
  my ( $o, $ok ) = t( auf_liste_setzen => zutat => 'Eier', menge => '2' );
  ok( $ok, 'Eier per Mehrzahl' );
  is( $o, 'Auf der Liste: Ei 2 Stück', '... Ausgabe' );
  is( $state->{kueche}{liste}{Ei}, 2, 'steht als Ei, 2 Stueck' );
  t( auf_liste_setzen => zutat => 'ei', menge => '1 Stück' );
  is( $state->{kueche}{liste}{Ei}, 3, 'addiert, Name ohne Gross/Klein' );
  ( $o, $ok ) = t( auf_liste_setzen => zutat => 'Milch', menge => '2 EL' );
  is( $state->{kueche}{liste}{Milch}, 30, '2 EL Milch = 30 ml' );
  ( $o, $ok ) = t( auf_liste_setzen => zutat => 'Milch', menge => '100 g' );
  ok( !$ok, 'Milch in g: abgelehnt' );
  is( $o, "Fehler: Einheit 'g' passt nicht — wird in ml geführt.", '... mit der Grundeinheit' );
  is( $state->{kueche}{liste}{Milch}, 30, '... Liste unveraendert' );
  ( $o, $ok ) = t( auf_liste_setzen => zutat => 'Mais', menge => '2 Dosen Mais' );
  is( $state->{kueche}{liste}{Mais}, 2, 'Menge mit Zutatenname' );
  ( $o, $ok ) = t( auf_liste_setzen => zutat => '  ', menge => '2' );
  is_deeply( [ $o, $ok ], [ 'Fehler: Zutat fehlt.', 0 ], 'leere Zutat' );
  ( $o, $ok ) = t( von_liste_nehmen => zutat => 'Eier', menge => '1' );
  is( $state->{kueche}{liste}{Ei}, 2, 'abgezogen' );
  ( $o, $ok ) = t( von_liste_nehmen => zutat => 'Ei', menge => '5' );
  ok( !$ok, 'mehr abziehen als da: abgelehnt' );
  is( $o, 'Fehler: auf der Liste stehen nur 2 Stück.', '... mit dem Stand' );
  ( $o, $ok ) = t( von_liste_nehmen => zutat => 'Ei' );
  ok( $ok && !exists $state->{kueche}{liste}{Ei}, 'ohne Menge: gestrichen' );
  is( $o, 'Ei von der Liste gestrichen.', '... Ausgabe' );
  ( $o, $ok ) = t( von_liste_nehmen => zutat => 'Zucker' );
  ok( !$ok, 'nicht auf der Liste: Fehler' );
  ( $o, $ok ) = t( auf_liste_setzen => zutat => 'Zucker', menge => '250 g' );
  ok( $ok, 'unbekannte Zutat mit Einheit: angenommen' );
  is( $state->{kueche}{liste}{Zucker}, 250, '... in ihrer Grundeinheit' );
  is_deeply( $state->{kueche}{zutaten}{Zucker}, { einheit => 'g' }, '... und mit ihr in zutaten' );
  ( $o, $ok ) = t( von_liste_nehmen => zutat => 'Zucker', menge => '250 g' );
  ok( $ok && !exists $state->{kueche}{liste}{Zucker}, 'alles abgezogen: gestrichen' );
  ($o) = t( liste_lesen => () );
  is( $o, "- Mais: 2 Dosen\n- Milch: 30 ml", 'liste_lesen' );
};

subtest 'Sammlung, Vorrat, Plan' => sub {
  fresh();
  my ($o) = t( rezepte_suchen => suchbegriff => 'mais' );
  is( $o, "1 Rezepte:\n- maistaler: Maistaler (2 Portionen, 30 min, vegan)", 'Suche im Titel' );
  ($o) = t( rezepte_suchen => suchbegriff => 'milch' );
  like( $o, qr/pfannkuchen/, 'Suche in den Zutaten' );
  ($o) = t( rezepte_suchen => () );
  like( $o, qr/^2 Rezepte/, 'ohne Begriff: alle' );
  ($o) = t( rezepte_suchen => suchbegriff => 'waffel' );
  is( $o, 'Keine Rezepte gefunden.', 'nichts gefunden' );
  ($o) = t( rezept_lesen => rezept => 'Pfannkuchen' );
  is(
    $o,
    "Pfannkuchen (ID pfannkuchen)\nPortionen: 4\nZubereitungszeit: 20 min\nVegetarisch: vegetarisch\nZutaten:\n- 200 g Mehl\n- 2 Eier\n- 0,4 l Milch",
    'Rezept',
  );
  my $ok;
  ( $o, $ok ) = t( rezept_lesen => rezept => 'Waffeln' );
  is_deeply( [ $o, $ok ], [ "Rezept 'Waffeln' nicht gefunden.", 0 ], 'unbekanntes Rezept' );
  ($o) = t( vorrat_lesen => () );
  is( $o, "- Ei: 1 Stück\n- Mehl: 1000 g", 'Vorrat' );
  ($o) = t( plan_lesen => () );
  is( $o, 'Der Wochenplan ist leer.', 'leerer Plan' );
  ( $o, $ok ) = t( plan_setzen => tag => 'montag', rezept => 'pfannkuchen', portionen => '2' );
  ok( $ok, 'Plan gesetzt' );
  is( $o, 'Montag: Pfannkuchen, 2 Portionen.', '... Ausgabe' );
  is_deeply( $state->{kueche}{plan}{Montag}, { rezept => 'pfannkuchen', portionen => 2 }, '... als Montag' );
  ( $o, $ok ) = t( plan_setzen => tag => 'Feiertag', rezept => 'pfannkuchen', portionen => 2 );
  ok( !$ok, 'unbekannter Tag' );
  ( $o, $ok ) = t( plan_setzen => tag => 'Dienstag', rezept => 'pfannkuchen', portionen => '2-3' );
  is_deeply( [ $o, $ok ], [ 'Fehler: Portionen als ganze Zahl ab 1.', 0 ], 'Spanne als Portionen' );
  ( $o, $ok ) = t( plan_setzen => tag => 'Dienstag', rezept => 'waffeln', portionen => 2 );
  ok( !$ok, 'unbekanntes Rezept im Plan' );
  ($o) = t( plan_lesen => () );
  is( $o, '- Montag: Pfannkuchen (ID pfannkuchen), 2 Portionen', 'plan_lesen' );
};

subtest 'Lesen aendert nichts' => sub {
  # regression: cai-platform legte beim Lesen zutaten.<name> bzw. rezepte.<id>
  # als leeren Hash an, sobald eine Zutat der Liste oder ein Rezept des Plans
  # dort fehlte — ein Lesebefehl erschien so als Aenderung im Endzustand.
  my $sparse = { kueche => {
    type  => 'kueche',
    liste => { Zucker => 100 },
    plan  => { Freitag => { rezept => 'weg', portionen => 2 } },
  } };
  $state = clone($sparse);
  my ($o) = t( liste_lesen => () );
  is( $o, '- Zucker: 100 Stück', 'Liste ohne zutaten' );
  ($o) = t( plan_lesen => () );
  is( $o, '- Freitag: weg (ID weg), 2 Portionen', 'Plan mit fehlendem Rezept' );
  my ( undef, $ok ) = t( von_liste_nehmen => zutat => 'Zucker', menge => 'etwas' );
  ok( !$ok, 'unlesbare Menge: abgelehnt' );
  t( vorrat_lesen => () );
  t( rezepte_suchen => () );
  is_deeply( [ diff( $sparse, $state ) ], [], 'Zustand unveraendert' );
};

# Lesen und abgelehnte Aufrufe aendern den Zustand nicht, auch bei Luecken im
# Zustand: Zutaten in Vorrat und Liste ohne Eintrag in zutaten, ein Plan mit
# einem Rezept, das es nicht gibt, eine Kueche ganz ohne rezepte/liste/zutaten
# (k58).
subtest 'Lesen aendert nichts: Matrix' => sub {
  my %luecken = (
    mit_luecken => { type => 'kueche', zutaten => { Mehl => { einheit => 'g' } },
      rezepte => { pfannkuchen => { titel => 'Pfannkuchen', portionen => 4, zutaten => [] } },
      vorrat  => { Mehl => 500, Zucker => 250, Salz => 'vorhanden' }, liste => { Hefe => 1 },
      plan    => { Montag => { rezept => 'pfannkuchen', portionen => 2 }, Dienstag => { rezept => 'geloescht', portionen => 1 } } },
    leer => { type => 'kueche', plan => { Montag => { rezept => 'weg', portionen => 1 } }, vorrat => { Ei => 2 } },
    ohne_liste => { type => 'kueche', zutaten => { Mehl => { einheit => 'g' } } },
  );
  my @calls = ( ['rezepte_suchen'], [ rezepte_suchen => suchbegriff => 'mehl' ], [ rezept_lesen => rezept => 'pfannkuchen' ],
    [ rezept_lesen => rezept => 'gibtsnicht' ], ['vorrat_lesen'], ['liste_lesen'], ['plan_lesen'],
    [ von_liste_nehmen => zutat => 'Zucker' ], [ von_liste_nehmen => zutat => 'Mehl' ], [ von_liste_nehmen => zutat => 'Hefe', menge => '5' ],
    [ auf_liste_setzen => zutat => 'Mehl', menge => '1 l' ], [ plan_setzen => tag => 'Montag', rezept => 'gibtsnicht', portionen => 1 ] );
  for my $k ( sort keys %luecken ) {
    for my $c (@calls) {
      my ( $name, %a ) = @$c;
      $state = { kueche => clone( $luecken{$k} ) };
      my ( $o, $ok ) = t( $name, %a );
      next if $ok && $name !~ /_lesen\z|_suchen\z/;
      is_deeply( $state->{kueche}, $luecken{$k}, "$k: $name".( %a ? ' '.join( ',', map {"$_=$a{$_}"} sort keys %a ) : '' ).' laesst den Zustand, wie er war' );
    }
  }
  $state = { kueche => clone( $luecken{mit_luecken} ) };
  my ($o) = t('plan_lesen');
  like( $o, qr/- Dienstag: geloescht \(ID geloescht\), 1 Portion/, 'Plan mit fehlendem Rezept: zeigt die ID' );
  ($o) = t('vorrat_lesen');
  like( $o, qr/- Zucker: 250 Stück/, 'Vorrat ohne Eintrag in zutaten: Stück' );
};

subtest 'ueber die Registry' => sub {
  fresh();
  my ( $o, $ok ) = t( kochen => () );
  is_deeply( [ $o, $ok ], [ "Fehler: unbekanntes Werkzeug 'kochen'", 0 ], 'unbekanntes Werkzeug' );
  ( $o, $ok ) = t( auf_liste_setzen => zutat => 'Mehl', menge => '2 EL' );
  ok( $ok, 'Aufruf' );
  is( $state->{kueche}{liste}{Mehl}, 30, 'Zustand geaendert' );
  is_deeply( $start->{kueche}{liste}, {}, 'Anfangszustand unberuehrt' );
  is_deeply(
    [ sims()->tool_call( { gw => { type => 'linux' } }, kueche => 'liste_lesen' => {} ) ],
    [ 'Fehler: diese Umgebung hat keine kueche.', 0 ],
    'ohne Kueche im Zustand',
  );
};

done_testing;
