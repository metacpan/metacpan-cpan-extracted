use warnings;
use strict;
use utf8;
use Test::More;
# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output, ":utf8";
binmode Test::More->builder->failure_output, ":utf8";
BEGIN { use_ok('Lingua::JA::Moji') };

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
			bad_kanji/;

# Sanity tests

ok (romaji2kana ('kakikukeko') eq 'カキクケコ', "Convert 'kakikukeko' to kana");
ok (kana2romaji ('かきくけこ') eq 'kakikukeko', "Convert 'かきくけこ' to romaji");

# Sokuon

ok (romaji2kana ('kakko') eq 'カッコ', "Convert 'kakko' to katakana");

ok (! is_romaji ("abcdefg"), "abcdefg does not look like romaji");
ok (is_romaji ("atarimae") eq "atarimae");
ok (romaji2hiragana ("iitte") eq "いいって", "romaji2hiragana does not use chouon");
ok (is_romaji ("kooru"));
#print is_romaji ("kuruu"), "\n";
ok (is_romaji ("kuruu") eq "kuruu");
ok (is_romaji ("benkyō suru"));

ok (is_kana ("いいって"));
ok (!is_kana ("いいってd"));
ok (!is_kana ("ddd"));

# Check for existence of styles

ok (romaji_styles ("nihon"));


my $ouhisi = kana2romaji ("おうひし", {style => "nihon", ve_type => "wapuro"});
#print "$ouhisi\n";

ok ($ouhisi eq "ouhisi");

my $ouhisi2 = kana2romaji ("おうひし", {style => "kunrei", ve_type => "wapuro"});
ok ($ouhisi2 eq "ouhisi");

# "romaji2hiragana" (Romaji to hiragana) tests

ok (romaji2hiragana ("fa-to") eq "ふぁーと");

# Double n plus vowel

my $double_n = romaji2hiragana ('keisatu no danna');
ok ($double_n =~ /んな/, "double n in 'danna' converted to ん plus な");

# l for small vowel

ok (romaji2kana ("lyo") eq "ョ");

# du, dzu both づ

ok (romaji2hiragana ("dudzu") eq "づづ", "Romanization of du, dzu");

# "is_romaji" tests

ok (is_romaji ('honto ni honto ni honto ni raion desu boku ben'));
ok (! is_romaji ('ドロップ'), 'katakana does not look like romaji');

# kana2romaji tests

my $fall = kana2romaji ("フォール", {ve_type => "wapuro"});
is ($fall, 'huxo-ru', "small o kana");
my $fell = kana2romaji ("フェール", {ve_type => "wapuro"});
is ($fell, 'huxe-ru', "small e kana");
my $wood = kana2romaji ("ウッド");
ok ($wood !~ /ッ/);
my $legend = kana2romaji ('レジェンド');
#print "$legend\n";
ok ($legend =~ /zixe/, "je -> zixe");
my $perfume = kana2romaji ('パフューム', {ve_type => 'wapuro'});
#print "$perfume\n";
ok ($perfume eq 'pahuxyu-mu');
my $invoice = kana2romaji ('インヴォイス', {ve_type => 'wapuro', debug=>undef});
#print "$invoice\n";
ok ($invoice eq 'invuxoisu');

my $gunma = romaji2hiragana ('Gunma');
ok ($gunma eq 'ぐんま');
my $gumma = romaji2hiragana ('Gumma');
#print "$gumma\n";
ok ($gumma eq 'ぐんま');

my $rev_gunma = kana2romaji ($gumma);
print "$rev_gunma\n";
ok ($rev_gunma eq 'gunma');

my $hep_donmai = kana2romaji ('ドンマイ', {style => 'hepburn', use_m => 0});
ok ($hep_donmai eq 'donmai');
my $hep_shinbun = kana2romaji ('しんぶん', {style => 'hepburn', use_m => 0});
ok ($hep_shinbun eq 'shinbun');

my $reform = kana2romaji ('リフォーム', {style => 'common'});
is ($reform, 'rifōmu');

my $niigata = kana2romaji ('にいがた', {style => 'hepburn'});
is ($niigata, 'niigata');

my $small = "きゃきょうゎぉ";
my $large = kana_to_large ($small);
is ($large, 'きやきようわお');
my $small2 = "キャキョウヮォ";
my $large2 = kana_to_large ($small2);
is ($large2, 'キヤキヨウワオ');

my @list = (qw/カン スウ ハツ オオ/);
nigori_first (\@list);
is_deeply (\@list, [qw/カン スウ ハツ オオ ガン ズウ バツ パツ/]);

is (smallize_kana ('シヤツター'), 'シャッター');
is (cleanup_kana ('kaｋｉｸけコ一'), 'カキクケコー');

my @bk = bad_kanji ();
ok (@bk > 0, "got bad kanji");
my $aku;
for (@bk) {
    if (/悪/) {
	$aku = 1;
    }
}
ok ($aku, "found 悪 in bad kanji list");
done_testing ();
