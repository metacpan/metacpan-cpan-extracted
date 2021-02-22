use FindBin '$Bin';
use lib "$Bin";
use LJMT;

my $old1 = '櫻井';
my $new1 = old2new_kanji ($old1);
ok ($new1 eq '桜井', 'Convert 櫻井 to 桜井');
my $new2 = '三国 連太郎';
my $old2 = new2old_kanji ($new2);
ok ($old2 eq '三國 連太郎', 'Convert 三國');

done_testing ();
