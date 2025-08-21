
# translate color names to values and vice versa

package Graphics::Toolkit::Color::Name;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name::Scheme;
use Graphics::Toolkit::Color::Space::Util qw/uniq round_decimals/;

#### public API ########################################################
sub all {
    my (@scheme_names) = @_;
    push @scheme_names, 'default' unless @scheme_names;
    my @names = ();
    for my $scheme_name (@scheme_names) {
        my $scheme = try_get_scheme( $scheme_name );
        next unless ref $scheme;
        push @names, $scheme->all_names;
    }
    return uniq( @names );
}

sub get_values {
    my ($color_name, $scheme_name) = @_;
    ($scheme_name, $color_name) = split(':', $color_name, 2) if index($color_name, ':') > -1;
    my $scheme = try_get_scheme( $scheme_name );
    return $scheme unless ref $scheme;
    return $scheme->values_from_name( $color_name );
}

sub from_values {
    my ($values, $scheme_name, $all_names, $full_name) = @_;
    my @names = ();
    my @scheme_names = (ref $scheme_name eq 'ARRAY') ? (@$scheme_name)
                     : (defined $scheme_name)        ? $scheme_name : 'default';
    for my $scheme_name (@scheme_names) {
        my $scheme = try_get_scheme( $scheme_name );
        next unless ref $scheme;
        my $names = $scheme->names_from_values( $values );
        next unless ref $names;
        push @names, @$names;
    }
    push @names, '' unless @names;
    @names = uniq( @names );
    return (defined $all_names and $all_names) ? @names : $names[0];
}

sub closest_from_values {
    my ($values, $scheme_name, $all_names, $full_name) = @_;
    # exact search first
    my @names = from_values( $values, $scheme_name, $all_names, $full_name );
    return ((@names == 1) ? $names[0] : \@names, 0)
        unless @names == 1 and $names[0] eq '';

    my @scheme_names = (ref $scheme_name eq 'ARRAY') ? (@$scheme_name)
                     : (defined $scheme_name)        ? $scheme_name : 'default';
    @names = ();
    my $distance = 'Inf';
    for my $scheme_name (@scheme_names) {
        my $scheme = try_get_scheme( $scheme_name );
        next unless ref $scheme;
        my ($names, $d) = $scheme->closest_names_from_values( $values );
        $d = round_decimals($d, 5);
        next unless ref $names;
        next unless $d <= $distance;
        $distance = $d;
        @names = ($distance == $d) ? (@names, @$names) : (@$names);
    }
    @names = uniq( @names );
    my $name = (defined $all_names and $all_names) ? \@names : $names[0];
    return ($name, $distance);
}

#### color scheme API ##################################################
# load default scheme on RUNTIME
my %color_scheme = (default => Graphics::Toolkit::Color::Name::Scheme->new());
my $default_names = require Graphics::Toolkit::Color::Name::Constant;
for my $color_block (@$default_names){
    $color_scheme{'default'}->add_color( $_, [ @{$color_block->{$_}}[0,1,2] ] ) for keys %$color_block;
}

sub try_get_scheme { # auto loader
    my $scheme_name = shift // 'default';
    unless (exists $color_scheme{ $scheme_name }){
        my $module_base = 'Graphics::ColorNames';
        # eval "use $module_base";
        # return "$module_base is not installed, but it's needed to load external color schemes!" if $@;
        my $module = $module_base.'::'.$scheme_name;
        eval "use $module";
        return "Perl module $module is not installed, but needed to load color scheme '$scheme_name'" if $@;
        my $palette = eval $module.'::NamesRgbTable();';
        return "Could not use Perl module $module , it seems to be damaged!" if $@ or ref $palette ne 'HASH';
        my $scheme = Graphics::Toolkit::Color::Name::Scheme->new();
        $scheme->add_color( $_, from_hex_to_rgb_tuple( $palette->{$_} ) ) for keys %$palette;
        add_scheme( $scheme, $scheme_name );
    }
    return $color_scheme{ $scheme_name };
}
sub add_scheme {
    my ($scheme, $scheme_name) = @_;
    return if ref $scheme ne 'Graphics::Toolkit::Color::Name::Scheme'
        or not defined $scheme_name or exists $color_scheme{ $scheme_name };
    $color_scheme{ $scheme_name } = $scheme;
}
my $rgb_max = 256;
sub from_hex_to_rgb_tuple {
    my $hex = shift;
    my $rg = int $hex / $rgb_max;
    return [ int $rg / $rgb_max, $rg % $rgb_max, $hex % $rgb_max];
}


1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Name - translate color names to values and vice versa

=head1 SYNOPSIS

    use Graphics::Toolkit::Color::Name;
    my @names = Graphics::Toolkit::Color::Name::all('HTML', 'default');
    my $values = Graphics::Toolkit::Color::Name::get_values('green');
    my $values = Graphics::Toolkit::Color::Name::get_values('green', [qw/SVG X/]);
    my $name = Graphics::Toolkit::Color::Name::from_values([0, 128, 0]);
    my $name = Graphics::Toolkit::Color::Name::from_values([0, 128, 0], 'HTML');
    my ($name, $distance) = Graphics::Toolkit::Color::Name::closest_from_values(
                                [0, 128, 0], [qw/CSS Pantone/], 'all');

    Graphics::Toolkit::Color::Name::add_scheme( $scheme, 'custom' );

=head1 DESCRIPTION

This modules stores a set of
L<color schemes|Graphics::Toolkit::Color::Name::Scheme>, where named
color constants are stored. There is a
L<default scheme|Graphics::Toolkit::Color::Name::Constant> and additional
ones, fed by L<Bundle::Graphics::ColorNames> modules, which have to be
installed separately. Wherever a method accepts a color scheme name,
you may also pass an ARRAY with several scheme names.


=head1 ROUTINES


=head2 all

Returns a list of color names constants of the default schema.
All arguments are interpreted as scheme names. If provided, the method
hows only the names from these schemes.

=head2 get_values

.. accepts two arguments. The first one is required and is a color name.
The result will be the RGB value tuple (ARRAY) of this color.

Optionally you may provide a second argument, which is a color scheme
name - if none is provided, the default scheme is used. Please note this
is the only routine in this lib where you can provide only one scheme.


=head2 from_values

This method works the other way around as the previous one. It takes am
RGB value tuple and returns a color name if possible. If no stored color
has the exact same values, an empty string is the result.

The search is limited to the default color scheme, unless a name of another
scheme or several of them in an ARRAY are provided as second argument.

If the provided values belong to several color names only the first one
is returned, which is in many cases the most popular. If you provide
the third positional argument with a positive  pseudo boolean, you will
get all found color names.


=head2 closest_from_values

this method gets the same parameter and works almost the same way,
as the previous method. The big difference: the search is not for an
exact match but the closest one (Euclidean distance). This way you are
guaranteed to get one or several names in return. These names have
to be delivered inside a ARRAY ref, because there is a second return value,
the distance between the provided values and the found color


=head1 SEE ALSO

L<Color::Library>

L<Graphics::ColorNamesLite::All>

=head1 COPYRIGHT & LICENSE

Copyright 2025 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>
