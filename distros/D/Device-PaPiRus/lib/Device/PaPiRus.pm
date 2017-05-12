package Device::PaPiRus;
#---AUTOPRAGMASTART---
use 5.012;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English qw( -no_match_vars );
use Carp;
our $VERSION = 1.3;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use Fatal qw( close );
#---AUTOPRAGMAEND---

use GD;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;

    my $self = \%config;

    bless $self, $class; # bless with our class

    # Let's load the display size
    if(defined($self->{debug}) && $self->{debug}) {
        # Debugging only, no actual device
        $self->{width} = 264;
        $self->{height} = 176;
    } else {
        open(my $ifh, '<', '/dev/epd/panel') or croak($OS_ERROR);
        my $line = <$ifh>;
        close $ifh;
        if($line =~ /\ (\d+)x(\d+)\ /) {
            ($self->{width}, $self->{height}) = ($1, $2);
        } else {
            croak("Can't read panel dimensions!");
        }
    }

    # Default
    $self->{threshold} = 150;
    $self->{randomize_white} = 0;
    $self->{randomize_black} = 0;
    $self->{dithering} = 0;
    $self->{greyscale} = 0;

    return $self;
}

sub getWidth {
    my ($self) = @_;

    return $self->{width};
}

sub getHeight {
    my ($self) = @_;

    return $self->{height};
}

sub randomizeWhite {
    my ($self, $val) = @_;

    $self->{randomize_white} = $val;
    return;
}

sub randomizeBlack {
    my ($self, $val) = @_;

    $self->{randomize_black} = $val;
    return;
}

sub useDithering {
    my ($self, $val) = @_;

    $self->{dithering} = $val;
    return;
}

sub useGreyscale {
    my ($self, $val) = @_;

    $self->{greyscale} = $val;
    return;
}

sub setThreshold {
    my ($self, $threshold) = @_;

    $threshold = 0 + $threshold;
    if($threshold < 0) {
        croak("Threshold can not be less than zero");
    } elsif($threshold > 255) {
        croak("Threshold can not be larger than 255");
    }
    $self->{threshold} = $threshold;
    return;
}

sub fullUpdate {
    my ($self, $img) = @_;

    my $panelImage;
    if($self->{dithering}) {
        $panelImage = $self->calculateDitheringImage($img);
    } elsif($self->{greyscale}) {
        $panelImage = $self->calculateGreyscaleImage($img);
    } else {
        $panelImage = $self->calculateImage($img);
    }   
    return $self->writeImage($panelImage, 'U');
}

sub partialUpdate {
    my ($self, $img) = @_;

    my $panelImage;
    if($self->{dithering}) {
        $panelImage = $self->calculateDitheringImage($img);
    } elsif($self->{greyscale}) {
        $panelImage = $self->calculateGreyscaleImage($img);
    } else {
        $panelImage = $self->calculateImage($img);
    }   
    return $self->writeImage($panelImage, 'P');
}

sub writeImage {
    my ($self, $img, $mode) = @_;

    if(defined($self->{debug}) && $self->{debug}) {
        # Debugging only, no actual device
        return;
    }
    
    open(my $ofh, '>', '/dev/epd/display') or croak($!);
    binmode $ofh;
    print $ofh $img;
    close $ofh;

    open(my $cfh, '>', '/dev/epd/command') or croak($!);
    print $cfh $mode;
    close $cfh;

    return;
}

sub calculateImage {
    my ($self, $img) = @_;
    my $outimg = '';

    my ($sourcewidth, $sourceheight) = $img->getBounds();
    if($sourcewidth != $self->{width} || $sourceheight != $self->{height}) {
        croak('Image dimensions (' . $sourcewidth . 'x' . $sourceheight . ') do not match panel size (' . $self->{width} . 'x' . $self->{height} . ')!');
    }

    # We need to read 8 pixels of the image in one go, turn them into pure black&white bits and stuff the 8 of them into a single byte,
    # correcting for endianess and all that...
    for(my $y = 0; $y < $self->{height}; $y++) {
        for(my $x = 0; $x < ($self->{width} / 8); $x++) {
            my $buf = '';
            for(my $offs = 0; $offs < 8; $offs++) {
                my $index = $img->getPixel(($x*8) + $offs,$y);
                my ($r,$g,$b) = $img->rgb($index);
                my $grey = int(($r+$g+$b)/3);
                if($grey > $self->{threshold}) {
                    if($self->{randomize_white} && int(rand(10000)) % 4 == 0) {
                        $buf .= "1";
                    } else {
                        $buf .= "0";
                    }
                } else {
                    if($self->{randomize_black} && int(rand(10000)) % 4 == 0) {
                        $buf .= "0";
                    } else {
                        $buf .= "1";
                    }
                }
            }
            my $byte = pack('b8', $buf);
            $outimg .= $byte;
        }
    }

    return $outimg;
}

sub calculateGreyscaleImage {
    my ($self, $img) = @_;
    my $outimg = '';

    my ($stepsize, @greys);
    if($self->{greyscale} == 1) {
        $stepsize = 2;
        @greys = ('0000', '1000', '1010', '1110', '1111');
    } elsif($self->{greyscale} == 2) {
        $stepsize = 3;
        @greys = (
            '000000000',
            '000010000',
            '100000001',
            '010101000',
            '001010110',
            '101010101',
            '010101111',
            '011111110',
            '111101111',
            '111111111',
        );
    } elsif($self->{greyscale} == 3) {
        $stepsize = 4;
        @greys = (
            '0000000000000000',
            '0000000001000000',
            '0000100000100000',
            '0010000001000001',
            '1000001000101000',
            '1010000000010110',
            '0001010001101010',
            '1010110010100100',
            '1010010101101010',
            '1001011001011011',
            '1001011110101101',
            '1101101001111110',
            '1011111001111011',
            '1011011111101111',
            '1111011111101111',
            '1111111110111111',
            '1111111111111111',
        );
    } else {
        croak("Greyscale mode " . $self->{greyscale} . " not implemented!");
    }

    my ($sourcewidth, $sourceheight) = $img->getBounds();
    if($sourcewidth != $self->{width} || $sourceheight != $self->{height}) {
        croak('Image dimensions (' . $sourcewidth . 'x' . $sourceheight . ') do not match panel size (' . $self->{width} . 'x' . $self->{height} . ')!');
    }



    # Init array with the greyscale pixel value of the image
    my @opixel;
    my @npixel;
    for(my $x = 0; $x < $self->{width}; $x++) {
        my @oline;
        my @nline;
        for(my $y = 0; $y < $self->{height}; $y++) {
            my $index = $img->getPixel($x, $y);
            my ($r,$g,$b) = $img->rgb($index);
            my $oldpixel = int(($r+$g+$b)/3);
            push @oline, $oldpixel;
            push @nline, 0;
        }
        $opixel[$x] = \@oline;
        $npixel[$x] = \@nline;
    }


    # Run greyscale
    for(my $y = 0; $y < $self->{height} - ($stepsize - 1); $y+= $stepsize) {
        for(my $x = 0; $x < $self->{width} - ($stepsize - 1); $x+= $stepsize) {
            my $oldpixel = 0;
            for(my $ox = 0; $ox < $stepsize; $ox++) {
                for(my $oy = 0; $oy < $stepsize; $oy++) {
                    $oldpixel += $opixel[$x + $ox]->[$y + $oy];
                }
            }
            $oldpixel = $oldpixel / ($stepsize * $stepsize); # Average

            my $offs = int($oldpixel / (256 / (($stepsize * $stepsize) + 1)));
            my @greypixel = split//, $greys[$offs];

            for(my $ox = 0; $ox < $stepsize; $ox++) {
                for(my $oy = 0; $oy < $stepsize; $oy++) {
                    $npixel[$x + $ox]->[$y + $oy] = $greypixel[($ox * $stepsize) + $oy];
                }
            }
        }
    }

    # We need to read 8 pixels of the image in one go, turn them into pure black&white bits and stuff the 8 of them into a single byte,
    # correcting for endianess and all that...
    for(my $y = 0; $y < $self->{height}; $y++) {
        for(my $x = 0; $x < ($self->{width} / 8); $x++) {
            my $buf = '';
            for(my $offs = 0; $offs < 8; $offs++) {
                my $raw = $npixel[($x * 8) + $offs]->[$y];
                if($raw >= 0.5) {
                    $buf .= '0';
                } else {
                    $buf .= '1';
                }
            }
            my $byte = pack('b8', $buf);
            $outimg .= $byte;
        }
    }

    return $outimg;
}

sub calculateDitheringImage {
    my ($self, $img) = @_;
    my $outimg = '';

    my ($stepsize, @greys);
    if($self->{dithering} == 1) {
        $stepsize = 2;
        @greys = ('0000', '1000', '1010', '1110', '1111');
    } elsif($self->{dithering} == 2) {
        $stepsize = 3;
        @greys = (
            '000000000',
            '000010000',
            '100000001',
            '010101000',
            '001010110',
            '101010101',
            '010101111',
            '011111110',
            '111101111',
            '111111111',
        );
    } elsif($self->{dithering} == 3) {
        $stepsize = 4;
        @greys = (
            '0000000000000000',
            '0000000001000000',
            '0000100000100000',
            '0010000001000001',
            '1000001000101000',
            '1010000000010110',
            '0001010001101010',
            '1010110010100100',
            '1010010101101010',
            '1001011001011011',
            '1001011110101101',
            '1101101001111110',
            '1011111001111011',
            '1011011111101111',
            '1111011111101111',
            '1111111110111111',
            '1111111111111111',
        );
    } else {
        croak("Greyscale mode " . $self->{greyscale} . " not implemented!");
    }

    my ($sourcewidth, $sourceheight) = $img->getBounds();
    if($sourcewidth != $self->{width} || $sourceheight != $self->{height}) {
        croak('Image dimensions (' . $sourcewidth . 'x' . $sourceheight . ') do not match panel size (' . $self->{width} . 'x' . $self->{height} . ')!');
    }



    # Init array with the greyscale pixel value of the image
    my @opixel;
    my @npixel;
    for(my $x = 0; $x < $self->{width}; $x++) {
        my @oline;
        my @nline;
        for(my $y = 0; $y < $self->{height}; $y++) {
            my $index = $img->getPixel($x, $y);
            my ($r,$g,$b) = $img->rgb($index);
            my $oldpixel = int(($r+$g+$b)/3);
            push @oline, $oldpixel;
            my @tmp;
            push @nline, \@tmp;
        }
        $opixel[$x] = \@oline;
        $npixel[$x] = \@nline;
    }


    # Run greyscale FOR EACH PIXEL
    for(my $y = 0; $y < $self->{height}; $y++) {
        for(my $x = 0; $x < $self->{width}; $x++) {
            my $oldpixel = 0;
            my $count = 0;
            for(my $ox = 0; $ox < $stepsize; $ox++) {
                for(my $oy = 0; $oy < $stepsize; $oy++) {
                    if(($x + $ox) < $self->{width} && ($y + $oy) < $self->{height}) {
                        $oldpixel += $opixel[$x + $ox]->[$y + $oy];
                        $count++
                    }
                }
            }
            next unless $count;
            $oldpixel = $oldpixel / $count; # Average

            my $offs = int($oldpixel / (256 / (($stepsize * $stepsize) + 1)));
            my @greypixel = split//, $greys[$offs];

            for(my $ox = 0; $ox < $stepsize; $ox++) {
                for(my $oy = 0; $oy < $stepsize; $oy++) {
                    push @{$npixel[$x + $ox]->[$y + $oy]}, $greypixel[($ox * $stepsize) + $oy];
                }
            }
        }
    }

    #print Dumper (\@npixel);
    #die;

    # We need to read 8 pixels of the image in one go, turn them into pure black&white bits and stuff the 8 of them into a single byte,
    # correcting for endianess and all that...
    # We have multiple b&w values for each pixel. We need to add them up and decide if it really is B or W
    for(my $y = 0; $y < $self->{height}; $y++) {
        for(my $x = 0; $x < ($self->{width} / 8); $x++) {
            my $buf = '';
            for(my $offs = 0; $offs < 8; $offs++) {
                #my $raw = $npixel[($x * 8) + $offs]->[$y];

                my @vals = @{$npixel[($x * 8) + $offs]->[$y]};
                my $raw = 0;
                foreach my $val (@vals) {
                    $raw += $val;
                }
                if(scalar @vals) {
                    $raw = $raw / (scalar @vals);
                }

                if($raw >= 0.5) {
                    $buf .= '0';
                } else {
                    $buf .= '1';
                }
            }
            my $byte = pack('b8', $buf);
            $outimg .= $byte;
        }
    }

    return $outimg;
}

1;
__END__

=head1 NAME

Device::PaPiRus - Raspberry Pi "PaPiRus" e-paper display

=head1 SYNOPSIS

  use Device::PaPiRus;
  use GD;
  
  my $img = GD::Image->new('cvc.png');
  my $papirus = Device::PapiRus->new();

  $papirus->setThreshold(100);
  $papirus->fullUpdate($img);
  

=head1 DESCRIPTION

Device::PaPiRus is a library to use the PaPiRus e-paper display from Perl
with the help of the GD image library.

The Image must match the size of the panel exactly. Also the transformation to a single-bit black&white image in
this library is rather simple: take the average of R+G+B to make it greyscale, then see if it's above the given
threshold.

While the implementation is simple, it still allows you a few simple "animations" with whatever framerate you can get out of your panel. For example, if
you have a white-to-black gradient in the image, you can move the threshold and repaint the image to make a simple "moving" animation. Also, you can set
either randomize the white or black pixels while repainting the image over and over again. Nothing fancy, for more elaborate stuff look into the GD
library itself.

=head1 FUNCTIONS

=head2 new

Takes no arguments. Checks for a display panel and reads out its size.

=head2 getWidth

Returns the width of the panel in pixels.

=head2 getHeight

Returns the height of the panel in pixels.

=head2 setThreshold

Sets the threshold of where black ends and white begins. Default: 150

=head2 randomizeWhite

A true value means white pixels are randomized. Default: false

=head2 randomizeBlack

A true value means black pixels are randomized. Default: false

=head2 useGreyscale

Use a pseudo-greyscale implementation with handcoded disthering. Default: 0

The following values are supported

    0 ... disables
    1 ... 2x2 pixel grid
    2 ... 3x3 pixel grid
    3 ... 4x4 pixel grid

When greyscale is enabled, it ignores randomizeWhite, randomizeBlack and setThreshold.

=head2 useDithering

Use an experimental dithering implementation, which may or (most likely) may not work. Default: 0

The following values are supported

    0 ... disables
    1 ... 2x2 pixel grid
    2 ... 3x3 pixel grid
    3 ... 4x4 pixel grid

When dithering is enabled, it ignores randomizeWhite, randomizeBlack, setThreshold and useGreyscale.

=head2 fullUpdate

Does a "full" update of the display panel (complete clearing by inverting pixels and stuff). Slow and annoying, but
guarantuees that all pixels are nice, shiny and in the correct color.

=head2 partialUpdate

Does a "partial" update of the display panel. This only overwrites pixels that have changed. A bit quicker than a full
update, no annoying going-to-black-and-back flicker, but may leave artifacts. If you need "quick" screen updates for a demo,
a partial update is the way to go. If you want very crisp text, you should choose a full update, at least every few screen
updates.

=head1 INSTALLATION NOTES

This module uses the EPD fuse module from the rePaper project for low level device access. Something like this should
get you going on Raspbian:

First, enable SPI in raspi-config (make sure it's loaded on boot).

Then:

  sudo apt-get install libfuse-dev python-imaging python-setuptools
  sudo easy_install pip

  git clone https://github.com/repaper/gratis.git
  cd gratis/PlatformWithOS
  make PANEL_VERSION=V231_G2 rpi-epd_fuse
  sudo make PANEL_VERSION=V231_G2 rpi-install

The next step is to edit /etc/default/epd-fuse. Make sure you got the correct panel size (EPD_SIZE) selected (for example 2.7).

Then reboot. If there is a problem, try 

  sudo service epd-fuse start

There's also a manual from Adafruit here: L<https://learn.adafruit.com/repaper-eink-development-board-arm-linux-raspberry-pi-beagle-bone-black?view=all>. Beware, the
Adafruit manual is based on a slightly older library and uses a slightly different panel.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2016 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
