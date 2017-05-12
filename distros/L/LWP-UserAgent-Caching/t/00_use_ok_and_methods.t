use Test::Most tests => 3;
use Test::MockObject;

subtest 'LWP::UserAgent::Caching' => sub {
    plan tests => 1;
    use_ok('LWP::UserAgent::Caching');
};


# mock cache
my %cache;
my $mocked_cache = Test::MockObject->new;
$mocked_cache->mock( set => sub { } );
$mocked_cache->mock( get => sub { } );

subtest 'Instantiating LWP::UserAgent::Caching object' => sub {
    plan tests => 1;
    
    my $ua_caching =
    new_ok('LWP::UserAgent::Caching', [
            http_caching => {
                cache                   => $mocked_cache,
                request_directives      => 'max-age=3600',
            }
        ] , 'my $ua_caching'
    );
    
};

subtest 'LWP::UserAgent::Caching request' => sub {
    plan tests => 6;
    
    my $ua_caching = eval {
        LWP::UserAgent::Caching->new(
            http_caching => {
                cache                   => $mocked_cache,
                request_directives      => 'max-age=3600',
            }
        )
    };
    
    can_ok($ua_caching, 'request');
    
    can_ok($ua_caching, 'get');
    can_ok($ua_caching, 'post');
    can_ok($ua_caching, 'head');
    can_ok($ua_caching, 'put');
    can_ok($ua_caching, 'delete');
    
};
