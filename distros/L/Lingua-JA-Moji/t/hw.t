use FindBin '$Bin';
use lib "$Bin";
use LJMT;

my $full = 'ヴァイオリンー';
my $half = 'ｳﾞｧｲｵﾘﾝｰ';

is (kana2hw($full), $half);
is (hw2katakana($half), $full);

done_testing ();
