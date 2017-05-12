#==========================================================================
#              Copyright (c) 1995-1998 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph::colour.pm
#
#   Description:
#       Package of colour manipulation routines, to be used 
#       with GD::Graph.
#
# $Id: colour.pm,v 1.10 2005/12/14 04:09:40 ben Exp $
#
#==========================================================================

 
package GD::Graph::colour;

($GD::Graph::colour::VERSION) = '$Revision: 1.10 $' =~ /\s([\d.]+)/;

=head1 NAME

GD::Graph::colour - Colour manipulation routines for use with GD::Graph

=head1 SYNOPSIS

use GD::Graph::colour qw(:colours :lists :files :convert);

=head1 DESCRIPTION

The B<GD::Graph::colour> package provides a few routines to work with
colours. The functionality of this package is mainly defined by what is
needed, now and historically, by the GD::Graph modules.

=cut

use vars qw( @EXPORT_OK %EXPORT_TAGS );
use strict;
require Exporter;
use Carp;

@GD::Graph::colour::ISA = qw( Exporter );

@EXPORT_OK = qw( 
    _rgb _luminance _hue add_colour
    colour_list sorted_colour_list
    read_rgb
    hex2rgb rgb2hex
);
%EXPORT_TAGS = ( 
    colours => [qw( add_colour _rgb _luminance _hue )],
    lists => [qw( colour_list sorted_colour_list )],
    files => [qw( read_rgb )],
    convert => [qw( hex2rgb rgb2hex )],
);

my %RGB = (
    white   => [0xFF,0xFF,0xFF], 
    lgray   => [0xBF,0xBF,0xBF], 
    gray    => [0x7F,0x7F,0x7F],
    dgray   => [0x3F,0x3F,0x3F],
    black   => [0x00,0x00,0x00],
    lblue   => [0x00,0x00,0xFF], 
    blue    => [0x00,0x00,0xBF],
    dblue   => [0x00,0x00,0x7F], 
    gold    => [0xFF,0xD7,0x00],
    lyellow => [0xFF,0xFF,0x00], 
    yellow  => [0xBF,0xBF,0x00], 
    dyellow => [0x7F,0x7F,0x00],
    lgreen  => [0x00,0xFF,0x00], 
    green   => [0x00,0xBF,0x00], 
    dgreen  => [0x00,0x7F,0x00],
    lred    => [0xFF,0x00,0x00], 
    red     => [0xBF,0x00,0x00],
    dred    => [0x7F,0x00,0x00],
    lpurple => [0xFF,0x00,0xFF], 
    purple  => [0xBF,0x00,0xBF],
    dpurple => [0x7F,0x00,0x7F],
    lorange => [0xFF,0xB7,0x00], 
    orange  => [0xFF,0x7F,0x00],
    pink    => [0xFF,0xB7,0xC1], 
    dpink   => [0xFF,0x69,0xB4],
    marine  => [0x7F,0x7F,0xFF], 
    cyan    => [0x00,0xFF,0xFF],
    lbrown  => [0xD2,0xB4,0x8C], 
    dbrown  => [0xA5,0x2A,0x2A],
);

=head1 FUNCTIONS

=head2 colour_list( I<number of colours> )

Returns a list of I<number of colours> colour names known to the package.
Exported with the :lists tag.

=cut

sub colour_list 
{
    my $n = ( $_[0] ) ? $_[0] : keys %RGB;
    return (keys %RGB)[0 .. $n-1]; 
}

=head2 sorted_colour_list( I<number of colours> )

Returns a list of I<number of colours> colour names known to the package, 
sorted by luminance or hue.
B<NB.> Right now it always sorts by luminance. Will add an option in a later
stage to decide sorting method at run time.
Exported with the :lists tag.

=cut

sub sorted_colour_list 
{
    my $n = $_[0] ? $_[0] : keys %RGB;
    return (sort by_luminance keys %RGB)[0 .. $n-1];
    # return (sort by_hue keys %rgb)[0..$n-1];

    sub by_luminance { _luminance(@{$RGB{$b}}) <=> _luminance(@{$RGB{$a}}) }
    sub by_hue       { _hue(@{$RGB{$b}}) <=> _hue(@{$RGB{$a}}) }
}

=head2 _rgb( I<colour name> )

Returns a list of the RGB values of I<colour name>. if the colour name
is a string of the form that is acceptable to the hex2rgb sub, then the
colour will be added to the list dynamically.
Exported with the :colours tag.

=cut

my %warned_clrs = ();

# return the RGB values of the colour name
sub _rgb 
{ 
    my $clr = shift or return;

    # Try adding the colour if it doesn't exist yet. It may be of a
    # parseable form
    add_colour($clr) unless exists $RGB{$clr};

    my $rgb_ref = $RGB{$clr};
    if (!defined $rgb_ref)
    {
        $rgb_ref = $RGB{'black'};
        unless ($warned_clrs{$clr})
        {
            $warned_clrs{$clr}++;
            carp "Colour $clr is not defined, reverting to black"; 
        }
    };

    @{$rgb_ref};
}

=head2 _hue( I<R,G,B> )

Returns the hue of the colour with the specified RGB values.
Exported with the :colours tag.

=head2 _luminance( I<R,G,B> )

Returns the luminance of the colour with the specified RGB values.
Exported with the :colours tag.

=cut

# return the luminance of the colour (RGB)
sub _luminance 
{ 
    (0.212671 * $_[0] + 0.715160 * $_[1] + 0.072169 * $_[2])/0xFF
}

# return the hue of the colour (RGB)
sub _hue 
{ 
    ($_[0] + $_[1] + $_[2])/(3 * 0xFF) 
}

=head2 add_colour(colourname => [$r, $g, $b]) or
add_colour('#7fe310')

Self-explanatory.
Exported with the :colours tag.

=cut

sub add_colour
{
    my $name = shift;
    my $val  = shift;

    if (!defined $val)
    {
        my @rgb = hex2rgb($name) or return;
        $val = [@rgb];
    }

    if (ref $val && ref $val eq 'ARRAY')
    {
        $RGB{$name} = [@{$val}];
        return $name;
    }

    return;
}

=head2 rgb2hex($red, $green, $blue)

=head2 hex2rgb('#7fe310')

These functions translate a list of RGB values into a hexadecimal
string, as is commonly used in HTML and the Image::Magick API, and vice
versa.
Exported with the :convert tag.

=cut

# Color translation
sub rgb2hex
{
    return unless @_ == 3;
    my $color = '#';
    foreach my $cc (@_)
    {
        $color .= sprintf("%02x", $cc);
    }
    return $color;
}

sub hex2rgb
{
    my $clr = shift;
    my @rgb = $clr =~ /^#([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})$/i;
    return unless @rgb;
    return map { hex $_ } @rgb;
}

=head2 read_rgb( F<file name> )

Reads in colours from a rgb file as used by the X11 system.

Doing something like:

    use GD::Graph::bars;
    use GD::Graph::colour;

    GD::Graph::colour::read_rgb("rgb.txt") or die "cannot read colours";

Will allow you to use any colours defined in rgb.txt in your graph.
Exported with the :files tag.

=cut

#
# Read a rgb.txt file (X11)
#
# Expected format of the file:
#
# R G B colour name
#
# Fields can be separated by any number of whitespace
# Lines starting with an exclamation mark (!) are comment and 
# will be ignored.
#
# returns number of colours read

sub read_rgb($) # (filename)
{
    my $fn = shift;
    my $n = 0;
    my $line;

    open(RGB, $fn) or return 0;

    while (defined($line = <RGB>))
    {
        next if ($line =~ /\s*!/);
        chomp($line);

        # remove leading white space
        $line =~ s/^\s+//;

        # get the colours
        my ($r, $g, $b, $name) = split(/\s+/, $line, 4);
        
        # Ignore bad lines
        next unless (defined $name);

        $RGB{$name} = [$r, $g, $b];
        $n++;
    }

    close(RGB);

    return $n;
}

sub version { $GD::Graph::colour::VERSION }

sub dump_colours
{
    my $max = $_[0] ? $_[0] : keys %RGB;
    my $n = 0;

    my $clr;
    foreach $clr (sorted_colour_list($max))
    {
        last if $n > $max;
        print "colour: $clr, " . 
            "${$RGB{$clr}}[0], ${$RGB{$clr}}[1], ${$RGB{$clr}}[2]\n"
    }
}


"Just another true value";

__END__

=head1 PREDEFINED COLOUR NAMES

white,
lgray,
gray,
dgray,
black,
lblue,
blue,
dblue,
gold,
lyellow,
yellow,
dyellow,
lgreen,
green,
dgreen,
lred,
red,
dred,
lpurple,
purple,
dpurple,
lorange,
orange,
pink,
dpink,
marine,
cyan,
lbrown,
dbrown.

=head1 AUTHOR

Martien Verbruggen E<lt>mgjv@tradingpost.com.auE<gt>

=head2 Copyright

GIFgraph: Copyright (c) 1995-1999 Martien Verbruggen.
Chart::PNGgraph: Copyright (c) 1999 Steve Bonds.
GD::Graph: Copyright (c) 1999 Martien Verbruggen.

All rights reserved. This package is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<GD::Graph>, 
L<GD::Graph::FAQ>

