#!perl -T

use warnings;

use Test::More tests => 4;

use HTML::ListScraper;
use HTML::ListScraper::Interactive qw(format_tags canonicalize_tags);

use Class::Generate qw(class);

class 'HTML::ListScraper::TTag' => {
    name => { type => '$', required => 1, readonly => 1 },
    index => { type => '$', required => 1, readonly => 1 },
    link => { type => '$', readonly => 1 },
    text => '$',
};

my $scraper = HTML::ListScraper->new( api_version => 3,
				      marked_sections => 1 );
$scraper->parse_file("testdata/synth.html");
my @seq = $scraper->get_sequences;
my $seq = shift @seq;
my @inst = $seq->instances;
my $inst = shift @inst;

my $expected = <<EXPECTED
<tr>
  <td>
  </td>
  <td>
  </td>
</tr>
EXPECTED
;

my @formatted = format_tags($scraper, [ $inst->tags ]);
my $formatted = join '', @formatted;
is($formatted, $expected);

my @expected = qw(tr td /td td /td /tr);
my @plain = canonicalize_tags(@formatted);
is_deeply(\@plain, \@expected);

$expected = <<EXPECTED
<p>
  <p>
  </p>
  <p>
  </p>
</p>
EXPECTED
;

my @tags;
my $index = 0;
foreach (qw(p p /p p /p /p)) {
    push @tags, HTML::ListScraper::TTag->new(name => $_, index => $index++);
}
@formatted = format_tags($scraper, \@tags);
$formatted = join '', @formatted;
is($formatted, $expected);

$expected = <<EXPECTED2
<hr/>
<hr/>
EXPECTED2
;

@tags = ();
$index = 0;
foreach (qw(hr hr)) {
    push @tags, HTML::ListScraper::TTag->new(name => $_, index => $index++);
}
@formatted = format_tags($scraper, \@tags);
$formatted = join '', @formatted;
is($formatted, $expected);
