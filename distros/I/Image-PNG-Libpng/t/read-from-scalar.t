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


my $file = "$Bin/tantei-san.png";
my $scalarfile = "$Bin/scalar.png";
rmfile ($scalarfile);

open my $in, "<:raw", $file or die $!;
my $pngtext = '';
while (<$in>) {
    $pngtext .= $_;
}
close $in or die $!;
my $png = read_from_scalar ($pngtext);
eval {
    $png->write_png_file ($scalarfile);
};
ok ($@, "got error trying to write a read structure");
like ($@, qr!read!, "Correct kind of error message");

my $copy = copy_png ($png);
$copy->write_png_file ($scalarfile);
ok (-f $scalarfile, "Wrote file");
ok (!image_data_diff ($scalarfile, $file), "test of read_from_scalar");
my $wpng = copy_png ($png);
my $pngout = $wpng->write_to_scalar ();
open my $out, ">:raw", $scalarfile or die $!;
print $out $pngout;
close $out or die $!;
ok (!png_compare ($scalarfile, $file), "test of write_to_scalar");
rmfile ($scalarfile);
done_testing ();
