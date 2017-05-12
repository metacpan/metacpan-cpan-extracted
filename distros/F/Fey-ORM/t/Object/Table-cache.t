use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Fey::ORM::Test;
use Fey::Test;

Fey::ORM::Test::insert_user_data();
Fey::ORM::Test::define_live_classes();

run_tests();
User->meta()->make_immutable();
run_tests();

sub run_tests {
    {
        User->EnableObjectCache();

        my $user1 = User->new( user_id => 1 );
        my $user2 = User->new( user_id => 1 );

        is(
            $user1, $user2,
            'two objects for the same id are identical when the object cache is enabled'
        );

        my $user3 = User->new( { user_id => 1 } );

        is(
            $user1, $user3,
            'two objects for the same id are identical when the object cache is enabled - one object created via hashref to new()'
        );
    }

    {
        User->DisableObjectCache();

        my $user1 = User->new( user_id => 1 );
        my $user2 = User->new( user_id => 1 );

        isnt(
            $user1, $user2,
            'two objects for the same id are not identical when the object cache is disabled'
        );
    }

    {
        User->EnableObjectCache();

        my $user1 = User->new( user_id => 1 );

        User->ClearObjectCache();

        my $user2 = User->new( user_id => 1 );

        isnt(
            $user1, $user2,
            'two objects for the same id are not identical when the object cache is enabled but cleared between calls to new()'
        );
    }
}

done_testing();
