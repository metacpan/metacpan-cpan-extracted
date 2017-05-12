package Image::Button::Plain;

# $Id: Plain.pm,v 1.6 2003/03/04 15:58:15 joanmg Exp $

use strict;
use vars qw(@ISA $VERSION);

$VERSION = "0.53";


use Image::Button;
@ISA = qw(Image::Button);

use GD 1.20;


# This only sets defaults, overriding defaults in SUPER::allocate
sub allocate
{
    my $self = shift;
    my %args = (border  => 1,
                btcolor => undef,
                @_,);
    $self->SUPER::allocate(%args);
}

sub print
{
    my $self = shift;
    my %args = (file    => $self->{file},
                prefix  => '',
                postfix => '',
                @_,);

    my $file = $args{file}; die "Need output file\n" unless $file;
    $file = $self->buildFile(%args);

    my $text  = $self->{text};
    my $font  = $self->{font};     die "Need font\n"      unless $font;
    my $size  = $self->{fontsize}; die "Need font size\n" unless $size;
    my $fgcol = $self->{fgcolor};  die "Need fg color\n"  unless $fgcol;
    my $bgcol = $self->{bgcolor};  # Only as a possible default for btcol

    # Button color defaults to background
    my $btcol = $self->{btcolor};  $btcol = $bgcol unless $btcol;
    # Border color defaults to button color
    my $bdcol = $self->{bdcolor};  $bdcol = $btcol unless $bdcol;

    my $vmarg  = $self->{vmargin}; $vmarg = 4  unless defined $vmarg;
    my $hmarg  = $self->{hmargin}; $hmarg = 4  unless defined $hmarg;
    my $border = $self->{border};

    $font = $self->getFont($font);

    # Compute bounds
    my @bounds = &GD::Image::stringFT('GD::Image', 0, $font,
                                      $size, 0, 0, 0, $text);
    # @bounds[0,1]  Lower left corner (x,y)
    # @bounds[2,3]  Lower right corner (x,y)
    # @bounds[4,5]  Upper right corner (x,y)
    # @bounds[6,7]  Upper left corner (x,y)

    if (!@bounds) {
        die "Error figuring out bounds for '$text': $@\n";
    }

    # We need the text width to center it later on, in case tw has come
    # defined (this happens when we want several buttons to share the
    # same width).
    my $thisTw = $bounds[2] - $bounds[0];
    my $thisTh = $bounds[1] - $bounds[7];
    my $th = $self->{texth};
    my $tw = $self->{textw};
    $th = $th ? $th : $thisTh;
    $tw = $tw ? $tw : $thisTw;

    # How much it goes down under the reference line
    my $moveUp = $bounds[1] / 2;
    if ($th != $thisTh) {
        $moveUp += ($th - $thisTh)/2;
        #$moveUp += $border;
    }

    # Figure out sizes and build image
    my $w = $tw + 2 * ($hmarg + $border);
    my $h = $th + 2 * ($vmarg + $border);

    my $img = new GD::Image($w, $h);

    # Build and allocate colors
    my @dk  = map { int($_/1.75) }  @$btcol; # dark (shadows)
    my @lt  = map { int($_ * 1.2) } @dk;     # light shadow
    my @vlt = map { int($_ * 1.5) } @dk;     # very light shadow

    my $abt    = $img->colorAllocate(@$btcol);
    my $afg    = $img->colorAllocate(@$fgcol);
    my $abd    = $img->colorAllocate(@$bdcol);
    my $awhite = $img->colorAllocate(255, 255, 255);

    $img->fill(0, 0, $abt);

    # Border
    for (my $b=0; $b<$border; $b++) {
        $img->line($b,      $b,      $w-$b-1, $b,      $abd);  # top
        $img->line($b,      $b,      $b,      $h-$b-1, $abd);  # left
        $img->line($b,      $h-$b-1, $w-$b-1, $h-$b-1, $abd);  # bottom
        $img->line($w-$b-1, $b,      $w-$b-1, $h-$b-1, $abd);  # right
    }

    $img->stringFT($afg, $font, $size, 0,
                   $w/2 - $thisTw/2, $h-$border-$vmarg-$moveUp, $text) ||
                       die "Rendering of '$text' did not work: $@\n";

    open FOUT, ">$file" || die "Could not open $file for writing\n";
    binmode FOUT;
    print FOUT $img->png;
    close FOUT;
}

# Overrides Button::getSize
sub getSize
{
    my $self = shift;
    my ($w, $h) = $self->SUPER::getSize;

    return ($w+2*$self->{border}, $h+2*$self->{border});
}

# Overrides Button::textSize
sub textSize
{
    my $self = shift;
    my %args = (texth => undef,
                textw => undef,
                @_,);
    $self->{texth} = $args{texth};
    $self->{texth} -= 2*$self->{border} if $self->{texth};
    $self->{textw} = $args{textw};
    $self->{textw} -= 2*$self->{border} if $self->{textw};
}

1;

=head1 NAME

Image::Button::Plain - Builds plain rectangular PNG buttons

=head1 SYNOPSIS

  use Image::Button::Plain;

  my $b1 = new Image::Button::Plain(text     => 'text b1',
                                    font     => 'newsgotn.ttf',
                                    fontsize => 20,
                                    bdcolor  => [0, 0, 0], # border
                                    file     => 'b1.png');

  $b1->print;

=head1 DESCRIPTION

Builds a plain vanilla rectangular button, with an optional border,
using GD with TrueType support.  See F<Image::Button> for more details
about things you can do with Buttons.

=head2 Constructor

    my $b = new Image::Button::Plain(text     => 'text',
                                     font     => 'newsgotn.ttf',
                                     fontsize => 20,
                                     file     => 'file.png');

The arguments are

=over 4

=item text => 'button text'

Defaults to ''.

=item font => 'something.ttf'

The TrueType font with which to print.  It should be localted either
in the current directory or in the directory pointed at by the
environment variable I<TTFONTS>.  Mandatory.

=item fontsize => 12

Font size.  Defaults to 12 points.

=item file => 'button.png'

File where the button will be saved.  Can be overridden in the print
function.  Mandatory if you plan to use F<Image::Button::Set> to
output several related buttons at a time.  Defaults to the button
text, replacing spaces by '-'.  Use '>-' if you want to send the image
to standard output.

=item bgcolor => [ 255, 255, 255 ]

Background color in RGB (so [255,255,255] is white and [0,0,0] is
black).  Defaults to [255,255,255].  Used only as a default for
btcolor, down there, for compatibility with other button types.

=item btcolor => [ 238, 238, 204 ]

Button color in RGB .  Defaults to the background color, which in turn
defaults to white.

=item fgcolor => [ 0, 0, 0 ]

Foreground (text) color in RGB.  Defaults to [0,0,0].

=item bdcolor => [ 0, 0, 0 ]

Border color in RGB.  Defaults to the button color, so if you don't
set it you'll get a solid rectangle of btcolor.

=item border => 1

Border size in pixels.  Note that if you want to see the border you
have to set the border color with bdcolor.  Defaults to 1.

=item vmargin => 4

Vertical margin under and over the text.  Defaults to 4 pixels.

=item hmargin => 4

Horizontal margin left and right of the text.  Defaults to 4 pixels.

=back

=head1 SEE ALSO

F<Image::Button> for a description of how to make buttons, and other
functions you can use with Image::Button::Plain.

F<Image::Button::Set> for building sets of related buttons.

=head1 AUTHOR

Juan M. García-Reyero E<lt>joanmg@twostones.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2003 Juan M. García-Reyero.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


