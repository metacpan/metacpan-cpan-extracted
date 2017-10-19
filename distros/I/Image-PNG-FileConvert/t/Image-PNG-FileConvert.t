use warnings;
use strict;
use Test::More tests => 4;
BEGIN { use_ok('Image::PNG::FileConvert') };
use Image::PNG::FileConvert qw/file2png png2file/;
use FindBin '$Bin';
use File::Compare;

my $infile = "$Bin/Image-PNG-FileConvert.t";
round_trip ($infile);
exit;
#done_testing ();

=head2 round_trip

    round_trip ($file);

Turn a file into a PNG, then turn it back into itself, and compare the
input file with the output file.

=cut

sub round_trip
{
    my ($file) = @_;
    my $test_png = "$Bin/test.png";
    my $back = "$Bin/back";
    for my $tempfile ($test_png, $back) {
        if (-f $tempfile) {
            unlink $tempfile;
        }
    }
    file2png ($file, $test_png, {name => $back,
                                 row_length => 0x100,
                                 verbose => 1});
    ok (-f $test_png, "PNG file output OK");
    png2file ($test_png, verbose => 1);
    ok (-f $back, "File '$back' exists");
    ok (compare ($back, $file) == 0, "Round trip output is equal to input");
    if (-f $back) {
	unlink $back;
    }
}

# Local variables:
# mode: perl
# End:
