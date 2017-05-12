use strict;
use warnings;

use Test::More;
use File::Slurp;
use HTML::ExtractContent;

@_ = sort(glob("t/input*.html"));
$_[-1] =~ /^t\/input(.*)\.html$/;
my $files = $1;
plan tests => $files*2;

my $extractor = HTML::ExtractContent->new;

for my $n (1..$files) {
    my $input = read_file("t/input${n}.html");
    my $raw = read_file("t/raw${n}.html");
    my $text = read_file("t/text${n}.txt");

    $extractor->extract($input);
    is($raw, $extractor->as_html);
    is($text, $extractor->as_text);
}

