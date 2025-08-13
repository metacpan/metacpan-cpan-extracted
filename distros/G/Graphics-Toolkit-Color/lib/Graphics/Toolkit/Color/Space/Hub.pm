
# store all clolor space objects, to convert check, convert and measure color values

package Graphics::Toolkit::Color::Space::Hub;
use v5.12;
use warnings;
use Carp;

#### internal space loading ############################################
our $default_space_name = 'RGB';
my @search_order = ($default_space_name,
                   qw/CMY CMYK HSL HSV HSB HWB NCol YIQ YUV/, # missing: CubeHelix OKLAB Hunterlab
                   qw/CIEXYZ CIELAB CIELUV CIELCHab CIELCHuv/);
my %space_obj;
add_space( require "Graphics/Toolkit/Color/Space/Instance/$_.pm" ) for @search_order;

#### space API #########################################################
sub is_space_name      { (ref get_space($_[0])) ? 1 : 0 }
sub all_space_names    { sort keys %space_obj }
sub default_space_name { $default_space_name }
sub default_space      { get_space( $default_space_name ) }
sub get_space          { (defined $_[0] and exists $space_obj{ uc $_[0] }) ? $space_obj{ uc $_[0] } : '' }
sub try_get_space {
    my $name = shift || $default_space_name;
    my $space = get_space( $name );
    return (ref $space) ? $space
                        : "$name is an unknown color space, try one of: ".(join ', ', all_space_names());
}

sub add_space {
    my $space = shift;
    return 'got no Graphics::Toolkit::Color::Space object' if ref $space ne 'Graphics::Toolkit::Color::Space';
    my $name = $space->name;
    return "space objct has no name" unless $name;
    return "color space name $name is already taken" if ref get_space( $name );
    my @converter_target = $space->converter_names;
    return "can not add color space $name, it has no converter" unless @converter_target or $name eq $default_space_name;
     for my $converter_target (@converter_target){
        my $target_space = get_space( $converter_target );
        return "space object $name does convert into $converter_target, which is no known color space" unless $target_space;
        $space->alias_converter_name( $converter_target, $target_space->alias ) if $target_space->alias;
    }
    $space_obj{ uc $name } = $space;
    $space_obj{ uc $space->alias } = $space if $space->alias and not ref get_space( $space->alias );
    return 1;
}
sub remove_space {
    my $name = shift;
    return "need name of color space as argument in order to remove the space" unless defined $name and $name;
    my $space = get_space( $name );
    return "can not remove unknown color space: $name" unless ref $space;
    delete $space_obj{ uc $space->alias } if $space->alias;
    delete $space_obj{ uc $space->name };
}

#### value API #########################################################
sub convert { # normalized RGB tuple, ~space_name --> ?normalized tuple in wanted space
    my ($values, $target_space_name, $want_result_normalized, $source_space_name, $source_values) = @_;
    my $target_space = try_get_space( $target_space_name );
    my $source_space = try_get_space( $source_space_name );
    $want_result_normalized //= 0;
    return "need an ARRAY ref with 3 RGB values as first argument in order to convert them"
        unless default_space()->is_value_tuple( $values );
    return $target_space unless ref $target_space;
    return "arguments source_space_name and source_values have to be provided both or none."
        if defined $source_space_name xor defined $source_values;
    return "argument source_values has to be a tuple, if provided"
        if $source_values and not $source_space->is_value_tuple( $source_values );

    # none conversion cases
    $values = $source_values if ref $source_values and $source_space eq $target_space;
    if ($target_space->name eq default_space()->name or $source_space eq $target_space) {
        return ($want_result_normalized) ? $values : $target_space->round($target_space->denormalize( $values ));
    }
    # find conversion chain
    my $current_space = $target_space;
    my @convert_chain = ($target_space->name);
    while ($current_space->name ne $default_space_name ){
        my ($next_space_name, @next_options) = $current_space->converter_names;
        $next_space_name = shift @next_options while @next_options and $next_space_name ne $default_space_name;
        unshift @convert_chain, $next_space_name if $next_space_name ne $default_space_name;
        $current_space = get_space( $next_space_name );
    }
    # actual conversion
    my $values_are_normal = 1;
    my $space_name_before = default_space_name();
    for my $space_name (@convert_chain){
        my $current_space = get_space( $space_name );
        if ($current_space eq $source_space){
            $values = $source_values;
            $values_are_normal = 1;
        } else {
            my @normal_in_out = $current_space->converter_normal_states( 'from', $space_name_before );
            $values = $current_space->normalize( $values ) if not $values_are_normal and $normal_in_out[0];
            $values = $current_space->denormalize( $values ) if $values_are_normal and not $normal_in_out[0];
            $values = $current_space->convert_from( $space_name_before, $values);
            $values_are_normal = $normal_in_out[1];
        }
        $space_name_before = $current_space->name;
    }
    $values = $target_space->normalize( $values )   if not $values_are_normal and $want_result_normalized;
    $values = $target_space->denormalize( $values ) if $values_are_normal and not $want_result_normalized;
    return    $target_space->clamp( $values, ($want_result_normalized ? 'normal' : undef));
}
sub deconvert { # normalizd value tuple --> RGB tuple
    my ($space_name, $values, $want_result_normalized) = @_;
    return "need a space name to convert to as first argument" unless defined $space_name;
    my $original_space = try_get_space( $space_name );
    return $original_space unless ref $original_space;
    return "need an ARRAY ref with 3 or 4 values as first argument in order to deconvert them"
        unless ref $values eq 'ARRAY' and (@$values == 3 or @$values == 4);
    $want_result_normalized //= 0;
    if ($original_space->name eq $default_space_name) { # nothing to convert
        return ($want_result_normalized) ? $values : $original_space->round( $original_space->denormalize( $values ));
    }

    my $current_space = $original_space;
    my $values_are_normal = 1;
    while (uc $current_space->name ne $default_space_name){
        my ($next_space_name, @next_options) = $current_space->converter_names;
        $next_space_name = shift @next_options while @next_options and $next_space_name ne $default_space_name;
        my @normal_in_out = $current_space->converter_normal_states( 'to', $next_space_name );
        $values = $current_space->normalize( $values ) if not $values_are_normal and $normal_in_out[0];
        $values = $current_space->denormalize( $values ) if $values_are_normal and not $normal_in_out[0];
        $values = $current_space->convert_to( $next_space_name, $values);
        $values_are_normal = $normal_in_out[1];
        $current_space = get_space( $next_space_name );
    }
    return ($want_result_normalized) ? $values : $current_space->round( $current_space->denormalize( $values ));
}

sub deformat { # formatted color def --> normalized values
    my ($color_def, $ranges, $suffix) = @_;
    return 'got no color definition' unless defined $color_def;
    my ($values, $original_space, $format_name);
    for my $space_name (all_space_names()) {
        my $color_space = get_space( $space_name );
        ($values, $format_name) = $color_space->deformat( $color_def );
        if (defined $format_name){
            $original_space = $color_space;
            last;
        }
    }
    return 'could not deformat color definition: "$color_def"' unless ref $original_space;
    return $values, $original_space->name, $format_name;
}

sub deformat_partial_hash { # convert partial hash into
    my ($value_hash, $space_name) = @_;
    return unless ref $value_hash eq 'HASH';
    my $space = try_get_space( $space_name );
    return $space unless ref $space;
    my @space_name_options = (defined $space_name and $space_name) ? ($space->name) : (@search_order);
    for my $space_name (@space_name_options) {
        my $color_space = get_space( $space_name );
        my $values = $color_space->tuple_from_partial_hash( $value_hash );
        next unless ref $values;
        return wantarray ? ($values, $color_space->name) : $values;
    }
    return undef;
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Space::Hub - (de-)convert and deformat color value tuples

=head1 SYNOPSIS

Central store for all color space objects, which hold color space specific
information and algorithms. Home to all methods that have to iterate over
all color spaces.

    use Graphics::Toolkit::Color::Space::Hub;
    my $true = Graphics::Toolkit::Color::Space::Hub::is_space( 'HSL' );
    my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space( 'HSL');
    my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space();

    Graphics::Toolkit::Color::Space::Hub::space_names();     # all space names and aliases

    $HSL->normalize([240,100, 0]);         # 2/3, 1, 0
    $HSL->convert([240, 100, 0], 'RGB');   #   0, 0, 1
    $HSL->deconvert([0, 0, 1], 'RGB');     # 2/3, 1, 0
    $RGB->denormalize([0, 0, 1]);          #   0, 0, 255
    $RGB->format([0, 0, 255], 'hex');      #   '#0000ff'

    # [0, 0, 255] , 'RGB'
    my ($values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat( '#0000ff' );


=head1 DESCRIPTION

This module is supposed to be used only internally and not directly by
the user, unless he wants to add his own color space. Therefore it exports
no symbols and the methods are much less DWIM then the main module.
But lot of important documentation is still here.


=head1 COLOR SPACES

Up next, a listing of all supported color spaces. These are mathematical
constructs that associate each color with a point inside this space.
The numerical values of a color definition become coordinates along
axis that express different properties. The closer two
colors are along an axis the more similar are they in that property.
All color spaces are finite and only certain value ranges along an
axis are acceptable. Most spaces have 3 dimensions (axis) and are
completely lineary like in Euclidean (everyday) geometry.
A few spaces have more axis and some spaces are cylindrical. That
means that some axis are not lines but circles and the associated value
descibes an angle.

Color definitions contain either the name of a space or the names
of its axis (long or short). If the space name or its long alias is used,
the values have to be provided in the same order as the axis described here.

Color space or axis names may be written in any combination of upper and
lower case characters, but I recommended to use the spelling presented here.
Each axis has also two specific names, one long and one short, which are
in rare cases equal. To define a color according a space you need
to provide for each axis one value, that is inside the required value
range and of a specificed type (int or real with amount of decimals).

While I acknowledge that some of the spaces below should be called systems
to be technically correct, they still will be called spaces here, because
the main goal of this software is seamless interoperabilitiy between them.


=head2 RGB

... is the default color space of this CPAN module. It is used
by most computer hardware like monitors and follows the logic of additive
color mixing as produced by an overlay of three colored light beams.
The sum of all colors will be white, as in opposite to subtractive mixing.
Its is a completely Cartesian (Euclidean) 3D space and thus a RGB tuple
consists of three integer values:

B<red> (short B<r>) range: 0 .. 255, B<green> (short B<g>) range: 0 .. 255
and B<blue> (short B<b>) range: 0 .. 255.
A higher value means a stronger beam of that base color flows into the mix
above a black background, so that black is (0,0,0), white (255,255,255)
and a pure red (fully saturated color) is (255, 0, 0).

=head2 CMY

is the opposite of L<RGB> since it follows the logic of subtractive
color mixing as used in printing. Think of it as the amount of colored
ink on white paper, so that white is (0,0,0) and black (1,1,1).
It uses normalized real value ranges: 0 .. 1.
An CMY tuple has also three values:

B<cyan> (short B<c>) is the inverse of I<red>,
B<magenta> (short B<m> ) is inverse to I<green> and
B<yellow> (short B<y>) is inverse of I<blue>.

=head2 CMYK

is an extension of L<CMY> with a fourth value named B<key> (short B<k>),
which is the amount of black ink mixed into the CMY color.
It also has an normalized range of 0 .. 1. This should not bother you
since you are free to change the range at you preference.

=head2 HSL

.. is a cylindrical space that orders colors along cognitive properties.
The first dimension is the angular one and it rotates in 360 degrees around
the rainbow of fully saturated colors: 0 = red, 15 approximates orange,
60 - yellow 120 - green, 180 - cyan, 240 - blue, 270 - violet,
300 - magenta, 330 - pink. 0 and 360 points to the same coordinate.
This module only outputs 0, even if accepting 360 as input. Thes second,
linear dimension (axis) measures the distance between a point the the center
column of the cylinder at the same height, no matter in which direction.
The center column has the value 0 (white .. gray .. black) and the outer
mantle of the cylinder contains the most saturated, purest colors.
The third, vertical axis reaches from bottom value 0 (always black no
matter the other values) to 100 (always white no matter the other values).
In summary: HSL needs three integer values: B<hue> (short B<h>) (0 .. 359),
B<saturation> (short B<s>) (0 .. 100) and B<lightness> (short B<l>) (0 .. 100).

=head2 HSV

... is also cylindrical but can be shaped like a cone.
Similar to HSL we have B<hue> and B<saturation>, but the third axis is
named B<value> (short B<v>). In L<HSL> we always get white, when I<lightness>
is 100. In HSV additionally I<saturation> has to be zero to get white.
When I<saturation> is 100 and I<value> is 100 we have the purest, most
sturated color of whatever I<hue> sets. So unlike in C<HSL>, here every
color has its unique coordinates.

=head2 HSB

Is an alias to L<HSV>, just the I<value> axis is renamed with B<brightness> (B<b>).

=head2 HWB

An inverted L<HSV>, where the saturated, pure colors are on the center
column of the cylinder. It still has the same circular B<hue> dimension
with  an integer range of 0 .. 360. The other two, linear dimensions
(also 0 .. 100 inter range with optional suffix '%') are B<whiteness>
(B<w>) and B<blackness> (B<b>). They desribe how much white or black
are mixed into the pure hue. If both are zero, than we have a pure color.
I<whiteness> of 100 always leads to white and I<blackness> of 100 always
leads to black. The space is truncated as a cone so the sum of I<whiteness>
and I<blackness> can never be greater than 100.

=head2 NCol

Is a more human readable variant of the L<HWB> space with an altered
B<hue> values, that consists of a letter and two digits.
The letter demarks one of the six areas around the rainbow. B<R> is I<Red>,
B<Y> (I<Yellow>), B<G> (I<Green>), B<C> (I<Cyan>), B<B> (I<Blue>),
B<M> (I<Magenta). The two digits after this letter are an angular value,
measuring the distance between the pure color (as stated by the letter)
and the described color (toward the next color on the rainbow).
The B<whiteness> and B<blackness> axis have integer values with the
suffix I<'%'>, since they are percentual values as well.

=head2 YIQ

Is a space developed for I<NTSC> to broadcast a colored television signal,
which is still compatible with black and white TV. It achieves this by
sending the B<luminance> (short I<y>) (sort of brightness with real range
of 0 .. 1) in channel number one, which is all black and white TV needs.
Additionally we have the axis of B<in-phase> (short B<i>)
(cyan - orange - balance, range -0.5959 .. 0.5959) and
B<quadrature> (short B<q>) (magenta - green - balance, range: -0.5227 .. 0.5227).

=head2 YUV

Is a slightly altered version of L<YIQ> for the I<PAL> TV standard.
We use a variant called B<YPbPr>, which can also be used as space name.
It has computation friendly value ranges and is still relevant in video
and image formats and compression algorithms, but under the name I<YCbCr>.
The only difference is that I<YCbCr> works with digital values but
this module computes with real (analogue)  value to enable any precision
the user might prefer. To make this clear, this space holds the name B<YPbPr>.
It has three Cartesian axis: 1. B<luma> (short B<y>) with a real value
range of 0..1, 2. B<Pb> (short I<u>, -0.5 .. 0.5) and 3. C<Pr>
(short I<v>, -0.5 .. 0.5). (see also L<CIELUV>)

=head2 CIEXYZ

this space (alias B<XYZ>) has the axis B<X>, B<Y> and B<Z> (long and short
names are same this time), that refer to the red, green and blue receptors
(cones) in the retina (on the back side of the eye). Because those cones
measure a lot more left and right than just exactly those colors, they got
these technical names. The values in that space tell you about the amount
of chemical and neurological activity a color produces inside the eye.
The values range of C<X>, C<Y> and C<Z> go from zero to to 0.95047, 1
and 1.08883 respectively.
These values are due to the use of the standard luminant I<D65>, which
holds true for all CIE spaces in GTC.

=head2 CIELAB

Is a derivate of L<CIEXYZ> that reorderes the colors along axis that
reflect how the brain processes them. It uses three information channels.
One named B<L> (lightness) with a real value range of (0 .. 100).
Second is channel (B<a>, that reaches from red to green (-500 .. 500) and
thirdly B<b> from yellow to blue (-200 .. 200). Values will be displayed
with three decimals. The long names of the axis names contain a '*'
and are thus: B<L*>, B<a*> and B<b*>. The I<a> and I<b> axis reflect the
opponent color theory and the short alias name of this space is B<LAB>.

=head2 CIELUV

Is a more perceptually uniform  version of L<CIELAB> and the axis I<a>
and I<b> got renamed to I<u> and I<v> (see L<YUV>) but did not change
their meaning. It has also three Cartesian dimension named L*, u* and v*,
(short names have only the first letter of these names). Their have
real valued ranges, which are 0 .. 100, -134 .. 220 and -140 .. 122.
The short alias name of this space is B<LUV>.

=head2 CIELCHab

.. is the cylindrical version of the L<CIELAB> with the dimensions
B<luminance>, B<chroma> and B<hue> - in short  B<l>,  B<c> and B<h>.
The real valued ranges are from zero to 100, 539 and 360 respectively.
Like with the L<HSL> and L<HSV>, hue is the circular dimensions and its
values are meant as degrees in a circle. For gray colors in the middle
column the value I<chroma> has no importance and will be in this
implementation implementation alsway be zero.
The short alias name of this space is B<LCH>.

=head2 CIELCHuv

.. is the cylindrical version of the L<CIELUV> and works similar to
L<CIELCHab> except the real valued range of B<chroma> is (0 .. 261) and
the space has no alias name.



=head1 RANGES

As pointed out in the previous paragraph, each dimension of color space has
its default range. However, one can demand custom value ranges, if the method
accepts a range decriptor as argument. If so, the following values are accepted:

    'normal'          real value range from 0 ..   1 (default)
    'percent'         real value range from 0 .. 100
     number           integer range from zero to that number
    [0 1]             real number range from 0 to 1, same as 'normal'
    [min max]         range from min .. max, int if both numbers are int
    [min max 'int']   integer range from min .. max
    [min max 'real']  real number range from min .. max

The whole definition has to be an ARRAY ref. Each element is the range definition
of one dimension. If the definition is not an ARRAY but a single value it is applied
as definition of every dimension.


=head1 FORMATS

These formats are available in all color spaces.

=head2 list

Is the default format and the only one not containing the name of the
color space. This is why it can only work for the default space (RGB).

    (10, 20, 30)
    ('XYZ', 15, 3.53, 37.1)

=head2 named_array

Basically the same with squared brackets around.

    [RGB => 10, 20, 30]


=head2 named_string

Same inside a string.

    'RGB: 10, 20, 30'

=head2 css_string

Strings for usage in CSS, SVG files and alike.

    'rgb(10, 20, 30)'

=head2 hex_string

String for websites and alike, RGB only. Long and short form can be read
and output is long form only.

    '#1020FF'
    '#12F'

=head2 hash

Hash reference with long axis names.

    { red => 10, green => 20, blue => 30 }

=head2 char_hash

Hash reference with short axis names.

    { r => 10, g => 20, b => 30 }

=head1 ROUTINES

This package provides two sets of routines. Thes first is just a lookup
of what color space objects are available, what the names are and to
retrieve a color space object.  The second set consists of 4 routines
that can handle a lot of unknowns. The are:

    1. convert               (RGB -> any)
    2. deconvert             (any -> RGB)
    3. deformat              (extract values)
    3. deformat_partial_hash (deformat hashes with missing axis)

=head2 space_names

Returns a list of string values, which are the names of all available
color space. See L</COLOR-SPACES>.

=head2 is_space

Needs one argument, that supposed to be a color space name.
If it is, the result is an 1, otherwise 0 (perlish pseudo boolean).

=head2 get_space

Needs one argument, that supposed to be a color space name.
If it is, the result is the according color space object, otherwise undef.

=head2 try_get_space

Same thing but if nothing is provided it returns the default space.

=head2 default_space

Return the color space object of (currently) RGB name space.
This name space is special since every color space object provides
converters from and to RGB, but the RGB itself has no converter.


=head2 convert

Converts a value vector (first argument) from base space (RGB) into any
space mentioned space (second argument - see L</COLOR-SPACES>).
The values have to be normalized (inside 0..1). If there are outside
the acceptable range, there will be clamped, so that the result will
also normal. It the third argument is positive the output will also be
normal. Arguments four and five are for internal use to omit rounding errors.
Its the original values and their color space. So when during the conversion,
the method tries to convert into the space of the original, it replaces
the values with them.

    # convert from RGB to  HSL
    my @hsl = Graphics::Toolkit::Color::Space::Hub::convert( [0.1, 0.5, .7], 'HSL' );

=head2 deconvert

Converts the result of L</deformat> into a RGB value tuple.

    # convert from HSL to RGB
    my @rgb = Graphics::Toolkit::Color::Space::Hub::deconvert( [0.9, 0.5, 0.5], 'HSL' );

=head2 deformat

Extracts the values of a color definition in any space or I<format>.
That's why it takes only one argument, a scalar that can be a string,
ARRAY ref or HASH ref. The result will be three values.
The first is a ARRAY (tuple) with all the unaltered, not clamped and not
rounded and not normalized values. The second is the name of the recognized
color name space. Thirs is the format name.

    my ($values, $space) =  Graphics::Toolkit::Color::Space::Hub::deformat( 'ff00a0' );
    # [255, 10 , 0], 'RGB'
    ($values, $space) =  Graphics::Toolkit::Color::Space::Hub::deformat( [255, 10 , 0] ); # same result

=head2 deformat_partial_hash

This is a special case of the I<deformat> routine for the I<hash> and
I<char_hash> format (see I</FORMATS>). It can tolerate missing values.
The result will also be a tuple (ARRAY) with missing values being undef.
Since there is a given search order, a hash with only a I<hue> value will
always assume a I<HSL> space. To change that you can provide the space
name as a second, optional argument.


=head1 SEE ALSO

=over 4

=item *

L<Convert::Color>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2023-25 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>
