use Test::Most tests => 4;
use Test::MockObject;

use HTTP::Caching::DeprecationWarning ':hide';
use HTTP::Caching;

use HTTP::Request;
use HTTP::Response;

use Readonly;

# Although it does look like a proper URI, no, the file does not need to exist.
Readonly my $URI_LOCATION   => 'file:///tmp/HTTP_Cacing/greetings.txt';
Readonly my $URI_MD5        => '7d3d0fc115036f144964caafaf2c7df2';

my $rqst_minimal = HTTP::Request->new('HEAD');
my $resp_minimal = HTTP::Response->new(100);
$resp_minimal->header(cache_control => 'max-age=1');

# mock cache
my %cache;
my $mocked_cache = Test::MockObject->new;
$mocked_cache->mock( set => sub { $cache{$_[1]} = $_[2] } );
$mocked_cache->mock( get => sub { return $cache{$_[1]} } );

my $rqst_normal = $rqst_minimal->clone;
$rqst_normal->uri($URI_LOCATION);
$rqst_normal->content('knock knock ...');

# 501 Not Implemented is a 'by default' cachable response
my $resp_normal = $resp_minimal->clone;
$resp_normal->code(501);
$resp_normal->content('Who is there?');

my $forwarded_rqst = undef; # flag to be set if we do forward the request
my $forwarded_resp = $resp_normal;

my $http_caching = HTTP::Caching->new(
    cache                   => $mocked_cache,
    cache_type              => 'private',
    forwarder               => sub {
        $forwarded_rqst = shift;
        return $forwarded_resp
    }
);

my $response_one = $http_caching->make_request($rqst_normal);
is ($forwarded_rqst->content(), 'knock knock ...',
    "Request has been forwarded");
is ($response_one->content(), 'Who is there?',
    "... and response one is as expected" );

$forwarded_rqst = undef;

my $response_two = $http_caching->make_request($rqst_normal);
is ($forwarded_rqst, undef,
    "Request has not been forwarded for the second time");
is ($response_two->content(), 'Who is there?',
    "... and response two is as expected" );

