package Geo::Hex::V3::XS;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.11";
use Exporter 5.57 qw/import/;
our @EXPORT_OK = qw/encode_geohex decode_geohex geohex_hexsize/;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub new {
    my ($class, %args) = @_;
    if (exists $args{code}) {
        return $class->_new_with_code($args{code}) || die "invalid code: $args{code}";
    }
    elsif (exists $args{lat} and exists $args{lng} and exists $args{level}) {
        return $class->_new_with_latlng(@args{qw/lat lng level/});
    }
    elsif (exists $args{x} and exists $args{y} and exists $args{level}) {
        return $class->_new_with_xy(@args{qw/x y level/});
    }
    else {
        die "Usage: $class->new(code => \$geohex_code) or $class->new(lat => \$lat, lng => \$lng, lng => \$level) or $class->new(x => \$x, y => \$y, lng => \$level)";
    }
}

1;
__END__

=for stopwords c-geohex3 geohex geohex's

=encoding utf-8

=head1 NAME

Geo::Hex::V3::XS - GeoHex implementation with XS. (c-geohex3 Perl5 binding.)

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Geo::Hex::V3::XS is L<GeoHex|http://geohex.net/> implementation.

=head1 FUNCTIONS

=over

=item C<my $geohex_code = encode_geohex($lat, $lng, $level)>

Convert location,level to geohex's code.

=item C<my ($lat, $lng, $code) = decode_geohex($geohex_code)>

Convert geohex's code to location,level.
This location is center of geohex.

=item C<my $size = geohex_hexsize($level)>

Calculate geohex hex size by level.

=back

=head1 METHODS

=over

=item C<my $zone = Geo::Hex::V3::XS-E<gt>new(...)>

Create geohex zone object.

Arguments can be:

=over

=item * C<code>

Create geohex zone object from geohex code.

    use Geo::Hex::V3::XS;

    my $zone = Geo::Hex::V3::XS->new(code => 'XM488548');

=item * C<lat/lng/level>

Create geohex zone object from location with level.

    use Geo::Hex::V3::XS;

    my $zone = Geo::Hex::V3::XS->new(
        lat   => 40.5814792855475,
        lng   => 134.296601127877,
        level => 7,
    );

=item * C<x/y/level>

Create geohex zone object from coordinate with level.

    use Geo::Hex::V3::XS;

    my $zone = Geo::Hex::V3::XS->new(
        x     => 11554,
        y     => -3131,
        level => 7,
    );

=back

=item C<$zone-E<gt>lat>

Get geohex center location latitude.

=item C<$zone-E<gt>lng>

Get geohex center location longitude.

=item C<$zone-E<gt>x>

Get geohex center x coordinate.

=item C<$zone-E<gt>y>

Get geohex center y coordinate.

=item C<$zone-E<gt>code>

Get geohex code.

=item C<$zone-E<gt>level>

Get geohex level. (0-15)

=item C<$zone-E<gt>size>

Get geohex size.

=item C<my @locations = $zone-E<gt>polygon()>

Get vertex locations of a geohex polygon.

=back

=head1 LICENSE

Copyright (C) 2015 karupanerura <karupa@cpan.org>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 ALGORITHM LICENSE

Copyright (c) 2009 @sa2da (http://twitter.com/sa2da)
http://www.geohex.org
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

