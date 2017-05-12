package Geo::Coder::Google::V2;

use strict;
use warnings;
our $VERSION = '0.18';

use Carp;
use Encode;
use JSON;
use HTTP::Request;
use LWP::UserAgent;
use URI;

sub new {
    my($class, %param) = @_;

    my $ua       = delete $param{ua}       || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
    my $host     = delete $param{host}     || 'maps.google.com';
    my $language = delete $param{language};
    my $gl       = delete $param{gl};
    my $oe       = delete $param{oe}       || 'utf8';

    bless { ua => $ua, host => $host, language => $language, gl => $gl, oe => $oe }, $class;
}

sub ua {
    my $self = shift;
    if (@_) {
        $self->{ua} = shift;
    }
    $self->{ua};
}

sub geocode {
    my $self = shift;

    my %param;
    if (@_ % 2 == 0) {
        %param = @_;
    } else {
        $param{location} = shift;
    }

    my $location = $param{location}
        or Carp::croak("Usage: geocode(location => \$location)");

    if (Encode::is_utf8($location)) {
        $location = Encode::encode_utf8($location);
    }

    my $uri = URI->new("http://$self->{host}/maps/geo");
    my %query_parameters = (q => $location, output => 'json');
    $query_parameters{hl} = $self->{language} if defined $self->{language};
    $query_parameters{gl} = $self->{gl} if defined $self->{gl};
    $query_parameters{oe} = $self->{oe};
    $uri->query_form(%query_parameters);

    my $res = $self->{ua}->get($uri);

    if ($res->is_error) {
        Carp::croak("Google Maps API returned error: " . $res->status_line);
    }

    my $json = JSON->new->utf8;
    my $data = $json->decode($res->content);

    my @placemark = @{ $data->{Placemark} || [] };
    wantarray ? @placemark : $placemark[0];
}

1;
__END__

=head1 NAME

Geo::Coder::Google::V2 - Google Maps Geocoding API V2

=head1 SYNOPSIS

  use Geo::Coder::Google;

  my $geocoder = Geo::Coder::Google->new();
  my $location = $geocoder->geocode( location => 'Hollywood and Highland, Los Angeles, CA' );

=head1 DESCRIPTION

Geo::Coder::Google::V2 provides a geocoding functionality using Google Maps API V2.

B<Note: Google no longer supports the V2 API. There are no longer any V2 servers to
connect to. Any attempt to use the V2 API will fail.>

=head1 METHODS

=over 4

=item new

  $geocoder = Geo::Coder::Google->new();
  $geocoder = Geo::Coder::Google->new(host => 'maps.google.co.jp');
  $geocoder = Geo::Coder::Google->new(language => 'ru');
  $geocoder = Geo::Coder::Google->new(gl => 'ca');
  $geocoder = Geo::Coder::Google->new(oe => 'latin1');

Creates a new geocoding object.

When you'd like to query Japanese address, you might want to set
I<host> parameter, which should point to I<maps.google.co.jp>. I think
this also applies to other countries like UK (maps.google.co.uk), but
so far I only tested with I<.com> and I<.co.jp>.

To specify the language of Google's response add C<language> parameter
with a two-letter value. Note that adding that parameter does not
guarantee that every request returns translated data.

You can also set C<gl> parameter to set country code (e.g. I<ca> for Canada).

You can ask for a character encoding other than utf-8 by setting the I<oe>
parameter, but this is not recommended.

=item geocode

  $location = $geocoder->geocode(location => $location);
  @location = $geocoder->geocode(location => $location);

Queries I<$location> to Google Maps geocoding API and returns hash
reference returned back from API server. When you cann the method in
an array context, it returns all the candidates got back, while it
returns the 1st one in a scalar context.

When you'd like to pass non-ascii string as a location, you should
pass it as either UTF-8 bytes or Unicode flagged string.

Returned data structure is as follows:

  {
    'AddressDetails' => {
      'Country' => {
        'AdministrativeArea' => {
          'SubAdministrativeArea' => {
            'SubAdministrativeAreaName' => 'San Francisco',
            'Locality' => {
              'PostalCode' => {
                'PostalCodeNumber' => '94107'
              },
              'LocalityName' => 'San Francisco',
              'Thoroughfare' => {
                'ThoroughfareName' => '548 4th St'
              }
            }
          },
          'AdministrativeAreaName' => 'CA'
        },
        'CountryNameCode' => 'US'
      }
    },
    'address' => '548 4th St, San Francisco, CA 94107, USA',
    'Point' => {
      'coordinates' => [
        '-122.397323',
        '37.778993',
        0
      ]
    }
  }

=item ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

  $coder->ua->env_proxy;

You can also set your own User-Agent object:

  $coder->ua( LWPx::ParanoidAgent->new );

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Geo::Coder::Yahoo>, L<http://www.google.com/apis/maps/documentation/#Geocoding_Examples>

List of supported languages: L<http://spreadsheets.google.com/pub?key=p9pdwsai2hDMsLkXsoM05KQ&gid=1>

=cut
