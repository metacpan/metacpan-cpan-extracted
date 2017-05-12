package Geo::DNA;

our $VERSION = "0.33";

use common::sense;

use Math::Trig qw( :pi rad2deg asin deg2rad );
use POSIX "fmod";

use Exporter 'import';

our @EXPORT_OK = qw(
    encode_geo_dna
    decode_geo_dna
    neighbours_geo_dna
    bounding_box_geo_dna
    neighbours_within_radius
);


my $RADIUS_OF_EARTH = 6378100;
my $ALPHABET = [ "g", "a", "t", "c", ];
my $DECODE_MAP = {
    'g' => 0,
    'a' => 1,
    't' => 2,
    'c' => 3,
};

sub _mod {
    my ( $x, $m ) = @_;
    return fmod( fmod( $x, $m ) + $m, $m);
}

sub encode_geo_dna {
    my ( @args ) = @_;
    encode( @args );
}

sub encode {
    my ( $latitude, $longitude, @opts ) = @_;
    my $options = { @opts };
    my $precision = $options->{precision} || 22;
    my $radians   = $options->{radians}   || 0;

    my $geodna = '';
    my ( $loni, $lati );

    if ( $radians ) {
        $latitude  = rad2deg( $latitude );
        $longitude = rad2deg( $longitude );
    }

    if ( $longitude < 0 ) {
        $geodna .= 'w';
        $loni = [ -180.0, 0.0 ];
    } else {
        $geodna .= 'e';
        $loni = [ 0.0, 180.0 ];
    }

    $lati = [ -90.0, 90.0 ];

    while ( length( $geodna ) < $precision ) {
        my $ch = 0;

        my $mid = ( $loni->[0] + $loni->[1] ) / 2;
        if ( $longitude > $mid ) {
            $ch |= 2;
            $loni = [ $mid, $loni->[1] ];
        } else {
            $loni = [ $loni->[0], $mid ];
        }

        $mid = ( $lati->[0] + $lati->[1] ) / 2;
        if ( $latitude > $mid ) {
            $ch |= 1;
            $lati = [ $mid, $lati->[1] ];
        } else {
            $lati = [ $lati->[0], $mid ];
        }

        $geodna .= $ALPHABET->[$ch];
    }
    return $geodna;
}

sub decode_geo_dna {
    my ( @args ) = @_;
    decode( @args );
}

sub decode {
    my ( $geodna, @opts ) = @_;
    my $options = { @opts };

    my ( $lati, $loni ) = bounding_box( $geodna );

    my $lat = ( $lati->[0] + $lati->[1] ) / 2;
    my $lon = ( $loni->[0] + $loni->[1] ) / 2;
    if ( $options->{radians} ) {
        return ( deg2rad( $lat ), deg2rad( $lon ) );
    }
    return ( $lat, $lon );
}

sub bounding_box_geo_dna {
    return bounding_box( @_ );
}

# locates the min/max lat/lons around the geo_dna
sub bounding_box {
    my ( $geodna ) = @_;

    my @chars = split( //, $geodna );

    my $loni;
    my $lati = [ -90.0, 90.0 ];
    my $first = shift @chars;

    if ( $first eq 'w' ) {
        $loni = [ -180.0, 0.0 ];
    } elsif ( $first eq 'e' ) {
        $loni = [ 0.0, 180.0 ];
    }

    foreach my $c (@chars) {
        my $cd = $DECODE_MAP->{$c};
        if ( $cd & 2 ) {
            $loni = [ ( $loni->[0] + $loni->[1] ) / 2, $loni->[1] ];
        } else {
            $loni = [ $loni->[0],  ( $loni->[0] + $loni->[1] ) / 2 ];
        }
        if ( $cd & 1 ) {
            $lati = [ ( $lati->[0] + $lati->[1] ) / 2, $lati->[1] ];
        } else {
            $lati = [ $lati->[0],  ( $lati->[0] + $lati->[1] ) / 2 ];
        }
    }
    return ( $lati, $loni );
}

sub add_vector {
    my ( $geodna, $dy, $dx ) = @_;
    my ( $lat, $lon ) = decode( $geodna );
    return (
        _mod( ( $lat + 90.0 + $dy ), 180.0 ) - 90.0,
        _mod( ( $lon + 180.0 + $dx ), 360.0 )  - 180.0
    );
}


sub normalise {
    my ( $lat, $lon ) = @_;
    return (
        _mod( ( $lat + 90.0 ), 180.0 ) - 90.0,
        _mod( ( $lon + 180.0 ), 360.0 ) - 180.0,
    );
}

# """
# Return the eight neighboring geodna codes

sub neighbours_geo_dna {
    my ( @args ) = @_;
    neighbours( @args );
}

sub neighbours {
    my ( $geodna ) = @_;

    # TODO:kd - this can be optimised
    my ( $lati, $loni ) = bounding_box( $geodna );
    my $width  = abs( $loni->[1] - $loni->[0] );
    my $height = abs( $lati->[1] - $lati->[0] );

    my $neighbours = [];
    foreach my $y ( -1, 0, 1 ) {
        foreach my $x ( -1, 0, 1 ) {
            next unless ( $x || $y );
            push (@$neighbours, encode( add_vector( $geodna, $height * $y, $width * $x ) ) );
        }
    }
    return $neighbours;
}

sub point_from_point_bearing_and_distance {
    my ( $geodna, $bearing, $distance, @opts ) = @_;
    my $options = { @opts };
    my $distance = $distance * 1000; # make it metres instead of kilometres
    my $precision = $options->{precision} || length( $geodna );
    my ( $lat1, $lon1 ) = decode( $geodna, radians => 1 );

    my $lat2 = asin( sin( $lat1 ) * cos( $distance / $RADIUS_OF_EARTH ) +
                     cos( $lat1 ) * sin( $distance / $RADIUS_OF_EARTH ) * cos( $bearing ) );
    my $lon2 = $lon1 + atan2( sin( $bearing ) * sin( $distance / $RADIUS_OF_EARTH ) * cos( $lat1 ),
                      cos( $distance / $RADIUS_OF_EARTH ) - sin( $lat1 ) * sin( $lat2 ));
    return encode( $lat2, $lon2, precision => $precision, radians => 1 );
}

sub distance_in_km {
    my ( $ga, $gb ) = @_;
    my ( $alat, $alon ) = decode( $ga );
    my ( $blat, $blon ) = decode( $gb );

    # if a[1] and b[1] have different signs, we need to translate
    # everything a bit in order for the formulae to work.
    if ( $alon * $blon < 0.0 && abs( $alon - $blon ) > 180.0 ) {
        ( $alat, $alon ) = add_vector( $ga, 0.0, 180.0 );
        ( $blat, $blon ) = add_vector( $gb, 0.0, 180.0 );
    }
    my $x = ( deg2rad( $blon ) - deg2rad( $alon ) ) * cos( ( deg2rad( $alat ) + deg2rad( $blat ) ) / 2 );
    my $y = ( deg2rad( $blat ) - deg2rad( $alat ) );
    my $d = sqrt( $x * $x + $y * $y ) * $RADIUS_OF_EARTH;
    return $d / 1000;
}

# This is experimental!!
# Totally unoptimised - use at your peril!
sub neighbours_within_radius {
    my ( $geodna, $radius, @opts) = @_;
    my $options = { @opts };
    $options->{precision} ||= 12;

    my $neighbours = [];
    my $rh = $radius * sqrt(2);

    my $start = point_from_point_bearing_and_distance( $geodna, -( pi / 4 ), $rh, %$options );
    my   $end = point_from_point_bearing_and_distance( $geodna, pi / 4, $rh, %$options );
    my ( $blat, $blon ) = bounding_box( $start );
    my ( $dummy, $slon ) = decode( $start );
    my ( $dummy, $elon ) = decode( $end );
    my $dheight = abs( $blat->[1] - $blat->[0] );
    my $dwidth  = abs( $blon->[1] - $blon->[0] );
    my ( $nlat, $nlon ) = normalise( 0.0, abs( $elon - $slon ) );
    my $delta = abs( $nlon );
    my $tlat = 0.0;
    my $tlon = 0.0;
    my $current = $start;

    while ( $tlat <= $delta ) {
        while ( $tlon <= $delta ) {
            my ( $clat, $clon ) = add_vector( $current, 0.0, $dwidth );
            $current = encode( $clat, $clon, %$options );
            my $d = distance_in_km( $current, $geodna );
            if ( $d <= $radius ) {
                push @$neighbours, $current;
            }
            $tlon = $tlon + $dwidth;
        }

        $tlat = $tlat + $dheight;
        my ( $rlat, $rlon ) = add_vector( $start, -$tlat , 0.0 );
        $current = encode( $rlat, $rlon, %$options );
        $tlon = 0.0;
    }
    return $neighbours;
}

# This takes an array of GeoDNA codes and reduces it to its
# minimal set of codes covering the same area.
# Needs a more optimal impl.
sub reduce {
    my ( $geodna_codes ) = @_;

    # hash all the codes
    my $codes = {};
    foreach my $code (@$geodna_codes) {
        $codes->{$code} = 1;
    }

    my $reduced = [];
    my $code;
    foreach my $code (@$geodna_codes) {
        if ( $codes->{$code} ) {
            my $parent = substr( $code, 0, length($code) - 1 );

            if ( $codes->{ $parent . 'a' }
              && $codes->{ $parent . 't' }
              && $codes->{ $parent . 'g' }
              && $codes->{ $parent . 'c' }) {
                  delete $codes->{ $parent . 'a' };
                  delete $codes->{ $parent . 't' };
                  delete $codes->{ $parent . 'g' };
                  delete $codes->{ $parent . 'c' };
                  push @$reduced, $parent;
            } else {
                push @$reduced, $code;
            }
        }
    }
    if ( scalar @$geodna_codes == scalar @$reduced ) {
        return $reduced;
    }
    return reduce( $reduced );
}

=head1 NAME

Geo::DNA - Encode latitude and longitude in a useful string format

=head1 SYNOPSIS

 use Geo::DNA qw( encode_geo_dna decode_geo_dna );

 my $geo = encode_geo_dna( -41.288889, 174.777222, precision => 22 );
 print "$geo\n"
 etctttagatagtgacagtcta

 my ( $lat, $lon ) = decode_geo_dna( $geo );
 print "$lat | $lon\n";
 -41.288889 | 174.777222

=head1 VERSION

    0.33


=head1 FEATURES

=over

=item * Simple API

Generally you just convert coordinates back and forth
with simple function calls.

=item * Fast

It's just basic space partitioning, really.



=back

=head1 DESCRIPTION

NEW: see an interactive demo of Geo::DNA codes at
http://www.geodna.org/docs/google-maps.html

This is a Perl version of the Python "geoprint" system that we developed
a few years back at Action Without Borders.

Its purpose is to encode a latitude/longitude pair in a string format that
can be used in text databases to locate items by proximity.  For example,
if Wellington, New Zealand has the Geo::DNA(10) value of

etctttagat

(which it does), then you can chop characters off the end of that to expand
the area around Wellington.  You can easily tell if items are close
together because (for the most part) their Geo::DNA will have the same
prefix.  For example, Palmerston North, New Zealand, has a Geo::DNA(10) code of

etctttaatc

which has the same initial 7 characters.

The original implementation of this in Python was by Michel Pelletier.

This uses a concept that is very similar to Gustavo Niemeyer's geohash
system ( http://geohash.org ), but encodes the latitude and longitude in a
way that is more conducive to stem-based searching (which is probably
the a common use of these hashing systems).


=head2 FUNCTIONS

=head3 C<encode_geo_dna>

 my $code = encode_geo_dna( latitude, longitude, options);

Returns a Geo::DNA code (which is a string) for latitude, longitude.
Possible options are:

=over

=item radians => true/false

A true value means the latitude and longitude are in radians.

=item precision => Integer (defaults to 22)

number of characters in the Geo::DNA code.
Note that any more than 22 chars and you're kinda splitting hairs.

=back

=head3 C<decode_geo_dna>

 my ( $lat, $lon ) = decode_geo_dna( code, options )

Returns the latitude and longitude encoded within a Geo::DNA code.

=over

=item radians => true/false

If true, the values returned will be in radians.

=back


=head3 C<neighbours_geo_dna>

 my $neighbours = neighbours_geo_dna( $code );

Returns an arrayref of the 8 Geo::DNA codes representing boxes of
equal size around the one represented by $code.  This is very useful
for proximity searching, because you can generate these Geo::DNA codes,
and then using only textual searching (eg. a SQL "LIKE" operator), you
can locate any items within any of those boxes.

The precision (ie. string length) of the Geo::DNA codes will be the same
as $code.


=head3 C<neighbours_within_radius>

 my $neighbours = neighbours_within_radius( code, radius, options );

Returns a raw list of GeoDNA codes of a certain size contained within the
radius (specified in kilometres) about the point represented by a
code.

The size of the returned codes will either be specified in options, or
will be the default (12).

=over

=item precision => N
    If this is present, the returned GeoDNA codes will have this size.

=back

=head3 C<reduce>

 my $neighbours = Geo::DNA::reduce( $neighbours )

Given an array of GeoDNA codes of arbitrary size (eg. as returned by
the "neighbours_within_radius" function), this will return the minimal set
of GeoDNA codes (of any sizes) that exactly cover the same area.  This is
important because it can massively reduce the number of comparisons you
have to do in order to perform stem-matching, *and* more crucially, if
you *don't* reduce the list, you *can't* perform stem matching.


=head3 C<bounding_box_geo_dna>

 my ( $lats, $lons ) = Geo::DNA::bounding_box_geo_dna( $code );

This returns an arrayref containing two arrayrefs:

 [ [ minimum latitude,  maximum latitude  ],
   [ minimum longitude, maximum longitude ],
 ]


=head1 TODO

=over

=item * Add conveniences to help you with prefix-based searching

At present you have to understand how this geometry works fairly well in
order to get the most out of this module.

=item * Bulletproofing

It's not particularly well-tested.  And there is the boundary-problem in that
two very close-by locations can have radically different Geo::DNA codes if
they are on different sides of a partition.  This is not a problem if you
use the neighbouring Geo::DNA codes of your reference point to do proximity
searching, but if you don't know how to do that, it will make life hard
for you.

=back


=head1 BUGS

Please report bugs relevant to C<GeoDNA> to E<lt>info[at]kyledawkins.comE<gt>.

=head1 CONTRIBUTING

The github repository is at git://github.com/quile/geodna-perl.git.


=head1 SEE ALSO

Some other stuff.

=head1 AUTHOR

Kyle Dawkins, E<lt>info[at]kyledawkins.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Kyle Dawkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
