#! perl

use warnings;
use strict;

use Test::More tests => 4;
use Finance::Kitko::Charts;

my $obj = Finance::Kitko::Charts->new();

my $r = $obj->gold();

is $r->{'24h'}, "http://www.kitco.com/images/live/goldw.gif";
is $r->{'ny'}, "http://www.kitco.com/images/live/nygoldw.gif";

$r = $obj->silver();

is $r->{'30d'}, "http://www.kitco.com/LFgif/ag0030lnb.gif";
is $r->{'60d'}, "http://www.kitco.com/LFgif/ag0060lnb.gif";
