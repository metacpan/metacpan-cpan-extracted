
# read only color holding object with methods for relation, mixing and transitions

package Graphics::Toolkit::Color;
our $VERSION = '1.71';
use v5.12;
use warnings;

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
    my ($c2, $space_name, $select, $range) = ($args{'to'}, $args{'in'}, $args{'select'}, $args{'range'});
    return carp "missing argument: color object or scalar color definition" unless defined $c2;
    $c2 = _new_from_scalar( $c2 );
    return carp "second color for distance calculation (named argument 'to') is badly defined" unless ref $c2 eq __PACKAGE__;
    $self->{'values'}->distance( $c2->{'values'}, $space_name, $select, $range );
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
sub gradient { # $to ~in + steps +dynamic +variance --> @_
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


my $comp_help = 'set constructor "complement" accepts 4 named args: "steps" (positive int), '.
                '"hue_tilt" or "h" (-180 .. 180), '.
                '"saturation_tilt or "s" (-100..100) or { s => (-100..100), h => (-180..180)} and '.
                '"lightness_tilt or "l" (-100..100) or { l => (-100..100), h => (-180..180)}';
    sub complementary { complement(@_) }
sub complement { # +steps +hue_tilt +saturation_tilt +lightness_tilt --> @_
    my ($self) = shift;
    my %arg = (not @_ % 2) ? @_ :
              (@_ == 1)    ? (steps => $_[0]) : return carp $comp_help;
    my $steps = int abs($arg{'steps'} // 1);
    my $hue_tilt = (exists $arg{'h'}) ? (delete $arg{'h'}) :
                   (exists $arg{'hue_tilt'}) ? (delete $arg{'hue_tilt'}) : 0;
    return carp $comp_help if ref $hue_tilt;
    my $saturation_tilt = (exists $arg{'s'}) ? (delete $arg{'s'}) :
                          (exists $arg{'saturation_tilt'}) ? (delete $arg{'saturation_tilt'}) : 0;
    return carp $comp_help if ref $saturation_tilt and ref $saturation_tilt ne 'HASH';
    my $saturation_axis_offset = 0;
    if (ref $saturation_tilt eq 'HASH'){
        my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::partial_hash_deformat( $saturation_tilt );
        return carp $comp_help if not defined $space_name or $space_name ne 'HSL' or not exists $pos_hash->{1};
        $saturation_axis_offset = $pos_hash->{0} if exists $pos_hash->{0};
        $saturation_tilt = $pos_hash->{1};
    }
    my $lightness_tilt = (exists $arg{'l'}) ? (delete $arg{'l'}) :
                         (exists $arg{'lightness_tilt'}) ? (delete $arg{'lightness_tilt'}) : 0;
    return carp $comp_help if ref $lightness_tilt and ref $lightness_tilt ne 'HASH';
    my $lightness_axis_offset = 0;
    if (ref $lightness_tilt eq 'HASH'){
        my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::partial_hash_deformat( $lightness_tilt );
        return carp $comp_help if not defined $space_name or $space_name ne 'HSL' or not exists $pos_hash->{2};
        $lightness_axis_offset = $pos_hash->{0} if exists $pos_hash->{0};
        $lightness_tilt = $pos_hash->{2};
    }

    my @hsl2 = my @hsl = $self->values('HSL');
    my @hue_turn_point = ($hsl[0] + 90, $hsl[0] + 270, 800); # Dmax, Dmin and Pseudo-Inf
    my @sat_turn_point  = ($hsl[0] + 90, $hsl[0] + 270, 800);
    my @light_turn_point = ($hsl[0] + 90, $hsl[0] + 270, 800);
    my $sat_max_hue = $hsl[0] + 90 + $saturation_axis_offset;
    my $sat_step = $saturation_tilt * 4 / $steps;
    my $light_max_hue = $hsl[0] + 90 + $lightness_axis_offset;
    my $light_step = $lightness_tilt * 4 / $steps;
    if ($saturation_axis_offset){
        $sat_max_hue -= 360 while $sat_max_hue > $hsl[0]; # putting dmax in range
        $sat_max_hue += 360 while $sat_max_hue <= $hsl[0]; # above c1->hue
        my $dmin_first = $sat_max_hue > $hsl[0] + 180;
        @sat_turn_point =  $dmin_first ? ($sat_max_hue - 180, $sat_max_hue, 800)
                                       : ($sat_max_hue, $sat_max_hue + 180, 800);
        $sat_step = - $sat_step if $dmin_first;
        my $sat_start_delta = $dmin_first ? ((($sat_max_hue - 180 - $hsl[0]) / 90 * $saturation_tilt) - $saturation_tilt)
                                          : (-(($sat_max_hue -      $hsl[0]) / 90 * $saturation_tilt) + $saturation_tilt);
        $hsl[1] += $sat_start_delta;
        $hsl2[1] -= $sat_start_delta;
    }
    if ($lightness_axis_offset){
        $light_max_hue -= 360 while $light_max_hue > $hsl[0];
        $light_max_hue += 360 while $light_max_hue <= $hsl[0];
        my $dmin_first = $light_max_hue > $hsl[0] + 180;
        @light_turn_point =  $dmin_first ? ($light_max_hue - 180, $light_max_hue, 800)
                                         : ($light_max_hue, $light_max_hue + 180, 800);
        $light_step = - $light_step if $dmin_first;
        my $light_start_delta = $dmin_first ? ((($light_max_hue - 180 - $hsl[0]) / 90 * $lightness_tilt) - $lightness_tilt)
                                            : (-(($light_max_hue -      $hsl[0]) / 90 * $lightness_tilt) + $lightness_tilt);
        $hsl[2] += $light_start_delta;
        $hsl2[2] -= $light_start_delta;
    }
    my $c1 = _new_from_scalar( [ 'HSL', @hsl ] );
    $hsl2[0] += 180 + $hue_tilt;
    my $c2 = _new_from_scalar( [ 'HSL', @hsl2 ] ); # main complementary color
    return $c2 if $steps < 2;
    return $c1, $c2 if $steps == 2;

    my (@result) = $c1;
    my $hue_avg_step = 360 / $steps;
    my $hue_c2_distance = $self->distance( to => $c2, in => 'HSL', select => 'hue');
    my $hue_avg_tight_step = $hue_c2_distance * 2 / $steps;
    my $hue_sec_deg_delta = 8 * ($hue_avg_step - $hue_avg_tight_step) / $steps; # second degree delta
    $hue_sec_deg_delta = -$hue_sec_deg_delta if $hue_tilt < 0; # if c2 on right side
    my $hue_last_step = my $hue_ak_step = $hue_avg_step; # bar height of pseudo integral
    my $hue_current = my $hue_current_naive = $hsl[0];
    my $saturation_current = $hsl[1];
    my $lightness_current = $hsl[2];
    my $hi = my $si = my $li = 0; # index of next turn point where hue step increase gets flipped (at Dmax and Dmin)
    for my $i (1 .. $steps - 1){
        $hue_current_naive += $hue_avg_step;

        if ($hue_current_naive >= $hue_turn_point[$hi]){
            my $bar_width = ($hue_turn_point[$hi] - $hue_current_naive + $hue_avg_step) / $hue_avg_step;
            $hue_ak_step += $hue_sec_deg_delta * $bar_width;
            $hue_current += ($hue_ak_step + $hue_last_step) / 2 * $bar_width;
            $hue_last_step = $hue_ak_step;
            $bar_width = 1 - $bar_width;
            $hue_sec_deg_delta = -$hue_sec_deg_delta;
            $hue_ak_step += $hue_sec_deg_delta * $bar_width;
            $hue_current += ($hue_ak_step + $hue_last_step) / 2 * $bar_width;
            $hi++;
        } else {
            $hue_ak_step += $hue_sec_deg_delta;
            $hue_current += ($hue_ak_step + $hue_last_step) / 2;
        }
        $hue_last_step = $hue_ak_step;

        if ($hue_current_naive >= $sat_turn_point[$si]){
            my $bar_width = ($sat_turn_point[$si] - $hue_current_naive + $hue_avg_step) / $hue_avg_step;
            $saturation_current += $sat_step * ((2 * $bar_width) - 1);
            $sat_step = -$sat_step;
            $si++;
        } else {
            $saturation_current += $sat_step;
        }

        if ($hue_current_naive >= $light_turn_point[$li]){
            my $bar_width = ($light_turn_point[$li] - $hue_current_naive + $hue_avg_step) / $hue_avg_step;
            $lightness_current += $light_step * ((2 * $bar_width) - 1);
            $light_step = -$light_step;
            $li++;
        } else {
            $lightness_current += $light_step;
        }

        $result[$i] = _new_from_scalar( [ HSL => $hue_current, $saturation_current, $lightness_current ] );
    }

    return @result;
}

sub bowl {# +radius +distance|count +variance ~in @range
    my ($self, @args) = @_;
    my $arg = _get_arg_hash( @args );
    return unless ref $arg eq 'HASH';

}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color - color palette constructor

=head1 SYNOPSIS

    use Graphics::Toolkit::Color qw/color/;

    my $red = Graphics::Toolkit::Color->new('red'); # create color object
    say $red->add( 'blue' => 255 )->name;           # add blue value: 'fuchsia'
    my $blue = color( 0, 0, 255)->values('HSL');    # 240, 100, 50 = blue
    $blue->blend( with => [HSL => 0,0,80], pos => 0.1);# mix blue with a little grey in HSL
    $red->gradient( to => '#0000FF', steps => 10);  # 10 colors from red to blue
    $red->complement( 3 );                          # get fitting red green and blue


=head1 DESCRIPTION

ATTENTION: deprecated methods of the old API ( I<string>, I<rgb>, I<red>,
I<green>, I<blue>, I<rgb_hex>, I<rgb_hash>, I<hsl>, I<hue>, I<saturation>,
I<lightness>, I<hsl_hash>, I<blend_with>, I<gradient_to>,
I<rgb_gradient_to>, I<hsl_gradient_to>, I<complementary>)
will be removed on version 2.0.

Graphics::Toolkit::Color, for short GTC, is the top level API of this module
and the only one a regular user should be concerned with.
Its main purpose is the creation of sets of related colors, such as
gradients, complements and others.

GTC are read only color holding objects with no additional dependencies.
Create them in many different ways (see section L</CONSTRUCTOR>).
Access its values via methods from section L</GETTER>.
Measure differences with the I<distance> method. L</SINGLE-COLOR>
methods create one a object that is related to the current one and
L</COLOR-SETS> methods will create a host of color that are not
only related to the current color but also have relations between each other.

While this module can understand and output color values in many spaces,
such as YIQ, HSL and many more, RGB is the (internal) primal one,
because GTC is about colors that can be shown on the screen, and these
are usually encoded in RGB.

Humans access colors on hardware level (eye) in RGB, on cognition level
in HSL (brain) and on cultural level (language) with names.
Having easy access to all three and some color math should enable you to
get the color palette you desire quickly.

=head1 CONSTRUCTOR

There are many options to create a color objects. In short you can
either use the name of a constant or provide values in one of several
L<Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>, which also can be
formatted in many ways as described in this paragraph.

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


=head1 GETTER

giving access to different parts of the objects data.

=head2 name

String with normalized name (lower case without I<'_'>) of the color as
in X11 or HTML (SVG) standard or the Pantone report.
The name will be found and filled in, even when the object
was created numerical values.
If no color is found, C<name> returns an empty string.
All names are at: L<Graphics::Toolkit::Color::Name::Constant/NAMES>
(See als: L</new('name')>)

=head2 values

Returns the values of the color in given color space and format.
It accepts three named, optional arguments.

First argument is the name of a color space (named argument C<in>).
All options are under: L<Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>
The order of named arguments is of course chosen by the user, but I call
it the first (most important) argument, because if you give the method
only one value, it is assumed to be the color space.

Second argument is the format (name: C<as>).
In short any SCALAR format acceptable to the L</CONSTRUCTOR> can also be
reproduced by a getter method and the numerical cases by this one.
Not all formats are available under all color spaces, but the always
present options are: C<list> (default), C<hash>, C<char_hash> and C<array>.

Third named argument is the range inside which the numerical values have
to be. RGB are normally between 0 .. 255 and CMYK between 0 .. 1 ('normal').
Only a range of C<1> a.k.a. C<'normal'> displays decimals.
There are three syntax option to set the ranges. One value will be
understood as upper limit of all dimensions and zero being the lower one.
If you want to set the upper limits of all dimensions separately, you
have to  deliver an ARRAY ref with the 3 or 4 upper limits. To also
define the lower boundary, you replace the number with an ARRAY ref containing
the lower and then the upper limit.

    $blue->values();                               # get list in RGB: 0, 0, 255
    $blue->values( in => 'RGB', as => 'list');     # same call
    $blue->values( in => 'RGB', as => 'hash');     # { red => 0, green => 0, blue => 255}
    $blue->values( in => 'RGB', as => 'char_hash');# { r => 0, g => 0, b => 255}
    $blue->values( in => 'RGB', as => 'hex');      # '#00FFFF'
    $color->values('HSL');                         # 240, 100, 50
    $color->values( in => 'HSL', range => 1);      # 0.6666, 1, 0.5
    $color->values( in => 'RGB', range => 2**16);  # values in RGB16
    $color->values( in => 'HSB', as => 'hash')->{'hue'};  # how to get single values
   ($color->values( 'HSB'))[0];                           # same, but shorter


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
    $d = $blue->distance( to => 'airyblue', in => 'RGB', select => 'Blue'); # same amount of blue?
    $d = $color->distance( to => $c2, in => 'HSL', select => 'hue' );                  # same hue?
    # compute distance when with all value ranges 0 .. 1
    $d = $color->distance( to => $c2, in => 'HSL', select => 'hue', range => 'normal' );

=head1 SINGLE COLOR

construct colors that are related to the current object.

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

=head1 COLOR SETS

construct many interrelated color objects at once.


=head2 gradient

Creates a gradient (a list of colors that build a transition) between
current (C1) and a second, given color (C2) by named argument I<to>.

The only required argument you have to give under the name I<to> is C2.
Either as an Graphics::Toolkit::Color object or a scalar (name, hex, HASH
or ARRAY), which is acceptable to a L</CONSTRUCTOR>. This is the same
behaviour as in L</distance>.

An optional argument under the name I<steps> sets the number of colors,
which make up the gradient (including C1 and C2). It defaults to 3.
Negative numbers will be rectified by C<abs>.
These 3 color objects: C1, C2 and a color in between, which is the same
as the result of method L</blend>.

Another optional argument under the name I<dynamic> is a float number,
that defines the position of weight in the color transition from C1 to C2.
It defaults to zero which gives you a linear transition,
meaning the L</distance> between neighbouring colors in the gradient is equal.
If $dynamic > 0, the weight is moved toward C1 and vice versa.
The greater $dynamic, the slower the color change is in the beginning
of the gradient and the faster at the end (C2).

The last optional argument named I<in> defines the color space the changes
are computed in. It parallels the argument of the same name from the method
L</blend> and L</distance>.

    # we turn to grey
    my @colors = $c->gradient( to => $grey, steps => 5, in => 'RGB');
    # none linear gradient in HSL space :
    @colors = $c1->gradient( to =>[14,10,222], steps => 10, dynamic => 3 );

=head2 complement

Creates a set of complementary colors, which will be computed in I<HSL>
color space. It accepts 4 optional, named arguments.
Complementary colors have a different I<hue> value but same
I<saturation> and I<lightness>. Because they form a circle in HSL, they
will be called in this paragraph a circle.

If you provide no names (just a single argument), the value is understood
as I<steps>. I<steps> is the amount (count) of complementary colors,
which defaults to 1 (giving you then THE complementary color).
If more than one color is requested, the result will contain the calling
object as the first color.

The second optional argument is I<hue_tilt>, in short I<h>, which defaults
to zero. When zero, the hue distance between all resulting colors on the
circle is the same. When not zero, the I<hue_tilt> gets added (see L</add>)
to THE complementary color. The so computed color divides the circle in a
shorter and longer part. Both of these parts will now contain an equal
amount of result colors. The distribution will be computed in a way,
that there will be a place on the circle where the distance between colors
is the highest (let's call it Dmax) and one where it is the lowest (Dmin).
The distance between two colors increases or decreases steadily.
When I<hue_tilt> is zero, the axis through Dmax and Dmin and the axis
through $self and C2 are orthogonal.

The third optional argument I<saturation_tilt>, or short I<s>, which also
defaults to zero. If the value differs from zero it gets added the color
on Dmax (last paragraph), subtracted on Dmin, changed accordingly in between,
so that the circle gets moved in direction Dmin. If you want to move
the circle in any other direction you have to give I<saturation_tilt>
a HASH reference with 2 keys. First is I<saturation> or I<s>, which is
the  value as described. Secondly  I<hue> or I<h> rotates the direction
in which the circle will be moved. Please not, this will not change
the position of Dmin and Dmax, because it just defines the angle
between the Dmin-Dmax axis and the direction where the circle is moved.

The fourth optional argument is I<lightness_tilt> or I<l>m which works
analogously to I<saturation_tilt>. Only difference is that it tilts the
circle in the up-down direction, which is in HSL color space lightness.

    my @colors = $c->complement( 4 );    # $self + 3 compementary (square) colors
    my @colors = $c->complement( steps => 3, s => 20, l => -10 );
    my @colors = $c->complement( steps => 3, hue_tilt => -40,
                                     saturation_tilt => {saturation => 300, hue => -50},
                                     lightness_tilt => {l => -10, hue => 30} );

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

