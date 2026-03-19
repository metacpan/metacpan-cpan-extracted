use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use lib '../blib/lib';
use lib '../blib/arch';
use Image::PNG::Libpng qw/read_png_file copy_png image_data_diff/;
my $dir = "$Bin/../t/libpng";
my @files = do { opendir my $dh, $dir or die "opendir $dir: $!"; grep !/^\.{1,2}$/ && /\.png$/, readdir $dh };

# Switch to a true value for debugging. This was originally related to
# the problems with the files listed in %broken below.

my $verbose;
#my $verbose = 1;

# Files beginning with an x are corrupted.
# http://www.schaik.com/pngsuite/#corrupted
@files = grep !/^x/, @files;

# These files seem to not match the current version of libpng, even
# though they come from the PNG test suite. The error looks like this:

# libpng warning: IDAT: Too many IDATs found

# More details on the file contents is here:

# http://www.schaik.com/pngsuite/pngsuite_ord_png.html

# Skipping the test for these.

my %broken = (
    'oi9n0g16.png' => 1,
    'oi9n0c16.png' => 1,
    'oi9n2c16.png' => 1,
);

for my $file (@files) {
    if ($broken{$file}) {
	next;
    }
    copytest ("$dir/$file");
}

done_testing ();

sub copytest
{
    my ($infile) = @_;
    if ($verbose) {
	print "Copy test for '$infile'.\n";
    }
    my $copytest = "$Bin/copy-png-test.png";
    my $png1 = read_png_file ($infile);
    my $png2 = $png1->copy_png ();
    $png2->write_file ($copytest);
    my $diff = image_data_diff ($copytest, $infile);
    my $tinfile = $infile;
    $tinfile =~ s!.*/!!;
    ok (! $diff, "$tinfile copied OK");
    if ($diff) {
	note ($diff);
    }
    if (-f $copytest) {
	unlink $copytest;
    }
    if ($verbose) {
	print "Finished copy test for '$infile'.\n";
    }
}

