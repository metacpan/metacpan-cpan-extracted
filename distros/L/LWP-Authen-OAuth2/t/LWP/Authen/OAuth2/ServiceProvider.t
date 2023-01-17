#! /usr/bin/env perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";

BEGIN {
    use_ok( 'LWP::Authen::OAuth2::ServiceProvider' ) || print "Bail out!\n";
    use LWP::Authen::OAuth2;

    my $oauth2 = LWP::Authen::OAuth2->new(
        is_strict              => 0,
        client_id              => 'Test',
        client_secret          => 'Test',
    );

    my $service_provider = LWP::Authen::OAuth2::ServiceProvider->new({
        request_default_params => {
            key1 => 'value1',
        },
    });

    my $params = $service_provider->collect_action_params(
        'request',
        $oauth2,
    );

    is_deeply(
        $params,
        {
            client_id     => 'Test',
            client_secret => 'Test',
            key1          => 'value1',
        },
        'collect_action_params - no strict mode, keep default values if not specified elsewhere',
    );
}

done_testing();
