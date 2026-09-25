#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;

# Every fan's sentence is in the rulebook. The text is the WMO "Mahjong
# Competition Rules" (2006) PDF, fetched from
# http://mahjong-europe.org/portal/images/docs/mcr_EN.pdf and pulled out of
# its streams by the one-liner in plan_mahjong/00-overview.md; it is not
# shipped (WMO copyright). Name it in MCR_TEXT. A missing file is a FAILURE
# that names the fetch, never a skip: a green run must mean the sentences
# were found.
#
# The comparison removes every whitespace character from both sides, because
# the PDF's text breaks lines inside words ("su it") and no sentence of the
# table can be expected to survive that with its spaces intact.

my $path = $ENV{MCR_TEXT};
plan tests => 82;

ok($path && -r $path, 'MCR_TEXT names a readable file')
	or BAIL_OUT('set MCR_TEXT to the extracted rulebook text (see plan_mahjong/00-overview.md)');

my $text = do { local $/; open my $fh, '<', $path or die "$path: $!"; <$fh> };
(my $flat = $text) =~ s/\s+//g;
# the PDF's typographic quotes and dashes against the table's ASCII ones
$flat =~ s/[\x{2018}\x{2019}]/'/g;
$flat =~ s/[\x{201c}\x{201d}]/"/g;
$flat =~ s/\x{2013}/-/g;

for my $fan (Game::Mahjong::Fans::all()) {
	(my $says = $fan->says) =~ s/\s+//g;
	my $found = index($flat, $says) >= 0;
	ok($found, sprintf('%2d %s: the sentence is in the rulebook', $fan->n, $fan->key))
		or diag "not found: " . $fan->says;
}
