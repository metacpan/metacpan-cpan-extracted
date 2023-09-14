use v5.12;
use warnings;

# value objects with cache of original values

package Graphics::Toolkit::Color::Values;
use Graphics::Toolkit::Color::Space::Hub;
use Carp;

sub new {
    my ($pkg, $color_val) = @_;
    my ($values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat( $color_val );
    return carp "could not recognize color values" unless ref $values;
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    my $std_space = Graphics::Toolkit::Color::Space::Hub::base_space();
    my $self = {};
    $self->{'origin'} = $space->name;
    $values = [$space->clamp( $values )];
    $values = [$space->normalize( $values )];
    $self->{$space->name} = $values;
    $self->{$std_space->name} = [$space->convert($values, $std_space->name)] if $space ne $std_space;
    bless $self;
}

sub get { # get a value tuple in any color space, range and format
    my ($self, $space_name, $format_name, $range_def) = @_;
    Graphics::Toolkit::Color::Space::Hub::check_space_name( $space_name ) and return;
    my $std_space_name = $Graphics::Toolkit::Color::Space::Hub::base_package;
    $space_name //= $std_space_name;
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    my $values = (exists $self->{$space->name})
               ? $self->{$space->name}
               : [$space->deconvert( $self->{$std_space_name}, $std_space_name)];
    $values = [ $space->denormalize( $values, $range_def) ];
    Graphics::Toolkit::Color::Space::Hub::format( $values, $space_name, $format_name);
}
sub string { $_[0]->get( $_[0]->{'origin'}, 'string' ) }

########################################################################

sub set { # %val --> _
    my ($self, $val_hash) = @_;
    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::partial_hash_deformat( $val_hash );
    return carp 'key names: '.join(', ', keys %$val_hash). ' do not correlate to any supported color space' unless defined $space_name;
    my @values = $self->get( $space_name );
    for my $pos (keys %$pos_hash){
        $values[$pos] = $pos_hash->{ $pos };
    }
    __PACKAGE__->new([$space_name, @values]);
}

sub add { # %val --> _
    my ($self, $val_hash) = @_;
    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::partial_hash_deformat( $val_hash );
    return carp 'key names: '.join(', ', keys %$val_hash). ' do not correlate to any supported color space' unless defined $space_name;
    my @values = $self->get( $space_name );
    for my $pos (keys %$pos_hash){
        $values[$pos] += $pos_hash->{ $pos };
    }
    __PACKAGE__->new([$space_name, @values]);
}

sub blend { # _c1 _c2 -- +factor ~space --> _
    my ($self, $c2, $factor, $space_name ) = @_;
    return carp "need value object as second argument" unless ref $c2 eq __PACKAGE__;
    $factor //= 0.5;
    $space_name //= 'HSL';
    Graphics::Toolkit::Color::Space::Hub::check_space_name( $space_name ) and return;
    my @values1 = $self->get( $space_name );
    my @values2 = $c2->get( $space_name );
    my @rvalues = map { ((1-$factor) * $values1[$_]) + ($factor * $values2[$_]) } 0 .. $#values1;
    __PACKAGE__->new([$space_name, @rvalues]);
}

########################################################################

sub distance { # _c1 _c2 -- ~space ~metric @range --> +
    my ($self, $c2, $space_name, $metric, $range) = @_;
#say "distance ";
    return carp "need value object as second argument" unless ref $c2 eq __PACKAGE__;
    $space_name //= 'HSL';
    Graphics::Toolkit::Color::Space::Hub::check_space_name( $space_name ) and return;
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    $metric = $space->basis->key_shortcut($metric) if $space->basis->is_key( $metric );
    my @values1 = $self->get( $space_name, 'list', 'normal' );
    my @values2 = $c2->get( $space_name, 'list', 'normal' );
#say "values: @values1   @values2 $space_name";
    return unless defined $values1[0] and defined $values2[0];
    my @delta = $space->delta( \@values1, \@values2 );
#say "normalized:  @delta $metric" if defined $metric;

    @delta = $space->denormalize_range( \@delta, $range);
#say "denormal :  @delta " if defined $metric;
    return unless defined $delta[0] and @delta == $space->dimensions;

    # grep values for individual metric / subspace distance
    if (defined $metric and $metric){
        my @components = split( '', $metric );
        my $pos = $space->basis->key_pos( $metric );
        @components = defined( $pos )
                    ? ($pos)
                    : (map  { $space->basis->shortcut_pos($_) }
                       grep { defined $space->basis->shortcut_pos($_) } @components);
        return - carp "called 'distance' for metric $metric that does not fit color space $space_name!" unless @components;
        @delta = map { $delta [$_] } @components;
    }

    # Euclidean distance:
    @delta = map {$_ * $_} @delta;
    my $d = 0;
    for (@delta) {$d += $_}
    return sqrt $d;
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Value - single color related high level methods

=head1 SYNOPSIS

Readonly object that holds values of a color. It provides methods to get
the values back in different formats, to measure difference to other colors
or to create value objects of related colors.

    use Graphics::Toolkit::Color::Value;

    my $blue = Graphics::Toolkit::Color::Value->new( 'hsl(220,50,60)' );
    my @rgb = $blue->get();
    my $purple = $blue->set({red => 220});


=head1 DESCRIPTION

The object that holds the normalized values of the original color
definition (getter argument) and the normalized RGB tripled, if the color
was not defined in RGB values. This way we omit conversion and rounding
errors as much as possible.

This package is a mediation layer between L<Graphics::Toolkit::Color::Space::Hub>
below, where its just about number crunching of value vectors and the user
API above in L<Graphics::Toolkit::Color>, where it's mainly about producing
sets of colors and handling the arguments. This module is not meant to be
used as an public API since it has much less comfort than I<Graphics::Toolkit::Color>.

=head1 METHODS

=head2 new

The constructor takes only one required argument, a scalar that completely
and numerically defines a color. Inside color definitions are color
space names case insensitive. Some possible formats are

    [ 1, 2, 3 ]                  # RGB triplet
    [ HSL => 220, 100, 3 ]       # named HSL vector
    { h => 220, s =>100, l => 3} # char hash
    { cyan => 1, magenta => 0.5, yellow => 0} # hash
    'hwb: 20, 60, 30'            # string
    'hwb(20,60,30)'              # css_string
    '#2211FF'                    # rgb hex string


=head2 get

Universal getter method -almost reverse function to new: It can return
the colors values in all supported color spaces (first argument)
(see: L<Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>)
and all mentioned formats above (second argument). Additionally a third
arguments can convert the numerical values into different ranges.
The default name space is RGB, default format is a list and every color
space has its default range.

    my @rgb = $val_object->get();
    my @cmyk = $val_object->get('CMYK', 'list', 255);
    my $YIQ = $val_object->get('YIQ', 'string');

=head2 set

Constructs a new C<Graphics::Toolkit::Color::Value> object by absolutely
changing some values of the current object and keeping others. (I<add>
changes some values relatively.) The only and required argument is a
I<HASH> reference which has keys that match only one of the supported
color spaces
(see: L<Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>).
Values outside of the defined limits will be clamped to an acceptable
value (or rotated in case of circular dimensions).


    my $more_blend_color = $val_object->set( {saturation => 40} );
    my $bright_color = $val_object->set( {saturation => 2240} ); #saturation will be 100

=head2 add

This method takes also a HASH reference as input and also produces a related
color object as previous I<set>. Only difference is: the hash values
will be added to the current. If they go outside of the defined limits,
they will be clamped (or rotated in case of circular dimensions).

    my $darker_color = $val_object->set( {lightness => -10} );

=head2 blend

Creates a color value object by mixing two colors.
First and only required argument is the second color value object.
Second argument is the mixing ratio. Zero would result in the original
color and one to the second color. Default value is 0.5 (1:1 mix). Values
outside the 0..1 rande are possible and values will be clamped if they
leave the defined bounds of the required color space.

Third optional argument is the name of the color space the mix will be
calculated in - it defaults to I<'HSL'>.

    my $green = Graphics::Toolkit::Color::Values->new( '#00ff00' );
    my $cyan = $blue->blend( $green, 0.6, 'YIQ' );


=head2 distance

Computes a real number which designates the (Euclidean) distance between
two points in a color space (a.k.a. colors).

The first and only required argument is the second color as an
I<Graphics::Toolkit::Color::Value> object. Second and optional argument
is the name of the color space, where the distance is calculated in
(default is I<'HSL'>). Third argument is the metric, which currently is
just the subset of dimension in the chosen space that should be observed.
One can also mention the shortcut name of a dimension several times to
increase their weight in the calculation. Fourth optional argument are
the numeric ranges of the dimensions. If none are given, the method
only uses normalised (range: 0..1) values.

    my $blue = Graphics::Toolkit::Color::Values->new( '#0000ff' );
    my $green = Graphics::Toolkit::Color::Values->new( '#00ff00' );
    my $d = $blue->distance( $green, 'HSV', 's', 255); # 0 : both have same saturation


=head1 SEE ALSO

=over 4

=item *

L<Convert::Color>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2023 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut
