#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';
my $outfile = "$Bin/mono.png";
my ($height, $width, $rows) = pixelate (__FILE__, 5);
my $png = create_write_struct ();
open my $out, ">:raw", $outfile or die $!;
$png->init_io ($out);
$png->set_IHDR ({height => $height, width => $width, bit_depth => 1,
                 color_type => PNG_COLOR_TYPE_GRAY});
$png->set_text ([{key => 'silly', text => 'finely-tuned breakfast cereal',}]);
$png->set_tIME ({year => 1999});
$png->write_info ();
$png->set_invert_mono ();
# PNG puts the leftmost pixel in the high-order part of the byte.
$png->set_packswap ();
$png->write_image ($rows);
$png->write_end ();
close $out or die $!;
exit;

sub pixelate
{
    my ($file, $box) = @_;
    open my $in, "<", $file or die "Can't open '$file': $!";
    my $width = 0;
    my @lines;
    while (<$in>) {
        chomp;
	s/\t/        /g;
        push @lines, $_;
        if (length ($_) > $width) {
            $width = length ($_);
        }
    }
    close $in or die $!;
    $width *= $box;
    my $height = scalar (@lines) * $box;
    my $zero = pack "C", 0;
    my $bwidth = int(($width+7)/8);
    my @rows = ($zero x $bwidth) x $height;
    for my $r (0..$height-1) {
	my $y = int ($r/$box);
        my $line = $lines[$y];
        for my $x (0..length ($line) - 1) {
            if (substr ($line, $x, 1) ne ' ') {
		for my $c (0..$box - 1) {
		    my $offset = $x*$box + $c;
		    my $byte = int ($offset / 8);
		    my $bit = $offset % 8;
		    my $octet = ord (substr ($rows[$r], $byte, 1));
		    substr ($rows[$r], $byte, 1) = chr ($octet | 1<<$bit);
		}
	    }
	}
    }
    return ($height, $width, \@rows);
}
