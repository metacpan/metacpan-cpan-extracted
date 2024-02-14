use FindBin '$Bin';
use lib "$Bin";
use LJMT;

my $long = 'ソーシャルブックマークサービス';

my $pieces = katakana2syllable ($long);

is_deeply ($pieces,
           ['ソー', 'シャ', 'ル', 'ブ', 'ック', 'マー', 'ク', 'サー', 'ビ', 'ス'],
           "decomposition of katakana into syllables");

$long = 'ソーシャール';

$pieces = katakana2syllable ($long);

is_deeply ($pieces,
           ['ソー', 'シャー', 'ル'],
           "ya plus chouon");

my $syllables = katakana2syllable ('ジョン・フラナガン');
unlike (join ('!', @$syllables), qr/!ン/, "ン is not a syllable");

my $nobrand = katakana2syllable ('ノーブランド');

is_deeply ($nobrand, ['ノー', 'ブ', 'ラン', 'ド']); 

done_testing ();
