
# store all color space objects, to convert check, convert and measure color values

package Graphics::Toolkit::Color::Space::Hub;
use v5.12;
use warnings;

#### internal space loading ############################################
our $default_space_name = 'RGB';
our @load_order = ($default_space_name,
                  qw/RGBLinear CMY CMYK HSL HSV HSB HWB NCol YIQ YUV/,
                  qw/CIEXYZ CIERGB CIELAB CIELUV CIELCHab CIELCHuv HunterLAB/,
                  qw/AppleRGB AdobeRGB ProPhotoRGB WideGamutRGB/,
                  qw/DisplayP3Linear DisplayP3 DCIP3Linear DCIP3 Rec709 Rec2020/,
                  qw/OKLAB OKLCH/);
add_space( require "Graphics/Toolkit/Color/Space/Instance/$_.pm" ) for @load_order;
my ($default_space, @search_order, %space_obj, %next_conversion_node);

#### space API #########################################################
sub is_space_name      { 
	(ref get_space( $default_space->normalize_name( $_[0] ))) ? 1 : 0 }
sub all_space_names    { sort keys %space_obj }
sub default_space_name { $default_space_name }
sub default_space      { $default_space }
sub get_space          { # takes only normal names or alias names
    my $name = shift;
    return unless defined $name;
	exists $space_obj{ $name }  ? $space_obj{ $name } : '';
}
sub try_get_space      { # takes any name variant and defaults to $default_space_name
    my $name = shift || $default_space_name;
    return $name if ref $name eq 'Graphics::Toolkit::Color::Space' and is_space_name( $name->name );
    $name = default_space()->normalize_name( $name );
    my $space = get_space( $name );
    return (ref $space) ? $space
                        : "$name is an unknown color space, try one of: ".(join ', ', all_space_names());
}

sub add_space {
    my $space = shift;
    return 'add_space got no Graphics::Toolkit::Color::Space object as argument' if ref $space ne 'Graphics::Toolkit::Color::Space';
    my $name = $space->name;
    my $alias = $space->name('alias');
    return "can not add color space object without a name" unless $name;
    return "color space name $name is already taken" if ref get_space( $name );
    if ($name eq $default_space_name) { # there is no parent
		$default_space = $space;
    } else {
		my $conversion_parent = $space->conversion_tree_parent;
		return "can not add color space $name, it has no converter" unless defined $conversion_parent and $conversion_parent;
		$conversion_parent = $space->normalize_name( $conversion_parent );
        my $parent_space = get_space( $conversion_parent );
        return "color space $name does only convert into '$conversion_parent', which is no known color space" unless ref $parent_space;
        my $parent_name = $parent_space->name;
        $next_conversion_node{ $parent_name }{ $name } = $name;
        unless ($parent_name eq $default_space_name){
			my $upper_space_name = $default_space_name;
			while ($upper_space_name ne $parent_name){
				$upper_space_name = $next_conversion_node{ $upper_space_name }{ $name } 
				                  = $next_conversion_node{ $upper_space_name }{ $parent_name };
			}
		}
    }
    push @search_order, $name;
    $space_obj{ $name } = $space;
    $space_obj{ $alias } = $space if $alias and not ref get_space( $alias );
    return 1;
}
sub remove_space {
    my $name = shift;
    return "need name of color space as argument in order to remove the space" unless defined $name and $name;
    my $space = try_get_space( $name );
    return "can not remove unknown color space: $name" if not ref $space;
    return "can not remove default color space: $name" if $space->name eq $default_space_name;

    $name = $space->name;
	my $upper_space_name = $default_space_name;
	while ($upper_space_name ne $name){
		$upper_space_name = delete $next_conversion_node{ $upper_space_name }{ $name };
	}
    delete $space_obj{ $space->name('alias') } if $space->name('alias');
    delete $space_obj{ $name };
}

#### tuple API ##########################################################
sub convert { # normalized RGB tuple, ~space_name --> |normalized tuple in wanted space
    my ($tuple, $target_space_name, $want_result_normalized, $source_tuple, $source_space_name) = @_;
    return "need an ARRAY ref with 3 normalized RGB values as first argument in order to convert them" 
		unless $default_space->is_number_tuple( $tuple );
    my $target_space = try_get_space( $target_space_name );
    return "got unknown space name: '$target_space_name' as second argument, can not convert " unless ref $target_space;
    my $source_space = try_get_space( $source_space_name );
    return "did not found target color space !'$target_space_name'" unless ref $target_space;
    if ($source_space_name xor $source_tuple){
		return "arguments source_space_name and source_values (nr. 4 and 5) have to be provided both or none of them";
	} elsif ($source_space_name and $source_tuple) {
		return "got unknown source color space $source_space_name" if not ref $source_space;
		return "argument source_values has to be a tuple, if provided" unless $source_space->is_number_tuple( $source_tuple );
	}

    $tuple = [@$tuple];                       # unwrap ref to avoid spooky action
    my $current_space_name = $default_space_name; # we start in RGB
    $target_space_name = $target_space->name; # use only normalized name
    $want_result_normalized //= 0;            # normal flags to start state
    my $tuple_is_normal = 1;

    while ($current_space_name ne $target_space_name){
		my $next_space_name = $next_conversion_node{ $current_space_name }{ $target_space_name };
		# replace tuple with values from constructor if possible
		if (defined $source_space_name and $next_space_name eq $source_space_name){
            $tuple = [@$source_tuple];
            $tuple_is_normal = 1;
        } else {
			my $next_space = get_space( $next_space_name );
            my @normal_in_out = $next_space->converter_normal_states( 'from', $current_space_name );
            $tuple = $next_space->normalize( $tuple ) if not $tuple_is_normal and $normal_in_out[0];
            $tuple = $next_space->denormalize( $tuple ) if $tuple_is_normal and not $normal_in_out[0];
            $tuple = $next_space->convert_from( $current_space_name, $tuple );
            $tuple_is_normal = $normal_in_out[1];
            if (not $tuple_is_normal and $next_space_name ne $target_space_name){
				$tuple_is_normal = 1;
				$tuple = $next_space->normalize( $tuple );
			}
        }
		$current_space_name = $next_space_name;		
	}
    $tuple = $target_space->normalize( $tuple )   if not $tuple_is_normal and $want_result_normalized;
    $tuple = $target_space->denormalize( $tuple ) if $tuple_is_normal and not $want_result_normalized;
    return $tuple;
}
sub deconvert { # normalized value tuple --> RGB tuple
    my ($tuple, $original_space_name, $want_result_normalized, $source_tuple, $source_space_name) = @_;
    my $original_space = try_get_space( $original_space_name );
    my $source_space = try_get_space( $source_space_name );
    $want_result_normalized //= 0;
    return "need a space name to convert from as second argument" unless defined $original_space_name;
    return "got unknown color space name as second argument" unless ref $original_space;
    return "need as first argument an ARRAY with valid number of normalized values from the color space ". $original_space->name
		unless $original_space->is_number_tuple( $tuple );
   
    if ($source_space_name xor $source_tuple){
		return "arguments source_space_name and source_values (nr. 4 and 5) have to be provided both or none of them";
	} elsif ($source_space_name and $source_tuple) {
		return "got unknown source color space $source_space_name" if not ref $source_space;
		return "argument source_values has to be a tuple, if provided" unless $source_space->is_number_tuple( $source_tuple );
	}
    
    # none conversion cases        
    if ($original_space->name eq $default_space_name) { # nothing to convert
        return ($want_result_normalized) ? $tuple : $original_space->denormalize( $tuple );
    }
    my $current_space = $original_space;
    my $tuple_is_normal = 1;
    # actual conversion
    while ($current_space->name ne $default_space_name){
        my ($next_space_name, @next_options) = $current_space->conversion_tree_parent;
        $next_space_name = shift @next_options while @next_options and $next_space_name ne $default_space_name;
        # replace tuple with values from constructor if possible
        if ($source_space_name and $next_space_name eq $source_space->name){
            $tuple = [@$source_tuple];
            $tuple_is_normal = 1;
        } else {
            my @normal_in_out = $current_space->converter_normal_states( 'to', $next_space_name );
            $tuple = $current_space->normalize( $tuple ) if not $tuple_is_normal and $normal_in_out[0];
            $tuple = $current_space->denormalize( $tuple ) if $tuple_is_normal and not $normal_in_out[0];
            $tuple = $current_space->convert_to( $next_space_name, $tuple);
            $tuple_is_normal = $normal_in_out[1];
            if (not $tuple_is_normal and $current_space->name ne $default_space_name){
				$tuple_is_normal = 1;
				$tuple = $current_space->normalize( $tuple );
			}
        }
        $current_space = get_space( $next_space_name );
    }
    $tuple = $current_space->normalize( $tuple )   if not $tuple_is_normal and $want_result_normalized;
    $tuple = $current_space->denormalize( $tuple ) if $tuple_is_normal and not $want_result_normalized;
    return $tuple;
}

sub deformat { # formatted color def --> normalized values
    my ($color_def, $ranges, $suffix) = @_;
    return 'got no color definition' unless defined $color_def;
    my ($tuple, $original_space, $format_name);
    for my $space_name (@search_order) {
        my $color_space = get_space( $space_name );
        ($tuple, $format_name) = $color_space->deformat( $color_def );
        if (defined $format_name){
            $original_space = $color_space;
            last;
        }
    }
    return "could not deformat color definition: '$color_def'" unless ref $original_space;
    return $tuple, $original_space->name, $format_name;
}
sub deformat_partial_hash { # convert partial hash into
    my ($value_hash, $space_name) = @_;
    return unless ref $value_hash eq 'HASH';
    my $space = try_get_space( $space_name );
    return $space unless ref $space;
    my @space_name_options = (defined $space_name and $space_name) ? ($space->name) : (@search_order);
    for my $space_name (@space_name_options) {
        my $color_space = try_get_space( $space_name );
        my $tuple = $color_space->tuple_from_partial_hash( $value_hash );
        next unless ref $tuple;
        return wantarray ? ($tuple, $color_space->name) : $tuple;
    }
    return undef;
}

sub distance { # @c1 @c2 -- ~space ~select @range --> +
    my ($tuple_a, $tuple_b, $space_name, $select_axis, $range) = @_;
    my $color_space = try_get_space( $space_name );
    return $color_space unless ref $color_space;
    $tuple_a = convert( $tuple_a, $space_name, 'normal' );
    $tuple_b = convert( $tuple_b, $space_name, 'normal' );
    my $delta = $color_space->delta( $tuple_a, $tuple_b );
    $delta = $color_space->denormalize_delta( $delta, $range );
    if (defined $select_axis){
        $select_axis = [$select_axis] unless ref $select_axis;
        my @selected_values = grep {defined $_} map {$delta->[$_]}
                              grep {defined $_} map {$color_space->pos_from_axis_name($_)} @$select_axis;
        $delta = \@selected_values;
    }
    my $d = 0;
    $d += $_ * $_ for @$delta;
    return sqrt $d;
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
    my $true = ...::Space::Hub::is_space_name( 'HSL' );
    my $HSL = ..Space::Hub::get_space( 'HSL');
    my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space();
    ...Space::Hub::all_space_names();                        # all space names and aliases

    ...::Space::Hub::convert(   'HSL' [0, 0, 1]);               # [2/3, 1, 0]
    ...::Space::Hub::deconvert( 'HSL' [2/3, 1, 0]);             # [  0, 0, 1] 
    ...::Space::Hub::deformat(  '#0000ff' );                    # [  0, 0, 1], 'RGB' , 'hex_string'
    ...::Space::Hub::distance(  [2/3, 1, 0], [0, 1, 0], 'HSL' );# 1/3

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
completely linear like in Euclidean (everyday) geometry.
A few spaces have more axis and some spaces are cylindrical. That
means that some axis are not lines but circles and the associated value
describes an angle.

Color definitions contain either the name of a space or the names
of its axis (long or short). If the space name or its long alias is used,
the values have to be provided in the same order as the axis described here.

Color space or axis names may be written in any combination of upper and
lower case characters, but I recommend using the spelling presented here.
Each axis has also two specific names, one long and one short, which are
in rare cases equal. To define a color according to a space you need
to provide for each axis one value, that is inside the required value
range and of a specified type (int or real with amount of decimals).

While I acknowledge that some of the spaces below should be called systems
to be technically correct, they still will be called spaces here, because
the main goal of this software is seamless interoperability between them.


=head2 RGB

... (alias B<SRGB> - standard RGB) is the default color space of this 
CPAN module. It is used by most computer hardware like monitors and follows
the logic of additive color mixing as produced by an overlay of three 
colored light beams. The sum of all colors will be white, as in opposite
to subtractive mixing. It is a completely Cartesian (Euclidean) 3D space
and thus a RGB tuple consists of three integer values:

B<red> (short B<r>) range: 0 .. 255, B<green> (short B<g>) range: 0 .. 255
and B<blue> (short B<b>) range: 0 .. 255.
A higher value means a stronger beam of that base color flows into the mix
above a black background, so that black is (0, 0, 0), white (255, 255, 255)
and a pure red (fully saturated color) is (255, 0, 0). RGB has a gamma
of 2.4, which is clipped in the corners (piecewise transfer function).

=head2 LinearRGB

Same as L</RGB> but with normal value ranges (0 .. 1) and removed piecewise
gamma correction. That means there is a linear correlation between the 
shown values and the RGB brightness of the pixel on the screen without
any adaptation to human sensibilities. Its alias name is B<LinRGB>.

=head2 CMY

is the opposite of L</RGB> since it follows the logic of subtractive
color mixing as used in printing. Think of it as the amount of colored
ink on white paper, so that white is (0,0,0) and black (1,1,1).
It uses normalized real value ranges: 0 .. 1.
An CMY tuple has also three values:

B<cyan> (short B<c>) is the inverse of I<red>,
B<magenta> (short B<m> ) is inverse to I<green> and
B<yellow> (short B<y>) is inverse of I<blue>.

=head2 CMYK

is an extension of L</CMY> with a fourth value named B<key> (short B<k>),
which is the amount of black ink mixed into the CMY color.
It also has an normalized range of 0 .. 1. This should not bother you
since you are free to change the range at your preference.

=head2 HSL

.. is a cylindrical space that orders colors along cognitive properties.
The first dimension is the angular one and it rotates in 360 degrees around
the rainbow of fully saturated colors: 0 = red, 15 approximates orange,
60 - yellow 120 - green, 180 - cyan, 240 - blue, 270 - violet,
300 - magenta, 330 - pink. 0 and 360 points to the same coordinate.
This module only outputs 0, even if accepting 360 as input. The second,
linear dimension (axis) measures the distance between a point the center
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
saturated color of whatever I<hue> sets. So unlike in C<HSL>, here every
color has its unique coordinates.

=head2 HSB

Is an alias to L</HSV>, just the I<value> axis is renamed with B<brightness> (B<b>).

=head2 HWB

An inverted L</HSV>, where the saturated, pure colors are on the center
column of the cylinder. It still has the same circular B<hue> dimension
with an integer range of 0 .. 360. The other two, linear dimensions
(also 0 .. 100 integer range with optional suffix '%') are B<whiteness>
(B<w>) and B<blackness> (B<b>). They describe how much white or black
are mixed into the pure hue. If both are zero, you get a pure color.
I<whiteness> of 100 always leads to white and I<blackness> of 100 always
leads to black. The space is truncated as a cone so the sum of I<whiteness>
and I<blackness> can never be greater than 100.

=head2 NCol

Is a more human readable variant of the L</HWB> space with an altered
B<hue> values, that consists of a letter and two digits.
The letter demarks one of the six areas around the rainbow. B<R> is I<Red>,
B<Y> (I<Yellow>), B<G> (I<Green>), B<C> (I<Cyan>), B<B> (I<Blue>),
B<M> (I<Magenta>). The two digits after this letter are an angular value,
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
this module computes with real (analogue) values to enable any precision
the user might prefer. To make this clear, this space holds the name B<YPbPr>.
It has three Cartesian axis: 1. B<luma> (short B<y>) with a real value
range of 0..1, 2. B<Pb> (short I<u>, -0.5 .. 0.5) and 3. B<Pr>
(short I<v>, -0.5 .. 0.5). (see also L</CIELUV>)

=head2 HunterLAB

predecessor of L</CIELAB> by Richard S. Hunter with no alias name and
slightly different color transitions on yellow-blue-direction.
The axis have same long and short names: B<L> with normal values (0 .. 1),
B<a> -172.30 .. 172.30 and B<b> -67.20 .. 67.20.


=head2 CIEXYZ

this space (alias B<XYZ>) has the axis B<X>, B<Y> and B<Z> (long and short
axis names are this time the same), that refer to the red, green and blue 
receptors (cones) in the retina (on the back side of the eye). Because 
those cones measure a lot more left and right than just exactly those colors,
they got these technical names. The values in that space tell you about 
the amount of chemical and neurological activity a color produces inside
the eye. The values ranges are always from zero and reach 95.047 on the
C<X> - axis, 100 on C<Y> and 108.883 on C<Z>, due to the used white
point of I<D65> which has these values divided by 100. The illuminant
I<D65> is standard for all CIE spaces except I<CIERGB>.

=head2 CIELAB

(alias B<LAB>) is a derivate of L</CIEXYZ> that reorders the colors along
axis that reflect how the brain processes them. It uses three information
channels. One named B<L> (lightness) with a real value range of (0 .. 100).
Second is channel B<a>, that reaches from red to green (-500 .. 500) and
thirdly B<b> from yellow to blue (-200 .. 200). Values will be displayed
with three decimals. The long names of the axis names contain a '*'
and are thus: B<L*>, B<a*> and B<b*>. The I<a> and I<b> axis reflect the
opponent color theory.

=head2 CIELUV

(alias B<LUV>) is a more perceptually uniform version of L</CIELAB> and
the axis I<a> and I<b> got renamed to I<u> and I<v> (see L</YUV>) but
did not change their meaning. It has also three Cartesian dimension named
B<L*>, B<u*> and B<v*>, (short names have only the first letter of these names).
They have real valued ranges, which are 0 .. 100, -134 .. 220 and
-140 .. 122.

=head2 CIELCHab

(alias B<LCH>) is the cylindrical version of the L</CIELAB> with the
dimensions B<luminance>, B<chroma> and B<hue> - in short  B<l>,  B<c> and B<h>.
The real valued ranges are from zero to 100, 539 and 360 respectively.
Like with the L</HSL> and L</HSV>, hue is the circular dimensions and its
values are meant as degrees in a circle. For gray colors in the middle
column the value I<chroma> has no importance and will be in this
implementation always be zero.

=head2 CIELCHuv

(alias B<LCHuv>) is the cylindrical version of the L</CIELUV> and works 
similar to L<CIELCHab> except the real valued range of B<chroma> is 
(0 .. 261) and the space has no alias name.

=head2 CIERGB

1931 standardized, normal valued (0 .. 1) space with same axis as L</RGB>:
I<red> (I<r>), I<green> (I<g>) and I<blue> (I<b>). 
It has the illuminant E and no gamma (linear RGB).

=head2 AdobeRGB

(alias name B<opRGB>) is a normalized L</RGB> variant with the 
CIE white point D65 a gamma of about 2.2.

=head2 AppleRGB

normal L</RGB> variant with white point of D65 and gamma is 1.8.
It is the legacy color space Apple used in the 90ies.

=head2 ProPhotoRGB

(alias name B<ROMMRGB>) normal L</RGB> variant with a white point of
D50, gamma = 1.8 and a wide gamut.

=head2 WideGamutRGB

Even greater gamut then previous spaces with white point D50 and gamma of ~2.2.

=head2 Display P3

wide gamut RGB variant with same gamma function as L</RGB>, 
has alias name B<P3>.

=head2 Display P3 Linear

P3 variant without any gamma - wider gamut variant of L<\LinearRGB>.

=head2 DCI-P3

Simply I<Display P3 Linear> with a gamma of 2.4, has alias name B<SMPTE P3>.

=head2 Rec.709

RGB space, has alias name B<BT.709>.

=head2 Rec.2020

RGB space, has alias name B<BT.2020>.

=head2 OKLAB

is a modern improvement of L</CIELAB> by Bjoern Ottosson with no alias name
and for nicer color transitions and better numeric behaviour.
The axis long names are same as the same ones: B<L> with values (0 .. 1),
B<a> and B<b> with both (-0.5 .. 0.5). If you want to use it like in B<CSS>,
just add C<< range => [100, [-120,120], [-120,120]], suffix => '%' >>.

=head2 OKLCH

is the cylindrical variant of L</OKLAB> just parallels L</CIELCHab>.
The axis names are again: B<luminance>, B<chroma> and B<hue> - in short:
B<l>,  B<c> and B<h>. Value ranges are similar as in C<OKLAB>:
I<luminance> 0 .. 1 (normal), I<chroma> 0 .. 0.5 and I<hue> are angles
of 0 .. 360 degrees. Also if you prefer a B<CSS> compatible format,
use C<< range => [100, 120, 360] >> and a preferred suffix.


=head1 RANGES

As pointed out in the previous paragraph, each dimension of color space has
its default range. However, one can demand custom value ranges, if the method
accepts a range descriptor as argument. If so, the following values are accepted:

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

Unless stated otherwise, these formats are available in all color spaces.

=head2 list

A list of values, the first being the name of the color space. The name
can be omitted, if it is the default color space (L</RGB>).
Default format of the output method "values".

    (10, 20, 30)
    ('XYZ', 15, 3.53, 37.1)

=head2 named_array

The same with squared brackets around.

    [RGB => 10, 20, 30]


=head2 named_string

Same inside a quotes.

    'RGB: 10, 20, 30'

=head2 css_string

Strings for usage in CSS, SVG files and alike. Here are commas optional.
There are two spots where space is not allowed: 1. Between the space
name and opening bracket and between axis value and value suffix (here '%').

    'rgb(10, 20, 30)'
    'hsl(10  20%  30%)'

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

This package provides two sets of routines. The first is just a lookup
of what color space objects are available. What are their names to
retrieve them? The second set consists of 5 routines that can handle a 
lot of unknowns. The are:

    1. convert               (RGB -> any)
    2. deconvert             (any -> RGB)
    3. deformat              (extract values)
    4. deformat_partial_hash (deformat hashes with missing axis)
    5. distance              (distance between 2 colors in any space)

=head2 all_space_names

Returns a list of string values, which are the names of all available
color space. See L</COLOR-SPACES>.

=head2 is_space_name

Needs one argument, that is supposed to be a color space name.
If it is, the result is an 1, otherwise 0 (perlish pseudo boolean).

=head2 get_space

Needs one argument, that is supposed to be a color space name.
If it is, the result is the according color space object, otherwise undef.

=head2 try_get_space

Same thing but if nothing is provided it returns the default space.

=head2 default_space

Return the color space object of (currently) RGB name space.
This name space is special since every color space object provides
converters from and to RGB, but the RGB itself has no converter.


=head2 convert

Converts a value tuple (first argument) from base space (RGB) into any
space mentioned space (second argument - see L</COLOR-SPACES>).
The values have to be normalized (inside 0..1). If there are outside
the acceptable range, there will be clamped, so that the result will
also normal. If the third argument is positive (pseudo boolean true),
the output will also be normal. 
Arguments four and five are for internal use to omit rounding errors.
They are the original, normalized values and their color space.
When during the conversion, the method tries to convert into the space 
of origin, it replaces the current values with the source values.

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
color name space. Third is the format name.

    my ($values, $space) =  Graphics::Toolkit::Color::Space::Hub::deformat( 'ff00a0' );
    # [255, 10, 0], 'RGB'
    ($values, $space) =  Graphics::Toolkit::Color::Space::Hub::deformat( [255, 10 , 0] ); # same result

=head2 deformat_partial_hash

This is a special case of the I<deformat> routine for the I<hash> and
I<char_hash> format (see L</FORMATS>). It can tolerate missing values.
The result will also be a tuple (ARRAY) with missing values being undef.
Since there is a given search order, a hash with only a I<hue> value will
always assume a I<HSL> space. To change that you can provide the space
name as a second, optional argument.

=head2 distance


=head1 SEE ALSO

=over 4

=item *

L<Convert::Color>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2023-26 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>
