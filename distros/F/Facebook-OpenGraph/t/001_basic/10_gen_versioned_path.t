use strict;
use warnings;
use Test::More;
use Test::Exception;
use Facebook::OpenGraph;

subtest 'version is set on initialization' => sub {
    my $fb = Facebook::OpenGraph->new(+{
        version => 'v2.0',
    });

    is($fb->gen_versioned_path('/me/friends'), '/v2.0/me/friends');    

    is(
        $fb->gen_versioned_path('/v1.0/me/friends'),
        '/v1.0/me/friends',
        'version is explicitly given in the path',
    );

    is($fb->gen_versioned_path('/'), '/v2.0/');
    is($fb->gen_versioned_path(''), '/v2.0/');
    is($fb->gen_versioned_path(), '/v2.0/');
    is($fb->gen_versioned_path('/v1.0/'), '/v1.0/');
};

subtest 'default version is not set on initialization' => sub {
    my $fb = Facebook::OpenGraph->new;

    is($fb->gen_versioned_path('/12345'), '/12345');
    
    is(
        $fb->gen_versioned_path('/v1.0/12345'),
        '/v1.0/12345',
        'version is explicitly given in the path'
    );

    is($fb->gen_versioned_path('/'), '/');
    is($fb->gen_versioned_path(''), '/');
    is($fb->gen_versioned_path(), '/');
    is($fb->gen_versioned_path('/v1.0/'), '/v1.0/');
};

done_testing;
