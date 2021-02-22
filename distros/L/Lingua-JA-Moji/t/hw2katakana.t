use FindBin '$Bin';
use lib "$Bin";
use LJMT;

my $full = 'アイウカキギョウ。、「」';
my $half = 'ｱｲｳｶｷｷﾞｮｳ｡､｢｣';

is (hw2katakana($half), $full);
is (kana2hw($full), $half);

done_testing ();
