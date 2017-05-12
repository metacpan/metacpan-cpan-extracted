#!perl -T

use warnings;

use Test::More tests => 30;

use HTML::ListScraper;

sub check;

my @known = qw(div a /a table tr td font br span /span nobr a /a a /a /nobr /font /td /tr /table /div);

my @testdata = qw(testdata/google.html testdata/google2.html testdata/google3.html);
foreach (@testdata) {
    check($_);
}

sub check {
    my $fname = shift;

    my $scraper = HTML::ListScraper->new( api_version => 3,
					  marked_sections => 1 );
    my @ignore_tags = qw(b i em strong);
    $scraper->ignore_tags(@ignore_tags);
    $scraper->parse_file($fname);

    my @seq = $scraper->get_sequences;
    is(scalar(@seq), 1);
    my $seq = shift @seq;
    isa_ok($seq, 'HTML::ListScraper::Sequence');
    ok($seq->len >= 20);

    my @inst = $seq->instances;
    ok(scalar(@inst) <= 10);

    @seq = $scraper->find_sequences;
    is(scalar(@seq), 1);
    $seq = shift @seq;
    isa_ok($seq, 'HTML::ListScraper::Sequence');
    ok($seq->len >= 20);

    @inst = $seq->instances;
    ok(scalar(@inst) >= 10);

    $seq = $scraper->find_known_sequence(@known);
    isa_ok($seq, 'HTML::ListScraper::Sequence');

    @inst = $seq->instances;
    ok(scalar(@inst) >= 10);
}
