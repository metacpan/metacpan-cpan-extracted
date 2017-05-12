use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/fullminus2long dashes2long/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $fullminus = chr(hex("FF0D"));
my $dash  = chr(hex("2014"));
my $long  = chr(hex("30FC"));

my $normalizer = Lingua::JA::NormalizeText->new(qw/fullminus2long dashes2long/);
my $fullminus_dash_long = "$fullminus$dash$long";

is(fullminus2long($fullminus_dash_long x 2), "$long$dash$long"  x 2);
is(dashes2long($fullminus_dash_long x 2),    "$fullminus$long$long" x 2);
is($normalizer->normalize($fullminus_dash_long x 2), $long x 6);

my $dashes = "\x{2012}\x{2013}\x{2014}\x{2015}";
is(dashes2long($dashes), $long x length $dashes);

done_testing;
