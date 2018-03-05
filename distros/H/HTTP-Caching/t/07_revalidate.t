use Test::Most tests => 2;
use Test::MockObject;

use HTTP::Caching::DeprecationWarning ':hide';
use HTTP::Caching;

$HTTP::Caching::DEBUG = 0; # so we get nice helpful messages back

use HTTP::Method;
use HTTP::Request;
use HTTP::Response;

# minimal HTTP::Messages
# - Request: HEAD
#   Method is understood,
#   Method is safe
#   Method is cachable
# - Response: 100 Continue
#   Status Code is understood
#   Status Code is not be default cachable
#   Will fall through
my $rqst_minimal = HTTP::Request->new('HEAD', 'http://localhost/');
my $resp_minimal = HTTP::Response->new(200);

# mock cache
my %cache;
my $mocked_cache = Test::MockObject->new;
$mocked_cache->mock( set => sub { $cache{$_[1]} = $_[2] } );
$mocked_cache->mock( get => sub { return $cache{$_[1]} } );

subtest 'Revalidate: use provided validators' => sub {
    
    plan tests => 4;
    
    my $test;
    
    my $forwarded_resp;
    my $forwarded_rqst;
    my $resp;
    
    my $http_caching = HTTP::Caching->new(
        cache                   => $mocked_cache,
        cache_type              => 'private',
        forwarder               => sub {
            $forwarded_rqst = shift;
            return $forwarded_resp
        }
    );
    
    # First make a request that will get a response to fill the cache
    # using a etag
    #
    
    my $rqst_etag = $rqst_minimal->clone;
    $rqst_etag->uri('http://localhost/etag');
    
    my $resp_etag = $resp_minimal->clone;
    $resp_etag->header(etag => '7a0629e5-373e-47a1-ba5a-c2da08053bcf');
    $resp_etag->content('Hello... ETag');
    
    $forwarded_resp = $resp_etag;
    
    # This will set $forwarded_rqst
    $http_caching->make_request($rqst_etag);
    
    # Unset it and make the request again
    $forwarded_rqst = undef;
    $resp = $http_caching->make_request($rqst_etag);
    
    is($forwarded_rqst->header('If-None-Match'),
        '7a0629e5-373e-47a1-ba5a-c2da08053bcf',
        'Made Conditional request with correct ETag');
    is($resp->content, 'Hello... ETag',
        '... and returns the response from cache');
    
    # Make a request that will get a response to fill the cache
    # using a last-modified
    #
    
    my $rqst_last = $rqst_minimal->clone;
    $rqst_last->uri('http://localhost/last');
    
    my $resp_last = $resp_minimal->clone;
    $resp_last->header(last_modified => 'Thu, 01 Jan 1970 01:01:00');
    $resp_last->content('Hello... Last-Modified');
    
    $forwarded_resp = $resp_last;
    
    # This will set $forwarded_rqst
    $http_caching->make_request($rqst_last);
    
    # Unset it and make the request again
    $forwarded_rqst = undef;
    $resp = $http_caching->make_request($rqst_last);
    
    is($forwarded_rqst->header('If-Modified-Since'),
        'Thu, 01 Jan 1970 01:01:00',
        'Made Conditional request with correct IF-Modified-Since');
    is($resp->content, 'Hello... Last-Modified',
        '... and returns the response from cache');
   
};


subtest 'Revalidate: use provided validators' => sub {
    
    plan tests => 1;
    
    my $test;
    
    my $forwarded_resp;
    my $forwarded_rqst;
    my $resp;
    
    my $http_caching = HTTP::Caching->new(
        cache                   => $mocked_cache,
        cache_type              => 'private',
        forwarder               => sub {
            $forwarded_rqst = shift;
            return $forwarded_resp
        }
    );
    
    # First make a request that will get a response to fill the cache
    # using a etag
    #
    
    my $rqst_both = $rqst_minimal->clone;
    $rqst_both->uri('http://localhost/both');
    
    my $resp_both = $resp_minimal->clone;
    $resp_both->header(etag => '7a0629e5-373e-47a1-ba5a-c2da08053bcf');
    $resp_both->header(last_modified => 'Thu, 01 Jan 1970 01:01:00');
    $resp_both->content('Hello... Both');
    
    $forwarded_resp = $resp_both;
    
    # This will set $forwarded_rqst
    $http_caching->make_request($rqst_both);
    
    
    
    my $resp_full = $resp_minimal->clone;
    $resp_full->content('Hello... Full');
    
    $forwarded_resp = $resp_full;
    
    # Unset it and make the request again
    $forwarded_rqst = undef;
    $resp = $http_caching->make_request($rqst_both);
    
    is($resp->content, 'Hello... Full',
        '... and returns the full response while validating');
    
}