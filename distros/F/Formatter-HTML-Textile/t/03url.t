use warnings;
use strict;
use Test::More tests=>4;
use Formatter::HTML::Textile;

my $source = '"title":http://www.example.com';
my $formatter = Formatter::HTML::Textile->format($source);
my $dest = $formatter->fragment;
my $expected = '<p><a href="http://www.example.com">title</a></p>';

is($dest, $expected);

my @links = @{ $formatter->links };

is(@links, 1, "1 link found");
is($links[0]->{url}, "http://www.example.com", "link correct");
is($links[0]->{title}, "title", "title correct");
