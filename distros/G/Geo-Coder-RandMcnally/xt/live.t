use strict;
use warnings;
use Encode;
use Geo::Coder::RandMcnally;
use Test::More;

my $debug = $ENV{GEO_CODER_RANDMCNALLY_DEBUG};
unless ($debug) {
    diag "Set GEO_CODER_RANDMCNALLY_DEBUG to see request/response data";
}

my $geocoder = Geo::Coder::RandMcnally->new(
    debug    => $debug,
    compress => 0,
);
{
    my $address = '9855 Woods Drive, Skokie, IL';
    my $location = $geocoder->geocode($address);
    like($location->{postalCode}, qr/^60077\b/, "correct ZIP for $address");
}

done_testing;
