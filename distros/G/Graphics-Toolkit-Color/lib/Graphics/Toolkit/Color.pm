
# read only color holding object with methods for relation, mixing and transitions

package Graphics::Toolkit::Color;
our $VERSION = '1.54';
use v5.12;

use Carp;
use Graphics::Toolkit::Color::Name;
use Graphics::Toolkit::Color::Value;

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
    @args = ([@args]) if @args == 3 or Graphics::Toolkit::Color::Value::is_space( $args[0]);
    @args = ({ @args }) if @args == 6 or @args == 8;
    return carp $new_help unless @args == 1;
    _new_from_scalar($args[0]);
}
sub _new_from_scalar {
    my ($color_def) = shift;
    my (@rgb, $name, $origin);
    if (not ref $color_def and substr($color_def, 0, 1) =~ /\w/){
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
    } elsif (ref $color_def eq __PACKAGE__) { # enables color objects to be passed as arguments
        ($name, @rgb, $origin) = @$color_def;
    } else {                                  # define color by numbers in any format
        my ($val, $origin) = Graphics::Toolkit::Color::Value::deformat( $color_def );
        return carp $new_help unless ref $val;
        @rgb = Graphics::Toolkit::Color::Value::deconvert( $val, $origin );
        return carp $new_help unless @rgb == 3;
        $name = Graphics::Toolkit::Color::Name::name_from_rgb( @rgb );
    }
    bless [$name, @rgb, $origin];
}

## getter ##############################################################

sub name        { $_[0][0] }
sub string      { $_[0]->name ? $_[0]->name : $_[0]->values('rgb', 'hex') }

    sub rgb         {  $_[0]->values('rgb') }
    sub red         {($_[0]->values('rgb'))[0] }
    sub green       {($_[0]->values('rgb'))[1] }
    sub blue        {($_[0]->values('rgb'))[2] }
    sub rgb_hex     { $_[0]->values('rgb', 'hex') }
    sub rgb_hash    { $_[0]->values('rgb', 'hash') }
    sub hsl         { $_[0]->values('hsl') }
    sub hue         {($_[0]->values('hsl'))[0] }
    sub saturation  {($_[0]->values('hsl'))[1] }
    sub lightness   {($_[0]->values('hsl'))[2] }
    sub hsl_hash    { $_[0]->values('hsl', 'hash') }

sub _rgb    { [@{$_[0]}[1 .. 3]] }
sub _origin {    $_[0][4] }
sub values      {
    my ($self, $space, @format) = @_;
    my @val = Graphics::Toolkit::Color::Value::convert( $self->_rgb, $space);
    Graphics::Toolkit::Color::Value::format( \@val, $space, @format);
}

## measurement methods ##############################################################

sub distance_to { distance(@_) }
sub distance {
    my ($self) = shift;
    my ($c2, $space_name, $subspace) = @_;
    if (ref $c2 eq 'HASH' and exists $c2->{'to'}){
        ($c2, $space_name, $subspace) = ($c2->{'to'}, $c2->{'in'}, $c2->{'notice_only'});
    }
    return carp "missing argument: color object or scalar color definition" unless defined $c2;
    $c2 = _new_from_scalar( $c2 );
    return carp "distance: second color is badly defined" unless ref $c2 eq __PACKAGE__;
    $space_name //= 'HSL';
    return carp "color space $space_name is unknown" unless ref Graphics::Toolkit::Color::Value::space( $space_name );
    my @val1 =  Graphics::Toolkit::Color::Value::convert( $self->_rgb, $space_name );
    my @val2 =  Graphics::Toolkit::Color::Value::convert( $c2->_rgb, $space_name );
    Graphics::Toolkit::Color::Value::distance( \@val1, \@val2, $space_name, $subspace);
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
    return unless ref $arg eq 'HASH';

    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Value::partial_hash_deformat( $arg );
    return carp "Given keywords do not match any known color space!! Please check the documentation of " unless ref $pos_hash;
    my @val = Graphics::Toolkit::Color::Value::convert( $self->_rgb, $space_name );
    for my $pos (keys %$pos_hash) {
        $val[ $pos ] = $pos_hash->{ $pos };
    }
    _new_from_scalar( [ Graphics::Toolkit::Color::Value::deconvert( \@val, $space_name ) ] );
}

sub add {
    my ($self, @args) = @_;
    my $arg = _get_arg_hash( @args );
    return unless ref $arg eq 'HASH';

    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Value::partial_hash_deformat( $arg );
    return carp "Given keywords do not match any known color space!! Please check the documentation of " unless ref $pos_hash;
    my @val = Graphics::Toolkit::Color::Value::convert( $self->_rgb, $space_name );
    for my $pos (keys %$pos_hash) {
        $val[ $pos ] += $pos_hash->{ $pos };
    }
    _new_from_scalar( [ Graphics::Toolkit::Color::Value::deconvert( \@val, $space_name ) ] );
}


sub blend_with { $_[0]->blend( with => $_[1], pos => $_[2], in => 'HSL') }
sub blend {
    my ($self, @args) = @_;
    my $arg = _get_arg_hash( @args );
    return unless ref $arg eq 'HASH';
    my $c2 = _new_from_scalar( $arg->{'with'} );
    return croak "need a second color under the key 'with' ( with => { h=>1, s=>2, l=>3 })" unless ref $c2;
    my $pos = $arg->{'pos'} // 0.5;
    my $space_name = $arg->{'in'} // 'HSL';
    return carp "color space $space_name is unknown" unless ref Graphics::Toolkit::Color::Value::space( $space_name );
    my @val1 =  Graphics::Toolkit::Color::Value::convert( $self->_rgb, $space_name );
    my @val2 =  Graphics::Toolkit::Color::Value::convert( $c2->_rgb,  $space_name );
    my @blend_val = map {((1-$pos) * $val1[ $_ ]) + ($pos * $val2[ $_ ])}
                         0 .. Graphics::Toolkit::Color::Value::space( $space_name )->dimensions - 1;
    _new_from_scalar( [ Graphics::Toolkit::Color::Value::deconvert( \@blend_val, $space_name ) ] );
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
    return croak "need a second color under the key 'to' ( to => [10, 20, 30])" unless ref $c2;
    my $space_name = $arg->{'in'} // 'HSL';
    my $steps = int(abs($arg->{'steps'} // 3));
    my $power = $arg->{'dynamic'} // 0;
    $power = ($power >= 0) ? $power + 1 : -(1/($power-1));
    return $self if $steps == 1;
    my $space = Graphics::Toolkit::Color::Value::space( $space_name );
    return carp "color space $space_name is unknown" unless ref $space;
    my @val1 =  Graphics::Toolkit::Color::Value::convert( $self->_rgb, $space_name );
    my @val2 =  Graphics::Toolkit::Color::Value::convert( $c2->_rgb, $space_name );
    my @delta_val = $space->delta (\@val1, \@val2 );
    my @colors = ();
    for my $nr (1 .. $steps-2){
        my $pos = ($nr / ($steps-1)) ** $power;
        my @rval = map {$val1[$_] + ($pos * $delta_val[$_])} 0 .. $space->dimensions - 1;
        my @rgb = Graphics::Toolkit::Color::Value::deconvert( \@rval, $space_name );
        push @colors, _new_from_scalar( [ @rgb ] );
    }
    return $self, @colors, $c2;
}

sub complementary {
    my ($self) = shift;
    my ($count) = int ((shift // 1) + 0.5);
    my ($saturation_change) = shift // 0;
    my ($lightness_change) = shift // 0;
    my @hsl2 = my @hsl_l = my @hsl_r = $self->values('HSL');
    $hsl2[0] += 180;
    $hsl2[1] += $saturation_change;
    $hsl2[2] += $lightness_change;
    @hsl2 = Graphics::Toolkit::Color::Value::HSL::trim( @hsl2 ); # HSL of C2
    my $c2 = color( h => $hsl2[0], s => $hsl2[1], l => $hsl2[2] );
    return $c2 if $count < 2;
    my (@colors_r, @colors_l);
    my @delta = (360 / $count, (($hsl2[1] - $hsl_r[1]) * 2 / $count), (($hsl2[2] - $hsl_r[2]) * 2 / $count) );
    for (1 .. ($count - 1) / 2){
        $hsl_r[$_] += $delta[$_] for 0..2;
        $hsl_l[0] -= $delta[0];
        $hsl_l[$_] = $hsl_r[$_] for 1,2;
        $hsl_l[0] += 360 if $hsl_l[0] <    0;
        $hsl_r[0] -= 360 if $hsl_l[0] >= 360;
        push @colors_r, color( H => $hsl_r[0], S => $hsl_r[1], L => $hsl_r[2] );
        unshift @colors_l, color( H => $hsl_l[0], S => $hsl_l[1], L => $hsl_l[2] );
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
    say $red->add( 'blue' => 256 )->name;           # mix in HSL: 'fuchsia'
    color( 0, 0, 255)->values('HSL');               # 240, 100, 50 = blue
                                                    # mix blue with a little grey in HSL
    $blue->blend( with => {H=> 0, S=> 0, L=> 80}, pos => 0.1);
    $red->gradient( to => '#0000FF', steps => 10);  # 10 colors from red to blue
    $red->complementary( 3 );                       # get fitting red green and blue


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
either use the name of a predefined constant or provide values in several
L<Graphics::Toolkit::Color::Value/COLOR-SPACES>

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

=head2 new( '#rgb' )

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

The named array syntax of the last example works for nany supported space.


=head2 new( {r => $r, g => $g, b => $b} )

Hash with the keys 'r', 'g' and 'b' does the same as shown in previous
paragraph, only more declarative. Casing of the keys will be normalised
and only the first letter of each key is significant.

    my $red = Graphics::Toolkit::Color->new( r => 255, g => 0, b => 0 );
    my $red = Graphics::Toolkit::Color->new({r => 255, g => 0, b => 0}); # works too
    ... Color->new( Red => 255, Green => 0, Blue => 0);   # also fine

=head2 new( {h => $h, s => $s, l => $l} )

To define a color in HSL space, with values for L</hue>, L</saturation> and
L</lightness>, use the following keys, which will be normalized as decribed
in previous paragraph. Out of range values will be corrected to the
closest value in range. Since L</hue> is a polar coordinate,
it will be rotated into range, e.g. 361 = 1.

    my $red = Graphics::Toolkit::Color->new( h =>   0, s => 100, l => 50 );
    my $red = Graphics::Toolkit::Color->new({h =>   0, s => 100, l => 50}); # good too
    ... ->new( Hue => 0, Saturation => 100, Lightness => 50 ); # also fine

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
was created with RGB or HSL values.
If no color is found, C<name> returns an empty string.
All names are at: L<Graphics::Toolkit::Color::Constant/NAMES>
(See als: L</new(-'name'-)>)

=head2 string

String that can be serialized back into a color an object
(recreated by Graphics::Toolkit::Color->new( $string )).
It is either the color L</name> (if color has one) or result of L</rgb_hex>.

=head2 values

Returns the color values.

First argument is the name of a color space: The options are:
'rgb' (default), hsl, cmyk and cmy.

Second argument is the format. That can vary from space to space but
generally available are C<list> (default), C<hash>, C<char_hash>
and names or initials of the value names of that particular space.
RGB also provides the option C<hex> to get values like '#aabbcc'.

    say $color->values();                      # get list of rgb : 0, 0, 255
    say $blue->values('RGB', 'hash');          # { red => 0. green => 0, blue => 255}
    say $blue->values('RGB', 'char_hash');     # { r => 0. g => 0, b => 255}
    say $blue->values('RGB', 'hex');           # '#00FFFF'
    say $color->values('HSL', 'saturation');   # 100

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

A floating pointnumber that measures the distance (difference) between
two colors (color of the calling object and C2, first argument).
The I<distance> is  measured in HSL space unless told otherwise.
It takes three arguments, only the first is required.

1. Second color (C2) in any scalar definition as I<new> would accept
(see chapter L</CONSTRUCTOR>).

2. The color space the difference is measured in. (see L<Graphics::Toolkit::Color::Value/COLOR-SPACES>)

3. The subspace as a string. For instance you want to ignore lightness
in HSL, then you subspace would be I<'hs'> (initials of the other two dimensions).
If you want to observe only one dimension of a color space you can name
is also fully (I<Hue>).

    # how close is blue to lapis color?
    my $d = $blue->distance( to => 'lapisblue' );
    # same amount of blue?
    $d = $blue->distance( to => 'airyblue', in => 'RGB', notice_only => 'Blue');
    # same hue ?
    $d = $color->distance( to => $c2, in => 'HSL', notice_only => 'hue' );
    # same command in hash syntax:
    $d = $color->distance( {to => $c2, in => 'HSL', notice_only => 'Hue' });

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
result will be rounded (trimmed), to keep it inside the defined RGB space.

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
   Numbers below 0 and above 1 are possible, butlikely to be trimmed to
   fit inside the color space. Name of the argument is I<pos>.

3. Color space name (default is I<HSL> - all can be seen unter
   L<Graphics::Toolkit::Color::Value/COLOR-SPACES>). Name of the argument
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

=head2 complementary

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

    my @colors = $c->complementary( 3, +20, -10 );

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

