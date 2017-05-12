use strict;
use warnings;
use utf8;
use Lingua::JA::Halfwidth::Katakana;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my ($begin, $end) = ( hex('FF65'), hex('FF9F') );

for my $code ($begin .. $end)
{
    ok(chr($code) =~ /\p{InHalfwidthKatakana}/, 'HalfwidthKatakana');
}

ok(chr(hex('FF64')) !~ /\p{InHalfwidthKatakana}/, 'HalfwidthCJKpunctuation');
ok(chr(hex('FFA0')) !~ /\p{InHalfwidthKatakana}/, 'HalfwidthHangul');

done_testing;
