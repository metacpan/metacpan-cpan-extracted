# $Id: Align.pm,v 1.18 2003/02/21 00:10:26 mgjv Exp $

package GD::Text::Align;

($GD::Text::Align::VERSION) = '$Revision: 1.18 $' =~ /\s([\d.]+)/;

=head1 NAME

GD::Text::Align - Draw aligned strings

=head1 SYNOPSIS

  use GD;
  use GD::Text::Align;

  my $gd = GD::Image->new(800,600);
  # allocate colours, do other things.

  my $align = GD::Text::Align->new($gd
    valign => 'top',
    halign => 'right',
  );
  $align->set_font('arial', 12);
  $align->set_text('some string');
  @bb = $align->bounding_box(200, 400, PI/3);
  # you can do things based on the bounding box here
  $align->draw(200, 400, PI/3);

=head1 DESCRIPTION

GD::Text::Align provides an object that draws a string aligned
to a coordinate at an angle.

For builtin fonts only two angles are valid: 0 and PI/2. All other
angles will be converted to one of these two.

=head1 METHODS

This class inherits everything from GD::Text. I will only discuss the
methods and attributes here that are not discussed there, or that have a
different interface or behaviour. Methods directly inherited include
C<set_text> and C<set_font>.

=cut

use strict;

# XXX add version number to GD
use GD;
use GD::Text;
use Carp;

@GD::Text::Align::ISA = qw(GD::Text);

=head2 GD::Text::Align->new($gd_object, attrib => value, ...)

Create a new object. The first argument to new has to be a valid
GD::Image object. The other arguments will be passed on to the set
method.

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $gd    = shift;
    ref($gd) and $gd->isa('GD::Image') 
        or croak "Not a GD::Image object";
    my $self = $class->SUPER::new() or return;
    $self->{gd} = $gd;
    $self->_init();
    $self->set(@_);
    bless $self => $class;
}

my %defaults = (
    halign  => 'left',
    valign  => 'base',
);

sub _init
{
    my $self = shift;
    while (my ($k, $v) = each(%defaults))
    {
        $self->{$k} = $v;
    }
    $self->{colour} = $self->{gd}->colorsTotal - 1,
}

=head2 $align->set(attrib => value, ...)

Set an attribute. Valid attributes are the ones discussed in
L<GD::Text> and:

=over 4

=item valign, halign

Vertical and horizontal alignment of the string. See also set_valign and
set_halign.

=item colour, color

Synonyms. The colour to use to draw the string. This should be the index
of the colour in the GD::Image object's palette. The default value is
the last colour in the GD object's palette at the time of the creation
of C<$align>.

=back

=cut

sub set
{
    my $self = shift;
    $@ = "Incorrect attribute list", return if @_%2;
    my %args = @_;
    my @super;

    foreach (keys %args)
    {
        /^valign/ and do {
            $self->set_valign($args{$_}); 
            next;
        };
        /^halign/ and do {
            $self->set_halign($args{$_}); 
            next;
        };
        /^colou?r$/ and do {
            $self->{colour} = $args{$_};
            next;
        };
        # Save anything unknown to pass off to SUPER class
        push @super, $_, $args{$_};
    }

    $self->SUPER::set(@super);
}

=head2 $align->get(attribute)

Get the value of an attribute.
Valid attributes are all the attributes mentioned in L<GD::Text>, the
attributes mentioned under the C<set> method and

=over 4

=item x, y and angle

The x and y coordinate and the angle to be used. You can only do this
after a call to the draw or bounding_box methods. Note that these
coordinates are not necessarily the same ones that were passed in.
Instead, they are the coordinates from where the GD methods will start
drawing. I doubt that this is very useful to anyone.

=back

Note that while you can set the colour with both 'color' and 'colour',
you can only get it as 'colour'. Sorry, but such is life in Australia.

=cut

# get is inherited unchanged

=head2 $align->set_valign(value)

Set the vertical alignment of the string to one of 'top', 'center',
'base' or 'bottom'. For builtin fonts the last two are the same. The
value 'base' denotes the baseline of a TrueType font.
Returns true on success, false on failure.

=cut

sub set_valign
{
    my $self = shift;
    local $_ = shift or return;

    if (/^top/ || /^center/ || /^bottom/ || /^base/) 
    {
        $self->{valign} = $_; 
        return $_;
    }
    else
    {
        carp "Illegal vertical alignment: $_";
        return;
    }
}

=head2 $align->set_halign(value)

Set the horizontal alignment of the string to one of 'left', 'center',
or 'right'. 
Returns true on success, false on failure.

=cut

sub set_halign
{
    my $self = shift;
    local $_ = shift or return;

    if (/^left/ || /^center/ || /^right/) 
    {
        $self->{halign} = $_; 
        return $_;
    }
    else
    {
        carp "Illegal horizontal alignment: $_";
        return;
    }
}

=head2 $align->set_align(valign, halign)

Set the vertical and horizontal alignment. Just here for convenience.
See also C<set_valign> and C<set_halign>.
Returns true on success, false on failure.

=cut

sub set_align
{
    my $self = shift;

    $self->set_valign(shift) or return;
    $self->set_halign(shift) or return;
}

#
# Determine whether a builtin font string should be drawn with the
# string or stringUp method. It will use the stringUp method for any
# angles between PI/4 and 3PI/4, 5PI/4 and 7PI/4, and all equivalents.
#
# return 
#   true for stringUp
#   false for string
#
sub _builtin_up
{
    my $self = shift;
    return 
	sin($self->{angle}) >  0.5 * sqrt(2) || 
	sin($self->{angle}) < -0.5 * sqrt(2)
}

#
# Calculates the x and y coordinate that should be passed
# to the GD::Image drawing routines, and set them as attributes
#
sub _align
{
    my $self = shift;
    my ($x, $y, $angle) = @_;

    defined $x  && defined $y or carp "Need X and Y coordinates", return;
    $self->{angle} = $angle || 0;

    if ($self->is_builtin)
    {
        return $self->_align_builtin($x, $y);
    }
    elsif ($self->is_ttf)
    {
        return $self->_align_ttf($x, $y);
    }
    else
    {
        confess "Impossible error in GD::Text::Align::_align";
    }
}

#
# calculate the alignment for a builtin font
#
sub _align_builtin
{
    my $self = shift;
    my ($x, $y) = @_;

    # Swap coordinates and make sure to keep the sign right, since left
    # becomes _down_ (larger) and right becomes _up_ (smaller)
    ($x, $y) = (-$y, $x) if ($self->_builtin_up);

    for ($self->{halign})
    {
        #/^left/   and $x = $x;
        /^center/ and $x -= $self->{width}/2;
        /^right/  and $x -= $self->{width};
    }
    for ($self->{valign})
    {
        #/^top/    and $y = $y;
        /^center/ and $y -= $self->{height}/2;
        /^bottom/ and $y -= $self->{height};
        /^base/   and $y -= $self->{height};
    }

    ($x, $y) = ($y, -$x) if ($self->_builtin_up);

    $self->{'x'} = $x;
    $self->{'y'} = $y;

    return 1;
}

#
# calculate the alignment for a TrueType font
#
sub _align_ttf
{
    my $self = shift;
    my ($x, $y) = @_;
    my $phi = $self->{angle};

    for ($self->{halign})
    {
        #/^left/ and $x = $x;
        /^center/ and do {
            $x -= cos($phi) * $self->{width}/2;
            $y += sin($phi) * $self->{width}/2;
        };
        /^right/  and do {
            $x -= cos($phi) * $self->{width};
            $y += sin($phi) * $self->{width};
        };
    }
    for ($self->{valign})
    {
        /^top/    and do {
            $x += sin($phi) * $self->{char_up};
            $y += cos($phi) * $self->{char_up};
        };
        /^center/ and do {
            $x -= sin($phi) * ($self->{char_down} - $self->{height}/2);
            $y -= cos($phi) * ($self->{char_down} - $self->{height}/2);
        };
        /^bottom/ and do {
            $x -= sin($phi) * $self->{char_down};
            $y -= cos($phi) * $self->{char_down};
        };
        #/^base/   and $y = $y;
    }

    $self->{'x'} = $x;
    $self->{'y'} = $y;

    return 1;
}

=head2 $align->draw(x, y, angle)

Draw the string at coordinates I<x>, I<y> at an angle I<angle> in
radians. The x and y coordinate become the pivot around which the
string rotates.

Note that for the builtin GD fonts the only two valid angles are 0 and
PI/2.

Returns the bounding box of the drawn string (see C<bounding_box()>).

=cut

sub draw
{
    my $self = shift;
    my ($x, $y, $angle) = @_;

    $@ = "No text set", return unless defined $self->{text};
    $@ = "No colour set", return unless defined $self->{colour};

    $self->_align($x, $y, $angle) or return;

    if ($self->is_builtin)
    {
        if ($self->_builtin_up)
        {
            $self->{gd}->stringUp($self->{font}, 
                $self->{'x'}, $self->{'y'},
                $self->{text}, $self->{colour});
        }
        else
        {
            $self->{gd}->string($self->{font}, 
                $self->{'x'}, $self->{'y'},
                $self->{text}, $self->{colour});
        }
    }
    elsif ($self->is_ttf)
    {
        $self->{gd}->stringTTF($self->{colour}, 
            $self->{font}, $self->{ptsize},
            $self->{angle}, $self->{'x'}, $self->{'y'}, $self->{text});
    }
    else
    {
        confess "impossible error in GD::Text::Align::draw";
    }

    return $self->bounding_box($x, $y, $angle);
}

=head2 $align->bounding_box(x, y, angle)

Return the bounding box of the string to draw. This returns an
eight-element list (exactly like the GD::Image->stringTTF method):

  (x1,y1) lower left corner
  (x2,y2) lower right corner
  (x3,y3) upper right corner
  (x4,y4) upper left corner

Note that upper, lower, left and right are relative to the string, not
to the canvas.

The bounding box can be used to make decisions about whether to move the
string or change the font size prior to actually drawing the string.

=cut

sub bounding_box
{
    my $self = shift;
    my ($x, $y, $angle) = @_;

    $@ = "No text set", return unless defined $self->{text};

    $self->_align($x, $y, $angle) or return;

    if ($self->is_builtin)
    {
        if ($self->_builtin_up)
        {
            return (
                $self->{'x'} + $self->{height}, $self->{'y'},
                $self->{'x'} + $self->{height}, $self->{'y'} - $self->{width},
                $self->{'x'}                  , $self->{'y'} - $self->{width},
                $self->{'x'}                  , $self->{'y'},
            )
        }
        else
        {
            return (
                $self->{'x'}                 , $self->{'y'} + $self->{height},
                $self->{'x'} + $self->{width}, $self->{'y'} + $self->{height},
                $self->{'x'} + $self->{width}, $self->{'y'},
                $self->{'x'}                 , $self->{'y'},
            )
        }
    }
    elsif ($self->is_ttf)
    {
        return GD::Image->stringTTF($self->{colour}, 
            $self->{font}, $self->{ptsize},
            $self->{angle}, $self->{'x'}, $self->{'y'}, $self->{text});
    }
    else
    {
        confess "impossible error in GD::Text::Align::draw";
    }
}

=head1 NOTES

As with all Modules for Perl: Please stick to using the interface. If
you try to fiddle too much with knowledge of the internals of this
module, you may get burned. I may change them at any time.

You can only use TrueType fonts with version of GD > 1.20, and then
only if compiled with support for this. If you attempt to do it
anyway, you will get errors.

In the following, terms like 'top', 'upper', 'left' and the like are all
relative to the string to be drawn, not to the canvas.

=head1 BUGS

Any bugs inherited from GD::Text.

=head1 COPYRIGHT

copyright 1999
Martien Verbruggen (mgjv@comdyn.com.au)

=head1 SEE ALSO

L<GD>, L<GD::Text>, L<GD::Text::Wrap>

=cut

1;
