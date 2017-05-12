package Image::Button::Rect;

# $Id: Rect.pm,v 1.5 2003/03/04 15:58:15 joanmg Exp $

use strict;
use vars qw(@ISA $VERSION);

$VERSION = "0.53";


use Image::Button;
@ISA = qw(Image::Button);

use GD 1.20;

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

    my $font  = $self->{font};     die "Need font\n"         unless $font;
    my $size  = $self->{fontsize}; die "Need font size\n"    unless $size;
    my $btcol = $self->{btcolor};  die "Need button color\n" unless $btcol;
    my $bgcol = $self->{bgcolor};  die "Need bg color\n"     unless $bgcol;
    my $fgcol = $self->{fgcolor};  die "Need fg color\n"     unless $fgcol;
    my $vmarg = $self->{vmargin};  $vmarg = 4 unless defined $vmarg;
    my $hmarg = $self->{hmargin};  $hmarg = 4 unless defined $hmarg;

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

    # We need the text width to center it later on in case tw has come
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
    }

    # Figure out sizes and build image
    my $w = $tw + 2 * $hmarg + 4;  # shadows are 2 pixels wide
    my $h = $th + 2 * $vmarg + 5;  # shadows are 2 and 3 pixels tall

    my $img = new GD::Image($w, $h);

    # Build and allocate colors
    my @dk  = map { int($_/1.75) }  @$btcol; # dark (shadows)
    my @lt  = map { int($_ * 1.2) } @dk;     # light shadow
    my @vlt = map { int($_ * 1.5) } @dk;     # very light shadow

    my $abt  = $img->colorAllocate(@$btcol);
    my $abg  = $img->colorAllocate(@$bgcol);
    my $afg  = $img->colorAllocate(@$fgcol);
    my $adk  = $img->colorAllocate(@dk);
    my $alt  = $img->colorAllocate(@lt);
    my $avlt = $img->colorAllocate(@vlt);
    my $awhite = $img->colorAllocate(255, 255, 255);

    $img->fill(0, 0, $abg);

    # Dark border
    $img->line(1,    0,    $w-3, 0,    $adk);  # top
    $img->line(0,    1,    0,    $h-2, $adk);  # left
    $img->line(2,    $h-2, $w-2, $h-2, $adk);  # bottom
    $img->line($w-2, $h-2, $w-2, 1,    $adk);  # right

    # Light shadow
    $img->line(1, $h-1, $w-2, $h-1, $alt);  # bottom

    # Very light shadow
    $img->line(3, $h-3, $w-4, $h-3, $avlt);  # bottom
    $img->line($w-1, 2, $w-1, $h-2, $avlt);  # right
    
    # Fill up the button
    $img->fill(int($w/2), int($h/2), $abt);

    # White shadow
    $img->line(1, 1, 1, $h-2, $awhite);  # left
    $img->line(1, 1, $w-3, 1, $awhite);  # left

    $img->stringFT($afg, $font, $size, 0,
                   $w/2 - $thisTw/2, $h-3-$vmarg-$moveUp, $text) ||
                       die "Rendering of '$text' did not work: $@\n";

    open FOUT, ">$file" || die "Could not open $file for writing\n";
    binmode FOUT;
    print FOUT $img->png;
    close FOUT;
}

# Overrides Button::getSize.
sub getSize
{
    my $self = shift;
    my ($w, $h) = $self->SUPER::getSize;
    return ($w+4, $h+5);  # Increase with the shadow size
}

# Overrides Button::textSize
sub textSize
{
    my $self = shift;
    my %args = (texth => undef,
                textw => undef,
                @_,);
    $self->{texth} = $args{texth}; $self->{texth} -= 4 if $self->{texth};
    $self->{textw} = $args{textw}; $self->{textw} -= 5 if $self->{textw};
}

1;

=head1 NAME

Image::Button::Rect - Builds rectangular PNG buttons

=head1 SYNOPSIS

  use Image::Button::Rect;

  my $b1 = new Image::Button::Rect(text     => 'text b1',
                                   font     => 'newsgotn.ttf',
                                   fontsize => 20,
                                   file     => 'b1.png');

  $b1->print;

=head1 DESCRIPTION

Builds reasonably good looking rectangular buttons, with shadows and
all, using GD with TrueType support.  See F<Image::Button> for more
details about things you can do with Buttons.

=head2 Constructor

    my $b = new Image::Button::Rect(text     => 'text',
                                    font     => 'newsgotn.ttf',
                                    fontsize => 20,
                                    file     => 'file.png');

The arguments are

=over 4

=item text => 'button text'

Defaults to ''.

=item font => 'something.ttf'

The TrueType font with which to print.  It should be located either
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

=item btcolor => [ 238, 238, 204 ]

Button color in RGB (so [255,255,255] is white and [0,0,0] is black).
Defaults to [238,238,204], which is as nice a color as any other.

=item fgcolor => [ 0, 0, 0 ]

Foreground (text) color in RGB.  Defaults to [0,0,0].

=item bgcolor => [ 255, 255, 255 ]

Background color in RGB.  This is the color you want to be equal to
your page background.  Defaults to [255,255,255].  You might want to
set this transparent, but (1) it's not implemented---in Button.pm, GD
knows how to do it--- and (2) IE, or at least some versions of it,
doesn't handle transparent PNGs correctly.

=item vmargin => 4

Vertical margin under and over the text, more or less.  Defaults to 4
pixels.

=item hmargin => 4

Horizontal margin left and right of the text, more or less.  Defaults
to 4 pixels.

=back

=head1 SEE ALSO

F<Image::Button> for a description of how to make buttons, and other
functions you can use with Image::Button::Rect.

F<Image::Button::Set> for building sets of related buttons.

=head1 AUTHOR

Juan M. García-Reyero E<lt>joanmg@twostones.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2003 Juan M. García-Reyero.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


