#!perl

# test basic usage, no callbacks, in record mode

BEGIN {
    $ENV{ LWP_UA_MOCK } = 'record';
    $ENV{ LWP_UA_MOCK_FILE } = 'basic.mockdata';
}

use strict;
use warnings;

use Test::More;
use Test::RequiresInternet;

use LWP;
use LWP::UserAgent::Mockable;

my $ua = LWP::UserAgent->new;
is( ref $ua, 'LWP::UserAgent', 'mocked LWP::UA is still a LWP::UA' );

$ua->env_proxy;

my $get = $ua->get( "http://www.google.com" );
is( ref $get, 'HTTP::Response', 'and responses from requests are as per LWP::UA' );
ok( defined $get->code, "...which respond to LWP methods in an expected manner" );

my @methods = qw(
    code
    protocol
    as_string
);

foreach my $method ( @methods ) {
    ok ( defined $get->$method, "$method method returns expected value" );
}

# not doing much with this, just here so that can ensure that multiple
# requests work, and that can support methods other than get.
my $post = $ua->post( "http://www.google.com" );
is( ref $post, "HTTP::Response", 'post returns an HTTP::Response object' );

END {
    LWP::UserAgent::Mockable->finished;
}

done_testing();
