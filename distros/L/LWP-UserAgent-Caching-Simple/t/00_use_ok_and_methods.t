use Test::Most tests => 3;
use Test::MockObject;

subtest 'LWP::UserAgent::Caching::Simple' => sub {
    plan tests => 1;
    use_ok('LWP::UserAgent::Caching::Simple');
};

subtest 'Instantiating LWP::UserAgent::Caching::Simple object' => sub {
    plan tests => 1;
    
    my $ua_simple =
    new_ok('LWP::UserAgent::Caching::Simple', undef, 'my $ua_simple' );
    
};

subtest 'LWP::UserAgent::Caching::Simple request' => sub {
    plan tests => 6;
    
    my $ua_simple = eval { LWP::UserAgent::Caching::Simple->new };
    
    # all inherited
    can_ok($ua_simple, 'request');
    
    can_ok($ua_simple, 'get');
    can_ok($ua_simple, 'post');
    can_ok($ua_simple, 'head');
    can_ok($ua_simple, 'put');
    can_ok($ua_simple, 'delete');
    
};
