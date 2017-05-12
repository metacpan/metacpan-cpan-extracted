use strict;
use warnings;
use Test::More tests => 32;
use Encode;
use Encode::JP::Mobile;

sub test_it {
    my ($jis, $normal_uni, $case) = @_;
    $case ||= unpack "H*", $normal_uni;

    is decode("x-iso-2022-jp-airh", $jis), $normal_uni, "decoding $case";
    is $jis, encode("x-iso-2022-jp-airh", $normal_uni), "encoding $case";

    my $bytes = $jis;
    Encode::from_to($bytes, "x-iso-2022-jp-airh" => "x-sjis-airh");
    Encode::from_to($bytes, "x-sjis-airh", "x-iso-2022-jp-airh");
    is $bytes, $jis, "x-sjis-airh $case";
}

test_it("\e\$B\xF8\x9F\e(B", "\x{E63E}", "pictogram");

test_it "a", decode('utf8', 'a'), 'alphabet';
test_it "\e\$B\x24\x57\e(B", "\x{3077}", 'hiragana(pu)';

is encode('x-iso-2022-jp-airh', "\x{5bc5}"), encode('iso-2022-jp', "\x{5bc5}"), "kanji(tora)";
is encode('x-iso-2022-jp-airedge', "\x{5bc5}"), encode('iso-2022-jp', "\x{5bc5}"), "kanji(tora) x-iso-2022-jp-airedge alias";
is decode('x-iso-2022-jp-airh', "\e\$B\x24\x57\e(B", Encode::FB_PERLQQ), "\x{3077}", "test fallback branch(only for test coverage)";
is decode('x-iso-2022-jp-airh', "\e\$B\x24\x22\xF8\xA0\e(B"), "\x{3042}\x{E63F}", "hiragana alphabet";
is decode('x-iso-2022-jp-airh', "a\e\$B\x24\x22\xF8\xA0\e(B"), "a\x{3042}\x{E63F}", "alphabet hiragana pictogram";
is decode('x-iso-2022-jp-airh', "\xF8\xA0\e\$B\x24\x22\e(Ba"), "\x{E63F}\x{3042}a", "pictogram hiragana alphabet(real position of escape sequence)";
is decode('x-iso-2022-jp-airh', "\e\$B\xF8\xA0\x24\x22\e(Ba"), "\x{E63F}\x{3042}a", "pictogram hiragana alphabet(unreal position of escape sequence)";
is decode('x-iso-2022-jp-airh', "\xF8\xA0a\e\$B\x24\x22\e(B"), "\x{E63F}a\x{3042}", "pictogram alphabet hiragana(real position of escape sequence)";

test_it "\e\$B\xF8\xA0\e(B", "\x{E63F}", 'pictogram';
test_it "\e\$B\xF8\xA2\xF8\xA1\e(B", "\x{E641}\x{E640}", 'pictogram';
test_it encode('iso-2022-jp', decode("utf8", "お")), decode('utf8', "お"), 'o';
test_it encode('iso-2022-jp', decode("utf8", "おい。山田くん。zabutonイチマイ。")), decode('utf8', "おい。山田くん。zabutonイチマイ。"), 'kanji, hiragana, alphabet';
test_it "\e\(I\x4c\x5e\x30\x4c\x28\x30\e(B", decode('utf8', "ﾌﾞｰﾌｨｰ"), 'half width katakana';

# is decode('x-iso-2022-jp-kddi', "\e\$(D\x2B\x21\x30\x57\e(B"), "\x{00E1}\x{4F0C}", 'JIS X 0212';
