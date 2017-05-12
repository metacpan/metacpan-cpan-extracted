# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Device::PCD8544::ConvertImage;
$Device::PCD8544::ConvertImage::VERSION = '0.0268329147520525';
use v5.14;
use warnings;
use Device::PCD8544::Exceptions;

use constant WIDTH  => 84;
use constant HEIGHT => 48;


sub convert
{
    my ($img) = @_;
    my $width = $img->getwidth;
    my $height = $img->getheight;
    if( ($width != WIDTH) || ($height != HEIGHT) ) {
        Device::PCD8544::ImageSizeException->throw( 'Width/height is'
            . " $width/$height"
            . ', expected is ' . WIDTH . '/' . HEIGHT
            . '.  Please rescale image.' );
    }

    my @lcd_bitmap = ();
    
    my $total_pixels = $width * $height;
    for( my $i = 0; $i < $total_pixels; $i += 8 ) {
        my $max_i = $i + 7;
        $max_i    = $total_pixels - 1 if $max_i >= $total_pixels;
        my @pixels = _get_pixels( $img, $width, $height, $i, $max_i );

        my $val = $pixels[0];
        foreach my $j (1 .. 7) {
            $val <<= 1;
            $val |= $pixels[$j];
        }

        push @lcd_bitmap, $val;
    }

    return \@lcd_bitmap;
}


sub _get_pixels
{
    my ($img, $width, $height, $i_min, $i_max) = @_;

    my @pixels;
    foreach my $i ($i_min .. $i_max) {
        my $x = $i % $width;
        my $y = int( $i / $width );
        my $pixel = $img->getpixel( x => $x, y => $y );
        my ($r, $g, $b, $a) = $pixel->rgba;
        my $val = ($r || $g || $b) ? 0 : 1;
        push @pixels, $val;
    }

    return @pixels;
}


1;
__END__

=head1 NAME

  Device::PCD8544::ConvertImage - Convert an image to the format for the PCD8544 LCD

=cut
