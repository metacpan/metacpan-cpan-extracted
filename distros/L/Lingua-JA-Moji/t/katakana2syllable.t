use warnings;
use strict;
use Test::More;
use utf8;
use Lingua::JA::Moji 'katakana2syllable';
use warnings;
use strict;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

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
