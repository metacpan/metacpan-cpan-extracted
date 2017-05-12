use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/trim ltrim rtrim/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/ltrim rtrim/);

is(  trim("\x{0020}\x{0020}にゃ ？\x{3000}"), "にゃ ？",  "trim" );
is( ltrim("\x{0020}\x{0020}にゃ ？\x{0020}"), "にゃ ？\x{0020}", "ltrim" );
is( rtrim("\x{0020}\x{0020}にゃにゃーん\x{0020}！\x{0020}\x{0020}"), "\x{0020}\x{0020}にゃにゃーん\x{0020}！", "rtrim" );

my $text = do { local $/; <DATA> };
is(trim($text), "にゃんだかにゃー　\n にゃふん！", "trim multi-line");
is($normalizer->normalize($text), "にゃんだかにゃー　\n にゃふん！", "normalize multi-line");

done_testing;

__DATA__
　  	にゃんだかにゃー　
 にゃふん！　	
