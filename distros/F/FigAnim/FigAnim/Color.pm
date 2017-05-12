package Color;

=head1 NAME

Color - A XFig file animator class - Color object

=head1 DESCRIPTION

Color pseudo-object (user defined colors) - object code in FIG format: 0.
This is used to define arbitrary colors beyond the 32 standard colors.
Here are all the attributes of this class:

B<color_bumber, rgb>

=head1 FIG ATTRIBUTES

=over

=item color_bumber

color number, from 32-543 (512 total)

The two color fields (pen and fill; pen only, for texts) are
defined as follows:

-1: Default;
0: Black;
1: Blue;
2: Green;
3: Cyan;
4: Red;
5: Magenta;
6: Yellow;
7: White;
8..11: four shades of blue (dark to lighter);
12..14: three shades of green (dark to lighter);
15..17: three shades of cyan (dark to lighter);
18..20: three shades of red (dark to lighter);
21..23: three shades of magenta (dark to lighter);
24..26: three shades of brown (dark to lighter);
27..30: four shades of pink (dark to lighter);
31: Gold;
32..543 (512 total): user colors defined in color pseudo-objects (type 0).

For White color, the area fill field is defined as follows:

-1: not filled;
0: black;
1..19: shades of grey, from darker to lighter;
20: white;
21..40: not used;
41..56: see patterns for colors, below.

For Black or Default color, the area fill field is defined as follows:

-1: not filled;
0: white;
1..19: shades of grey, from lighter to darker;
20: black;
21..40: not used;
41..56: see patterns for colors, below.

For all other colors, the area fill field is defined as follows:

-1: not filled;
0: black;
1..19: "shades" of the color, from darker to lighter,
a shade is defined as the color mixed with black;
20: full saturation of the color;
21..39: "tints" of the color from the color to white,
a tint is defined as the color mixed with white;
40: white;
41: 30 degree left diagonal pattern;
42: 30 degree right diagonal pattern;
43: 30 degree crosshatch;
44: 45 degree left diagonal pattern;
45: 45 degree right diagonal pattern;
46: 45 degree crosshatch;
47: bricks;
48: circles;
49: horizontal lines;
50: vertical lines;
51: crosshatch;
52: fish scales;
53: small fish scales;
54: octagons;
55: horizontal "tire treads";
56: vertical "tire treads".

=item rgb

hex string rgb values:
hexadecimal string describing red, green and blue values (e.g. #330099)

=back

=cut

use strict;
use warnings;

# constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    
    #$self->{object_code} = 0;
    $self->{color_number} = shift;
    $self->{rgb} = shift;
    
    bless ($self, $class);
    return $self;
}


# methods
sub clone {
    my $self = shift;
    my $obj = new Color;
    $obj->{$_} = $self->{$_} foreach (keys %{$self});
    return $obj;
}

sub output {
    my $self = shift;
    my $fh = shift;
    
    printf $fh "0 %d %s\n", @$self{'color_number','rgb'};
}

1;
