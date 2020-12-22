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
use Image::PNG::Libpng ':all';
BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};
my $tpng = "$Bin/test.png";
my $rpng = read_png_file ($tpng);

my $wpng = create_write_struct ();
$wpng->set_IHDR ($rpng->get_IHDR ());
my $ofile = "$Bin/otest.png";
rmfile ($ofile);
open my $out, ">:raw", $ofile or die $!;
$wpng->init_io ($out);
$wpng->write_info ();
my $rows = $rpng->get_rows ();
$wpng->write_image ($rows);
$wpng->write_end ();
close $out or die $!;
ok (! png_compare ($tpng, $ofile),
    "Got identical image data in $tpng and $ofile");
rmfile ($ofile);

done_testing ();
