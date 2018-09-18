use warnings;
use strict;
use utf8;
use Test::More;
# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output, ":utf8";
binmode Test::More->builder->failure_output, ":utf8";
BEGIN {
    use_ok ('Lingua::JA::Moji');
};

use Lingua::JA::Moji qw/romaji2kana
                        kana2romaji
                        is_romaji
                        romaji2hiragana
                        is_kana
                        romaji_styles
                        kana_to_large
			nigori_first
			smallize_kana
			cleanup_kana
			bad_kanji
			yurei_moji/;

# Basic tests of romaji/kana conversion

ok (romaji2kana ('kakikukeko') eq 'カキクケコ', "Convert 'kakikukeko' to kana");
ok (kana2romaji ('かきくけこ') eq 'kakikukeko', "Convert 'かきくけこ' to romaji");

# Sokuon

ok (romaji2kana ('kakko') eq 'カッコ', "Convert 'kakko' to katakana");

ok (romaji2hiragana ("iitte") eq "いいって",
    "romaji2hiragana does not use chouon");

# Tests of "is_romaji".

ok (is_romaji ("atarimae") eq "atarimae",
    "Simple romaji is allowed by is_romaji (1)");
ok (is_romaji ('honto ni honto ni honto ni raion desu boku ben'),
    "Simple romaji is allowed by is_romaji (2)");
ok (! is_romaji ('ドロップ'), 'Katakana is not allowed by is_romaji');
ok (is_romaji ("kooru"), "Double o is allowed by is_romaji");
ok (is_romaji ("kuruu") eq "kuruu", "Return value of is_romaji is right");
ok (is_romaji ("benkyō suru"), "Macron-o is allowed by is_romaji");
ok (! is_romaji ("abcdefg"), "'abcdefg' is not allowed by is_romaji");

# Tests of "is_kana"

ok (is_kana ("いいって"), "Sokuon is allowed by is_kana");
ok (!is_kana ("いいってd"), "Mixed kana/romaji is not allowed by is_kana");
ok (!is_kana ("ddd"), "Romaji only is not allowed by is_kana");

# Check for existence of styles

ok (romaji_styles ("nihon"), "Basic operation of romaji_styles");

my $ouhisi = kana2romaji ("おうひし", {style => "nihon", ve_type => "wapuro"});

ok ($ouhisi eq "ouhisi", "nippon shiki romaji as expected");

my $ouhisi2 = kana2romaji ("おうひし", {style => "kunrei", ve_type => "wapuro"});
ok ($ouhisi2 eq "ouhisi", "kunrei shiki romaji as expected");

# "romaji2hiragana" (Romaji to hiragana) tests

ok (romaji2hiragana ("fa-to") eq "ふぁーと",
    "romaji2hiragana basic operation ok");

# Double n plus vowel

my $double_n = romaji2hiragana ('keisatu no danna');
ok ($double_n =~ /んな/, "Double n in 'danna' converted to syllabic n plus na");

# l for small vowel

ok (romaji2kana ("lyo") eq "ョ", "romaji2kana makes lyo into small yo");

# du, dzu both づ

ok (romaji2hiragana ("dudzu") eq "づづ", "Romanization of du, dzu");

# kana2romaji tests

my $fall = kana2romaji ("フォール", {ve_type => "wapuro"});
is ($fall, 'huxo-ru', "small o kana becomes xo");
my $fell = kana2romaji ("フェール", {ve_type => "wapuro"});
is ($fell, 'huxe-ru', "small e kana becomes xe");
my $wood = kana2romaji ("ウッド");
ok ($wood !~ /ッ/, "Conversion of sokuon + d");
my $legend = kana2romaji ('レジェンド');
ok ($legend =~ /zixe/, "Romanisation of je -> zixe");
my $perfume = kana2romaji ('パフューム', {ve_type => 'wapuro'});
ok ($perfume eq 'pahuxyu-mu', "Romanisation of fu plus small yu");
my $invoice = kana2romaji ('インヴォイス', {ve_type => 'wapuro', debug=>undef});
ok ($invoice eq 'invuxoisu', "Romanisation of nigori-u plus small o");

# Syllabic n tests

my $gunma = romaji2hiragana ('Gunma');
ok ($gunma eq 'ぐんま', "Kanaisation of nma");
my $gumma = romaji2hiragana ('Gumma');
ok ($gumma eq 'ぐんま', "Kanaisation of mma");

# Standard format is to convert syllabic n to "n", not "m".

my $rev_gunma = kana2romaji ($gumma);
ok ($rev_gunma eq 'gunma', "Syllabic n is represented by n");

my $hep_donmai = kana2romaji ('ドンマイ', {style => 'hepburn', use_m => 0});
ok ($hep_donmai eq 'donmai', "Syllabic n is represented by n");
my $hep_shinbun = kana2romaji ('しんぶん', {style => 'hepburn', use_m => 0});
ok ($hep_shinbun eq 'shinbun', "Syllabic n is represented by n");

# Romanisation niggles

my $reform = kana2romaji ('リフォーム', {style => 'common'});
is ($reform, 'rifōmu',
    "fu plus xo plus chouon becomes f-macron-o in common system");

my $niigata = kana2romaji ('にいがた', {style => 'hepburn'});
is ($niigata, 'niigata', "Double i does not have a macron");

my $small = "きゃきょうゎぉ";
my $large = kana_to_large ($small);
is ($large, 'きやきようわお', "Basic operation of kana_to_large part 1");
my $small2 = "キャキョウヮォ";
my $large2 = kana_to_large ($small2);
is ($large2, 'キヤキヨウワオ', "Basic operation of kana_to_large part 2");

my @list = (qw/カン スウ ハツ オオ/);
nigori_first (\@list);
is_deeply (\@list, [qw/カン スウ ハツ オオ ガン ズウ バツ パツ/],
	   "Operation of nigori_first");

is (smallize_kana ('シヤツター'), 'シャッター',
    "Basic operation of smallize_kana");

is (smallize_kana ('ケンブリツジ'), 'ケンブリッジ');

# Test the cleanup of badly-input kana

is (cleanup_kana ('kaｋｉｸけコ一'), 'カキクケコー', "Clean up kana");
is (cleanup_kana ('ファ二ガ'), 'ファニガ',
    "Convert 'two' kanji to 'ni' kana");

# Tests of bad_kanji

my @bk = bad_kanji ();
ok (@bk > 0, "Got a non-empty list from bad_kanji");
ok (find_kanji (\@bk, '悪'), "Found kanji 'bad' in bad kanji list");

# Tests of yurei_moji

my @ym = yurei_moji ();
ok (@ym > 0, "Got a non-empty list from yurei_moji");
ok (find_kanji (\@ym, '彁'), "Found non-existent kanji in yurei moji list");

done_testing ();
exit;

# Find a kanji $kanji in a list of kanjis $list and return true if
# found, false if not.

sub find_kanji
{
    my ($list, $kanji) = @_;
    my $aku;
    for (@$list) {
	if ($_ eq $kanji) {
	    $aku = 1;
	}
    }
    return $aku;
}
