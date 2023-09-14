
# read only color holding object with methods for relation, mixing and transitions

package Graphics::Toolkit::Color;
our $VERSION = '1.61';
use v5.12;

use Carp;
use Graphics::Toolkit::Color::Name;
use Graphics::Toolkit::Color::Values;

use Exporter 'import';
our @EXPORT_OK = qw/color/;

my $new_help = 'constructor of Graphics::Toolkit::Color object needs either:'.
        ' 1. hash or ref (RGB, HSL or any other): ->new(r => 255, g => 0, b => 0), ->new({ h => 0, s => 100, l => 50 })'.
        ' 2. RGB array or ref: ->new( [255, 0, 0 ]) or >new( 255, 0, 0 )'.
        ' 3. hex form "#FF0000" or "#f00" 4. a name: "red" or "SVG:red".';

## constructor #########################################################

sub color { Graphics::Toolkit::Color->new ( @_ ) }

sub new {
    my ($pkg, @args) = @_;
    @args = ([@args]) if @args == 3 or Graphics::Toolkit::Color::Space::Hub::is_space( $args[0]);
    @args = ({ @args }) if @args == 6 or @args == 8;
    return carp $new_help unless @args == 1;
    _new_from_scalar($args[0]);
}
sub _new_from_scalar {
    my ($color_def) = shift;
    my ($value_obj, @rgb, $name, $origin);
    # strings that are not '#112233' or 'rgb: 23,34,56'
    if (not ref $color_def and substr($color_def, 0, 1) =~ /\w/ and $color_def !~ /,/){
        $name = $color_def;
        $origin = 'name';
        my $i = index( $color_def, ':');
        if ($i > -1 ){                        # resolve pallet:name
            my $pallet_name = substr $color_def, 0, $i;
            my $color_name = Graphics::Toolkit::Color::Name::_clean(substr $color_def, $i+1);
            my $module_base = 'Graphics::ColorNames';
            eval "use $module_base";
            return carp "$module_base is not installed, but it's needed to load external colors" if $@;
            my $module = $module_base.'::'.$pallet_name;
            eval "use $module";
            return carp "$module is not installed, but needed to load color '$pallet_name:$color_name'" if $@;

            my $pallet = Graphics::ColorNames->new( $pallet_name );
            @rgb = $pallet->rgb( $color_name );
            return carp "color '$color_name' was not found, propably not part of $module" unless @rgb == 3;
        } else {                              # resolve name ->
            @rgb = Graphics::Toolkit::Color::Name::rgb_from_name( $color_def );
            return carp "'$color_def' is an unknown color name, please check Graphics::Toolkit::Color::Name::all()." unless @rgb == 3;
        }
        $value_obj = Graphics::Toolkit::Color::Values->new( [@rgb] );
    } elsif (ref $color_def eq __PACKAGE__) { # enables color objects to be passed as arguments
        $name = $color_def->name;
        $value_obj = Graphics::Toolkit::Color::Values->new( $color_def->{'values'}->string );
    } else {                                  # define color by numbers in any format
        my $value_obj = Graphics::Toolkit::Color::Values->new( $color_def );
        return unless ref $value_obj;
        return _new_from_value_obj($value_obj);
    }
    bless {name => $name, values => $value_obj};
}
sub _new_from_value_obj {
    my ($value_obj) = @_;
    return unless ref $value_obj eq 'Graphics::Toolkit::Color::Values';
    bless {name => scalar Graphics::Toolkit::Color::Name::name_from_rgb( $value_obj->get() ), values => $value_obj};
}

## getter ##############################################################

sub name        { $_[0]{'name'} }

    sub string      { $_[0]{'name'} || $_[0]->{'values'}->string }
    sub rgb         { $_[0]->values( ) }
    sub red         {($_[0]->values( in => 'rgb'))[0] }
    sub green       {($_[0]->values( in => 'rgb'))[1] }
    sub blue        {($_[0]->values( in => 'rgb'))[2] }
    sub rgb_hex     { $_[0]->values( in => 'rgb', as => 'hex') }
    sub rgb_hash    { $_[0]->values( in => 'rgb', as => 'hash') }
    sub hsl         { $_[0]->values( in => 'hsl') }
    sub hue         {($_[0]->values( in => 'hsl'))[0] }
    sub saturation  {($_[0]->values( in => 'hsl'))[1] }
    sub lightness   {($_[0]->values( in => 'hsl'))[2] }
    sub hsl_hash    { $_[0]->values( in => 'hsl', as => 'hash') }

sub values      {
    my ($self) = shift;
    my %args = (not @_ % 2) ? @_ :
               (@_ == 1)    ? (in => $_[0])
                            : return carp "accept three optional, named arguments: in => 'HSL', as => 'css_string', range => 16";
    $self->{'values'}->get( $args{'in'}, $args{'as'}, $args{'range'} );
}

## measurement methods ##############################################################

sub distance_to { distance(@_) }
sub distance {
    my ($self) = shift;
    my %args = (not @_ % 2) ? @_ :
               (@_ == 1)    ? (to => $_[0])
                            : return carp "accept four optional, named arguments: to => 'color or color definition', in => 'RGB', metric => 'r', range => 16";
    my ($c2, $space_name, $metric, $range) = ($args{'to'}, $args{'in'}, $args{'metric'}, $args{'range'});
    return carp "missing argument: color object or scalar color definition" unless defined $c2;
    $c2 = _new_from_scalar( $c2 );
    return carp "second color for distance calculation (named argument 'to') is badly defined" unless ref $c2 eq __PACKAGE__;
    $self->{'values'}->distance( $c2->{'values'}, $space_name, $metric );
}

## single color creation methods #######################################

sub _get_arg_hash {
    my $arg = (ref $_[0] eq 'HASH') ? $_[0]
            : (not @_ % 2)          ? {@_}
            :                         {} ;
    return (keys %$arg) ? $arg : carp "need arguments as hash (with or without braces)";
}

sub set {
    my ($self, @args) = @_;
    my $arg = _get_arg_hash( @args );
    return unless ref $arg;
    _new_from_value_obj( $self->{'values'}->set( $arg ) );
}

sub add {
    my ($self, @args) = @_;
    my $arg = _get_arg_hash( @args );
    return unless ref $arg;
    _new_from_value_obj( $self->{'values'}->add( $arg ) );
}

sub blend_with { $_[0]->blend( with => $_[1], pos => $_[2], in => 'HSL') }
sub blend {
    my ($self, @args) = @_;
    my $arg = _get_arg_hash( @args );
    return unless ref $arg;
    my $c2 = _new_from_scalar( $arg->{'with'} );
    return croak "need a second color under the key 'with' ( with => { h=>1, s=>2, l=>3 })" unless ref $c2;
    my $pos = $arg->{'pos'} // $arg->{'position'} // 0.5;
    my $space_name = $arg->{'in'} // 'HSL';
    return carp "color space $space_name is unknown" unless Graphics::Toolkit::Color::Space::Hub::is_space( $space_name );
    _new_from_value_obj( $self->{'values'}->blend( $c2->{'values'}, $pos, $space_name ) );
}

## color set creation methods ##########################################


# for compatibility
sub gradient_to     { hsl_gradient_to( @_ ) }
sub rgb_gradient_to { $_[0]->gradient( to => $_[1], steps => $_[2], dynamic => $_[3], in => 'RGB' ) }
sub hsl_gradient_to { $_[0]->gradient( to => $_[1], steps => $_[2], dynamic => $_[3], in => 'HSL' ) }
sub gradient {
    my ($self, @args) = @_;
    my $arg = _get_arg_hash( @args );
    return unless ref $arg eq 'HASH';
    my $c2 = _new_from_scalar( $arg->{'to'} );
    return croak "need a second color under the key 'to' : ( to => ['HSL', 10, 20, 30])" unless ref $c2;
    my $space_name = $arg->{'in'} // 'HSL';
    my $steps = int(abs($arg->{'steps'} // 3));
    my $power = $arg->{'dynamic'} // 0;
    $power = ($power >= 0) ? $power + 1 : -(1/($power-1));
    return $self if $steps == 1;
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    return carp "color space $space_name is unknown" unless ref $space;
    my @val1 =  $self->{'values'}->get( $space_name, 'list', 'normal' );
    my @val2 =  $c2->{'values'}->get( $space_name, 'list', 'normal' );
    my @delta_val = $space->delta (\@val1, \@val2 );
    my @colors = ();
    for my $nr (1 .. $steps-2){
        my $pos = ($nr / ($steps-1)) ** $power;
        my @rval = map {$val1[$_] + ($pos * $delta_val[$_])} 0 .. $space->dimensions - 1;
        @rval = $space->denormalize ( \@rval );
        push @colors, _new_from_scalar( [ $space_name, @rval ] );
    }
    return $self, @colors, $c2;
}

sub complementary { complement(@_) }
sub complement { # steps => +,  delta => {}
    my ($self) = shift;
    my ($count) = int ((shift // 1) + 0.5);
    my ($saturation_change) = shift // 0;
    my ($lightness_change) = shift // 0;
    my @hsl2 = my @hsl_l = my @hsl_r = $self->values('HSL');
    my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');
    $hsl2[0] += 180;
    $hsl2[1] += $saturation_change;
    $hsl2[2] += $lightness_change;
    my $c2 = _new_from_scalar( [ 'HSL', @hsl2 ] );
    return $c2 if $count < 2;
    my (@colors_r, @colors_l);
    my @delta = (360 / $count, (($hsl2[1] - $hsl_r[1]) * 2 / $count), (($hsl2[2] - $hsl_r[2]) * 2 / $count) );
    for (1 .. ($count - 1) / 2){
        $hsl_r[$_] += $delta[$_] for 0..2;
        $hsl_l[0] -= $delta[0];
        $hsl_l[$_] = $hsl_r[$_] for 1,2;
        $hsl_l[0] += 360 if $hsl_l[0] <    0;
        $hsl_r[0] -= 360 if $hsl_l[0] >= 360;
        push    @colors_r, _new_from_scalar( [ 'HSL', @hsl_r ] );
        unshift @colors_l, _new_from_scalar( [ 'HSL', @hsl_l ] );
    }
    push @colors_r, $c2 unless $count % 2;
    $self, @colors_r, @colors_l;
}

sub bowl {
    my ($self, @args) = @_;
    my $arg = _get_arg_hash( @args );
    return unless ref $arg eq 'HASH';
# radius size in
# distance | count
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color - color palette creation helper

=head1 SYNOPSIS

    use Graphics::Toolkit::Color qw/color/;

    my $red = Graphics::Toolkit::Color->new('red'); # create color object
    say $red->add( 'blue' => 255 )->name;           # add blue value: 'fuchsia'
    color( 0, 0, 255)->values('HSL');               # 240, 100, 50 = blue
                                                    # mix blue with a little grey in HSL
    $blue->blend( with => { H=> 0, S=> 0, L=> 80 }, pos => 0.1);
    $red->gradient( to => '#0000FF', steps => 10);  # 10 colors from red to blue
    $red->complement( 3 );                          # get fitting red green and blue


=head1 DESCRIPTION

ATTENTION: deprecated methods of the old API will be removed on version 2.0.

Graphics::Toolkit::Color, for short GTC, is the top level API of this
module. It is designed to get fast access to a set of related colors,
that serve your need. While it can understand and output many color
formats, its primary (internal) format is RGB, because this it is
about colors that can be shown on the screen.

Humans access colors on hardware level (eye) in RGB, on cognition level
in HSL (brain) and on cultural level (language) with names.
Having easy access to all three and some color math should enable you to get the color
palette you desire quickly.

GTC are read only color holding objects with no additional dependencies.
Create them in many different ways (see section I<CONSTRUCTOR>).
Access its values via methods from section I<GETTER> or measure differences
and create related color objects via methods listed under I<METHODS>.


=head1 CONSTRUCTOR

There are many options to create a color objects.  In short you can
either use the name of a constant or provide values in several
L<Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES> and many formats
as described in this paragraph.

=head2 new('name')

Get a color by providing a name from the X11, HTML (CSS) or SVG standard
or a Pantone report. UPPER or CamelCase will be normalized to lower case
and inserted underscore letters ('_') will be ignored as perl does in
numbers (1_000 == 1000). All available names are listed under
L<Graphics::Toolkit::Color::Name::Constant/NAMES>. (See also: L</name>)

    my $color = Graphics::Toolkit::Color->new('Emerald');
    my @names = Graphics::Toolkit::Color::Name::all(); # select from these

=head2 new('scheme:color')

Get a color by name from a specific scheme or standard as provided by an
external module L<Graphics::ColorNames>::* , which has to be installed
separately. * is a placeholder for the pallet name, which might be:
Crayola, CSS, EmergyC, GrayScale, HTML, IE, Mozilla, Netscape, Pantone,
PantoneReport, SVG, VACCC, Werner, Windows, WWW or X. In ladder case
Graphics::ColorNames::X has to be installed. You can get them all at once
via L<Bundle::Graphics::ColorNames>. The color name will be  normalized
as above.

    my $color = Graphics::Toolkit::Color->new('SVG:green');
    my @s = Graphics::ColorNames::all_schemes();          # look up the installed

=head2 new('#rgb')

Color definitions in hexadecimal format as widely used in the web, are
also acceptable.

    my $color = Graphics::Toolkit::Color->new('#FF0000');
    my $color = Graphics::Toolkit::Color->new('#f00');    # works too


=head2 new( [$r, $g, $b] )

Triplet of integer RGB values (red, green and blue : 0 .. 255).
Out of range values will be corrected to the closest value in range.

    my $red = Graphics::Toolkit::Color->new( 255, 0, 0 );
    my $red = Graphics::Toolkit::Color->new([255, 0, 0]);        # does the same
    my $red = Graphics::Toolkit::Color->new('RGB' => 255, 0, 0);  # named tuple syntax
    my $red = Graphics::Toolkit::Color->new(['RGB' => 255, 0, 0]); # named ARRAY

The named array syntax of the last example, as any here following,
work for any supported color space.


=head2 new({ r => $r, g => $g, b => $b })

Hash with the keys 'r', 'g' and 'b' does the same as shown in previous
paragraph, only more declarative. Casing of the keys will be normalised
and only the first letter of each key is significant.

    my $red = Graphics::Toolkit::Color->new( r => 255, g => 0, b => 0 );
    my $red = Graphics::Toolkit::Color->new({r => 255, g => 0, b => 0}); # works too
                        ... ->new( Red => 255, Green => 0, Blue => 0);   # also fine
              ... ->new( Hue => 0, Saturation => 100, Lightness => 50 ); # same color
                  ... ->new( Hue => 0, whiteness => 0, blackness => 0 ); # still the same

=head2 new('rgb: $r, $g, $b')

String format (good for serialisation) that maximizes readability.

    my $red = Graphics::Toolkit::Color->new( 'rgb: 255, 0, 0' );
    my $blue = Graphics::Toolkit::Color->new( 'HSV: 240, 100, 100' );

=head2 new('rgb($r,$g,$b)')

Variant of string format that is supported by CSS.

    my $red = Graphics::Toolkit::Color->new( 'rgb(255, 0, 0)' );
    my $blue = Graphics::Toolkit::Color->new( 'hsv(240, 100, 100)' );

=head2 color

If writing

    Graphics::Toolkit::Color->new( ...);

is too much typing for you or takes to much space, import the subroutine
C<color>, which takes all the same arguments as described above.

    use Graphics::Toolkit::Color qw/color/;
    my $green = color('green');
    my $darkblue = color([20, 20, 250]);


=head1 GETTER / ATTRIBUTES

are read only methods - giving access to different parts of the
objects data.

=head2 name

String with normalized name (lower case without I<'_'>) of the color as
in X11 or HTML (SVG) standard or the Pantone report.
The name will be found and filled in, even when the object
was created numerical values.
If no color is found, C<name> returns an empty string.
All names are at: L<Graphics::Toolkit::Color::Name::Constant/NAMES>
(See als: L</new('name')>)

=head2 string

DEPRECATED:
String that can be serialized back into a color an object
(recreated by Graphics::Toolkit::Color->new( $string )).
It is either the color L</name> (if color has one) or result of L</rgb_hex>.

=head2 values

Returns the values of the color in given color space and with given format.
In short any format acceptable by the constructor can also be reproduce
by a getter method and in most cases by this one.

First argument is the name of a color space (named argument C<in>).
The options are to be found under: L<Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>
This is the only argument where the name can be left out.

Second argument is the format (named argument C<as>).
Not all formats are available under all color spaces, but the alway present
options are: C<list> (default), C<hash>, C<char_hash> and C<array>.

Third named argument is the upper border of the range inide which the
numerical values have to be. RGB are normally between 0..255 and
CMYK between 0 .. 1. If you want to change that order a different range.
Only a range of C<1> a.k.a. C<normal> displays decimals.


    $blue->values();                              # get list of rgb : 0, 0, 255
    $blue->values( in => 'RGB', as => 'list');    # same call
    $blue->values('RGB', as => 'hash');           # { red => 0. green => 0, blue => 255}
    $blue->values('RGB', as =>'char_hash');       # { r => 0. g => 0, b => 255}
    $blue->values('RGB', as => 'hex');            # '#00FFFF'
    $color->values(in => 'HSL');                  # 240, 100, 50
    $color->values(in => 'HSL', range => 1);      # 0.6666, 1, 0.5
    $color->values(in => 'RGB', range => 16);     # values in RGB16
    $color->values('HSB', as => 'hash')->{'hue'}; # how to get single values

=head2 hue

DEPRECATED:
Integer between 0 .. 359 describing the angle (in degrees) of the
circular dimension in HSL space named hue.
0 approximates red, 30 - orange, 60 - yellow, 120 - green, 180 - cyan,
240 - blue, 270 - violet, 300 - magenta, 330 - pink.
0 and 360 point to the same coordinate. This module only outputs 0,
even if accepting 360 as input.

=head2 saturation

DEPRECATED:
Integer between 0 .. 100 describing percentage of saturation in HSL space.
0 is grey and 100 the most colorful (except when lightness is 0 or 100).

=head2 lightness

DEPRECATED:
Integer between 0 .. 100 describing percentage of lightness in HSL space.
0 is always black, 100 is always white and 50 the most colorful
(depending on L</hue> value) (or grey - if saturation = 0).

=head2 rgb

DEPRECATED:
List (no I<ARRAY> reference) with values of L</red>, L</green> and L</blue>.

=head2 hsl

DEPRECATED:
List (no I<ARRAY> reference) with values of L</hue>, L</saturation> and L</lightness>.

=head2 rgb_hex

DEPRECATED:
String starting with character '#', followed by six hexadecimal lower case figures.
Two digits for each of L</red>, L</green> and L</blue> value -
the format used in CSS (#rrggbb).

=head2 rgb_hash

DEPRECATED:
Reference to a I<HASH> containing the keys C<'red'>, C<'green'> and C<'blue'>
with their respective values as defined above.

=head2 hsl_hash

DEPRECATED:
Reference to a I<HASH> containing the keys C<'hue'>, C<'saturation'> and C<'lightness'>
with their respective values as defined above.


=head1 COLOR RELATION METHODS

create new, related color (objects) or compute similarity of colors

=head2 distance

Is a floating point number that measures the Euclidean distance between
two colors. One color is the calling object itself and the second (C2)
has to provided as a named argument (I<to>), which is the only required one.
It ca come in the form of a second GTC object or any scalar color definition
I<new> would accept. The I<distance> is measured in HSL color space unless
told otherwise by the argument I<in>. The third argument is named I<metric>.
It's useful if you want to notice only certain dimensions. Metric is the
long or short name of that dimension or the short names of several dimensions.
They all have to come from one color space and one shortcut letter can be
used several times to heighten the weight of this dimension. The last
argument in named I<range> and is a range definition, unless you don't
want to compute the distance with the default ranges of the selected color
space.

    my $d = $blue->distance( to => 'lapisblue' );              # how close is blue to lapis color?
    $d = $blue->distance( to => 'airyblue', in => 'RGB', metric => 'Blue'); # same amount of blue?
    $d = $color->distance( to => $c2, in => 'HSL', metric => 'hue' );                  # same hue?
    # compute distance when with all value ranges 0 .. 1
    $d = $color->distance( to => $c2, in => 'HSL', metric => 'hue', range => 'normal' );

=head2 set

Create a new object that differs in certain values defined in the arguments
as a hash.

    $black->set( blue => 255 )->name;   # blue, same as #0000ff
    $blue->set( saturation => 50 );     # pale blue, same as $blue->set( s => 50 );

=head2 add

Create a Graphics::Toolkit::Color object, by adding any RGB or HSL values to current
color. (Same rules apply for key names as in new - values can be negative.)
RGB and HSL can be combined, but please note that RGB are applied first.

If the first argument is a Graphics::Toolkit::Color object, than RGB values will be added.
In that case an optional second argument is a factor (default = 1),
by which the RGB values will be multiplied before being added. Negative
values of that factor lead to darkening of result colors, but its not
subtractive color mixing, since this module does not support CMY color
space. All RGB operations follow the logic of additive mixing, and the
result will be rounded (clamped), to keep it inside the defined RGB space.

    my $blue = Graphics::Toolkit::Color->new('blue');
    my $darkblue = $blue->add( Lightness => -25 );
    my $blue2 = $blue->add( blue => 10 );        # this is bluer than blue

=head2 blend

Create a Graphics::Toolkit::Color object, that has the average values
between the calling object (color 1 - C1) and another color (C2).

It takes three named arguments, only the first is required.

1. The color C2 (scalar that is acceptable by the constructor: object, string, ARRAY, HASH).
   The name of the argument is I<with> (color is blended with ...).

2. Blend position is a floating point number, which defaults to 0.5.
   (blending ratio of 1:1 ). 0 represents here C1 and 1 is pure C2.
   Numbers below 0 and above 1 are possible, butlikely to be clamped to
   fit inside the color space. Name of the argument is I<pos>.

3. Color space name (default is I<HSL> - all can be seen unter
   L<Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>). Name of the argument
   is I<in>.

    # a little more silver than $color in the mix
    $color->blend( with => 'silver', pos => 0.6 );
    $color->blend({ with => 'silver', pos => 0.6 });             # works too!
    $blue->blend( with => {H => 240, S =>100, L => 50}, in => 'RGB' ); # teal

=head1 COLOR SET CREATION METHODS

=head2 gradient

Creates a gradient (a list of colors that build a transition) between
current (C1) and a second, given color (C2) by named argument I<to>.

The only required argument you have to give under the name I<to> is C2.
Either as an Graphics::Toolkit::Color object or a scalar (name, hex, hash
or reference), which is acceptable to a L</constructor>. This is the same
behaviour as in L</distance>.

An optional argument under the name I<steps> is the number of colors,
which make up the gradient (including C1 and C2). It defaults to 3.
Negative numbers will berectified by C<abs>.
These 3 color objects: C1, C2 and a color in between, which is the same
as the result of method L</blend>.

Another optional argument under the name I<dynamic> is also a float number,
which defaults to zero. It defines the position of weight of the transition
between the two colors. If $dynamic == 0 you get a linear transition,
meaning the L</distance> between neighbouring colors in the gradient.
If $dynamic > 0, the weight is moved toward C1 and vice versa.
The greater $dynamic, the slower the color change is in the beginning
of the gradient and faster at the end (C2).

The last optional argument names I<in> defines the color space the changes
are computed in. It parallels the argument of the same name of the method
L</blend> and L</distance>.

    # we turn to grey
    my @colors = $c->gradient( to => $grey, steps => 5, in => 'RGB');
    # none linear gradient in HSL space :
    @colors = $c1->gradient( to =>[14,10,222], steps => 10, dynamic => 3 );

=head2 complement

Creates a set of complementary colors.
It accepts 3 numerical arguments: n, delta_S and delta_L.

Imagine an horizontal circle in HSL space, whith a center in the (grey)
center column. The saturation and lightness of all colors on that
circle is the same, they differ only in hue. The color of the current
color object ($self a.k.a C1) lies on that circle as well as C2,
which is 180 degrees (half the circumference) apposed to C1.

This circle will be divided in $n (first argument) equal partitions,
creating $n equally distanced colors. All of them will be returned,
as objects, starting with C1. However, when $n is set to 1 (default),
the result is only C2, which is THE complementary color to C1.

The second argument moves C2 along the S axis (both directions),
so that the center of the circle is no longer in the HSL middle column
and the complementary colors differ in saturation. (C1 stays unmoved. )

The third argument moves C2 along the L axis (vertical), which gives the
circle a tilt, so that the complementary colors will differ in lightness.

    my @colors = $c->complement( 3, +20, -10 );

=head1 SEE ALSO

=over 4

=item *

L<Color::Scheme>

=item *

L<Graphics::ColorUtils>

=item *

L<Color::Fade>

=item *

L<Graphics::Color>

=item *

L<Graphics::ColorObject>

=item *

L<Color::Calc>

=item *

L<Convert::Color>

=item *

L<Color::Similarity>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2022-2023 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut

