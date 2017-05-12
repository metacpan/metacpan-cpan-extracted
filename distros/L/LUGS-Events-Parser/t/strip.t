#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use File::Temp qw(tempfile);
use LUGS::Events::Parser;
use Test::More tests => 2;

my $join = sub { local $_ = shift; chomp; s/\n/ /g; $_ };

my ($fh, $tmpfile) = tempfile();
print {$fh} do { local $/; <DATA> };
close($fh);

my $parser = LUGS::Events::Parser->new($tmpfile, {
    filter_html  => true,
    tag_handlers => {
        'a href' => [ {
            rewrite => '$TEXT - <$HREF>',
            fields  => [ qw(responsible) ],
        } ],
    },
    strip_text => [
       'noch ',      # text only
       '3012',       # not enclosed with tags / inside tag attributes
      ' Vorstand',   # enclosed with tags
       'mailto:',    # inside tag attributes
       'href',       # don't strip from tags
    ],
});

my @expected = (
    [
      'Restaurant Beaulieu, Erlachstrasse 3,  Bern (<a href="http://map.search.ch/-bern/erlachstr.-3">Karte</a>)',
      'LugBE - <info@lugbe.ch>',
      '<a href="http://lugbe.ch/action/index.phtml">Mehr Infos</a>',
    ],
    [
      'Standort unbekannt',
      'LUGS - <lugsvs@lugs.ch>',
      $join->(<<'EOT'),
Spezial-Event: Ideen / Vorschläge bitte per E-Mail an den
<a href="lugsvs@lugs.ch?subject=Vorschlag Spezial-Event 03.05.2012">Vorstand</a>
senden.
EOT
    ],
);

my @events;
while (my $event = $parser->next_event) {
    push @events, [
        $event->get_event_location,
        $event->get_event_responsible,
        $event->get_event_more,
    ];
}

foreach my $i (0 .. $#events) {
    is_deeply($events[$i], $expected[$i], 'Stripping text');
}

__DATA__
event 20120301
  time 19:30 - 22:30
  title LugBE Treff
  color bern
  location Restaurant Beaulieu, Erlachstrasse 3, 3012 Bern (<a href="http://map.search.ch/3012-bern/erlachstr.-3">Karte</a>)
  responsible <a href="mailto:info@lugbe.ch">LugBE</a>
  more <a href="http://lugbe.ch/action/index.phtml">Mehr Infos</a>
endevent

event 20120503
  time 19:15 - 23:00
  title LUGS Treff - Spezial
  color treff
  location Standort noch unbekannt
  responsible <a href="mailto:lugsvs@lugs.ch">LUGS Vorstand</a>
  more Spezial-Event: Ideen / Vorschl&auml;ge bitte per E-Mail an den
  more <a href="mailto:lugsvs@lugs.ch?subject=Vorschlag Spezial-Event 03.05.2012">Vorstand</a>
  more senden.
endevent
