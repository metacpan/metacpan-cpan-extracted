package GD::Text::Arc;

$GD::Text::Arc::VERSION = '0.02';

use strict;
use GD 1.2;    # fails if version < 1.20 (no TrueType support)
use base qw(GD::Text);
use Carp;

use constant PI   => 4 * atan2(1, 1);

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $gd    = shift;
    ref($gd) and $gd->isa('GD::Image') 
        or croak "Not a GD::Image object";
    my $self = $class->SUPER::new() or return;
    $self->{gd} = $gd;
    bless $self => $class;
    $self->_init();
    $self->set(@_);
    return $self;
}

# fill these in with defaults

my %defaults = (
    align                   => 'left',
    angle                   => 0,
    font                    => '',
    text                    => '',
    orientation             => 'clockwise',
    side                    => 'outside',
    compress_factor         => .9,
    points_to_pixels_factor => .8

);

sub _init
{
    my $self = shift;
    while (my ($k, $v) = each(%defaults))
    {
        $self->{$k} = $v;
    }
    $self->{colour}   = 1; # if indexed, 1 is the first non-background color. 
                           # if truecolor, (0,0,1) is nearly black.
    $self->{color}    = $self->{colour};
    $self->{center_x} = ($self->{gd}->getBounds())[0] / 2;
    $self->{center_y} = ($self->{gd}->getBounds())[1] / 2;
    $self->{radius}   = _min( $self->{center_x}, $self->{center_y});
}

sub set
{
    my $self = shift;
    $@ = "Incorrect attribute list (one left over)", return if @_%2;
    my %args = @_;
    my @super;

    foreach (keys %args)
    {
        /^align/ and do {
            $self->set_align($args{$_}); 
            next;
        };
        /^angle/ and do {
            $self->set_angle($args{$_});
            next;
        };
        /^center_x/ and do {
            $self->{center_x} = $args{$_};
            next;
        };
        /^center_y/ and do {
            $self->{center_y} = $args{$_};
            next;
        };
        /^orientation/ and do {
            $self->{orientation} = $args{$_};
            next;
        };
        /^side/ and do {
            $self->{side} = $args{$_};
            next;
        };
        /^radius/ and do {
            $self->{radius} = $args{$_};
            next;
        };

        /^colou?r$/ and do {
            $self->{colour} = $args{$_};
            $self->{color} =  $args{$_};
            next;
        };
        # Save anything unknown to pass off to SUPER class
        push @super, $_, $args{$_};
    }

    $self->SUPER::set(@super);
}

# get is inherited unchanged

# redefine these methods which use non-TrueType fonts
{
    no warnings;
    sub gdTinyFont        { carp "Not a TrueType font" }
    sub gdSmallFont       { carp "Not a TrueType font" }
    sub gdMediumBoldFont  { carp "Not a TrueType font" }
    sub gdLargeFont       { carp "Not a TrueType font" }
    sub gdGiantFont       { carp "Not a TrueType font" }
    sub _set_builtin_font { carp "Not a TrueType font" }
}

# FIXME: these two methods are not very useful yet.
sub set_align
{
    my $self = shift;
    local $_ = shift or return;

    if (/^left/ || /^center/ || /^right/) 
    {
        $self->{align} = $_; 
        return $_;
    }
    else
    {
        carp "Illegal alignment: $_";
        return;
    }
}

sub set_angle
{
    my $self = shift;
    local $_ = shift or return;

    if (undef or /\d\.?\d*/ ) 
    {
        $self->{angle} = $_; 
        return $_;
    }
    else
    {
        carp "Not numeric angle: $_";
        return;
    }
}

sub draw
{
    my $self = shift;

    $@ = "No text set", return unless  $self->{text};
    $@ = "No colour set", return unless$self->{colour};
    $@ = "No font set", return unless $self->{font};
    $@ = "No font size set", return unless $self->{ptsize};

    my $angle           = $self->get('angle') || 0;
    my $colour          = $self->get('colour');
    my $font            = $self->get('font');
    my $fontsize        = $self->get('ptsize');
    my $string          = $self->get('text');
    my $centerX         = $self->get('center_x') || 
                                           ($self->{gd}->getBounds())[0] / 2;
    my $centerY         = $self->get('center_y') || 
                                           ($self->{gd}->getBounds())[1] / 2;
    my $r               = $self->get('radius') || _min($centerX, $centerY);
    my $side            = $self->get('side') || 'outside';

    # orientation default == blank == counterclockwise == -1
    my $orientation = ($self->get('orientation') eq 'clockwise') ? 1: -1;

    # correct radius for height of letters if counterclockwise and outside
    $r += ($fontsize* $self->get('points_to_pixels_factor')) 
        if ($orientation <0 and $side eq 'outside');
    
    # correct radius the other way if clockwise and inside
    $r -= ($fontsize* $self->get('points_to_pixels_factor')) 
        if ($orientation >0 and $side ne 'outside');


    # correct spacing between letters
    my $compressFactor = $self->get('compress_factor');

    my @letters = split //, $string;
    my @widths = $self->get_widths();


    #######################################################################: 
    #
    # GD allows .ttf text a position (x,y), and an angle rotation (theta).
    #    both are measured from the lower-left corner of the string.
    #
    # We want to draw each letter separately to approximate a smooth curve.
    #    Ideally, the position (x,y) would be from the center of the letter.
    #    Since it is from the corner, plotting each letter as-is will look
    #    jaggy, because of the difference in position and angle.  To fix
    #    this we can either adjust (x,y) or theta.
    #
    # theta seemed simpler to adjust.
    #
    #    thetaL = thetaN - (1/2 radWidth * orientation)
    #
    # where:
    #                   angles are measured from 12-o'clock, positive 
    #                      increasing clockwise.
    #
    #    thetaN       = the angle of the letter to calculate its position.
    #    thetaL       = the angle to draw the letter at.
    #    radWidth     = letter width in radians
    #    orientation  = -1 for counterclockwise, +1 for clockwise
    ####################################################################### 

    # calculate start angle for positioning (x,y) with thetaN
    my $thetaN = 0;
    foreach my $n (@widths) {
    	$thetaN += ($n * $orientation);
    }
    $thetaN /= 2;                # 1/2 width, in pixels
    $thetaN /= $r;               # ..in radians,
    $thetaN /= $compressFactor;  # ..with compression factor

    $thetaN += PI if ($orientation < 0);

    # draw each letter
    foreach my $n (0..$#letters) {

    	my $radWidth = ($widths[$n]) / ($r * $compressFactor);
        my $thetaL = $thetaN - ($radWidth/2 * $orientation) ;
        $thetaL = $thetaL - PI if ($orientation < 0);

    	my $xN = $centerX - $r * sin($thetaN);
    	my $yN = $centerY - $r * cos($thetaN);

    	$self->{gd}->stringFT($colour, $font, $fontsize, $thetaL, 
                              $xN, $yN, $letters[$n]) || return 0;

    	$thetaN -= ($radWidth * $orientation);
    }   
    return 1;
}

#
# get_widths - in array context, return a list of character-widths in pixels.
#   in scalar context, return a total width of the string.

sub get_widths {
    my $self = shift;

    my @widths;
    my $total;
    my @letters = split //, $self->get('text');

    #######################################################################
    # for character x, width(x) is not useful because .ttf fonts 
    #   account for kerning.  width(x1) + width(x2) + width(x3)
    #   is categorically different from width(x1.x2.x3).
    #
    # By process of elimination: an OK formula to find width(x2): 
    #   assume x1 is a space, and perform:
    #   width(x1.x2.x3) - (width(x1) + width(x3)).
    #
    # If x2 is a space, make it wider; if it is (A|C|V) make it narrower.
    #
    # Whew.  This should probably be simplified.
    #######################################################################

    foreach my $n (0..$#letters) {
        my $nextLetter = $letters[$n+1] || " ";
        my $lastLetter = " ";

        my $thiswidth = ($self->width($lastLetter.$letters[$n].$nextLetter) 
                         - 
                         ($self->width($lastLetter) + 
                          $self->width($nextLetter)));

        $thiswidth -=2 if ($letters[$n] =~ /[AVC]/);
        $thiswidth +=2 if ($letters[$n] =~ / /);
        push @widths, $thiswidth;
        $total += $thiswidth;
    }

    return (wantarray ? @widths : $total);   
}

#
# get_height - return the best guess for the height of the letters in pixels.

sub get_height {
    my $self = shift;

    return $self->get('ptsize') * $self->get('points_to_pixels_factor');
}

sub _min {
    return ($_[0] < $_[1] ? $_[0] : $_[1]);
}
    
=head1 NAME

GD::Text::Arc - draw TrueType text along an arc.

=head1 SYNOPSIS

  use GD::Text::Arc;

  my $image = GD::Image->new(600,500);

  my $gray =  $image->colorAllocate(75,75,75);
  my $boldfont = "Adventure.ttf";
  my $text = "here's a line.";

  my $ta = GD::Text::Arc->new($image, 
                              colour => $gray,
                              ptsize => $size,
                              font => $boldfont,
                              radius => $radius,
                              center_x => $centerX,
                              center_y => $centerY,
                              text => $text, 
                              side => 'inside'
                              orientation => 'clockwise'
                              );

  $ta->draw;

  $ta->set('color', $red);
  $ta->set('ptsize', $huge);
  $ta->set('orientation', 'counterclockwise');

  $ta->draw;

=head1 DESCRIPTION

This module provides a way to draw TrueType text along a curve (such as 
around the bottom or top of a circle).  It is to be used with GD::Text
(version > 1.20) and GD graphics objects.

=head1 METHODS

=head2 GD::Text->new($gd_object, attrib => value, ... )

Create a new object. The first argument has to be a valid GD::Image 
object.  See the C<set()> method for attributes.

=head2 $gd_text->set_font( font, size )

Set the font to use for the string, using absolute or relative
TrueType font names.  See L<"GD::Text"> and L<"GD::Text::font_path">
for details.

=head2 $gd_text->set_text('some text')

Set the text to operate on. 
Returns true on success and false on error.

=head2 $gd_text->set( attrib => value, ... )

The set method is the preferred way to set attributes.
Valid attributes are:

=over 4

=item text

The text to operate on, see also C<set_text()>.

=item font, ptsize

The font to use and the point size. Also see C<set_font()>.

=item colour, color

Synonyms. The colour to use to draw the string. This should be the index
of the colour in the GD::Image object's palette. For a true-color GD::Image,
the default value is nearly black: (0,0,1).  For indexed images, the default 
value is the first non-background colour in the GD object's palette at the 
time of the creation of C<$gd_text>.

=item center_x, center_y

The center point for the circle.  Defaults to 1/2 the width and height
of the containing GD object.

=item radius

The radius of the circle, which is either drawn outside or inside the
text (depending on C<side> attribute; see below).  The default
radius is the lesser of center_x or center_y.

=item orientation

Direction of the text.  Valid values: clockwise, counterclockwise.
Default is counterclockwise (that is, written along the bottom of the
circle, such as from 8-oclock to 5-oclock on a clock face.)

=item side

Whether the text is drawn inside the radius of the circle or outside.
Valid values: inside, outside.  Default is outside.

=item align

Not implemented yet; but will allow text to be left- or right- aligned
around a point on the circle.  At present, text is center-aligned..

=item angle

Not implemented yet; but will set the point on the circle around which
text is centered (or started or ended, depending on alignment).  At
present, angle is set to 0 (top of the circle) for clockwise
orientation, and PI (bottom of the circle) for counterclockwise
orientation.

=item compress_factor, points_to_pixels_factor

These parameters were found by experimentation and seem to apply to
any fonts and point-sizes I've tried, but might need adjusting under
some situations.

compress_factor adjusts spacing between characters.  It is .9 by
default; a larger value reduces the space between characters.

points_to_pixels_factor adjusts the radius (by a fraction of the
point-size) to compensate for the height of letters.
It is .8 by default; a larger value increases the radius.

=back

Returns true on success, false on any error, even if it was partially
successful. When an error is returned, no guarantees are given about
the correctness of the attributes.

=head2 $gd_text->get( attrib, ... )

Get the value of an attribute.
Return a list of the attribute values in list context, and the value of
the first attribute in scalar context.

The attributes that can be retrieved are all the ones that can be set,
plus those described in L<"GD::Text">.:

Note that unlike with GD::Text::Align, you can get() both 'color' and 
'colour'.  Vive la difference!

=head2 $gd_text->get_widths()

In array context, returns a list of character-widths for the text to
be drawn.  In scalar context, return the total width of the string
measured in pixels.  Because the way the characters are drawn (to
acount for kerning between adjacent characters), this is more accurate
than $gd_text->width. This is mostly an internal method, but might be
useful to make sure your text is shorter than, say, PI * radius
characters.

=head2 $gd_text->draw()

Draw the string according to coordinates, radius, orientation, and font.
Returns true on success, false on any error.

=head1 NOTES

=head2 GD::Text::Arc::PI

Owing to how 'use constant' works, for free, you get a definition of Pi
that is as good as your floating-point math.  You can also access it 
as method C<$gd_text-E<gt>PI>.

=head1 BUGS

Probably.

I haven't implemented align() or angle() methods yet;
for now, align = center and angle = 0.  I'm not sure this module will work 
perfectly with all fonts.  I've tried it with a few dozen, which look more
or less the way I wanted them to.

Suggestions gratefully welcomed.

=head1 COPYRIGHT

Copyright (C) 2004
Daniel Allen E<lt>da@coder.comE<gt>.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

GD(3), GD::Text(3), GD::Text::Wrap(3), GD::Text::Align(3)

=cut

1;
