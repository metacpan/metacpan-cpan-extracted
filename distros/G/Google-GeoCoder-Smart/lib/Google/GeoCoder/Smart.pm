package Google::GeoCoder::Smart;

use strict;
use warnings;

use parent qw(Exporter);

use HTTP::Tiny ();
use JSON::PP qw(decode_json);
use URI::Escape qw(uri_escape_utf8);

our @EXPORT = qw(geocode parse);

our $VERSION = "v2.6.8";

=head1 NAME

Google::GeoCoder::Smart - Simple Google Geocoding API client

=head1 SYNOPSIS

  use Google::GeoCoder::Smart;

  my $geo = Google::GeoCoder::Smart->new(
    key => $ENV{GOOGLE_MAPS_API_KEY},
  );

  my $response = $geo->geocode_addr({
    address => '1600 Amphitheatre Parkway',
    city    => 'Mountain View',
    state   => 'CA',
    zip     => '94043',
  });

  die "Error: $response->{status}" if $response->{status} ne 'OK';

  my $best_match = $response->{results}[0];
  my $lat = $best_match->{geometry}{location}{lat};
  my $lng = $best_match->{geometry}{location}{lng};

=head1 DESCRIPTION

L<Google::GeoCoder::Smart|https://metacpan.org/pod/Google::GeoCoder::Smart> provides a lightweight wrapper around the Google Geocoding API
v3 endpoint:

  https://maps.googleapis.com/maps/api/geocode/json

It supports both structured addresses and place IDs, and returns decoded API
payloads with C<rawJSON> attached for debugging.

=head1 WHAT THIS MODULE DOES

=over 4

=item * Sends geocoding requests to C<https://maps.googleapis.com/maps/api/geocode/json>.

=item * Supports structured address parts, C<place_id>, and optional C<language>, C<region>, C<bounds>, and C<components>.

=item * Returns decoded API payloads with C<rawJSON> attached for debugging.

=back

=head1 INSTALLATION

  perl Makefile.PL
  make
  make test
  make install

=head1 DEPENDENCIES

Runtime dependencies are declared in C<Makefile.PL>:

=over 4

=item * C<HTTP::Tiny>

=item * C<JSON::PP>

=item * C<URI::Escape>

=back

=head1 TESTING

Run tests with:

  make test

=head1 METHODS

=head2 new

  my $geo = Google::GeoCoder::Smart->new(
    key    => 'your-api-key',
    host   => 'maps.googleapis.com', # optional
    scheme => 'https',               # optional
    timeout => 10,                   # optional
  );

=head2 C<geocode_addr>

  my $response = $geo->geocode_addr({
    address   => '1600 Amphitheatre Parkway',
    city      => 'Mountain View',
    state     => 'CA',
    zip       => '94043',
    language  => 'en',
    region    => 'us',
    place_id  => 'ChIJ2eUgeAK6j4ARbn5u_wAGqWA',
    components => {
      country => 'US',
    },
  });

Returns a hashref mirroring Google API JSON.

=head2 geocode

Deprecated compatibility wrapper for legacy return shape:

  my ($count, $status, @results_and_raw) = $geo->geocode(...);

=head1 AUTHOR

TTG, C<ttg@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.10.0 or, at your option,
any later version of Perl 5 you may have available.

=cut

sub new {
  my ($class, %params) = @_;

  my $self = {
    key     => $params{key},
    host    => $params{host}   || 'maps.googleapis.com',
    scheme  => $params{scheme} || $params{http} || 'https',
    timeout => $params{timeout} || 10,
  };

  return bless $self, $class;
}

sub geocode_addr {
  my ($self, $params) = @_;
  $params ||= {};

  my %query;

  if (defined $params->{place_id} && $params->{place_id} ne q{}) {
    $query{place_id} = $params->{place_id};
  } else {
    my @parts;
    for my $field (qw(address city state zip)) {
      next if !defined $params->{$field} || $params->{$field} eq q{};
      push @parts, $params->{$field};
    }

    my $address = join(', ', @parts);
    if ($address eq q{}) {
      return {
        status        => 'INVALID_REQUEST',
        error_message => 'address or place_id is required',
        results       => [],
      };
    }
    $query{address} = $address;
  }

  for my $field (qw(language region bounds)) {
    next if !defined $params->{$field} || $params->{$field} eq q{};
    $query{$field} = $params->{$field};
  }

  if (ref $params->{components} eq 'HASH') {
    my @components = map { "$_:$params->{components}{$_}" } sort keys %{ $params->{components} };
    $query{components} = join('|', @components) if @components;
  }

  $query{key} = $self->{key} if defined $self->{key} && $self->{key} ne q{};

  my $url = $self->_build_geocode_url(\%query);
  my ($content, $fetch_error) = $self->_fetch_content($url);

  if (!defined $content) {
    return {
      status        => 'CONNECTION_ERROR',
      error_message => $fetch_error || 'connection',
      results       => [],
    };
  }

  if ($content eq q{}) {
    return {
      status        => 'ERROR_GETTING_PAGE',
      error_message => 'empty response body',
      results       => [],
    };
  }

  my $decoded = eval { decode_json($content) };
  if ($@) {
    return {
      status        => 'INVALID_RESPONSE',
      error_message => "$@",
      results       => [],
      rawJSON       => $content,
    };
  }

  $decoded->{status}  ||= 'UNKNOWN_ERROR';
  $decoded->{results} ||= [];
  $decoded->{rawJSON} = $content;

  return $decoded;
}

sub geocode {
  my ($self, %params) = @_;

  my $addr_info = $self->geocode_addr({
    address => $params{address},
    city    => $params{city},
    state   => $params{state},
    zip     => $params{zip},
  });

  my $results_ref = $addr_info->{results} || [];
  my $count       = scalar @{$results_ref};

  return $count, $addr_info->{status}, @{$results_ref}, $addr_info->{rawJSON};
}

sub parse {
  my ($json_text) = @_;
  return decode_json($json_text);
}

sub _build_geocode_url {
  my ($self, $query_ref) = @_;

  my @pairs;
  for my $key (sort keys %{$query_ref}) {
    my $value = defined $query_ref->{$key} ? $query_ref->{$key} : q{};
    push @pairs, uri_escape_utf8($key) . q{=} . uri_escape_utf8($value);
  }

  return sprintf '%s://%s/maps/api/geocode/json?%s',
    $self->{scheme},
    $self->{host},
    join('&', @pairs);
}

sub _fetch_content {
  my ($self, $url) = @_;

  my $http = HTTP::Tiny->new(timeout => $self->{timeout});
  my $res  = $http->get($url);

  return ($res->{content}, undef) if $res->{success};
  return (undef, join(' ', grep { defined && $_ ne q{} } $res->{status}, $res->{reason}));
}

1;
