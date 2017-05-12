use Test::Most tests => 1;
use Test::MockObject;

use Carp;

use HTTP::Caching;

use HTTP::Request;
use HTTP::Response;

use Readonly;

# Although it does look like a proper URI, no, the file does not need to exist.
Readonly my $URI_LOCATION   => 'file:///tmp/HTTP_Cacing/greetings.txt';
Readonly my $URI_MD5        => '7d3d0fc115036f144964caafaf2c7df2';
Readonly my $CONTENT_KEY    => '3e5f1b953da8430c6f88b90ac15d78fa'; # or whatever

my $rqst_minimal = HTTP::Request->new('HEAD');
my $resp_minimal = HTTP::Response->new(100);
$resp_minimal->header(cache_control => 'max-age=10');

# mock cache
my %cache;
my $mocked_cache = Test::MockObject->new;
$mocked_cache->mock( set => sub { } );
$mocked_cache->mock( get => sub { return $cache{$_[1]} } );

my $rqst_normal = $rqst_minimal->clone;
$rqst_normal->uri($URI_LOCATION);
$rqst_normal->content('knock knock ...');

my $expected_resp = HTTP::Response->new(501);
$expected_resp->content('Who is there?');
$expected_resp->header(cache_control => 'max-age=10');

# populate the cache, we could try mocking CHI, but I'm to lazy for that
$cache{$CONTENT_KEY} = $expected_resp;
$cache{$URI_MD5} = {
    $CONTENT_KEY => {
        resp_stripped => $expected_resp,
        rqst_stripped => $rqst_normal,
    }
};

my $http_caching = HTTP::Caching->new(
    cache                   => $mocked_cache,
    cache_type              => 'private',
    forwarder               => sub { "we shouldn't be here!" }
);

my $response = $http_caching->make_request($rqst_normal);

is ( $response->content(), 'Who is there?',
    "Got the expected response back");
