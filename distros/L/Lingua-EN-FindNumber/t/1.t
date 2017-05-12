use Test::More tests => 4;
use_ok("Lingua::EN::FindNumber");

ok($number_re, "Exported the regular expression");

my $text = "Fourscore and seven years ago, our four fathers...";

is(numify($text), "87 years ago, our 4 fathers...", "numify");
@numbers = extract_numbers($text); 
is_deeply(\@numbers, ["Fourscore and seven", "four"], "extract_numbers");

my $x = $number_re; #quiet warnings
$number_re = $x;
