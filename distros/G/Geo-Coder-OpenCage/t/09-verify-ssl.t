use strict;
use warnings;

use Test::More;
use HTTP::Tiny;

use lib './lib'; # actually use the module, not other versions installed
use Geo::Coder::OpenCage;

# The default UA must verify TLS certificates
{
    my $geocoder = Geo::Coder::OpenCage->new(api_key => 'dummy');
    ok($geocoder->ua->verify_SSL, 'default UA verifies TLS certificates');
}

{
    local $ENV{PERL_HTTP_TINY_SSL_INSECURE_BY_DEFAULT} = 1;
    my $geocoder = Geo::Coder::OpenCage->new(api_key => 'dummy');
    ok($geocoder->ua->verify_SSL,
        'default UA verifies TLS certificates even with PERL_HTTP_TINY_SSL_INSECURE_BY_DEFAULT=1');
}

# Providing your own UA allows to overwrite the verify_SSL
{
    my $ua       = HTTP::Tiny->new(verify_SSL => 0);
    my $geocoder = Geo::Coder::OpenCage->new(api_key => 'dummy', ua => $ua);
    ok(!$geocoder->ua->verify_SSL, 'caller-supplied UA keeps its own verify_SSL setting');
}

done_testing();
