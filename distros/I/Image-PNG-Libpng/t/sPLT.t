use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use Image::PNG::Libpng ':all';
use Data::Dumper;

my @files = qw/
ps1n0g08
ps1n2c16
ps2n0g08
ps2n2c16
/;

for my $file (@files) {
    my $ffile = "$Bin/libpng/$file.png";
    my $png = read_png_file ($ffile);
    ok ($png);
#    print Dumper ($png);
    my $splt = $png->get_sPLT ();
    ok ($splt);
#    print Dumper ($splt);
#    $png->set_verbosity (1);
    my $out = copy_png ($png, verbosity => 0);
    ok ($out);
}
done_testing ();
