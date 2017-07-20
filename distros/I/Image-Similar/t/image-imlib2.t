use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use Image::Similar 'load_image';
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
eval "use Image::Imlib2;";
if ($@) {
    plan (skip_all => "Image::Imlib2 not available: $@ error on loading");
}
my $chess100 = Image::Imlib2->load ("$Bin/images/chess/chess-100.png");
my $is = load_image ($chess100);
ok ($is);
my $chess200 = Image::Imlib2->load ("$Bin/images/chess/chess-200.png");
my $is200 = load_image ($chess200);
ok ($is200);
cmp_ok ($is->diff ($is200), '<', 0.1);
my $chess300 = Image::Imlib2->load ("$Bin/images/chess/chess-300.png");
my $is300 = load_image ($chess300);
ok ($is300);
cmp_ok ($is->diff ($is300), '<', 0.1);
cmp_ok ($is200->diff ($is300), '<', 0.1);
my $lfile = "$Bin/../xt/lena-gercke.jpg";
if (-f $lfile) {
    my $lena = Image::Imlib2->load ($lfile);
    my $img = load_image ($lena);
    for my $s (1..10) {
	my $size = $s * 100;
	my $lenax = Image::Imlib2->load ("$Bin/images/lenagercke/lena-$size.png");
	my $imgx = load_image ($lenax);
	cmp_ok ($img->diff ($imgx), "<", 0.1, "$size of lena looks like original");
    }
    cmp_ok ($is->diff ($img), ">", 0.1,
	    "Lena Gercke doesn't look like a chessboard to me");
}
done_testing ();
exit;
