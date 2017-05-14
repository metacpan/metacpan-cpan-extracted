# ABSTRACT: provides perl API to Forecast.io
package Forecast::IO;
use strict;
use warnings;
use JSON;
use HTTP::Tiny;
use Moo;

my $api   = "https://api.forecast.io/forecast";
my $docs  = "https://developer.forecast.io/docs/v2";
my %units = (
    si   => 1,
    us   => 1,
    auto => 1,
    ca   => 1,
    uk   => 1,
);

has key => ( is => 'ro' );
has units => (
    is    => 'ro',
    'isa' => sub {
        die "Invalid units specified: see $docs\n"
          unless exists( $units{ $_[0] } );
    },
    'default' => 'auto',
);

has latitude  => ( is => 'ro' );
has longitude => ( is => 'ro' );
has 'time'    => ( is => 'ro', default => '' );
has timezone  => ( is => 'ro' );
has offset    => ( is => 'ro' );
has currently => ( is => 'ro' );
has minutely  => ( is => 'ro' );
has hourly    => ( is => 'ro' );
has daily     => ( is => 'ro' );
has alerts    => ( is => 'ro' );
has flags     => ( is => 'ro' );

sub BUILDARGS {
    my ( $class, %args ) = @_;

    my $url = "";
    my @params;
    if ( exists( $args{time} ) && $args{time} ne '' ) {
        @params = ( $args{latitude}, $args{longitude}, $args{time} );
    }
    else {
        @params = ( $args{latitude}, $args{longitude} );
    }

    my $params = join( ',', @params );

    if ( exists( $args{units} ) ) {
        $url =
          $api . '/' . $args{key} . '/' . $params . "?units=" . $args{units};
    }
    else {
        $url = $api . '/' . $args{key} . '/' . $params . "?units=auto";
    }

    my $response = HTTP::Tiny->new->get($url);

    die "Request to '$url' failed: $response->{status} $response->{reason}\n"
      unless $response->{success};

    my $forecast = decode_json( $response->{content} );

    while ( my ( $key, $val ) = each %args ) {
        unless ( exists( $forecast->{$key} ) ) {
            $forecast->{$key} = $val;
        }
    }
    return $forecast;
}

1;
=pod

=encoding utf-8

=head1 NAME

Forecast::IO - Provides Perl API to Forecast.io

=head1 SYNOPSIS

    use 5.016;
    use Forecast::IO;
    use Data::Dumper;

    my $lat  = 43.6667;
    my $long = -79.4167;
    my $key = "c9ce1c59d139c3dc62961cbd63097d13"; # example Forecast.io API key

    my $forecast = Forecast::IO->new(
        key       => $key,
        longitude => $long,
        latitude  => $lat,
    );

    say "current temperature: " . $forecast->{currently}->{temperature};

    my @daily_data_points = @{ $forecast->{daily}->{data} };

    # Use your imagination about how to use this data.
    # in the meantime, inspect it by dumping it.
    for (@daily_data_points) {
        print Dumper($_);
    }

=head1 DESCRIPTION

This module is a wrapper around the Forecast.io API.

=head1 REFERENCES

Git repository: L<https://github.com/mlbright/Forecast-IO>

Forecast.io API docs: L<https://developer.forecast.io/docs/v2>

=head1 COPYRIGHT

Copyright (c) 2013 L</AUTHOR>

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
