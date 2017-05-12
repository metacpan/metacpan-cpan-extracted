use Test::More tests=>1;
use Formatter::HTML::Textile;

my $source = "paragraph1\n\nparagraph2\n\n";
my $dest = Formatter::HTML::Textile->format($source)->fragment;
my $expected = "<p>paragraph1</p>\n\n<p>paragraph2</p>";

is($dest, $expected);
