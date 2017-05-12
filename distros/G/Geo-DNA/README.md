# NAME

Geo::DNA - Encode latitude and longitude in a useful string format

# SYNOPSIS

    use Geo::DNA qw( encode_geo_dna decode_geo_dna );

    my $geo = encode_geo_dna( -41.288889, 174.777222, precision => 22 );
    print "$geo\n"
    etctttagatagtgacagtcta

    my ( $lat, $lon ) = decode_geo_dna( $geo );
    print "$lat | $lon\n";
    -41.288889 | 174.777222

# VERSION

    0.33



# FEATURES

- Simple API

Generally you just convert coordinates back and forth
with simple function calls.

- Fast

It's just basic space partitioning, really.





# DESCRIPTION

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



## FUNCTIONS

### `encode_geo_dna`

    my $code = encode_geo_dna( latitude, longitude, options);

Returns a Geo::DNA code (which is a string) for latitude, longitude.
Possible options are:

- radians => true/false

A true value means the latitude and longitude are in radians.

- precision => Integer (defaults to 22)

number of characters in the Geo::DNA code.
Note that any more than 22 chars and you're kinda splitting hairs.

### `decode_geo_dna`

    my ( $lat, $lon ) = decode_geo_dna( code, options )

Returns the latitude and longitude encoded within a Geo::DNA code.

- radians => true/false

If true, the values returned will be in radians.



### `neighbours_geo_dna`

    my $neighbours = neighbours_geo_dna( $code );

Returns an arrayref of the 8 Geo::DNA codes representing boxes of
equal size around the one represented by $code.  This is very useful
for proximity searching, because you can generate these Geo::DNA codes,
and then using only textual searching (eg. a SQL "LIKE" operator), you
can locate any items within any of those boxes.

The precision (ie. string length) of the Geo::DNA codes will be the same
as $code.



### `neighbours_within_radius`

    my $neighbours = neighbours_within_radius( code, radius, options );

Returns a raw list of GeoDNA codes of a certain size contained within the
radius (specified in kilometres) about the point represented by a
code.

The size of the returned codes will either be specified in options, or
will be the default (12).

- precision => N
    If this is present, the returned GeoDNA codes will have this size.

### `reduce`

    my $neighbours = Geo::DNA::reduce( $neighbours )

Given an array of GeoDNA codes of arbitrary size (eg. as returned by
the "neighbours_within_radius" function), this will return the minimal set
of GeoDNA codes (of any sizes) that exactly cover the same area.  This is
important because it can massively reduce the number of comparisons you
have to do in order to perform stem-matching, *and* more crucially, if
you *don't* reduce the list, you *can't* perform stem matching.



### `bounding_box_geo_dna`

    my ( $lats, $lons ) = Geo::DNA::bounding_box_geo_dna( $code );

This returns an arrayref containing two arrayrefs:

    [ [ minimum latitude,  maximum latitude  ],
      [ minimum longitude, maximum longitude ],
    ]



# TODO

- Add conveniences to help you with prefix-based searching

At present you have to understand how this geometry works fairly well in
order to get the most out of this module.

- Bulletproofing

It's not particularly well-tested.  And there is the boundary-problem in that
two very close-by locations can have radically different Geo::DNA codes if
they are on different sides of a partition.  This is not a problem if you
use the neighbouring Geo::DNA codes of your reference point to do proximity
searching, but if you don't know how to do that, it will make life hard
for you.



# BUGS

Please report bugs relevant to `GeoDNA` to <info[at]kyledawkins.com>.

# CONTRIBUTING

The github repository is at git://github.com/quile/geodna-perl.git.



# SEE ALSO

Some other stuff.

# AUTHOR

Kyle Dawkins, <info[at]kyledawkins.com>



# COPYRIGHT AND LICENSE

Copyright 2012 by Kyle Dawkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.