
# translate named colors from X11, HTML (SVG) standard and Pantone report

package Graphics::Toolkit::Color::Name;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name::Scheme;
use Graphics::Toolkit::Color::Space::Hub;

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');

########################################################################
sub values {
    my $name = shift;
    my $colon_pos = index( $name, ':');
    if ($colon_pos > -1 ){                         # resolve scheme:name
        my $scheme_name = substr( $name, 0, $colon_pos );
        my $color_name = _clean_name( substr( $name, $colon_pos + 1 ) );
        return Graphics::Toolkit::Color::Name::Scheme::rgb_from_name( $scheme_name, $color_name );
    } else {
        return rgb_from_name( $name );
    }
}

my $constants = require Graphics::Toolkit::Color::Name::Constant; # store
our (@name_from_rgb, @name_from_hsl);       # search caches
_add_color_to_reverse_search( $_, @{$constants->{$_}} ) for all(); # (all color names)

sub all      { sort keys %$constants }
sub is_taken { (exists  $constants->{ _clean_name($_[0]) }) ? 1 : 0 }
sub rgb_from_name {
    my $name = _clean_name(shift);
    return [@{$constants->{$name}}[0..2]] if is_taken( $name );
}
sub hsl_from_name {
    my $name = _clean_name(shift);
    return [@{$constants->{$name}}[3..5]] if is_taken( $name );
}

########################################################################
sub name_from_rgb {
    my ($rgb) = @_;
    return '' unless ref $RGB->check_value_shape( $rgb );
    return '' unless exists $name_from_rgb[ $rgb->[0] ] and exists $name_from_rgb[ $rgb->[0] ][ $rgb->[1] ]
                 and exists $name_from_rgb[ $rgb->[0] ][ $rgb->[1] ][ $rgb->[2] ];
    my @names = ($name_from_rgb[ $rgb->[0] ][ $rgb->[1] ][ $rgb->[2] ]);
    @names = @{$names[0]} if ref $names[0];
    return wantarray ? @names : $names[0];
}
sub name_from_hsl {
    my ($hsl) = @_;
    return unless ref $HSL->check_value_shape( $hsl );
    return '' unless exists $name_from_hsl[ $hsl->[0] ] and exists $name_from_hsl[ $hsl->[0] ][ $hsl->[1] ]
                 and exists $name_from_hsl[ $hsl->[0] ][ $hsl->[1] ][ $hsl->[2] ];
    my @names = ($name_from_hsl[ $hsl->[0] ][ $hsl->[1] ][ $hsl->[2] ]);
    @names = @{$names[0]} if ref $names[0];
    return wantarray ? @names : $names[0];
}

sub names_in_rgb_range { # @center, (@d | $d) --> @names
    return if @_ != 2;
    my ($rgb_center, $radius) = @_;
    return unless ref $RGB->check_value_shape( $rgb_center ) and defined $radius;
    return unless (ref $radius eq 'ARRAY' and @$radius == 3) or not ref $radius;
    my %distance;
    my $border = (ref $radius) ? $radius : [$radius, $radius, $radius];
    my @min = map {$rgb_center->[$_] - $border->[$_]} 0 .. 2;
    my @max = map {$rgb_center->[$_] + $border->[$_]} 0 .. 2;
    for my $name (all()){
        my @rgb = @{$constants->{$name}}[0..2];
        next if $rgb[0] < $min[0]  or $rgb[0] > $max[0];
        my @delta = map { ($rgb[$_] - $rgb_center->[$_]) ** 2 } 0 .. 2;
        my $d = sqrt( $delta[0] + $delta[1] + $delta[2] );
        $distance{ $name } = $d if ref $radius or $d <= $radius;
    }
    my @names = sort { $distance{$a} <=> $distance{$b} || $a cmp $b } keys %distance;
    my @d = map {$distance{$_}} @names;
    return \@names, \@d;
}
sub names_in_hsl_range { # @center, (@d | $d) --> @names
    return if @_ != 2;
    my ($hsl_center, $radius) = @_;
    return unless ref $HSL->check_value_shape( $hsl_center ) and defined $radius;
    return unless (ref $radius eq 'ARRAY' and @$radius == 3) or not ref $radius;
    my %distance;
    my $border = (ref $radius) ? $radius : [$radius, $radius, $radius];
    my @min = map {$hsl_center->[$_] - $border->[$_]} 0 .. 2;
    my @max = map {$hsl_center->[$_] + $border->[$_]} 0 .. 2;
    my $ignore_hue_filter = $border->[0] >= 180;
    my $flip_hue_boundaries = ($min[0] < 0 or $max[0] > 360);
    $min[0] += 360 if $min[0] < 0;
    $max[0] -= 360 if $max[0] > 360;
    for my $name (all()){
        my @hsl = @{$constants->{$name}}[3..5];
        unless ($ignore_hue_filter){
            if ($flip_hue_boundaries) { next if $hsl[0] > $min[0] and $hsl[0] < $max[0] }
            else                      { next if $hsl[0] < $min[0]  or $hsl[0] > $max[0] }
        }
        next if $hsl[1] < $min[1] or $hsl[1] > $max[1];
        next if $hsl[2] < $min[2] or $hsl[2] > $max[2];
        my $h_delta = abs ($hsl[0] - $hsl_center->[0]);
        $h_delta = 360 - $h_delta if $h_delta > 180;
        my $d = sqrt( $h_delta**2 + ($hsl[1]-$hsl_center->[1])**2 + ($hsl[2]-$hsl_center->[2])**2 );
        $distance{ $name } = $d if ref $radius or $d <= $radius;
    }
    my @names = sort { $distance{$a} <=> $distance{$b} || $a cmp $b } keys %distance;
    my @d = map {$distance{$_}} @names;
    return \@names, \@d;
}

##### extend store #####################################################
sub add_rgb {
    my ($name, $rgb) = @_;
    return 'need a color name that is not already taken as first argument' unless defined $name and not is_taken( $name );
    return "second argument: RGB tuple is malformed or values are  out of range" unless ref $RGB->check_value_shape( $rgb );
    my $hsl = $HSL->denormalize( $HSL->convert_from( 'RGB', $RGB->normalize( $rgb ) ) );
    _add_color( $name, $RGB->round( $rgb ), $HSL->round( $hsl ) );
}
sub add_hsl {
    my ($name, $hsl) = @_;
    return 'need a color name that is not already taken as first argument' unless defined $name and not is_taken( $name );
    return "second argument: HSL tuple is malformed or values are  out of range" unless ref $HSL->check_value_shape( $hsl );
    my $rgb = $RGB->denormalize( $HSL->convert_to( 'RGB', $HSL->normalize( $hsl ) ) );
    _add_color( $name, $RGB->round( $rgb ), $HSL->round( $hsl ) );
}
sub _add_color {
    my ($name, $rgb, $hsl) = @_;
    $name = _clean_name( $name );
    return "there is already a color named '$name' in store of ".__PACKAGE__ if is_taken( $name );
    _add_color_to_reverse_search( $name, @$rgb, @$hsl);
    my $ret = $constants->{$name} = [@$rgb, @$hsl];    # add to foreward search
    return 0;
}

########################################################################
sub _clean_name {
    my $name = shift;
    $name =~ tr/_'//d;
    lc $name;
}

sub _add_color_to_reverse_search { #     my ($name, @rgb, @hsl) = @_;
    my $name = $_[0];
    my $cell = $name_from_rgb[ $_[1] ][ $_[2] ][ $_[3] ];
    if (defined $cell) {
        if (ref $cell) {
            if (length $name < length $cell->[0] ) { unshift @$cell, $name }
            else                                   { push @$cell, $name    }
        } else {
            $name_from_rgb[ $_[1] ][ $_[2] ][ $_[3] ] =
                (length $name < length $cell) ? [ $name, $cell ]
                                              : [ $cell, $name ] ;
        }
    } else { $name_from_rgb[ $_[1] ][ $_[2] ][ $_[3] ] = $name  }

    $cell = $name_from_hsl[ $_[4] ][ $_[5] ][ $_[6] ];
    if (defined $cell) {
        if (ref $cell) {
            if (length $name < length $cell->[0] ) { unshift @$cell, $name }
            else                                   { push @$cell, $name    }
        } else {
            $name_from_hsl[ $_[4] ][ $_[5] ][ $_[6] ] =
                (length $name < length $cell) ? [ $name, $cell ]
                                              : [ $cell, $name ] ;
        }
    } else { $name_from_hsl[ $_[4] ][ $_[5] ][ $_[6] ] = $name  }
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Name - access values of color constants

=head1 SYNOPSIS

    use Graphics::Toolkit::Color::Name qw/:all/;
    my @names = Graphics::Toolkit::Color::Name::all();
    my @rgb  = rgb_from_name('darkblue');
    my @hsl  = hsl_from_name('darkblue');

    Graphics::Toolkit::Color::Value::add_rgb('lucky', [0, 100, 50]);

=head1 DESCRIPTION

RGB and HSL values of named colors from the X11, HTML(CSS), SVG standard
and Pantone report. Allows also nearby search, reverse search and storage
(not permanent) of additional names. One color may have multiple names.
Own colors can be (none permanently) stored for later reference by name.
For this a name has to be chosen, that is not already taken. The
corresponding color may be defined by an RGB or HSL triplet.

No symbol is imported by default. The sub symbols: C<rgb_from_name>,
C<hsl_from_name>, C<name_from_rgb>, C<name_from_hsl> may be imported
individually or by:

    use Graphics::Toolkit::Color::Name qw/:all/;


=head1 ROUTINES

=head2 rgb_from_name

Red, Green and Blue value of the named color.
These values are integer in 0 .. 255.

    my @rgb = Graphics::Toolkit::Color::Name::rgb_from_name('darkblue');
    @rgb = Graphics::Toolkit::Color::Name::rgb_from_name('dark_blue'); # same result
    @rgb = Graphics::Toolkit::Color::Name::rgb_from_name('DarkBlue');  # still same

=head2 hsl_from_name

Hue, saturation and lightness of the named color.
These are integer between 0 .. 359 (hue) or 100 (sat. & light.).
A hue of 360 and 0 (degree in a cylindrical coordinate system) is
considered to be the same, this modul deals only with the ladder.

    my @hsl = Graphics::Toolkit::Color::Name::hsl_from_name('darkblue');

=head2 name_from_rgb

Returns name of color with given rgb value triplet.
Returns empty string if color is not stored. When several names define
given color, the shortest name will be selected in scalar context.
In array context all names are given.

    say Graphics::Toolkit::Color::Name::name_from_rgb( 15, 10, 121 );  # 'darkblue'
    say Graphics::Toolkit::Color::Name::name_from_rgb([15, 10, 121]);  # works too

=head2 name_from_hsl

Returns name of color with given hsl value triplet.
Returns empty string if color is not stored. When several names define
given color, the shortest name will be selected in scalar context.
In array context all names are given.

    say scalar Graphics::Toolkit::Color::Name::name_from_hsl( 0, 100, 50 );  # 'red'
    scalar Graphics::Toolkit::Color::Name::name_from_hsl([0, 100, 50]);  # works too
    say for Graphics::Toolkit::Color::Name::name_from_hsl( 0, 100, 50 ); # 'red', 'red1'

=head2  names_in_hsl_range

Color names in selected neighbourhood of hsl color space, that look similar.
It requires two arguments. The first one is an array containing three
values (hue, saturation and lightness), that define the center of the
neighbourhood (searched area).

The second argument can either be a number or again an array with
three values (h,s and l). If its just a number, it will be the radius r
of a ball, that defines the neighbourhood. From all colors inside that
ball, that are equal distanced or nearer to the center than r, one
name will returned.

If the second argument is an array, it has to contain the tolerance
(allowed distance) in h, s and l direction. Please note the h dimension
is circular: the distance from 355 to 0 is 5. The s and l dimensions are
linear, so that a center value of 90 and a tolerance of 15 will result
in a search of in the range 75 .. 100.

The results contains only one name per color (the shortest).

    # all bright red'ish clors
    my @names = Graphics::Toolkit::Color::Name::names_in_hsl_range([0, 90, 50], 5);
    # approximates to :
    my @names = Graphics::Toolkit::Color::Name::names_in_hsl_range([0, 90, 50],[ 3, 3, 3]);


=head2 all

A sorted list of all stored color names.

=head2 is_taken

Predicate method that return true if the color name (first and only,
required argument) is already in use.

=head2 add_rgb

Adding a color to the store under an not taken (not already used) name.
Arguments are name, red, green and blue value (integer < 256, see rgb).

    Graphics::Toolkit::Color::Name::add_rgb('nightblue',  15, 10, 121 );
    Graphics::Toolkit::Color::Name::add_rgb('nightblue', [15, 10, 121]);

=head2 add_hsl

Adding a color to the store under an not taken (not already used) name.
Arguments are name, hue, saturation and lightness value (see hsl).

    Graphics::Toolkit::Color::Name::add_rgb('lucky',  0, 100, 50 );
    Graphics::Toolkit::Color::Name::add_rgb('lucky', [0, 100, 50]);

=head1 SEE ALSO

L<Color::Library>

L<Graphics::ColorNamesLite::All>

=head1 COPYRIGHT & LICENSE

Copyright 2022-23 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>
