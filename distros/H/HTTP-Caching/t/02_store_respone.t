use Test::Most tests => 1;
use Test::MockObject;

use HTTP::Caching;

use HTTP::Request;
use HTTP::Response;

use Readonly;

# Although it does look like a proper URI, no, the file does not need to exist.
Readonly my $URI_LOCATION  => 'file:///tmp/HTTP_Cacing/greetings.txt';
Readonly my $URI_MD5       => '7d3d0fc115036f144964caafaf2c7df2';

my $rqst_minimal = HTTP::Request->new('HEAD');
my $resp_minimal = HTTP::Response->new(100);

# mock cache
my %cache;
my $mocked_cache = Test::MockObject->new;
$mocked_cache->mock( set => sub { $cache{$_[1]} = $_[2] } );
$mocked_cache->mock( get => sub { } );

subtest "Simple Storing" => sub {
    
    plan tests => 5;
    
    my $rqst_normal = $rqst_minimal->clone;
    $rqst_normal->uri($URI_LOCATION);
    $rqst_normal->content('knock knock ...');
    
    my $resp_normal = $resp_minimal->clone;
    $resp_normal->code(200); # OK
    $resp_normal->content('Who is there?');

    my $resp_forwarded = $resp_normal->clone;
    
    my $http_caching = HTTP::Caching->new(
        cache                   => $mocked_cache,
        cache_type              => undef,
        forwarder               => sub { return $resp_forwarded }
    );
    
    # don't care about responses, we only want to store in the cache
    $http_caching->make_request($rqst_normal);
    
    is (keys %cache, 2,
        'there are 2 items in the cache');
    
    ok (exists $cache{$URI_MD5}, 
        'stored under the right key');
    
    my @meta_keys = keys %{$cache{$URI_MD5}};
    
    isa_ok ($cache{$meta_keys[0]}, 'HTTP::Response',
        '... a HTTP::Request object');
    
    is ($cache{$meta_keys[0]}->content, 'Who is there?',
        '... with the right content');
    
    $http_caching->make_request($rqst_normal);

    is (keys %cache, 3,
        'we store every response that _may_store_in_cache');
    
};
