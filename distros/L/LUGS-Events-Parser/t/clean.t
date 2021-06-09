#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use Encode qw(encode);
use File::Temp qw(tempfile);
use LUGS::Events::Parser;
use Test::More tests => 3;

my $join = sub { local $_ = shift; chomp; s/\n/ /g; $_ };

my $data = do { local $/; <DATA> };

my @expected = (map encode('UTF-8', $_),
    $join->(<<'EOT'),
Ideen / Vorschläge bitte per E-Mail an den CEO -
mailto:ceo@fress-und-sauf-verein.ch?subject=Vorschlag Thailändischer
Neujahrsmampf 2012 senden. Bereits eingegangene Vorschläge: Restaurant
Sala-Thai - http://www.sala-thai.ch/, Alte Landstrasse 1, 8708 Männedorf
(Karte - http://map.search.ch/maennedorf/alte-landstr.1)
EOT
    $join->(<<'EOT'),
Ideen / Vorschläge bitte per E-Mail an den CEO -
<mailto:ceo@fress-und-sauf-verein.ch?subject=Vorschlag Thailändischer
Neujahrsmampf 2012> senden. Bereits eingegangene Vorschläge: Restaurant
Sala-Thai - <http://www.sala-thai.ch/>, Alte Landstrasse 1, 8708 Männedorf
(Karte - <http://map.search.ch/maennedorf/alte-landstr.1>)
EOT
    $join->(<<'EOT'),
Ideen / Vorschläge bitte per E-Mail an den <CEO> senden. <hr>Bereits eingegangene
Vorschläge: <Restaurant Sala-Thai>, Alte Landstrasse 1, 8708 Männedorf (<Karte>)
EOT
);

my %rewrite = (
    a_href => [ '$TEXT - $HREF', '$TEXT - <$HREF>', '<$TEXT>' ],
    br     => [  undef,           undef,            '<hr>'    ],
);

foreach my $i (0 .. $#{$rewrite{(keys %rewrite)[0]}}) {
    my ($fh, $tmpfile) = tempfile();
    print {$fh} $data;
    close($fh);

    my $parser = LUGS::Events::Parser->new($tmpfile, {
        filter_html => true,
        tag_handlers => {
            'a href' => [ {
                rewrite => $rewrite{a_href}->[$i],
                fields  => [ qw(more) ],
            } ],
            defined $rewrite{br}->[$i] ? (
            'br' => [ {
                rewrite => $rewrite{br}->[$i],
                fields  => [ qw(more) ],
            } ] ) : (),
        },
        purge_tags => [ qw(more) ],
    });

    is($parser->next_event->get_event_more, $expected[$i], 'Purging tags');
}

__DATA__
event 20120413
  time 19:00 - 23:00
  title Thail&auml;ndischer Neujahrsmampf 2012
  color spec
  location Standort noch unbekannt
  responsible <a href="mailto:ceo@fress-und-sauf-verein.ch">Martin Ebn&ouml;ther</a>
  more Ideen / Vorschl&auml;ge bitte per E-Mail an den
  more <a href="mailto:ceo@fress-und-sauf-verein.ch?subject=Vorschlag Thail&auml;ndischer Neujahrsmampf 2012">CEO</a>
  more senden.
  more <br>Bereits eingegangene Vorschl&auml;ge:
  more <ul><li><a href="http://www.sala-thai.ch/">Restaurant Sala-Thai</a>, Alte Landstrasse 1, 8708 M&auml;nnedorf (<a href="http://map.search.ch/maennedorf/alte-landstr.1">Karte</a>)
  more </ul>
endevent
