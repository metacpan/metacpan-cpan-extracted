use Test::Most tests => 1;

use HTTP::Caching::DeprecationWarning ':hide';
use HTTP::Caching;

use HTTP::Request;
use HTTP::Response;

subtest 'Simple modifiactions' => sub {
    plan tests => 6;
    
    
    my $request = HTTP::Request->new();
    $request->method('TEST');
    my $response;
    
    my $forwarded_resp = HTTP::Response->new(501);
    my $forwarded_rqst;

    my $http_caching_undefs =
        new_ok('HTTP::Caching', [
            cache                   => undef, # no cache needed for these tests
            cache_type              => undef,
            cache_control_request   => undef,
            cache_control_response  => undef,
            forwarder               => sub { },
        ] , 'my $http_caching_undefs'
    );
    
    my $http_caching =
        new_ok('HTTP::Caching', [
            cache                   => undef, # no cache needed for these tests
            cache_type              => 'private',
            cache_control_request   => 'min-fresh=60',
            cache_control_response  => 'must-revalidate',
            forwarder               => sub {
                $forwarded_rqst = shift;
                return $forwarded_resp->clone;
            },
        ] , 'my $http_caching'
    );
    
    $response = $http_caching->make_request($request);
    
    is($forwarded_rqst->header('cache-control'), 'min-fresh=60',
        "modified request");
    
    is($response->header('cache-control'), 'must-revalidate',
        "modified response");
    
    # add some pre set cache-control directives
    $request->headers->push_header( cache_control => 'max-age=3600');
    $forwarded_resp->headers->push_header( cache_control => 'no-store');
    
    $response = $http_caching->make_request($request);
    
    is($forwarded_rqst->header('cache-control'), 'max-age=3600, min-fresh=60',
        "modified request with existing directives");
    
    is($response->header('cache-control'), 'no-store, must-revalidate',
        "modified response with existing directives");
    
}