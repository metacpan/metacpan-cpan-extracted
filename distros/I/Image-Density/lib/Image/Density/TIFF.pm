#
# Image::Density::TIFF
#
#   Calculate the density of a TIFF image in a way that helps estimate scanned
#   image quality.
#
# Copyright (C) 2003-2012 Gregor N. Purdy, Sr. All rights reserved.
# This program is free software. It is subject to the same license as Perl.
#
# $Id$
#

=head1 NAME

Image::Density::TIFF

=head1 SYNOPSIS

  use Image::Density::TIFF;
  print "Density: %f\n", tiff_density("foo.tif"); # single-page
  print "Densities: ", join(", ", tiff_densities("bar.tif")), "\n"; # multi-page

=head1 DESCRIPTION

A trivial density calculation would count the number of black pixels and
divide by the total number of pixels. However, it would produce misleading
results in the case where the image contains one or more target areas with
scanned content and large blank areas in between (imagine a photocopy of a
driver's license in the middle of a page).

The metric implemented here estimates the density of data where there I<is>
data, and has a
reasonable correlation with goodness as judged by humans. That is, if you
let a human look at a set of images and judge quality, the density values for
those images as calculated here tend to correlate well with the human
judgement (densities that are too high or too low represent "bad" images).

This algorithm is intended for use on bitonal TIFF images, such as those from
scanning paper documents.

=head2 The calculation

We omit the margins because there is likely to be noise there, such as black
strips due to page skew. This does admit the possibility that we are skipping
over something important, but the margin skipping here worked well on the
test images.

Leading and trailing white on a row are omitted from counting, as are runs of
white at least as long as the margin width. This helps out when we have images
with large blank areas, but decent density within the areas filled in, which
is what we really care about.

=head1 AUTHOR

Gregor N. Purdy, Sr. <gnp@acm.org>

=head1 COPYRIGHT

Copyright (C) 2003-2012 Gregor N. Purdy, Sr. All rights reserved.

=head1 LICENSE

This program is free software. Its use is subject to the same license as Perl.

=cut

use strict;
use warnings 'all';

package Image::Density::TIFF;

use MAS::TIFF::File;

our $VERSION = '0.3';

BEGIN {
  use Exporter;
  use vars qw(@ISA @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT = qw(&tiff_density &tiff_densities);
}

my $MARGIN_FACTOR = 20;

sub tiff_directory_density {
  use integer;
  
  my $t = shift;
  
  die "Could not open file for reading" unless defined $t;
  
  my $bps = $t->bits_per_sample;
  
  die "Could not determine TIFF bits per sample file for reading" unless defined $bps;
  
  die "Cannot process TIFF files with more than on ebit per sample!" unless $bps == 1;
  
  my $spp = $t->samples_per_pixel;
  
  my $w = $t->image_width;
  my $h = $t->image_length;
  
  my $w_margin = $w / $MARGIN_FACTOR;
  my $h_margin = $h / $MARGIN_FACTOR;
  
  my $black = 0;
  my $white = 0;
  
  #
  # We omit the top and bottom margins because there is likely to be noise there,
  # such as black strips due to page skew.
  #
  # We have to read the first h_margin rows, rather than skip them, because the
  # TIFF file's compression algorithm might not support random access.
  #

  my $scan_line_reader = $t->scan_line_reader;
  
  for (my $i = $h_margin; $i < ($h - $h_margin); $i++) {    
    #
    # We omit the left and right margins because there is likely to be noise there,
    # such as black strips due to page skew.
    #
    # The setup of last_sample and run_length simulates a leading white run long
    # enough that any actual leading white, no matter how much, will be omitted.
    #

    my $row_black = 0;
    my $row_white = 0;
    my $last_sample = 0;
    my $run_length = $w_margin;
    
    my $scan_line = &$scan_line_reader($i);
    
    for (my $j = $w_margin; $j < ($w - $w_margin); $j++) {
      my $byte_index = $j / 8;
      my $byte = vec($scan_line, $byte_index, 8);
      my $bit_index = 7 - ($j % 8);
      my $bit = ($byte >> $bit_index) & 0x01;
      my $sample = !$bit;
  
      #
      # We don't count row white until we see black. This omits leading and trailing
      # white on the row, which helps out when we have images with large blank areas,
      # but decent density within the areas filled in, which is what we really care
      # about.
      #
      # We also don't count row_white when it is greater than the margin, since that
      # amounts to a "large" empty space, and we really want the density of *data*,
      # where there *is* data.
      #
      
      if ($sample == $last_sample) {
        $run_length++;
      }
      else {
        if ($run_length < $w_margin) {
          if ($last_sample) {
            $row_black += $run_length;
          }
          else {
            $row_white += $run_length;
          }
        }

        $last_sample = $sample;
        $run_length = 1;
      }
    }
    
    if ($run_length < $w_margin) {
      if ($last_sample) {
        $row_black += $run_length;
      }

      # We don't add trailing white runs to the row's total
    }
  
    $white += $row_white;
    $black += $row_black;
  }
  
  my $density;
  
  if ($black + $white > 0) {
    no integer;
    $density = $black / ($black + $white);
  }
  else {
    $density = -1.0;
  }

  return $density;
}

sub tiff_density {
  my $file_name = shift;
  
  my $tiff = MAS::TIFF::File->new($file_name);

  my ($first_ifd, ) = $tiff->ifds;
  
  my $density = tiff_directory_density($first_ifd);
  
  $tiff->close;
  
  undef $tiff;
  
  return $density;
}

sub tiff_densities {
  my $file_name = shift;
  
  my $tiff = MAS::TIFF::File->new($file_name);

  my @densities = map { $_ = tiff_directory_density($_) } $tiff->ifds;
  
  $tiff->close;
  
  undef $tiff;
  
  return @densities;
}

1;

