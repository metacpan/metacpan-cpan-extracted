#line 2 "Libpng.t.tmpl"

# Various tests.

use warnings;
use strict;
use Test::More;
use FindBin;
use File::Compare;
use Image::PNG::Libpng;
use utf8;
use Image::PNG::Const ':all';

my $builder = Test::More->builder;

binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":utf8";

my $png = Image::PNG::Libpng::create_read_struct ();
ok ($png, 'call "create_read_struct" and get something');
$png->set_verbosity (1);
my $file_name = "$FindBin::Bin/test.png";

open my $file, "<", $file_name or die "Can't open '$file_name': $!";

$png->init_io ($file);
$png->read_info ();

my $IHDR = $png->get_IHDR ();
is ($IHDR->{width}, 100, "width");
is ($IHDR->{height}, 100, "height");
$png->destroy_read_struct ();
close $file or die $!;

my $file_in_name = "$FindBin::Bin/test.png";
open my $file_in, "<", $file_in_name or die "Can't open '$file_in_name': $!";

my $png_in = Image::PNG::Libpng::create_read_struct ();
$png_in->init_io ($file_in);
$png_in->read_png (0);
close $file_in or die $!;

my $file_out_name = "$FindBin::Bin/test-write.png";
my $png_out = Image::PNG::Libpng::create_write_struct ();

my $png3 = Image::PNG::Libpng::read_png_file ("$FindBin::Bin/tantei-san.png");
eval {
    Image::PNG::Libpng::destroy_read_struct ($png3);
};
ok (! $@, "no error from destroy_read_struct");

my $number_version = Image::PNG::Libpng::access_version_number ();
ok ($number_version =~ /^\d+$/, "Numerical version number OK");
my $version = Image::PNG::Libpng::get_libpng_ver ();
$version =~ s/\./0/g;

# The following fails for older versions of libpng which seem to have
# a different numbering system.

if ($number_version > 100000) {
    ok ($number_version == $version,
        "Library version $number_version == $version OK");
}

# Read a file which is not correct. On version 0.02 this caused a core
# dump of Perl because of a mistake in the error handler in
# perl-libpng.c.tmpl. The error was fixed in 0.03 but this test is new
# in 0.04.

my $badpngfile = "$FindBin::Bin/libpng/xlfn0g04.png";
if (! -f $badpngfile) {
    die "You are missing a test file";
}
eval {
    open my $badfh, "<:raw", $badpngfile or die $!;
    my $badpng = Image::PNG::Libpng::create_read_struct ();
    $badpng->init_io ($badfh);
    $badpng->read_png ();
};
ok ($@, "Error reading bad PNG causes croak (not core dump)");
like ($@, qr/libpng error/, "Found string 'libpng error' in error message.");

eval {
    my $png_no_rows = Image::PNG::Libpng::create_write_struct ();
    $png_no_rows->set_IHDR ({
        width => 200,
        height => 200,
        bit_depth => 1,
        color_type => PNG_COLOR_TYPE_GRAY,
    });
    my @rows;
    $png_no_rows->set_rows (\@rows);
};
like ($@, qr/requires 200 rows/, "Produces error for empty \@rows");

eval {
    my $png_no_io_init = Image::PNG::Libpng::create_write_struct ();
    $png_no_io_init->set_IHDR ({
        width => 1,
        height => 1,
        bit_depth => 1,
        color_type => PNG_COLOR_TYPE_GRAY,
    });
    $png_no_io_init->set_rows ([0]);
    $png_no_io_init->write_png ($png_no_io_init);
};
like ($@, qr/Attempt to write PNG without calling init_io/,
      "Produces error on write if no output file has been set");
done_testing ();
exit;

# Local variables:
# mode: perl
# End:
