use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/nl2space/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/nl2space/);

my $CR   = "\x{000D}";
my $LF   = "\x{000A}";
my $CRLF = "\x{000D}\x{000A}";

my $text = "あ${CR}い${LF}う${CRLF}え${LF}${CR}お${CR}${CR}か${LF}${LF}";
is(nl2space($text), "あ\x{0020}い\x{0020}う\x{0020}え\x{0020}\x{0020}お\x{0020}\x{0020}か\x{0020}\x{0020}");
is($normalizer->normalize($text), "あ\x{0020}い\x{0020}う\x{0020}え\x{0020}\x{0020}お\x{0020}\x{0020}か\x{0020}\x{0020}");

done_testing;
