
# public user level API: docs, help and arg cleaning

package Graphics::Toolkit::Color;
our $VERSION = '1.972';

use v5.12;
use warnings;
use Exporter 'import';
use Graphics::Toolkit::Color::Space::Util qw/is_nr/;
use Graphics::Toolkit::Color::SetCalculator;

my $default_space_name = Graphics::Toolkit::Color::Space::Hub::default_space_name();
our @EXPORT_OK = qw/color/;

## constructor #########################################################

sub color { Graphics::Toolkit::Color->new ( @_ ) }

sub new {
    my ($pkg, @args) = @_;
    my $help = <<EOH;
    constructor new of Graphics::Toolkit::Color object needs either:
    1. a color name: new('red') or new('SVG:red')
    3. RGB hex string new('#FF0000') or new('#f00')
    4. $default_space_name array or ARRAY ref: new( 255, 0, 0 ) or new( [255, 0, 0] )
    5. named array or ARRAY ref:  new( 'HSL', 255, 0, 0 ) or new( ['HSL', 255, 0, 0 ])
    6. named string:  new( 'HSL: 0, 100, 50' ) or new( 'ncol(r0, 0%, 0%)' )
    7. HASH or HASH ref with values from RGB or any other space:
       new(r => 255, g => 0, b => 0) or new({ hue => 0, saturation => 100, lightness => 50 })
EOH
    my $first_arg_is_color_space = Graphics::Toolkit::Color::Space::Hub::is_space_name( $args[0] );
    @args = ([ $args[0], @{$args[1]} ]) if @args == 2 and $first_arg_is_color_space and ref $args[1] eq 'ARRAY';
    @args = ([ @args ])                 if @args == 3 or (@args > 3 and $first_arg_is_color_space);
    @args = ({ @args })                 if @args == 6 or @args == 8;
    return $help unless @args == 1;
    my $self = _new_from_scalar_def( $args[0] );
    return (ref $self) ? $self : $help;
}
sub _new_from_scalar_def { # color defs of method arguments
    my ($color_def) = shift;
    return $color_def if ref $color_def eq __PACKAGE__;
    return _new_from_value_obj( Graphics::Toolkit::Color::Values->new_from_any_input( $color_def ) );
}
sub _new_from_value_obj {
    my ($value_obj) = @_;
    return $value_obj unless ref $value_obj eq 'Graphics::Toolkit::Color::Values';
    return bless {values => $value_obj};
}


## deprecated methods - deleted with 2.0
    sub string      { $_[0]{'name'} || $_[0]->{'values'}->string }
    sub rgb         { $_[0]->values( ) }
    sub red         {($_[0]->values( ))[0] }
    sub green       {($_[0]->values( ))[1] }
    sub blue        {($_[0]->values( ))[2] }
    sub rgb_hex     { $_[0]->values( as => 'hex') }
    sub rgb_hash    { $_[0]->values( as => 'hash') }
    sub hsl         { $_[0]->values( in => 'hsl') }
    sub hue         {($_[0]->values( in => 'hsl'))[0] }
    sub set         { shift->set_value( @_ ) }
    sub add         { shift->add_value( @_ ) }
    sub saturation  {($_[0]->values( in => 'hsl'))[1] }
    sub lightness   {($_[0]->values( in => 'hsl'))[2] }
    sub hsl_hash    { $_[0]->values( in => 'hsl', as => 'hash') }
    sub distance_to { distance(@_) }
    sub blend       { mix( @_ ) }
    sub blend_with  { $_[0]->mix( with => $_[1], amount => $_[2], in => 'HSL') }
    sub gradient_to     { hsl_gradient_to( @_ ) }
    sub rgb_gradient_to { $_[0]->gradient( to => $_[1], steps => $_[2], dynamic => $_[3], in => 'RGB' ) }
    sub hsl_gradient_to { $_[0]->gradient( to => $_[1], steps => $_[2], dynamic => $_[3], in => 'HSL' ) }
    sub complementary { complement(@_) }

sub _split_named_args {
    my ($raw_args, $only_parameter, $required_parameter, $optional_parameter, $parameter_alias) = @_;
    @$raw_args = %{$raw_args->[0]} if @$raw_args == 1 and ref $raw_args->[0] eq 'HASH' and not
                  (defined $only_parameter and $only_parameter eq 'to' and ref _new_from_scalar_def( $raw_args ) );

    if (@$raw_args == 1 and defined $only_parameter and $only_parameter){
        return "The one default argument can not cover multiple, required parameter !" if @$required_parameter > 1;
        return "The default argument does not cover the required argument!"
            if @$required_parameter and $required_parameter->[0] ne $only_parameter;

        my %defaults = %$optional_parameter;
        delete $defaults{$only_parameter};
        return {$only_parameter => $raw_args->[0], %defaults};
    }
    my %clean_arg;
    if (@$raw_args % 2) {
        return (defined $only_parameter and $only_parameter)
             ? "Got odd number of values, please use key value pairs as arguments or one default argument !\n"
             : "Got odd number of values, please use key value pairs as arguments !\n"
    }
    my %arg_hash = @$raw_args;
    for my $parameter_name (@$required_parameter){
        if (ref $parameter_alias eq 'HASH' and exists $parameter_alias->{ $parameter_name }
            and exists $arg_hash{ $parameter_alias->{$parameter_name} }){
            $arg_hash{ $parameter_name } = delete $arg_hash{ $parameter_alias->{$parameter_name} };
        }
        return "Argument '$parameter_name' is missing\n" unless exists $arg_hash{$parameter_name};
        $clean_arg{ $parameter_name } = delete $arg_hash{ $parameter_name };
    }
    for my $parameter_name (keys %$optional_parameter){
        if (ref $parameter_alias eq 'HASH' and exists $parameter_alias->{ $parameter_name }
            and exists $arg_hash{ $parameter_alias->{$parameter_name} }){
            $arg_hash{ $parameter_name } = delete $arg_hash{ $parameter_alias->{$parameter_name} };
        }
        $clean_arg{ $parameter_name } = exists $arg_hash{$parameter_name}
                                      ? delete $arg_hash{ $parameter_name }
                                      : $optional_parameter->{ $parameter_name };
    }
    return "Inserted unknown argument(s): ".(join ',', keys %arg_hash)."\n" if %arg_hash;
    return \%clean_arg;
}

## getter ##############################################################
sub values       {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'in', [],
                               { in => $default_space_name, as => 'list',
                                 precision => undef, range => undef, suffix => undef } );
    my $help = <<EOH;
    GTC method 'values' accepts either no arguments, one color space name or four optional, named args:
    values ( ...
        in => 'HSL',          # color space name, defaults to "$default_space_name"
        as => 'css_string',   # output format name, default is "list"
        range => 1,           # value range (SCALAR or ARRAY), default set by space def
        precision => 3,       # value precision (SCALAR or ARRAY), default set by space
        suffix => '%',        # value suffix (SCALAR or ARRAY), default set by color space

EOH
    return $arg.$help unless ref $arg;
    $self->{'values'}->formatted( @$arg{qw/in as suffix range precision/} );
}

sub name         {
    my ($self, @args) = @_;
    return $self->{'values'}->name unless @args;
    my $arg = _split_named_args( \@args, 'from', [], {from => 'default', all => 0, full => 0, distance => 0});
     my $help = <<EOH;
    GTC method 'name' accepts three optional, named arguments:
    name ( ...
        'CSS'                 # color naming scheme works as only positional argument
        from => 'CSS'         # same scheme (defaults to internal: X + CSS + PantoneReport)
        from => ['SVG', 'X']  # more color naming schemes at once, without duplicates
        all => 1              # returns list of all names with the object's RGB values (defaults 0)
        full => 1             # adds color scheme name to the color name. 'SVG:red' (defaults 0)
        distance => 3         # color names from within distance of 3 (defaults 0)
EOH
    return Graphics::Toolkit::Color::Name::from_values( $self->{'values'}->shaped, @$arg{qw/from all full distance/});
}

sub closest_name {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'from', [], {from => 'default', all => 0, full => 0});
    my $help = <<EOH;
    GTC method 'name' accepts three optional, named arguments:
    closest_name ( ...
        'CSS'                 # color naming scheme works as only positional argument
        from => 'CSS'         # same scheme (defaults to internal: X + CSS + PantoneReport)
        from => ['SVG', 'X']  # more color naming schemes at once, without duplicates
        all => 1              # returns list of all names with the object's RGB values (defaults 0)
        full => 1             # adds color scheme name to the color name. 'SVG:red' (defaults 0)
EOH
    my ($name, $distance) = Graphics::Toolkit::Color::Name::closest_from_values(
                                $self->{'values'}->shaped, @$arg{qw/from all full/});
    return wantarray ? ($name, $distance) : $name;
}

sub distance {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {in => $default_space_name, select => undef, range => undef});
    my $help = <<EOH;
    GTC method 'distance' accepts as arguments either a scalar color definition or
    four named arguments, only the first being required:
    distance ( ...
        to => 'green'         # color object or color definition (required)
        in => 'HSL'           # color space name, defaults to "$default_space_name"
        select => 'red'       # axis name or names (ARRAY ref), default is none
        range => 2**16        # value range definition, defaults come from color space def
EOH
    return $arg.$help unless ref $arg;
    my $target_color = _new_from_scalar_def( $arg->{'to'} );
    return "target color definition: $arg->{to} is ill formed" unless ref $target_color;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    if (defined $arg->{'select'}){
        if (not ref $arg->{'select'}){
            return $arg->{'select'}." is not an axis name in color space: ".$color_space->name
                unless $color_space->is_axis_name( $arg->{'select'} );
        } elsif (ref $arg->{'select'} eq 'ARRAY'){
            for my $axis_name (@{$arg->{'select'}}) {
                return "$axis_name is not an axis name in color space: ".$color_space->name
                    unless $color_space->is_axis_name( $axis_name );
            }
        } else { return "The 'select' argument needs one axis name or an ARRAY with several axis names".
                       " from the same color space!" }
    }
    my $range_def = $color_space->shape->try_check_range_definition( $arg->{'range'} );
    return $range_def unless ref $range_def;
    Graphics::Toolkit::Color::Space::Hub::distance(
        $self->{'values'}->normalized, $target_color->{'values'}->normalized, $color_space->name ,$arg->{'select'}, $range_def );
}

## single color creation methods #######################################
sub set_value {
    my ($self, @args) = @_;
    @args = %{$args[0]} if @args == 1 and ref $args[0] eq 'HASH';
    my $help = <<EOH;
    GTC method 'set_value' needs a value HASH (not a ref) whose keys are axis names or
    short names from one color space. If the chosen axis name(s) is/are ambiguous,
    you might add the "in" argument:
        set_value( green => 20 ) or set( g => 20 ) or
        set_value( hue => 240, in => 'HWB' )
EOH
    return $help if @args % 2 or not @args or @args > 10;
    my $partial_color = { @args };
    my $space_name = delete $partial_color->{'in'};
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return "$color_space\n".$help unless ref $color_space;
    _new_from_value_obj( $self->{'values'}->set( $partial_color, $space_name ) );
}

sub add_value {
    my ($self, @args) = @_;
    @args = %{$args[0]} if @args == 1 and ref $args[0] eq 'HASH';
    my $help = <<EOH;
    GTC method 'add_value' needs a value HASH (not a ref) whose keys are axis names or
    short names from one color space. If the chosen axis name(s) is/are ambiguous,
    you might add the "in" argument:
        add_value( blue => -10 ) or set( b => -10 )
        add_value( hue => 100 , in => 'HWB' )
EOH
    return $help if @args % 2 or not @args or @args > 10;
    my $partial_color = { @args };
    my $space_name = delete $partial_color->{'in'};
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return "$color_space\n".$help unless ref $color_space;
    _new_from_value_obj( $self->{'values'}->add( $partial_color, $space_name ) );
}

sub mix {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {in => $default_space_name, amount => 50});
    my $help = <<EOH;
    GTC method 'mix' accepts three named arguments, only the first being required:
    mix ( ...
        to => ['HSL', 240, 100, 50]    # scalar color definition or ARRAY ref thereof
        amount => 20                   # percentage value or ARRAY ref thereof, default is 50
        in => 'HSL'                    # color space name, defaults to "$default_space_name"
    Please note that either both or none of the first two arguments has to be an ARRAY.
    Both ARRAY have to have the same length. 'amount' refers to the color(s) picked with 'to'.
EOH
    return $arg.$help unless ref $arg;
    my $recipe = _new_from_scalar_def( $arg->{'to'} );
    if (ref $recipe){
        $recipe = [{color => $recipe->{'values'}, percent => 50}];
        return "Amount argument has to be a sacalar value if only one color is mixed !\n".$help if ref $arg->{'amount'};
        $recipe->[0]{'percent'} = $arg->{'amount'} if defined $arg->{'amount'};
    } else {
        if (ref $arg->{'to'} ne 'ARRAY'){
            return "target color definition (argument 'to'): $arg->{to} is ill formed, has to be one color definition or an ARRAY of";
        } else {
            $recipe = [];
            for my $color_def (@{$arg->{'to'}}){
                my $color = _new_from_scalar_def( $color_def );
                return "target color definition: '$color_def' is ill formed" unless ref $color;
                push @$recipe, { color => $color->{'values'}, percent => 50};
            }
            return "Amount argument has to be an ARRAY of same length as argument 'to' (color definitions)!\n".$help
                if ref $arg->{'to'} eq 'ARRAY' and ref $arg->{'amount'} eq 'ARRAY' and @{$arg->{'amount'}} != @{$arg->{'to'}};
            $arg->{'amount'} = [($arg->{'amount'}) x @{$arg->{'to'}}] if ref $arg->{'to'} and not ref $arg->{'amount'};
            $recipe->[$_]{'percent'} = $arg->{'amount'}[$_] for 0 .. $#{$arg->{'amount'}};
        }
    }
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( delete $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    _new_from_value_obj( $self->{'values'}->mix( $recipe, $color_space ) );
}

sub invert {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'in', [], {in => $default_space_name});
    my $help = <<EOH;
    GTC method 'invert' accepts one optional argument, which can be positional or named:
    invert ( ...
        in => 'HSL'                    # color space name, defaults to "$default_space_name"
EOH
    return $arg.$help unless ref $arg;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    _new_from_value_obj( $self->{'values'}->invert( $color_space ) );
}

## color set creation methods ##########################################
sub complement {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'steps', [], {steps => 1, tilt => 0, target => {}});
    my $help = <<EOH;
    GTC method 'complement' is computed in HSL and has two named, optional arguments:
    complement ( ...
        steps => 20                                 # count of produced colors, default is 1
        tilt => 10                                  # default is 0
        target => {h => 10, s => 20, l => 3}        # sub-keys are independent, default to 0
EOH
    return $arg.$help unless ref $arg;
    return "Optional argument 'steps' has to be a number !\n".$help unless is_nr($arg->{'steps'});
    return "Optional argument 'steps' is zero, no complement colors will be computed !\n".$help unless $arg->{'steps'};
    return "Optional argument 'tilt' has to be a number !\n".$help unless is_nr($arg->{'tilt'});
    return "Optional argument 'target' has to be a HASH ref !\n".$help if ref $arg->{'target'} ne 'HASH';
    my ($target_values, $space_name);
    if (keys %{$arg->{'target'}}){
        ($target_values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash( $arg->{'target'}, 'HSL' );
        return "Optional argument 'target' got HASH keys that do not fit HSL space (use 'h','s','l') !\n".$help
            unless ref $target_values;
    } else { $target_values = [] }
    map {_new_from_value_obj( $_ )}
        Graphics::Toolkit::Color::SetCalculator::complement( $self->{'values'}, @$arg{qw/steps tilt/}, $target_values );
}

sub gradient {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {steps => 10, tilt => 0, in => $default_space_name});
    my $help = <<EOH;
    GTC method 'gradient' accepts four named arguments, only the first is required:
    gradient ( ...
        to => 'blue'              # scalar color definition or ARRAY ref thereof
        steps =>  20              # count of produced colors, defaults to 10
        tilt  =>  1               # dynamics of color change, defaults to 0
        in => 'HSL'               # color space name, defaults to "$default_space_name"
EOH
    return $arg.$help unless ref $arg;
    my @colors = ($self->{'values'});
    my $target_color = _new_from_scalar_def( $arg->{'to'} );
    if (ref $target_color) {
        push @colors, $target_color->{'values'} }
    else {
        return "Argument 'to' contains malformed color definition!\n".$help if ref $arg->{'to'} ne 'ARRAY' or not @{$arg->{'to'}};
        for my $color_def (@{$arg->{'to'}}){
            my $target_color = _new_from_scalar_def( $color_def );
            return "Argument 'to' contains malformed color definition: $color_def !\n".$help unless ref $target_color;
            push @colors, $target_color->{'values'};
        }
    }
    return "Argument 'steps' has to be a number greater zero !\n".$help
        unless is_nr($arg->{'steps'}) and $arg->{'steps'} > 0;
    $arg->{'steps'} = int $arg->{'steps'};
    return "Argument 'tilt' has to be a number !\n".$help unless is_nr($arg->{'tilt'});
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    map {_new_from_value_obj( $_ )}
        Graphics::Toolkit::Color::SetCalculator::gradient( \@colors, @$arg{qw/steps tilt/}, $color_space);
}

sub cluster {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, undef, ['radius', 'minimal_distance'], {in => $default_space_name},
                                 {radius => 'r', minimal_distance => 'min_d'}                              );
    my $help = <<EOH;
    GTC method 'cluster' accepts three named arguments, the first two being required:
    cluster (  ...
        radius => 3                    # ball shaped cluster with cuboctahedral packing or
        r => [10, 5, 3]                # cuboid shaped cluster with cubical packing
        minimal_distance => 0.5        # minimal distance between colors in cluster
        min_d => 0.5                   # short alias for minimal distance
        in => 'HSL'                    # color space name, defaults to "$default_space_name"
EOH
    return $arg.$help unless ref $arg;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    return "Argument 'radius' has to be a number or an ARRAY of numbers".$help
        unless is_nr($arg->{'radius'}) or $color_space->is_number_tuple( $arg->{'radius'} );
    return "Argument 'distance' has to be a number greater zero !\n".$help
        unless is_nr($arg->{'minimal_distance'}) and $arg->{'minimal_distance'} > 0;
    return "Ball shaped cluster works only in spaces with three dimensions !\n".$help
        if $color_space->axis_count > 3 and not ref $arg->{'radius'};
    map {_new_from_value_obj( $_ )}
        Graphics::Toolkit::Color::SetCalculator::cluster( $self->{'values'}, @$arg{qw/radius minimal_distance/}, $color_space);
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color - calculate color (sets), IO many spaces and formats

=head1 SYNOPSIS

    use Graphics::Toolkit::Color qw/color/;

    my $red = Graphics::Toolkit::Color->new('red');  # create color object
    say $red->add_value( 'blue' => 255 )->name;      # red + blue = 'magenta'
    my @blue = color( 0, 0, 255)->values('HSL');     # 240, 100, 50 = blue
    $red->mix( to => [HSL => 0,0,80], amount => 10); # mix red with a little grey
    $red->gradient( to => '#0000FF', steps => 10);   # 10 colors from red to blue
    my @base_triadic = $red->complement( 3 );        # get fitting red green and blue
    my @reds = $red->cluster( radius => 4, distance => 1 );


=head1 DEPRECATION WARNING

Methods of the old API ( I<string>, I<rgb>, I<red>,
I<green>, I<blue>, I<rgb_hex>, I<rgb_hash>, I<hsl>, I<hue>, I<saturation>,
I<lightness>, I<hsl_hash>, I<add>, I<set>, I<blend>, I<blend_with>,
I<gradient_to>, I<rgb_gradient_to>, I<hsl_gradient_to>, I<complementary>)
will be removed with release of version 2.0.

=head1 DESCRIPTION

Graphics::Toolkit::Color, for short B<GTC>, is the top level API of this
release and the only package a regular user should be concerned with.
Its main purpose is the creation of related colors or sets of them,
such as gradients, complements and others. But you can use it also to
convert and/or reformat color definitions.

GTC are read only, one color representing objects with no additional
dependencies. Create them in many different ways (see L</CONSTRUCTOR>).
Access its values via methods from section L</GETTER>.
Measure differences with the L</distance> method. L</SINGLE-COLOR>
methods create one new object that is related to the current one and
L</COLOR-SETS> methods will create a group of colors, that are not
only related to the current color but also have relations between each other.
Error messages will appear as return values instead of the expected result.

While this module can understand and output color values to many
L<color spaces|Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>,
L<RGB|Graphics::Toolkit::Color::Space::Hub/RGB>
is the (internal) primal one, because GTC is about colors that can be
shown on the screen, and these are usually encoded in I<RGB>.
Humans access colors on hardware level (eye) in I<RGB>, on cognition level
in I<HSL> (brain) and on cultural level (language) with names.
Having easy access to all of those plus some color math and many formats
should enable you to get the color palette you desire quickly.


=head1 CONSTRUCTOR

There are many options to create a color object. In short you can either
use the name of a constant (see L</name>) or provide values, which are
coordinates in one of several
L<color spaces|Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>.
The latter are also understood in many
L<formats|Graphics::Toolkit::Color::Space::Hub/FORMATS>.
From now on any input that the constructor method C<new> accepts,
is called a B<color definition>.


=head2 new({ r => $r, g => $g, b => $b })

Most clear, flexible and longest input format: a hash with long or short
axis names as keys with fitting values. This can be C<red>, C<green> and
C<blue> or C<r>, C<g> and C<b> or names from any other color space.
Upper or lower case doesn't matter.

    my $red = Graphics::Toolkit::Color->new( r => 255, g => 0, b => 0 );
    my $red = Graphics::Toolkit::Color->new({r => 255, g => 0, b => 0}); # works too
                        ... ->new( Red => 255, Green => 0, Blue => 0);   # also fine
              ... ->new( Hue => 0, Saturation => 100, Lightness => 50 ); # same color
                  ... ->new( Hue => 0, whiteness => 0, blackness => 0 ); # still the same


=head2 new( [$r, $g, $b] )

takes a triplet of integer I<RGB> values (red, green and blue : 0 .. 255).
They can, but don't have to be put into an ARRAY reference (square brackets).
If you want to define a color by values from another color space,
you have to prepend the values with the name of a supported color space.
Out of range values will be corrected (clamped).

    my $red = Graphics::Toolkit::Color->new(         255, 0, 0 );
    my $red = Graphics::Toolkit::Color->new(        [255, 0, 0]); # does the same
    my $red = Graphics::Toolkit::Color->new( 'RGB',  255, 0, 0 ); # named ARRAY syntax
    my $red = Graphics::Toolkit::Color->new(  RGB => 255, 0, 0 ); # with fat comma
    my $red = Graphics::Toolkit::Color->new([ RGB => 255, 0, 0]); # and brackets
    my $red = Graphics::Toolkit::Color->new(  RGB =>[255, 0, 0]); # separate name and values
    my $red = Graphics::Toolkit::Color->new(  YUV =>.299,-0.168736, .5); # same color in YUV


=head2 new('rgb($r,$g,$b)')

String format that is supported by CSS (I<css_string> format): it starts
with the case insensitive color space name (lower case is default),
followed by the (optionally with) comma separated values in round braces.
The value suffixes that are defined by the color space (I<'%'> in case
of I<HSV>) are optional.

    my $red = Graphics::Toolkit::Color->new( 'rgb(255 0 0)' );
    my $blue = Graphics::Toolkit::Color->new( 'hsv(240, 100%, 100%)' );


=head2 new('rgb: $r, $g, $b')

String format I<named_string> (good for serialisation) that maximizes
readability.

    my $red = Graphics::Toolkit::Color->new( 'rgb: 255, 0, 0' );
    my $blue = Graphics::Toolkit::Color->new( 'HSV: 240, 100, 100' );


=head2 new('#rgb')

Color definitions in hexadecimal format as widely used in the web, are
also acceptable (I<RGB> only).

    my $color = Graphics::Toolkit::Color->new('#FF0000');
    my $color = Graphics::Toolkit::Color->new('#f00');    # short works too


=head2 new('name')

Get a color object by providing a name from the X11, HTML (CSS) or SVG
scheme or a Pantone report. UPPER or CamelCase will be normalized to
lower case and inserted underscore letters ('_') will be ignored as perl
does in numbers (1_000 == 1000). All available names are listed
L<here | Graphics::Toolkit::Color::Name::Constant/NAMES>.

    my $color = Graphics::Toolkit::Color->new('Emerald');
    my @names = Graphics::Toolkit::Color::Name::all(); # select from these


=head2 new('scheme:color')

Get a color by name from a specific scheme or standard as provided by an
external module L<Graphics::ColorNames>::* , which has to be installed
separately or with L<Bundle::Graphics::ColorNames>.
See all scheme names L<here | Graphics::Toolkit::Color::Name/SCHEMES>.
The color name will be  normalized as above.

    my $color = Graphics::Toolkit::Color->new('SVG:green');
    my @schemes = Graphics::ColorNames::all_schemes();      # look up the installed


=head2 color

If writing

    Graphics::Toolkit::Color->new( ...);

is too much typing work for you or takes up to much space in the code file,
import the subroutine C<color>, which accepts all the same arguments as C<new>.

    use Graphics::Toolkit::Color qw/color/;
    my $green = color('green');
    my $darkblue = color([20, 20, 250]);



=head1 GETTER

giving access to different parts of the objects data.


=head2 values

Returns the numeric values of the color, held by the object.
The method accepts five optional, named arguments:
L</in> (color space), C<as> (format), L</range>, C<precision> and C<suffix>.
In most cases, only the first one is needed.

When given no arguments, the method returns a list with the integer
values: C<red>, C<green> and C<blue> in 0 .. 255 range, since I<RGB> is
the default color space of this module.

If one positional argument is provided, the values get converted into the
color space of the given name. The same is done when using the named
argument L</in> (full explanation behind the link). The named argument
L</range> is also explained in its own section. Please note you have to
use the C<range> argument only, if you like to deviate from the value
ranges defined by the chosen color space.

The maybe most characteristic argument for this method is C<as>, which
enables all the same formats the constructor method C<new> accepts.
I<GTC> is built with the design principle of total serialisation.
This means: every contructor input format can be reproduced by a getter
method and vice versa. These formats are: C<list> (default),
C<named_array>, C<hash>, C<char_hash>, C<named_string>, C<css_string>,
C<array> (RGB only) and C<hex_string> (RGB only). The remaining two.
C<name> and C<full:name> are produce by the method L</name>.
Format names are case insensitive. For more explanations, please see:
L<formats section|Graphics::Toolkit::Color::Space::Hub/FORMATS> in GTC::Space::Hub.

C<precision> is more exotic argument, but sometimes you need to escape
the numeric precision, set by a color spaces definition.
For instance C<LAB> values will have maximally three decimals, no matter
how precise the input was. In case you prefer 4 decimals, just use
C<< precision => 4 >>. A zero means no decimals and -1 stands for maximal
precision -  which can spit out more decimals than you prefer.
Different precisions per axis are possible via an ARRAY ref:
C<< precision => [1,2,3] >>.

In same way you can atach a little strings per value by ussing the C<suffix>
argument. Normally these are percentage signs but in some spaces, where
they appear by default you can surpress them by adding C<< suffix => '' >>


    $blue->values();                                    # 0, 0, 255
    $blue->values( in => 'RGB', as => 'list');          # 0, 0, 255 # explicit arguments
    $blue->values(              as => 'array');         # [0, 0, 255] - RGB only
    $blue->values( in => 'RGB', as => 'named_array');   # ['RGB', 0, 0, 255]
    $blue->values( in => 'RGB', as => 'hash');          # { red => 0, green => 0, blue => 255}
    $blue->values( in => 'RGB', as => 'char_hash');     # { r => 0, g => 0, b => 255}
    $blue->values( in => 'RGB', as => 'named_string');  # 'rgb: 0, 0, 255'
    $blue->values( in => 'RGB', as => 'css_string');    # 'rgb( 0, 0, 255)'
    $blue->values(              as => 'hex_string');    # '#0000ff' - RGB only
    $blue->values(           range => 2**16 );          # 0, 0, 65536
    $blue->values('HSL');                               # 240, 100, 50
    $blue->values( in => 'HSL',suffix => ['', '%','%']);# 240, '100%', '50%'
    $blue->values( in => 'HSB',  as => 'hash')->{'hue'};# 240
   ($blue->values( 'HSB'))[0];                          # 240
    $blue->values( in => 'XYZ', range => 1, precision => 2);# normalized, 2 decimals max.


=head2 name

Returns the normalized name string (lower case, without I<'_'>) that
represents the I<RGB> values of this color in the default color scheme,
which is I<X11> + I<HTML> (I<SVG>) + I<Pantone report>
(see L<all names|Graphics::Toolkit::Color::Name::Constant/NAMES>).
These are the same which can be used with L</new('name')>.

Alternatively you may provide named arguments or one positional argument,
which is the same as the named argument C<from>. That required a name of
a color schemes, as listed L<here|Graphics::Toolkit::Color::Name/SCHEMES>.
You also can submit a list thereof inside a ARRRAY ref which also dictates
the order of resulting color names.
Please note that all color schemes, except the default one, depend on
external modules, which have to be installed separately or via
L<Bundle::Graphics::ColorNames>.
If you try to use a scheme from a not installed module your will get an
error message instead of a color name. You can also create your custom
color naming scheme via L<Graphics::Toolkit::Color::Name::Scheme>.

The second named argument is C<all>, which needs to be a perly boolean.
It defaults to false. But if set to 1, you will get a list of all names
that are associated with the current values. There will be no duplicates,
when several schemes are searched.

A third named argument is C<full> - also needing a perly boolean that
defaults to false. When set C<true> (1), the schema name becomes part of
the returned color name as in C<'SVG:red'>. These full names are also
accepted by the constructor.

The fourth named argument is C<distance>, which means the same thing as
in L</distance> and it defaults to zero. It is most useful in combinataion
with C<all> to get all color names that are within a certain distance.

    $blue->name();                                   # 'blue'
    $blue->name('SVG');                              # 'blue'
    $blue->name( from => [qw/CSS X/], all => 1);     # 'blue', 'blue1'
    $blue->name( from => 'CSS', full => 1);          # 'CSS:blue'
    $blue->name( distance => 3, all => 1) ;          # all names within the distance


=head2 closest_name

Returns in scalar context a color name, which has the shortest L</distance>
in I<RGB>nto the current color. In list context, you get additionally
the just mentioned distance as a second return value. This method works
almost identically as method L</name>, but guarantees a none empty
result, unless invoking a unusually empty color scheme.

All arguments work as mentioned above, only here is no C<distance> argument.
The only difference is (due to the second return value), multiple names
(when requested) have to come in the form of an ARRAY as the first return value.

    my $name = $red_like->closest_name;              # closest name in default scheme
    my $name = $red_like->closest_name('HTML');      # closest HTML constant
    ($red_name, $distance) = $red_like->closest_name( from => 'Pantone', all => 1 );


=head2 distance

Is a floating point number that measures the Euclidean distance between
two colors, which represent two points in a color space. One color
is the calling object itself and the second one has to be provided as
either the only argument or the named argument L</to>, which is the only
required one.

The C<distance> is measured in I<RGB> color space unless told otherwise
by the argument L</in>. Please use the I<OKLAB> or I<CIELUV> space, if
you are interested in getting a result that matches the human perception.

The third argument is named C<select>. It's useful if you want to regard
only certain dimensions (axis - long and short axis names are accepted).
For instance if you want to know only the difference in brightness between
two colors, you type C<< select => 'lightness' >> or C<< select => 'l' >>.
This naturally works only if you did also choose I<HSL> as a color space
or something similar that has a C<lightness> axis like I<LAB> or I<OKLAB>.
The C<select> argument accepts a string or an ARRAY with several axis names,
which can also repeat. For instance there is a formula to compute distances
in RGB that weights the squared value delta's:
C<< $distance =  sqrt( 3 * delta_red**2 + 4 * delta_green**2 + 2 * delta_blue**2) >>.
You can recreate that formula by typing C<< select => [qw/ r r r g g g g b b/] >>

The last argument is named L</range>, which can change the result drasticly.

    my $d = $blue->distance( 'lapisblue' );                 # how close is blue to lapis?
    $d = $blue->distance( to => 'airyblue', select => 'b'); # have they the same amount of blue?
    $d = $color->distance( to => $c2, in => 'HSL', select => 'hue' );  # same hue?
    $d = $color->distance( to => $c2, range => 'normal' );  # distance with values in 0 .. 1 range
    $d = $color->distance( to => $c2, select => [qw/r g b b/]); # double the weight of blue value differences



=head1 SINGLE COLOR

These methods generate one new color object that is related to the calling
object (invocant). You might expect that methods like C<set_value> change
the values of the invocant, but GTC objects are as mentioned in the
L</DESCRIPTION> read only. That supports a more functional programming
style as well as method stacking like:

    $color->add_value( saturation => 5)->invert->mix( to => 'green');


=head2 set_value

Creates a new GTC color object that shares some values with the current one,
but differs in others. The altered values are provided as absoltue numbers.
If the resulting color will be outside of the given color space, the values
will be clamped so it will become a regular color of that space.

The axis of
L<all supported color spaces|Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>
have long and short names. For instance I<HSL> has I<hue>, I<sturation>
and I<lightness>. The short equivalents are I<h>, I<s> and I<l>. This
method accepts these axis names as named arguments and disregards if
characters are written upper or lower case. This method can not work,
if you mix axis names from different spaces or choose one axis more than once.
One solvable issue is when axis in different spaces have the same name.
For instance I<HSL> and I<HSV> have a I<saturation> axis. To disambiguate
you can add the named argument L</in>.

    my $blue = $black->set_value( blue => 255 );              # same as #0000ff
    my $pale_blue = $blue->set_value( saturation => 50 );        # ->( s => 50) works too
    my $color = $blue->set_value( saturation => 50, in => 'HSV' );  # previous was HSL


=head2 add_value

Creates a new GTC color object that shares some values with the current one,
but differs in others. The altered values are provided relative to the current
ones. The rest works as described in L</set_value>.
This method was mainly created to get lighter, darker or more saturated
colors by using it like:


    my $blue = Graphics::Toolkit::Color->new('blue');
    my $darkblue = $blue->add_value( Lightness => -25 );  # get a darker tone
    my $blue2 = $blue->add_value( blue => 10 );           # bluer than blue ?
    my $blue3 = $blue->add_value( l => 10, in => 'LAB' ); # lighter color according CIELAB


=head2 mix

Create a new GTC object, that has the average values
between the calling object and another color (or several colors).
It accepts three named arguments: L</to>, C<amount> and L</in>, but only
the first one is required.

L</to> works like in other methods, with the exception that it also
accepts an ARRAY ref (square brackets) with several color definitions.

Per default I<mix> computes a 50-50 (1:1) mix. In order to change that,
employ the C<amount> argument, which is the weight the mixed in color(s)
get, counted in percentages. The remaining percentage to 100 is the weight
of the color, held by the caller object. This would be naturally nothing,
if the C<amount> is greater than hundret, which is especially something
to consider, if mixing more than two colors. Then both C<to> and C<amount>
have to get an array of colors and respectively their amounts (same order).
Obviously both arrays MUST have the same length. If the sum of amounts is
greater than 100 the original color is ignored but the weight ratios will
be kept. You may actually give C<amount> a scalar value while mixing a list
of colors. Then the amount is applied to every color mentioned under the
C<to> argument. In this case you go over the sum of 100% very quickly.

    $blue->mix( 'silver');                                         # 50% silver, 50% blue
    $blue->mix( to => 'silver', amount => 60 );                    # 60% silver, 40% blue
    $blue->mix( to => [qw/silver green/], amount => [10, 20]);     # 10% silver, 20% green, 70% blue
    $blue->mix( to => [qw/silver green/] );                        # 50% silver, 50% green
    $blue->mix( to => {H => 240, S =>100, L => 50}, in => 'RGB' ); # teal


=head2 invert

Computes the a new color object, where all values are inverted according
to the ranges of the chosen color space (see L</in>). It takes only one
optional, positional argument, a space name.

    my $black = $white->invert();         # to state the obvious
    my $blue = $yellow->invert( 'LUV' );  # invert in LUV space
    $yellow->invert( in => 'LUV' );       # would work too



=head1 COLOR SETS

construct several interrelated color objects at once.


=head2 complement

Creates a set of complementary colors (GTC objects), which will be
computed in I<HSL> color space. The method accepts three optional,
named arguments: C<steps> and C<tilt> and C<target>. But if none are
provided, THE (one) complementary color will be produced.

One singular, positional argument defines the number of produced colors,
same as the named argument C<steps> would have. If you want to get
'triadic' colors, choose 3 as an argument for C<steps> - 4 would get
you the 'tetradic' colors, .... and so on. The given color is always
the last in the row of produced complementary colors.

If you need split-complementary colors, just use the C<tilt> argument,
which defaults to zero. Without any tilt, complementary colors are equally
distanced dots on a horizontal circle around the vertical, central column
in I<HSL> space. In other words: complementary colors have all the same
'saturation' (distance from the column) and 'lightness' (height).
They differ only in 'hue' (position on the circle). The given color
and its (THE) complement sit on opposite sides of the circle.
The greater the C<tilt> amount, the more these colors (minus the given
one) will move on the circle toward THE complement and vice versa.
What is traditionally meant by split-complementary colors you will
get here with a C<tilt> factor of around 3.42 and three C<steps> or
a C<tilt> of 1.585 and four C<steps> (depending on if you need
THE complement also in your set).

To get an even greater variety of complementary colors, you can use
C<target> argument and move around THE complement and thus shape the
circle in all three directions. C<hue> (or C<h>) values move it
circularly C<saturation> (or C<s>) move it away or negative values toward
the central column and C<lightness> (or C<l>) move it up and down.

    my @colors = $c->complement( 4 );                       # 'tetradic' colors
    my @colors = $c->complement( steps => 4, tilt => 4 );   # split-complementary colors
    my @colors = $c->complement( steps => 3, tilt => { move => 2, target => {l => -10}} );
    my @colors = $c->complement( steps => 3, tilt => { move => 2,
                                                     target => { h => 20, s=> -5, l => -10 } });


=head2 gradient

Creates a gradient (a list of color objects that build a transition)
between the current color held by the object and a second color,
provided by the named argument L</to>, which is  required.
Optionally C<to> accepts an ARRAY ref (square braces) with a list of
colors in order to create the most fancy, custom and nonlinear gradients.

Also required is the named argument C<steps>, which is the gradient length
or count of colors, which are part of this gradient. Included in there
are the start color (given by this object) and end color (given with C<to>).

The optional, floating point valued argument C<tilt> makes the gradient
skewed toward one or the other end. Default is zero, which results in
a linear, uniform transition between start and stop.
Greater values of the argument let the color change rate start small,
steadily getting bigger. Negative values work vice versa.
The bigger the absolute numeric value the bigger the effect. Please have
in mind that values over 2 result is a very strong tilt.

Optional is the named argument L</in> (color space - details behind link).
Tip: use C<oklab> and C<cieluv> spaces for visually smooth gradients.

    # we turn to grey
    my @colors = $c->gradient( to => $grey, steps => 5);
    # none linear gradient in HSL space :
    @colors = $c1->gradient( to =>[14,10,222], steps => 10, tilt => 1, in => 'HSL' );
    @colors = $c1->gradient( to =>['blue', 'brown', {h => 30, s => 44, l => 50}] );


=head2 cluster

Computes a set of colors that are all similar but not the same.
The method accepts three named arguments: C<radius>, C<distance> and L</in>,
of which the first two are required.

The produced colors form a ball or cuboid in a color space around the given
color, depending on what the argument C<radius> got. If it is a single
number, it will be a ball with the given radius. If it is an ARRAY of
values you get the a cuboid with the given dimensions.

The minimal distance between any two colors of a cluster is set by the
C<minimal_distance> argument, which is computed the same way as the method
L</distance>, in has a short alias C<min_d>. In a cuboid shaped cluster-
the colors will form a cubic grid - inside the ball shaped cluster they
form a cuboctahedral grid, which is packed tighter, but still obeys the
minimal distance.

    my @blues = $blue->cluster( radius => 4, minimal_distance => 0.3 );
    my @c = $color->cluster( r => [2,2,3], min_d => 0.4, in => YUV );



=head1 ARGUMENTS

Some named arguments of the above listed methods reappear in several methods.
Thus they are explained here once. Please note that you must NOT wrap
the named args in curly braces (HASH ref).


=head2 in

The named argument I<in> expects the name of a color space as
L<listed here|Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>.
The default color space in this module is I<RGB>. Depending on the chosen
space, the results of all methods can be very different, since colors
are arranged there very differently and have different distances to each
other. Some colors might not even exist in some spaces.


=head2 range

Every color space comes with range definitions for its values.
For instance I<red>, I<green> and I<blue> in I<RGB> go usually from zero
to 255 (0..255). In order to change that, many methods accept the named
argument C<range>. When only one interger value provided, it changes the
upper bound on all three axis and as lower bound is assumed zero.
Let's say you need I<RGB16> values with a range of 0 .. 65536,
then you type C<< range => 65536 >> or C<< range => 2**16 >>.

If you provide an ARRAY ref you can change the upper bounds of all axis
individually and in order to change even the lower boundaries, use ARRAY
refs even inside that. For instance in C<HSL> the C<hue> is normally
0 .. 359 and the other two axis are 0 .. 100. In order to set C<hue>
to -100 .. 100 but keep the other two untouched you would have to insert:
C<< range => [[-100,100],100,100] >>.


=head2 to

This argument receives a second or target color. It may come in form of
another GTC object or a color definition that is acceptable to the
constructor. But it has to be a scalar (string or (HASH) reference),
not a value list or hash.

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

=head1 ACKNOWLEDGEMENT

These people contributed by providing patches, bug reports and useful
comments:

=over 4

=item *

Petr Pisar  (ppisar)

=item *

Slaven Rezic (srezic)

=item *

Gabor Szabo (szabgab)

=item *

Gene Boggs (GENE)

=item *

Stefan Reddig (sreagle)

=back


=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=head1 COPYRIGHT

Copyright 2022-2025 Herbert Breunung.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

