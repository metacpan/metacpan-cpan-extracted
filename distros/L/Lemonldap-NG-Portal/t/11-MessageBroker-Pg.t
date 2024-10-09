use strict;
use Test::More;
use IO::String;
use Time::Fake;

our $noPg;
our $started;

BEGIN {
    require 't/test-lib.pm';
    eval {
        require DBI;
        require DBD::Pg;
        require Lemonldap::NG::Common::MessageBroker::Pg;
        require 't/postgres/pg.pm';
    };
    if ($@) {
        $noPg = $@;
    }
}

SKIP: {
    skip( "LLNGTESTPG isn't set",      1 ) unless $ENV{LLNGTESTPG};
    skip( "One dep is missing: $noPg", 1 ) if $noPg;
    eval { &startPg };
    skip( $@, 1 ) if $@;
    $started++;
    my $client = LLNG::Manager::Test->new( {
            ini => {
                messageBroker        => '::Pg',
                messageBrokerOptions => &DBIPARAMS,
            }
        }
    );
    my $pub = Lemonldap::NG::Common::MessageBroker::Pg->new( {
            messageBrokerOptions => &DBIPARAMS,
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

eval { &stopPg } if $started;

clean_sessions();
done_testing();
