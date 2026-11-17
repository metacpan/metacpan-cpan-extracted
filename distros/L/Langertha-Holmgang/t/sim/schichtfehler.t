#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Sim::Schichtfehler;
use Holmgang::TestSim qw( sims clone );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Web-Anwendung als Welt ohne Geraet (ported from cai-platform
# t/eval_sim_schichtfehler.t). Behauptet wird: Dateien kommen mit
# Zeilennummern (auch ein Ausschnitt), Abrufe und Konsole kommen aus der
# Aufzeichnung — Parameter in beliebiger Reihenfolge und Kodierung —,
# statische Dateien liefert der Server selbst, ein unbekannter Pfad ist 404,
# ein nicht aufgezeichneter Abruf einer vorhandenen Seite ist eine Luecke der
# Simulation; ein Befund trifft eine Ursache genau dann, wenn Datei gleich ist
# und die Zeilen sich ueberlappen; die Antwort verraet nie, ob er trifft; zu
# grosse Bereiche, falsche Zeilen, unbekannte Schichten und Kategorien werden
# abgewiesen, ohne den Zustand zu aendern. Die Anwendung hier ist ausgedacht
# (keine Faelle einer Suite).

my $W = 'Langertha::Holmgang::Sim::Schichtfehler';

sub fresh {
  return {
    app => {
      type    => 'schichtfehler',
      dateien => {
        'artikel.php'   => join( "\n", map {"zeile $_"} 1 .. 40 )."\n",
        'js/artikel.js' => "'use strict';\nconst a = 1;\n",
        'css/app.css'   => "body { margin: 0; }\n",
      },
      abrufe => [
        { pfad => 'artikel.php', parameter => '', status => '200 OK', kopf => ['Content-Type: text/html; charset=UTF-8'], rumpf => "<!doctype html>\n<p>Liste</p>\n" },
        { pfad => 'api/artikel.php', parameter => 'q=Haus%20%26%20Garten&seite=1', status => '200 OK', kopf => ['Content-Type: application/json'], rumpf => '{"anzahl":1}' },
      ],
      konsole  => [ { pfad => 'artikel.php', parameter => '', ausgabe => "Konsole:\n(keine Meldungen)" } ],
      ursachen => [ { id => 'u1', orte => [ { datei => 'artikel.php', von => 20, bis => 22 } ] }, { id => 'u2', orte => [ { datei => 'js/artikel.js', von => 2, bis => 2 } ] } ],
      befunde  => [],
    },
  };
}

my $state = fresh();
sub t { my ( $name, %a ) = @_; return sims()->tool_call( $state, schichtfehler => $name, \%a ) }

subtest 'Vertrag' => sub {
  ok( $W->does('Langertha::Holmgang::Role::AnswerWorld'), 'eine Antwortwelt' );
  is( $W->device_type, 'schichtfehler', 'Typ schichtfehler' );
  ok( sims()->is_answer_world('schichtfehler'), 'eingebaut in der Registry' );
  is_deeply( [ sort keys %{ sims()->world_tools('schichtfehler') } ],
    [qw( befund_melden browser_konsole datei_lesen dateien_auflisten kein_fehler_melden seite_abrufen )], 'Werkzeuge der Welt' );
  is_deeply( sims()->world_tools('schichtfehler')->{befund_melden},
    [qw( datei zeile_von zeile_bis ursache_schicht symptom_schicht kategorie )], 'Pflichtparameter von befund_melden' );
  my ( $o, $ok ) = t('befunde_loeschen');
  ok( !$ok, 'unbekanntes Werkzeug scheitert' );
  like( $o, qr/unbekanntes Werkzeug 'befunde_loeschen'/, '... und nennt es' );
};

subtest 'Dateien' => sub {
  my ( $o, $ok ) = t('dateien_auflisten');
  ok( $ok, 'auflisten gelingt' );
  like( $o, qr/^artikel\.php  \(40 Zeilen\)$/m, 'mit Zeilenzahl' );
  ( $o, $ok ) = t( datei_lesen => pfad => '/artikel.php', von => 19, bis => 21 );
  is( $o, " 19| zeile 19\n 20| zeile 20\n 21| zeile 21", 'Ausschnitt mit Zeilennummern, fuehrendes / egal' );
  ( $o, $ok ) = t( datei_lesen => pfad => 'js/artikel.js' );
  is( $o, "  1| 'use strict';\n  2| const a = 1;", 'ganze Datei' );
  ( $o, $ok ) = t( datei_lesen => pfad => 'gibt/es/nicht.php' );
  ok( !$ok, 'fehlende Datei scheitert' );
  ( $o, $ok ) = t( datei_lesen => pfad => 'artikel.php', von => 50 );
  ok( !$ok, 'von hinter dem Ende scheitert' );
  ( $o, $ok ) = t( datei_lesen => pfad => 'artikel.php', von => '38', bis => '99' );
  like( $o, qr/\A 38\| zeile 38\n 39\| zeile 39\n 40\| zeile 40\z/, 'bis wird gekappt, Zahlen als Text' );
};

subtest 'Abrufe und Konsole' => sub {
  my ( $o, $ok, $gap ) = t( seite_abrufen => pfad => 'artikel.php' );
  is( $o, "HTTP/1.1 200 OK\nContent-Type: text/html; charset=UTF-8\n\n  1| <!doctype html>\n  2| <p>Liste</p>", 'Antwort mit Kopf und nummeriertem Rumpf' );
  ( $o, $ok ) = t( seite_abrufen => pfad => 'api/artikel.php', parameter => '?seite=1&q=Haus+%26+Garten' );
  like( $o, qr/"anzahl":1/, 'Parameter: Reihenfolge, ?, + und Kodierung egal' );
  ( $o, $ok ) = t( seite_abrufen => pfad => 'api/artikel.php?seite=1&q=Haus%20%26%20Garten' );
  like( $o, qr/"anzahl":1/, 'Query auch am Pfad' );
  ( $o, $ok, $gap ) = t( seite_abrufen => pfad => 'artikel.php', parameter => 'q=tee' );
  ok( !$ok, 'nicht aufgezeichnet: kein Erfolg' );
  ok( defined $gap, '... und Luecke der Simulation' );
  like( $o, qr/Aufgezeichnet: \(ohne Parameter\)/, '... nennt die aufgezeichneten Parameter' );
  ( $o, $ok, $gap ) = t( browser_konsole => pfad => 'artikel.php', parameter => 'q=tee' );
  ok( !$ok && defined $gap, 'Konsole nicht aufgezeichnet: ebenso Luecke' );
  ( $o, $ok, $gap ) = t( seite_abrufen => pfad => 'favicon.ico' );
  ok( $ok && !defined $gap, 'unbekannter Pfad: 404 wie ein Server, keine Luecke' );
  like( $o, qr/\AHTTP\/1\.1 404 Not Found/, 'Status 404 Not Found' );
  ( $o, $ok, $gap ) = t( seite_abrufen => pfad => 'css/app.css' );
  like( $o, qr/\AHTTP\/1\.1 200 OK\nContent-Type: text\/css; charset=UTF-8\n\n  1\| body/, 'statische Datei liefert der Server selbst' );
  ok( !defined $gap, '... ohne Luecke' );
  ( $o, $ok ) = t( browser_konsole => pfad => 'artikel.php', parameter => '' );
  like( $o, qr/keine Meldungen/, 'Konsole aus der Aufzeichnung' );
  is_deeply( $state, fresh(), 'Lesen aendert nichts' );
};

subtest 'status_zeile ersetzt die Statuszeile' => sub {
  my $s = fresh();
  push @{ $s->{app}{abrufe} }, { pfad => 'kaputt.php', parameter => '', status_zeile => 'HTTP/1.1 500 Internal Server Error', kopf => [], rumpf => '' };
  $s->{app}{dateien}{'kaputt.php'} = "<?php\n";
  my ( $o, $ok ) = sims()->tool_call( $s, schichtfehler => seite_abrufen => { pfad => 'kaputt.php' } );
  is( $o, "HTTP/1.1 500 Internal Server Error\n\n(leerer Rumpf)", 'eigene Statuszeile, leerer Rumpf' );
};

subtest 'Befunde' => sub {
  my $b = sub { my %a = ( datei => 'artikel.php', ursache_schicht => 'php', symptom_schicht => 'js', kategorie => 'quoting', @_ ); return t( befund_melden => %a ) };
  my ( $o, $ok ) = $b->( zeile_von => 22, zeile_bis => 25 );
  ok( $ok, 'Befund aufgenommen' );
  is( $o, 'Befund 1 aufgenommen (artikel.php, Zeilen 22–25).', 'Antwort verraet nicht, ob er trifft' );
  is_deeply( $state->{app}{befunde}[0]{trifft}, ['u1'], 'Ueberlappung am Rand (22) trifft u1' );
  $b->( zeile_von => 23, zeile_bis => 30 );
  is_deeply( $state->{app}{befunde}[1]{trifft}, [], 'dahinter trifft nichts' );
  $b->( zeile_von => 19, zeile_bis => 19 );
  is_deeply( $state->{app}{befunde}[2]{trifft}, [], 'davor trifft nichts' );
  $b->( datei => 'js/artikel.js', zeile_von => 1, zeile_bis => 2 );
  is_deeply( $state->{app}{befunde}[3]{trifft}, ['u2'], 'andere Datei, andere Ursache' );
  $b->( datei => 'js/artikel.js', zeile_von => 1, zeile_bis => 1 );
  is_deeply( $state->{app}{befunde}[4]{trifft}, [], 'gleiche Zeilennummer in anderer Datei trifft nicht' );
  my $before = clone( $state->{app}{befunde} );
  for my $bad ( [ 'zu grosser Bereich' => zeile_von => 1, zeile_bis => 31 ], [ 'bis vor von' => zeile_von => 5, zeile_bis => 4 ],
    [ 'hinter dem Ende' => zeile_von => 40, zeile_bis => 41 ], [ 'Zeile 0' => zeile_von => 0, zeile_bis => 1 ],
    [ 'unbekannte Datei' => datei => 'x.php', zeile_von => 1, zeile_bis => 1 ], [ 'unbekannte Schicht' => zeile_von => 1, zeile_bis => 1, ursache_schicht => 'css' ],
    [ 'unbekannte Kategorie' => zeile_von => 1, zeile_bis => 1, kategorie => 'tippfehler' ] ) {
    my ( $name, @a ) = @$bad;
    my ( undef, $okb ) = $b->(@a);
    ok( !$okb, "abgewiesen: $name" );
  }
  is_deeply( $state->{app}{befunde}, $before, 'abgewiesene Befunde aendern nichts' );
  ok( !exists $state->{app}{kein_fehler}, 'kein_fehler vorher nicht gesetzt' );
  ( $o, $ok ) = t('kein_fehler_melden');
  ok( $ok, 'kein_fehler_melden gelingt' );
  is( $state->{app}{kein_fehler}, 1, '... und steht im Zustand' );
};

is( $W->can('norm_query')->('?b=2&a=%41&a=1'), 'a=1&a=A&b=2', 'norm_query sortiert und dekodiert' );
is_deeply( [ $W->can('norm_path')->('./api/artikel.php?id=3') ], [ 'api/artikel.php', 'id=3' ], 'norm_path trennt die Query ab' );

done_testing;
