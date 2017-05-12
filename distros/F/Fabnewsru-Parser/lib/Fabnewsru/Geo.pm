package Fabnewsru::Geo;
$Fabnewsru::Geo::VERSION = '0.01';
# ABSTRACT: Functions for make geocoding


use warnings;
# use Devel::Peek;

use Exporter qw(import);
our @EXPORT_OK = qw(yandex_geocoder);




sub yandex_geocoder {
	my $address = shift;
	utf8::decode($address);   # set UTF8 flag if address string is cyrillic (need for correct Mojo::Dom working)
	# Dump $address;
	my $base_url='https://geocode-maps.yandex.ru/1.x/?format=json&geocode=';
	my $ua = Mojo::UserAgent->new;
	my $longlat = $ua->get($base_url . $address)->res->json->{response}->{GeoObjectCollection}->{featureMember}->[0]->{GeoObject}->{Point}->{pos};
	return $longlat;  # longitude, latitude
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Fabnewsru::Geo - Functions for make geocoding

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Fabnewsru::Geo qw(yandex_geocoder);
    my $longlat = yandex_geocoder('Россия, Заречный (Пензенская обл.), ул. Конституции СССР, д.39А'); # '45.16511 53.199109'

=head1 METHODS

=head2 yandex_geocoder

Make geocoding via Yandex Maps API (get longitude, latitude by specified address)

For documentation take a look at  https://tech.yandex.ru/maps/geocoder/

Free limit is 25000 queries per day, if limit was reached there will be HTTP 429 code

Will return string like '45.16511 53.199109', order is longlat (longitude, latitude)

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
