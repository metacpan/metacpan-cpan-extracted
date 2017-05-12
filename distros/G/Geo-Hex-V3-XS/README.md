[![Build Status](https://travis-ci.org/karupanerura/Geo-Hex-V3-XS.svg?branch=master)](https://travis-ci.org/karupanerura/Geo-Hex-V3-XS)
# NAME

Geo::Hex::V3::XS - GeoHex implementation with XS. (c-geohex3 Perl5 binding.)

# SYNOPSIS

    use Geo::Hex::V3::XS;

    my $zone = Geo::Hex::V3::XS->new(code => 'XM488276746');

    # or

    my $zone = Geo::Hex::V3::XS->new(lat => 35.579826, lng => 139.654524, level => 9);

    # or

    my $zone = Geo::Hex::V3::XS->new(x => 11554, y => -3131, level => 7);

    say 'geohex.code:  ', $zone->code;
    say 'geohex.lat:   ', $zone->lat;
    say 'geohex.lng:   ', $zone->lng;
    say 'geohex.level: ', $zone->level;

# DESCRIPTION

Geo::Hex::V3::XS is [GeoHex](http://geohex.net/) implementation.

# FUNCTIONS

- `my $geohex_code = encode_geohex($lat, $lng, $level)`

    Convert location,level to geohex's code.

- `my ($lat, $lng, $code) = decode_geohex($geohex_code)`

    Convert geohex's code to location,level.
    This location is center of geohex.

- `my $size = geohex_hexsize($level)`

    Calculate geohex hex size by level.

# METHODS

- `my $zone = Geo::Hex::V3::XS->new(...)`

    Create geohex zone object.

    Arguments can be:

    - `code`

        Create geohex zone object from geohex code.

            use Geo::Hex::V3::XS;

            my $zone = Geo::Hex::V3::XS->new(code => 'XM488548');

    - `lat/lng/level`

        Create geohex zone object from location with level.

            use Geo::Hex::V3::XS;

            my $zone = Geo::Hex::V3::XS->new(
                lat   => 40.5814792855475,
                lng   => 134.296601127877,
                level => 7,
            );

    - `x/y/level`

        Create geohex zone object from coordinate with level.

            use Geo::Hex::V3::XS;

            my $zone = Geo::Hex::V3::XS->new(
                x     => 11554,
                y     => -3131,
                level => 7,
            );

- `$zone->lat`

    Get geohex center location latitude.

- `$zone->lng`

    Get geohex center location longitude.

- `$zone->x`

    Get geohex center x coordinate.

- `$zone->y`

    Get geohex center y coordinate.

- `$zone->code`

    Get geohex code.

- `$zone->level`

    Get geohex level. (0-15)

- `$zone->size`

    Get geohex size.

- `my @locations = $zone->polygon()`

    Get vertex locations of a geohex polygon.

# LICENSE

Copyright (C) 2015 karupanerura <karupa@cpan.org>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# ALGORITHM LICENSE

Copyright (c) 2009 @sa2da (http://twitter.com/sa2da)
http://www.geohex.org
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# AUTHOR

karupanerura <karupa@cpan.org>
