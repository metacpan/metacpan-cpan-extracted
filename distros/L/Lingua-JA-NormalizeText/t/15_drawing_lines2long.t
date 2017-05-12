use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/drawing_lines2long/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer    = Lingua::JA::NormalizeText->new(qw/drawing_lines2long/);
my @drawing_lines = qw/2500 2501 254C 254D 2574 2576 2578 257A/;
my $minus_sign    = '2212';
my $long  = chr(hex("30FC"));

my $text;
for (@drawing_lines) { $text .= chr(hex($_)); }
$text .= chr(hex($minus_sign));

is(drawing_lines2long($text),     ($long x scalar @drawing_lines) . chr(hex($minus_sign)));
is($normalizer->normalize($text), ($long x scalar @drawing_lines) . chr(hex($minus_sign)));

done_testing;
