use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Data::Dumper;
use Image::PNG::Libpng ':all';
BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};
my $tpng = "$Bin/test.png";
my $rpng = create_read_struct ();
open my $in, "<:raw", $tpng or die $!;
$rpng->init_io ($in);
$rpng->read_info ();
my $ihdr = $rpng->get_IHDR ();
print Dumper ($ihdr);
my $rows = $rpng->read_image ();
cmp_ok (scalar (@$rows), '==', $rpng->get_image_height (),
	"height & rows same");
cmp_ok (length ($rows->[0]), '==', 300, "Got correct image width");
$rpng->read_end ();
close $in or die $!;
my $ofile = "$Bin/otest.png";
rmfile ($ofile);
my $wpng = copy_png ($rpng);
$wpng->write_png_file ($ofile);
ok (! png_compare ($tpng, $ofile),
     "Got identical image data in $tpng and $ofile");
rmfile ($ofile);

done_testing ();
