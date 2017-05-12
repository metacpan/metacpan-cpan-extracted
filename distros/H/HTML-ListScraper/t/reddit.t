#!perl -T

use warnings;

use Test::More tests => 4;

use HTML::ListScraper;

my $scraper = HTML::ListScraper->new( api_version => 3,
				      marked_sections => 1 );
$scraper->parse_file("testdata/reddit.html");

my @seq = $scraper->get_sequences;
is(scalar(@seq), 1);
my $seq = shift @seq;
isa_ok($seq, 'HTML::ListScraper::Sequence');
is($seq->len, 14);

my @inst = $seq->instances;
is(scalar(@inst), 25);
