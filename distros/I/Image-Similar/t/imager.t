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
eval "use Imager;";
if ($@) {
    plan (skip_all => "Imager not available: $@ error on loading");
}
my @read_types = Imager->read_types ();
my $png_ok = grep /\bpng\b/i, @read_types;
if (! $png_ok) {
    plan (skip_all => "local version of Imager doesn't support PNG for reading");
}
my $chess100 = Imager->new ();
$chess100->read (file => "$Bin/images/chess/chess-100.png")
    or die $chess100->errstr ();
my $is = load_image ($chess100);
ok ($is);
my $chess200 = Imager->new ();
$chess200->read (file => "$Bin/images/chess/chess-200.png")
    or die $chess200->errstr ();
my $is200 = load_image ($chess200);
ok ($is200);
print $is->diff ($is200), "\n";
my $chess300 = Imager->new ();
$chess300->read (file => "$Bin/images/chess/chess-300.png")
    or die $chess300->errstr ();
my $is300 = load_image ($chess300);
ok ($is300);
print $is->diff ($is300), "\n";
print "200-300 diff: ", $is200->diff ($is300), "\n";
my $lfile = "$Bin/../xt/lena-gercke.jpg";
if (-f $lfile) {
    my $lena = Imager->new ();
    $lena->read (file => "$Bin/../xt/lena-gercke.jpg");
    my $img = load_image ($lena);
    for my $s (1..10) {
	my $size = $s * 100;
	my $lenax = Imager->new ();
	$lenax->read (file => "$Bin/images/lenagercke/lena-$size.png");
	my $imgx = load_image ($lenax);
	cmp_ok ($img->diff ($imgx), "<", 0.1, "$size looks like original");
    }
    cmp_ok ($is->diff ($img), ">", 0.1,
	    "Lena Gercke doesn't look like a chessboard to me");
}
done_testing ();
exit;
