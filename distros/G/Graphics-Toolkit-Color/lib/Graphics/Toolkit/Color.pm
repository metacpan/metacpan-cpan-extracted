
# read only color holding object with methods for relation, mixing and transitions

use v5.12;

package Graphics::Toolkit::Color;
our $VERSION = '1.08';

use Carp;
use Graphics::Toolkit::Color::Constant ':all';
use Graphics::Toolkit::Color::Value    ':all';

use Exporter 'import';
our @EXPORT_OK = qw/color/;

my $new_help = 'constructor of Graphics::Toolkit::Color object needs either:'.
        ' 1. RGB or HSL hash or ref: ->new(r => 255, g => 0, b => 0), ->new({ h => 0, s => 100, l => 50 })'.
        ' 2. RGB array or ref: ->new( [255, 0, 0 ]) or >new( 255, 0, 0 )'.
        ' 3. hex form "#FF0000" or "#f00" 4. a name: "red" or "SVG:red".';

## constructor #########################################################

sub color { Graphics::Toolkit::Color->new ( @_ ) }

sub new {
    my ($pkg, @args) = @_;
    @args = ([@args]) if @args == 3;
    @args = ({ $args[0] => $args[1], $args[2] => $args[3], $args[4] => $args[5] }) if @args == 6;
    return carp $new_help unless @args == 1;
    _new_from_scalar($args[0]);
}
sub _new_from_scalar {
    my ($arg) = shift;
    my $name;
    if (not ref $arg){ # resolve 'color_name' or '#RRGGBB' -> ($r, $g, $b)
        my @rgb = _rgb_from_name_or_hex($arg);
        return unless @rgb == 3;
        $name = $arg if index( $arg, ':') > -1;
        $arg = { r => $rgb[0], g => $rgb[1], b => $rgb[2] };
    } elsif (ref $arg eq 'ARRAY'){
        return carp "need exactly 3 RGB numbers!" unless @$arg == 3;
        $arg = { r => $arg->[0], g => $arg->[1], b => $arg->[2] };
    } elsif (ref $arg eq __PACKAGE__) {
        $arg = { r => $arg->[1], g => $arg->[2], b => $arg->[3] };
    }

    return carp $new_help unless ref $arg eq 'HASH' and keys %$arg == 3;
    my %named_arg = map { _shrink_key($_) =>  $arg->{$_} } keys %$arg; # reduce keys to lc first char

    my (@rgb, @hsl);
    if      (exists $named_arg{'r'} and exists $named_arg{'g'} and exists $named_arg{'b'}) {
        @rgb = trim_rgb(@named_arg{qw/r g b/});
        @hsl = hsl_from_rgb( @rgb );
    } elsif (exists $named_arg{'h'} and exists $named_arg{'s'} and exists $named_arg{'l'}) {
        @hsl = trim_hsl( @named_arg{qw/h s l/});
        @rgb = rgb_from_hsl( @hsl );
    } else { return carp "argument keys need to be r, g and b or h, s and l (long names and upper case work too!)" }
    $name = name_from_rgb( @rgb ) unless defined $name;
    bless [$name, @rgb, @hsl];
}
sub _rgb_from_name_or_hex {
    my $arg = shift;
    my $i = index( $arg, ':');
    if (substr($arg, 0, 1) eq '#'){                  # resolve #RRGGBB -> ($r, $g, $b)
        return rgb_from_hex( $arg );
    } elsif ($i > -1 ){                              # resolve pallet:name -> ($r, $g, $b)
        my $pallet_name = substr $arg,   0, $i;
        my $color_name = Graphics::Toolkit::Color::Constant::_clean_name(substr $arg, $i+1);
        my $module_base = 'Graphics::ColorNames';
        eval "use $module_base";
        return carp "$module_base is not installed, but it's needed to load external colors" if $@;
        my $module = $module_base.'::'.$pallet_name;
        eval "use $module";
        return carp "$module is not installed, but needed to load color '$pallet_name:$color_name'" if $@;

        my $pal = Graphics::ColorNames->new( $pallet_name );
        my @rgb = $pal->rgb( $color_name );
        return carp "color '$color_name' was not found, propably not part of $module" unless @rgb == 3;
        @rgb;
    } else {                                         # resolve name -> ($r, $g, $b)
        my @rgb = rgb_from_name( $arg );
        carp "'$arg' is an unknown color name, please check Graphics::Toolkit::Color::Constant::all_names()." unless @rgb == 3;
        @rgb;
    }
}

## getter ##############################################################

sub name        { $_[0][0] }
sub red         { $_[0][1] }
sub green       { $_[0][2] }
sub blue        { $_[0][3] }
sub hue         { $_[0][4] }
sub saturation  { $_[0][5] }
sub lightness   { $_[0][6] }
sub string      { $_[0][0] ? $_[0][0] : $_[0]->rgb_hex }

sub rgb         { @{$_[0]}[1 .. 3] }
sub hsl         { @{$_[0]}[4 .. 6] }
sub rgb_hash    { { red => $_[0][1], green => $_[0][2], blue => $_[0][3] } }
sub hsl_hash    { { hue => $_[0][4], saturation => $_[0][5], lightness => $_[0][6] } }
sub rgb_hex     { hex_from_rgb( $_[0]->rgb() ) }

## methods ##############################################################

sub distance_to {
    my ($self, $c2, $metric) = @_;
    return croak "missing argument: color object or scalar color definition" unless defined $c2;
    $c2 = (ref $c2 eq __PACKAGE__) ? $c2 : new( __PACKAGE__, $c2 );
    return unless ref $c2 eq __PACKAGE__;

    return distance_hsl( [$self->hsl], [$c2->hsl] ) unless defined $metric;
    $metric = lc $metric;
    return distance_hsl( [$self->hsl], [$c2->hsl] ) if $metric eq 'hsl';
    return distance_rgb( [$self->rgb], [$c2->rgb] ) if $metric eq 'rgb';
    my @delta_rgb = difference_rgb( [$self->rgb], [$c2->rgb] );
    my @delta_hsl = difference_hsl( [$self->hsl], [$c2->hsl] );
    my $help = "unknown distance metric: $metric. try r, g, b, rg, rb, gb, rgb, h, s, l, hs, hl, sl, hsl (default).";
    if (length $metric == 2){
        if    ($metric eq 'hs' or $metric eq 'sh') {return sqrt( $delta_hsl[0] ** 2 + $delta_hsl[1] ** 2 )}
        elsif ($metric eq 'hl' or $metric eq 'lh') {return sqrt( $delta_hsl[0] ** 2 + $delta_hsl[2] ** 2 )}
        elsif ($metric eq 'sl' or $metric eq 'ls') {return sqrt( $delta_hsl[1] ** 2 + $delta_hsl[2] ** 2 )}
        elsif ($metric eq 'rg' or $metric eq 'gr') {return sqrt( $delta_rgb[0] ** 2 + $delta_rgb[1] ** 2 )}
        elsif ($metric eq 'rb' or $metric eq 'br') {return sqrt( $delta_rgb[0] ** 2 + $delta_rgb[2] ** 2 )}
        elsif ($metric eq 'gb' or $metric eq 'bg') {return sqrt( $delta_rgb[1] ** 2 + $delta_rgb[2] ** 2 )}
    }
    $metric = substr $metric, 0, 1;
    $metric eq 'h' ? $delta_hsl[0] :
    $metric eq 's' ? $delta_hsl[1] :
    $metric eq 'l' ? $delta_hsl[2] :
    $metric eq 'r' ? $delta_rgb[0] :
    $metric eq 'g' ? $delta_rgb[1] :
    $metric eq 'b' ? $delta_rgb[2] : croak $help;
}

sub add {
    my ($self, @args) = @_;
    my $add_help = 'Graphics::Toolkit::Color->add argument options: 1. a color object with optional factor as second arg, '.
        '2. a color name as string, 3. a color hex definition as in "#FF0000"'.
        '4. a list of thre values (RGB) (also in an array ref)'.
        '5. a hash with RGB and HSL keys (as in new, but can be mixed) (also in an hash ref).';
    if ((@args == 1 or @args == 2) and ref $args[0] ne 'HASH'){
        my @add_rgb;
        if (ref $args[0] eq __PACKAGE__){
            @add_rgb = $args[0]->rgb;
        } elsif (ref $args[0] eq 'ARRAY'){
            @add_rgb = @{$args[0]};
            return carp "array ref argument needs to have 3 numerical values (RGB) in it." unless @add_rgb == 3;
        } elsif (not ref $args[0] and not $args[0] =~ /^\d/){
            @add_rgb = _rgb_from_name_or_hex($args[0]);
            return unless @add_rgb > 1;
        } else { return carp $add_help }
        @add_rgb = ($add_rgb[0] * $args[1], $add_rgb[1] * $args[1], $add_rgb[2] * $args[1]) if defined $args[1];
        @args = @add_rgb;
    }
    my @rgb = $self->rgb;
    if (@args == 3) {
        @rgb = trim_rgb( $rgb[0] + $args[0], $rgb[1] + $args[1], $rgb[2] + $args[2]);
        return new( __PACKAGE__, @rgb );
    }
    return carp $add_help unless @args and ((@args % 2 == 0) or (ref $args[0] eq 'HASH'));
    my %arg = ref $args[0] eq 'HASH' ? %{$args[0]} : @args;
    my %named_arg = map {_shrink_key($_) =>  $arg{$_}} keys %arg; # clean keys
    $rgb[0] += delete $named_arg{'r'} // 0;
    $rgb[1] += delete $named_arg{'g'} // 0;
    $rgb[2] += delete $named_arg{'b'} // 0;
    return new( __PACKAGE__, trim_rgb( @rgb ) ) unless %named_arg;
    my @hsl = Graphics::Toolkit::Color::Value::_hsl_from_rgb( @rgb ); # withound rounding
    $hsl[0] += delete $named_arg{'h'} // 0;
    $hsl[1] += delete $named_arg{'s'} // 0;
    $hsl[2] += delete $named_arg{'l'} // 0;
    if (%named_arg) {
        my @nrkey = grep {/^\d+$/} keys %named_arg;
        return carp "wrong number of numerical arguments (only 3 needed)" if @nrkey;
        carp "got unknown hash key starting with", map {' '.$_} keys %named_arg;
    }
    @hsl = trim_hsl( @hsl );
    new( __PACKAGE__, { H => $hsl[0], S => $hsl[1], L => $hsl[2] });
}

sub blend_with {
    my ($self, $c2, $pos) = @_;
    return carp "need color object or definition as first argument" unless defined $c2;
    $c2 = (ref $c2 eq __PACKAGE__) ? $c2 : _new_from_scalar( $c2 );
    return unless ref $c2 eq __PACKAGE__;
    $pos //= 0.5;
    my $delta_hue = $c2->hue - $self->hue;
    $delta_hue -= 360 if $delta_hue >  180;
    $delta_hue += 360 if $delta_hue < -180;
    my @hsl = ( $self->hue        + ($pos * $delta_hue),
                $self->saturation + ($pos * ($c2->saturation - $self->saturation)),
                $self->lightness  + ($pos * ($c2->lightness  - $self->lightness))
    );
    @hsl = trim_hsl( @hsl );
    new( __PACKAGE__, { H => $hsl[0], S => $hsl[1], L => $hsl[2] });
}

# for compatibility
sub gradient_to { hsl_gradient_to( @_ ) }

sub hsl_gradient_to {
    my ($self, $c2, $steps, $power) = @_;
    return carp "need color object or definition as first argument" unless defined $c2;
    $c2 = (ref $c2 eq __PACKAGE__) ? $c2 : _new_from_scalar( $c2 );
    return unless ref $c2 eq __PACKAGE__;
    $steps //= 3;
    $power //= 1;
    return carp "third argument (dynamics), has to be positive (>= 0)" if $power <= 0;
    return $self if $steps == 1;
    my @colors = ();
    my @delta_hsl = ($c2->hue - $self->hue, $c2->saturation - $self->saturation,
                                            $c2->lightness - $self->lightness  );
    $delta_hsl[0] -= 360 if $delta_hsl[0] >  180;
    $delta_hsl[0] += 360 if $delta_hsl[0] < -180;
    for my $i (1 .. $steps-2){
        my $pos = ($i / ($steps-1)) ** $power;
        my @hsl = ( $self->hue        + ($pos * $delta_hsl[0]),
                    $self->saturation + ($pos * $delta_hsl[1]),
                    $self->lightness  + ($pos * $delta_hsl[2]));
        @hsl = trim_hsl( @hsl );
        push @colors, new( __PACKAGE__, { H => $hsl[0], S => $hsl[1], L => $hsl[2] });
    }
    $self, @colors, $c2;
}

sub rgb_gradient_to {
    my ($self, $c2, $steps, $power) = @_;
    return carp "need color object or definition as first argument" unless defined $c2;
    $c2 = (ref $c2 eq __PACKAGE__) ? $c2 : _new_from_scalar( $c2 );
    return unless ref $c2 eq __PACKAGE__;
    $steps //= 3;
    $power //= 1;
    return carp "third argument (dynamics), has to be positive (>= 0)" if $power <= 0;
    return $self if $steps == 1;
    my @colors = ();
    my @delta_rgb = ($c2->red - $self->red, $c2->green - $self->green, $c2->blue - $self->blue );
    for my $i (1 .. $steps-2){
        my $pos = ($i / ($steps-1)) ** $power;
        my @rgb = ( $self->red   + ($pos * $delta_rgb[0]),
                    $self->green + ($pos * $delta_rgb[1]),
                    $self->blue  + ($pos * $delta_rgb[2]));
        push @colors, new( __PACKAGE__, @rgb);
    }
    $self, @colors, $c2;
}

sub complementary {
    my ($self) = shift;
    my ($count) = int ((shift // 1) + 0.5);
    my ($saturation_change) = shift // 0;
    my ($lightness_change) = shift // 0;
    my @hsl2 = my @hsl_l = my @hsl_r = $self->hsl;
    $hsl2[0] += 180;
    $hsl2[1] += $saturation_change;
    $hsl2[2] += $lightness_change;
    @hsl2 = trim_hsl( @hsl2 ); # HSL of C2
    my $c2 = new( __PACKAGE__, { h => $hsl2[0], s => $hsl2[1], l => $hsl2[2] });
    return $c2 if $count < 2;
    my (@colors_r, @colors_l);
    my @delta = (360 / $count, (($hsl2[1] - $hsl_r[1]) * 2 / $count), (($hsl2[2] - $hsl_r[2]) * 2 / $count) );
    for (1 .. ($count - 1) / 2){
        $hsl_r[$_] += $delta[$_] for 0..2;
        $hsl_l[0] -= $delta[0];
        $hsl_l[$_] = $hsl_r[$_] for 1,2;
        $hsl_l[0] += 360 if $hsl_l[0] <    0;
        $hsl_r[0] -= 360 if $hsl_l[0] >= 360;
        push @colors_r, new( __PACKAGE__, { H => $hsl_r[0], S => $hsl_r[1], L => $hsl_r[2] });
        unshift @colors_l, new( __PACKAGE__, { H => $hsl_l[0], S => $hsl_l[1], L => $hsl_l[2] });
    }
    push @colors_r, $c2 unless $count % 2;
    $self, @colors_r, @colors_l;
}

sub _shrink_key { lc substr( $_[0], 0, 1 ) }

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color - color palette creation helper

=head1 SYNOPSIS

    my $red = Graphics::Toolkit::Color->new('red'); # create color object
    say $red->add('blue')->name;                    # mix in RGB: 'magenta'
    Graphics::Toolkit::Color->new( 0, 0, 255)->hsl; # 240, 100, 50 = blue
    $blue->blend_with({H=> 0, S=> 0, L=> 80}, 0.1); # mix blue with a little grey in HSL
    $red->rgb_gradient_to( '#0000FF', 10);          # 10 colors from red to blue
    $red->complementary( 3 );                       # get fitting red green and blue


=head1 DESCRIPTION

Read only color holding objects with no additional dependencies.
Create them in many different ways (see section I<CONSTRUCTOR>).
Access its values via methods from section I<GETTER> or create related
color objects via methods listed under I<METHODS>.

Humans access colors on hardware level (eye) in RGB, on cognition level
in HSL (brain) and on cultural level (language) with names.
Having easy access to all three and some color math should enable you to get the color
palette you desire quickly.


=head1 CONSTRUCTOR

There are many options to create a color objects.  In short you can
either use the name of a predefined constant or provide values in RGB
or HSL color space.

=head2 new( 'name' )

Get a color by providing a name from the X11, HTML (CSS) or SVG standard
or a Pantone report. UPPER or CamelCase will be normalized to lower case
and inserted underscore letters ('_') will be ignored as perl does in
numbers (1_000 == 1000). All available names are listed under
L<Graphics::Toolkit::Color::Constant>.

    my $color = Graphics::Toolkit::Color->new('Emerald');
    my @names = Graphics::Toolkit::Color::Constant::all_names(); # select from these

=head2 new( 'scheme:color' )

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

Triplet of integer RGB values (L</red>, L</green> and L</blue> : 0 .. 255).
Out of range values will be corrected to the closest value in range.


    my $red = Graphics::Toolkit::Color->new( 255, 0, 0 );
    my $red = Graphics::Toolkit::Color->new([255, 0, 0]); # does the same


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

    my $red = Graphics::Toolkit::Color->new( h =>   0, s => 100, b => 50 );
    my $red = Graphics::Toolkit::Color->new({h =>   0, s => 100, b => 50}); # good too
    ... ->new( Hue => 0, Saturation => 100, Lightness => 50 ); # also fine

=head2 color

If writing C<Graphics::Toolkit::Color->new(...> is too much typing for you
or takes to much space, import the subroutine C<color>, which takes
all the same arguments as described above.


    use Graphics::Toolkit::Color qw/color/;
    my $green = color('green');
    my $darkblue = color([20, 20, 250]);


=head1 GETTER / ATTRIBUTES

are read only methods - giving access to different parts of the
objects data.

=head2 name

String with name of the color in the X11 or HTML (SVG) standard or the
Pantone report. The name will be found and filled in, even when the object
is created with RGB or HSL values. If the color is not found in any of
the mentioned standards, it returns an empty string. All names are at:
L<Graphics::Toolkit::Color::Constant/NAMES>

=head2 string

String that can be serialized back into a color object
(recreated by Graphics::Toolkit::Color->new( $string )).
It is either the color L</name> (if color has one) or result of L</rgb_hex>.

=head2 red

Integer between 0 .. 255 describing the red portion in RGB space.
Higher value means more color and an lighter color.

=head2 green

Integer between 0 .. 255 describing the green portion in RGB space.
Higher value means more color and an lighter color.

=head2 blue

Integer between 0 .. 255 describing the blue portion in RGB space.
Higher value means more color and an lighter color.

=head2 hue

Integer between 0 .. 359 describing the angle (in degrees) of the
circular dimension in HSL space named hue.
0 approximates red, 30 - orange, 60 - yellow, 120 - green, 180 - cyan,
240 - blue, 270 - violet, 300 - magenta, 330 - pink.
0 and 360 point to the same coordinate. This module only outputs 0,
even if accepting 360 as input.

=head2 saturation

Integer between 0 .. 100 describing percentage of saturation in HSL space.
0 is grey and 100 the most colorful (except when lightness is 0 or 100).

=head2 lightness

Integer between 0 .. 100 describing percentage of lightness in HSL space.
0 is always black, 100 is always white and 50 the most colorful
(depending on L</hue> value) (or grey - if saturation = 0).

=head2 rgb

List (no I<ARRAY> reference) with values of L</red>, L</green> and L</blue>.

=head2 hsl

List (no I<ARRAY> reference) with values of L</hue>, L</saturation> and L</lightness>.

=head2 rgb_hex

String starting with character '#', followed by six hexadecimal lower case figures.
Two digits for each of L</red>, L</green> and L</blue> value -
the format used in CSS (#rrggbb).

=head2 rgb_hash

Reference to a I<HASH> containing the keys C<'red'>, C<'green'> and C<'blue'>
with their respective values as defined above.

=head2 hsl_hash

Reference to a I<HASH> containing the keys C<'hue'>, C<'saturation'> and C<'lightness'>
with their respective values as defined above.


=head1 METHODS

create new, related color (objects) or compute similarity of colors

=head2 distance_to

A number that measures the distance (difference) between two colors:
1. the calling object (C1) and 2. a provided first argument C2 -
color object or scalar data that is acceptable by new method :
name or #hex or [$r, $g, $b] or {...} (see chapter L<CONSTRUCTOR>).

If no second argument is provided, than the difference is the Euclidean
distance in cylindric HSL space. If second argument is 'rgb' or 'RGB',
then its the Euclidean distance in RGB space. But als subspaces of both
are possible, as r, g, b, rg, rb, gb, h, s, l, hs, hl, and sl.

    my $d = $blue->distance_to( 'lapisblue' ); # how close to lapis color?
    # how different is my blue value to airy_blue
    $d = $blue->distance_to( 'airyblue', 'Blue'); # same amount of blue?
    $d = $color->distance_to( $c2, 'Hue' ); # same hue ?
    $d = $color->distance_to( [10, 32, 112 ], 'rgb' );
    $d = $color->distance_to( { Hue => 222, Sat => 23, Light => 12 } );

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
    my $blue2 = $blue->add( blue => 10 );
    $blue->distance( $blue2 );           # == 0, can't get bluer than blue
    my $color = $blue->add( $c2, -1.2 ); # subtract color c2 with factor 1.2

=head2 blend_with

Create Graphics::Toolkit::Color object, that is the average of two colors in HSL space:
1. the calling object (C1) and 2. a provided argument C2 (object or a
refrence to data that is acceptable definition).

The second argument is the blend ratio, which defaults to 0.5 ( 1:1 ).
0 represents here C1 and 1 C2. Numbers below 0 and above 1 are possible,
and will be applied, as long the result is inside the finite HSL space.
There is a slight overlap with the add method which mostly operates in
RGB (unless told so), while this method always operates in HSL space.

    my $c = $color->blend_with( Graphics::Toolkit::Color->new('silver') );
    $color->blend_with( 'silver' );                        # same thing
    $color->blend_with( [192, 192, 192] );                 # still same
    my $difference = $color->blend_with( $c2, -1 );


=head2 rgb_gradient_to

Creates a gradient (a list of colors that build a transition) between
current (C1) and a second, given color (C2).

The first argument is C2. Either as an Graphics::Toolkit::Color object or a
scalar (name, hex or reference), which is acceptable to a constructor.

Second argument is the number $n of colors, which make up the gradient
(including C1 and C2). It defaults to 3. These 3 colors C1, C2 and a
color in between, which is the same as the result of method blend_with.

Third argument is also a positive number $p, which defaults to one.
It defines the dynamics of the transition between the two colors.
If $p == 1 you get a linear transition - meaning the distance in RGB
space is equal from one color to the next. If $p != 1,
the formula $n ** $p starts to create a parabola function, which defines
a none linear mapping. For values $n > 1 the transition starts by sticking
to C1 and slowly getting faster and faster toward C2. Values $n < 1 do
the opposite: starting by moving fastest from C1 to C2 (big distances)
and becoming slower and slower.

    my @colors = $c->rgb_gradient_to( $grey, 5 );         # we turn to grey
    @colors = $c1->rgb_gradient_to( [14,10,222], 10, 3 ); # none linear gradient

=head2 hsl_gradient_to

Same as L</rgb_gradient_to> (what you normally want), but in HSL space.

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

L<Color::Library>

=item *

L<Graphics::ColorUtils>

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

Copyright 2022 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut

