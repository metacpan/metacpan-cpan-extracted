#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Image::PNG::Libpng ':all';
my $file = "wave.png";
my $ncolors = 40;
my $palette = randompalette ($ncolors);
write_with_palette ($file, $palette, $ncolors, [], "random");
my $picked = points ($file, $ncolors);
my @hist = (1) x $ncolors;
write_with_palette ($file, $picked, $ncolors, \@hist, "picked");
exit;

sub write_with_palette
{
    my ($file, $palette, $ncolors, $hist, $name) = @_;
    my $rpng = create_reader ($file);
    $rpng->set_quantize ($palette, $ncolors, $hist, 1);
    $rpng->read_png ();
    my $wpng = copy_png ($rpng);
    $wpng->set_PLTE ($palette);
    $wpng->write_png_file ("$name-$file");
}

sub points
{
    my ($pngfile, $ncolors) = @_;
    my $png = read_png_file ($pngfile);
    my $rows = $png->get_rows ();
    my $h = $png->height ();
    my $w = $png->width ();
    my $ch = $png->get_channels ();
    my @p;
    for (0..$ncolors-1) {
	my $x = int (rand ($w));
	my $y = int (rand ($h));
	my $row = $rows->[$y];
	my @pix = split ('', substr ($row, $x*$ch, $ch));
	push @p, {
	    red => ord ($pix[0]),
	    green => ord ($pix[1]),
	    blue => ord ($pix[2]),
	};
    }
    return \@p;
}

sub randompalette
{
    my ($n) = @_;
    my @p;
    for (0..$n-1) {
	my %color;
	for my $c (qw!red green blue!) {
	    $color{$c} = int (rand (256))
	}
	push @p, \%color;
    }
    return \@p;
}
