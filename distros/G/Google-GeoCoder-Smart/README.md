# NAME

Google::GeoCoder::Smart - Simple Google Geocoding API client

# SYNOPSIS

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

# DESCRIPTION

[Google::GeoCoder::Smart](https://metacpan.org/pod/Google::GeoCoder::Smart) provides a lightweight wrapper around the Google Geocoding API
v3 endpoint:

    https://maps.googleapis.com/maps/api/geocode/json

It supports both structured addresses and place IDs, and returns decoded API
payloads with `rawJSON` attached for debugging.

# WHAT THIS MODULE DOES

- Sends geocoding requests to `https://maps.googleapis.com/maps/api/geocode/json`.
- Supports structured address parts, `place_id`, and optional `language`, `region`, `bounds`, and `components`.
- Returns decoded API payloads with `rawJSON` attached for debugging.

# INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

# DEPENDENCIES

Runtime dependencies are declared in `Makefile.PL`:

- `HTTP::Tiny`
- `JSON::PP`
- `URI::Escape`

# TESTING

Run tests with:

    make test

# METHODS

## new

    my $geo = Google::GeoCoder::Smart->new(
      key    => 'your-api-key',
      host   => 'maps.googleapis.com', # optional
      scheme => 'https',               # optional
      timeout => 10,                   # optional
    );

## `geocode_addr`

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

## geocode

Deprecated compatibility wrapper for legacy return shape:

    my ($count, $status, @results_and_raw) = $geo->geocode(...);

# AUTHOR

TTG, `ttg@cpan.org`

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.10.0 or, at your option,
any later version of Perl 5 you may have available.
