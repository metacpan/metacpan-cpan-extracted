use strict;
use Test::More;
use IO::String;
use Time::Fake;

our $noRedis;

BEGIN {
    require 't/test-lib.pm';
    eval 'use Redis';
    if ($@) {
        $noRedis++;
    }
    else {
        require 't/redis/redis.pm';
    }
}

SKIP: {
    skip( "LLNGTESTREDIS isn't set", 1 ) unless $ENV{LLNGTESTREDIS};
    skip( 'Redis is missing',        1 ) if $noRedis;
    &startRedis;
    my $client = LLNG::Manager::Test->new( {
            ini => {
                messageBroker        => '::Redis',
                messageBrokerOptions => {
                    server => &REDISSERVER,
                },
            }
        }
    );
    my $pub = Lemonldap::NG::Common::MessageBroker::Redis->new( {
            messageBrokerOptions => {
                server => &REDISSERVER,
            },
        }
    );

    # Simple test to verify that unlog is well propagated inside portal
    subtest "Simple login/logout" => sub {
        my $id = $client->login('dwho');
        $client->logout($id);
    };

    # Test to verify that cache is cleaned when an unlog event is read
    # from pub/sub
    subtest "External logout" => sub {
        my $id = $client->login('dwho');
        ok(
            unlink(
                $client->ini->{globalStorageOptions}->{Directory} . "/$id"
            ),
            'Delete session from global storage'
        );
        my $sd = $client->ini->{globalStorageOptions}->{Directory};
        note "Push unlog event";
        $pub->publish( 'llng_events', { action => 'unlog', id => $id } );
        Time::Fake->offset('+6s');
        my $res;
        ok( $res = $client->_get( '/', cookie => "lemonldap=$id" ),
            'Try / after 6 seconds' );
        expectReject($res);
    };

    # Test to verify that:
    #  - unlog event only unlog the good id
    #  - session destroyed without event still exist in cache
    subtest "External logout with 2 ids" => sub {
        my $id  = $client->login('dwho');
        my $id2 = $client->login('french');
        ok(
            unlink(
                $client->ini->{globalStorageOptions}->{Directory} . "/$id"
            ),
            'Delete session from global storage'
        );
        my $sd = $client->ini->{globalStorageOptions}->{Directory};
        note "Push unlog event";
        $pub->publish( 'llng_events', { action => 'unlog', id => $id } );

        # 6+6 because time already updated to +6
        Time::Fake->offset('+12s');
        my $res;
        ok( $res = $client->_get( '/', cookie => "lemonldap=$id" ),
            'Try / after 6 seconds' );
        expectReject($res);
        ok(
            unlink(
                $client->ini->{globalStorageOptions}->{Directory} . "/$id2"
            ),
            'Delete session from global storage'
        );
        Time::Fake->offset('+18s');
        ok(
            $res = $client->_get( '/', cookie => "lemonldap=$id2" ),
            'Try with unlogged user without event (still in cache)'
        );
        expectOK($res);
    };
}

eval { &stopRedis };

clean_sessions();
done_testing();
