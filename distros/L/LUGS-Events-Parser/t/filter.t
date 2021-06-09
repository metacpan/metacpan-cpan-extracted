#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use Encode qw(encode);
use File::Spec;
use FindBin qw($Bin);
use LUGS::Events::Parser;
use Test::More tests => 8;

my $join = sub { local $_ = shift; chomp; s/\n/ /g; $_ };

my $events_file = File::Spec->catfile($Bin, 'data', 'termine.txt');
my $parser = LUGS::Events::Parser->new($events_file, {
    filter_html  => true,
    tag_handlers => {
        'a href' => [ {
            rewrite => '$TEXT - $HREF',
            fields  => [ qw(location responsible) ],
        }, {
            rewrite => '$TEXT - $HREF',
            fields  => [ qw(more) ],
        } ],
        'font color' => [ {
             rewrite => '$TEXT',
             fields  => [ '*' ],
        } ],
        'b' => [ {
            rewrite => '$TEXT',
            fields  => [ '*' ],
        } ],
        'br' => [ {
            rewrite => '',
            fields  => [ '*' ],
        } ],
    },
    strip_text => [ 'mailto:' ],
});

my @expected = (
    [
      '20080303',
      '2008',
      '03',
      '03',
      '3',
      'Mo',
      '20:00',
      'Linux Stammtisch in Winterthur',
      'winti',
      $join->(<<'EOT'),
Restaurant Pizzeria La Pergola - http://www.la-pergola-winti.ch/, Stadthausstrasse
71, 8400 Winterthur (Karte - http://map.search.ch/8400-winterthur/stadthausstr.-71)
EOT
      'Paul Bosshard - Paul.Bosshard@LUGS.ch',
      'Mehr Infos - /lugs/sektionen/winterthur.phtml',
      '20080303_0_winti',
    ],
    [
      '20080306',
      '2008',
      '03',
      '06',
      '6',
      'Do',
      '19:30',
      'LugBE Treff',
      'bern',
      $join->(<<'EOT'),
Restaurant Beaulieu, Erlachstrasse 3, 3012 Bern (Karte -
http://map.search.ch/3012-bern/erlachstr.-3)
EOT
      'info@lugbe.ch - info@lugbe.ch',
      'Mehr Infos - http://lugbe.ch/action/nexttreff.phtml',
      '20080306_0_bern',
    ],
    [
      '20090709',
      '2009',
      '07',
      '09',
      '9',
      'Do',
      '19:15',
      'LUGS Treff',
      'treff',
      $join->(encode('UTF-8', <<'EOT')),
ETH Zürich, HG G 26.5 -
http://www.rauminfo.ethz.ch/grundrissplan.gif?region=Z&areal=Z&gebaeude=HG&geschoss=G&raumNr=26.5
(anderer Raum!)
EOT
      'LUGS Vorstand - lugsvs@lugs.ch',
      'Restaurant nach dem Treff: Auswahl / Anmeldung - http://www.dood' .
        'le.com/mgfpebmxx5ibyt4m (bis 09.07.2009 12:00)',
      '20090709_0_treff',
    ],
    [
      '20090725',
      '2009',
      '07',
      '25',
      '25',
      'Sa',
      'ab 17:00',
      'LUGS Grillabend',
      'spec',
      $join->(encode('UTF-8', <<'EOT')),
Hütte/Areal des Schäferhundeclubs Winterthur (Anreise -
http://neil.franklin.ch/Info_Texts/Anreise_SCOG_Clubhaus.html)
EOT
      'Neil Franklin - neil@franklin.ch',
      $join->(encode('UTF-8', <<'EOT')),
Wie schon die letzten Jahre werden wir auch dieses Jahr wieder eine LUGS-Grillparty
durchführen. Teilnehmer: LUGS Mitglieder (und werdende), Familie (Freund(in), Kinder,
Geschwister, ...), Freunde, ... Mehr Infos -
https://www.lugs.ch/lugs/interna/maillugs/200907/42.html (nur mit LUGS Login -
https://www.lugs.ch/lugs/badpw.phtml)
EOT
      '20090725_0_spec',
    ],
    [
      '20120922',
      '2012',
      '09',
      '22',
      '22',
      'Sa',
      '19:00 - 23:00',
      encode('UTF-8', 'Französischer Neujahrsmampf 2012'),
      'spec',
      'Standort noch unbekannt',
      encode('UTF-8', 'Martin Ebnöther - ceo@fress-und-sauf-verein.ch'),
      $join->(encode('UTF-8', <<'EOT')),
Ideen / Vorschläge bitte per E-Mail an den CEO - ceo@fress-und-sauf-verein.ch?subject=Vorschlag
Französischer Neujahrsmampf 2012 senden.
EOT
      '20120922_0_spec',
    ],
    [
      '20100212',
      '2010',
      '02',
      '12',
      '12',
      'Fr',
      '19:15',
      'LUGS Treff - Voodoo, Schwarze Magie und Internet per UMTS',
      'treff',
      $join->(encode('UTF-8', <<'EOT')),
Solino - http://www.solino.ch/, Am Schanzengraben 15, 8002 Zürich (Karte -
http://map.search.ch/zuerich/am-schanzengraben-15)
EOT
      encode('UTF-8', 'Martin Ebnöther - ventilator@semmel.ch'),
      undef,
      '20100212_0_treff',
    ],
    [
      '20110612',
      '2011',
      '06',
      '12',
      '12',
      'So',
       undef,
       undef,
      'spec',
       undef,
       undef,
       undef,
      '20110612_0_spec',
    ],
    [
      '20110612',
      '2011',
      '06',
      '12',
      '12',
      'So',
       undef,
       undef,
      'spec',
       undef,
       undef,
       undef,
      '20110612_1_spec',
    ],
);

my @events;
while (my $event = $parser->next_event) {
    push @events, [
        $event->get_event_date,
        $event->get_event_year,
        $event->get_event_month,
        $event->get_event_day,
        $event->get_event_simple_day,
        $event->get_event_weekday,
        $event->get_event_time,
        $event->get_event_title,
        $event->get_event_color,
        $event->get_event_location,
        $event->get_event_responsible,
        $event->get_event_more,
        $event->get_event_anchor,
    ];
}

foreach my $i (0 .. $#events) {
    my $counter = $i + 1 . '/' . scalar @events;
    is_deeply($events[$i], $expected[$i], "Filtering of event $counter");
}
