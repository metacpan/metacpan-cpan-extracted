
# read only store of a single color: name + values in default and original space

package Graphics::Toolkit::Color::Values;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name;
use Graphics::Toolkit::Color::Space::Hub;

my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space();

#### constructor #######################################################
sub new_from_any_input { #  values => %space_name => tuple ,   ~origin_space, ~color_name
    my ($pkg, $color_def, $range_def, $raw) = @_;
    return "Can not create color value object without color definition!" unless defined $color_def;
    if (not ref $color_def) { # try to resolve color name
        my $rgb = Graphics::Toolkit::Color::Name::get_values( $color_def );
        if (ref $rgb){
            $rgb = $RGB->clamp( $RGB->normalize( $rgb ), 'normal' );
            return bless { color_name => $color_def, rgb_tuple => $rgb, source_tuple => '', source_space_name => ''};
        }
    }
    my ($tuple, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat( $color_def );
    return "could not recognize color value format or color name: $color_def" unless ref $tuple;
    new_from_tuple( '', $tuple, $space_name, $range_def, $raw);
}
sub new_from_tuple { #
    my ($pkg, $tuple, $space_name, $range_def, $raw) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    return "Need ARRAY of ".$color_space->axis_count." ".$color_space->name." values as first argument!"
        unless $color_space->is_value_tuple( $tuple );
    $tuple = $color_space->normalize( $tuple, $range_def );
    $tuple = $color_space->clamp( $tuple, 'normal' ) unless defined $raw and $raw;

    my $source_tuple = '';
    my $source_space_name = '';
    if ($color_space->name ne $RGB->name){ # convert into RGB if needed
        $source_tuple = $tuple;
        $source_space_name = $color_space->name;
        $tuple = Graphics::Toolkit::Color::Space::Hub::deconvert( $tuple, $color_space->name, 'normal' );
    }

    my $name = Graphics::Toolkit::Color::Name::from_values( $RGB->round( $RGB->denormalize( $tuple ) ) );
    bless { rgb_tuple => $tuple, source_tuple => $source_tuple, source_space_name => $source_space_name, color_name => $name };
}

#### getter ############################################################
sub normalized { # normalized (0..1) value tuple in any color space
    my ($self, $space_name) = @_;
    Graphics::Toolkit::Color::Space::Hub::convert(
        $self->{'rgb_tuple'}, $space_name, 'normal', $self->{'source_tuple'}, $self->{'source_space_name'},
    );
}
sub shaped  { # in any color space, range and precision
    my ($self, $space_name, $range_def, $precision_def, $raw) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    my $tuple = $self->normalized( $color_space->name );
    return $tuple if not ref $tuple;
    $tuple = $color_space->denormalize( $tuple, $range_def );
    $tuple = $color_space->clamp( $tuple, $range_def ) unless $raw;
    $tuple = $color_space->round( $tuple, $precision_def ) unless ($raw and not defined $precision_def) 
                                                               or (defined $range_def and not defined $precision_def);
    return $tuple;
}
sub formatted { # in shape values in any format # _ -- ~space, @~|~format, @~|~range, @~|~suffix
    my ($self, $space_name, $format_name, $suffix_def, $range_def, $precision_def, $raw) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    my $tuple = $self->shaped( $color_space->name, $range_def, $precision_def, $raw );
    return $tuple unless ref $tuple;
    return $color_space->format( $tuple, $format_name, $suffix_def );
}
sub name { $_[0]->{'color_name'} }

sub is_in_gamut {
    my ($self, $space_name) = @_;
    $space_name = $self->{'source_space_name'} if not defined $space_name and $self->{'source_space_name'};
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name ); # default to RGB
    return 0 unless ref $color_space;
    my $tuple = $self->normalized( $space_name );
    return 0 unless ref $tuple;
    return $color_space->is_in_linear_bounds( $tuple, 'normal' );
}

1;
