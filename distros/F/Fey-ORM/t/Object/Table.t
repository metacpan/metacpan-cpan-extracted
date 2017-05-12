use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Fey::ORM::Test;
use Fey::Literal::String;
use Fey::Test;
use Test::Fatal;

Fey::ORM::Test::insert_user_data();
Fey::ORM::Test::define_live_classes();

basic_tests();
add_transform();
tests_with_transform();

Fey::ORM::Test::insert_user_data();

User->meta()->make_immutable();
basic_tests();
tests_with_transform();

sub basic_tests {
    {
        is( User->Count(), 2, 'Count() finds two rows' );
    }

    {
        my $user1 = User->new( user_id => 1 );
        ok( $user1, 'was able to load user where user_id = 1' );

        is(
            $user1->username(), 'autarch',
            'username is set as side effect of calling _get_column_values()'
        );

        if ( User->meta()->is_immutable() ) {
            is(
                $user1->email()->as_string(), 'autarch@example.com',
                'email is set as side effect of calling _get_column_values()'
            );
        }
        else {
            is(
                $user1->email(), 'autarch@example.com',
                'email is set as side effect of calling _get_column_values()'
            );
        }

        my $user2 = User->new( user_id => 1 );
        isnt(
            $user1, $user2,
            'calling User->new() twice with the same user_id returns two different objects'
        );

        is(
            $user2->username(), 'autarch',
            'username is fetched as needed'
        );
        ok(
            $user2->has_email(),
            'email is set as side effect of calling username()'
        );
    }

    {
        my $user = User->new( user_id => 12458686 );

        is(
            $user, undef,
            'nonexistent user_id to new() returns undef'
        );
    }

    {
        my $new_called = 0;

        {
            ## no critic (TestingAndDebugging::ProhibitNoWarnings, Variables::ProtectPrivateVars)
            no warnings 'redefine', 'once';
            local *User::new = sub { $new_called = 1 };

            User->insert(
                username => 'new',
                email    => 'new@example.com'
            );
        }

        ok(
            !$new_called,
            'new() is not called when insert() is done in void context'
        );

        is( User->Count(), 3, 'Count() is now 3' );

        my $user = User->insert(
            username => 'new2',
            email    => 'new@example.com'
        );

        is(
            $user->username(), 'new2',
            'object returned from insert() has username = new2'
        );
        cmp_ok(
            $user->user_id(), '>', 0,
            'object returned from insert() has a user id > 0 (fetched via last_insert_id())'
        );
        is( User->Count(), 4, 'Count() is now 4' );

        my $string = Fey::Literal::String->new('literal');

        $user = User->insert(
            username => $string,
            email    => 'new@example.com'
        );

        is(
            $user->username(), 'literal',
            'literals are handled correctly in an insert'
        );
    }

    {
        my $user = User->new( username => 'autarch' );
        is(
            $user->user_id(), 1,
            'got expected user when creating object via username'
        );
    }

    {
        User->new( username => 'does not exist at all' );
        like(
            User->ConstructorError(),
            qr/Could not find a row in User where username =/i,
            'error message when we cannot find a matching row in the dbms'
        );

        User->new();
        like(
            User->ConstructorError(),
            qr/Could not find a row in User matching the values you provided/i,
            'error message when we cannot find a matching row for any keys'
        );
    }

    {
        my %h1 = (
            username => 'new3',
            email    => 'new3@example.com',
        );

        my @users = User->insert_many(
            \%h1, {
                username => 'new4',
                email    => 'new4@example.com',
            },
        );

        is_deeply(
            \%h1, {
                username => 'new3',
                email    => 'new3@example.com',
            },
            'insert_many() does not alter its parameters'
        );

        is( @users, 2, 'two new users were inserted' );
        is_deeply(
            [ map { $_->username() } @users ],
            [qw( new3 new4 )],
            'users were returned with expected data in the order they were provided'
        );
    }

    {
        my $user = User->new( user_id => 1 );
        $user->update(
            username => 'updated',
            email    => 'updated@example.com'
        );

        ok(
            $user->has_email(),
            'email is not cleared when update value is a non-reference'
        );
        is( $user->username(), 'updated', 'username = updated' );

        if ( User->meta()->is_immutable() ) {
            is(
                $user->email()->as_string(), 'updated@example.com',
                'email = updated@example.com'
            );
        }
        else {
            is(
                $user->email(), 'updated@example.com',
                'email = updated@example.com'
            );
        }

        my $string = Fey::Literal::String->new('updated2');
        $user->update( username => $string );

        ok(
            !$user->has_username(),
            'username is cleared when update value is a reference'
        );
        is( $user->username(), 'updated2', 'username = updated2' );
    }

    {
        my $load_from_dbms_called = 0;
        my $user;

        {
            ## no critic (TestingAndDebugging::ProhibitNoWarnings, Variables::ProtectPrivateVars)
            no warnings 'redefine', 'once';
            local *User::_load_from_dbms = sub { $load_from_dbms_called = 1 };

            $user = User->new(
                user_id     => 99,
                username    => 'not in dbms',
                email       => 'notindbms@example.com',
                _from_query => 1,
            );
        }

        ok(
            !$load_from_dbms_called,
            '_load_from_dbms() is not called when _from_query is passed to the constructor'
        );
        is(
            $user->username(), 'not in dbms',
            'data passed to constructor is available from object'
        );
    }

    {
        like(
            exception {
                User->new(
                    email       => 'notindbms@example.com',
                    _from_query => 1,
                );
            },
            qr/pass the primary key/,
            'new() with _from_query requires the primary key'
        );

        my $user = User->new(
            user_id     => 99,
            _from_query => 1,
        );

        is(
            $user->user_id(), 99,
            'new() with _from_query works when given a candidate key'
        );
    }

    {
        my $user = UserGroup->new(
            user_id     => 99,
            group_id    => 26,
            _from_query => 1,
        );

        my %pk_hash = ( user_id => 99, group_id => 26 );

        # The order of the columns returned by ->primary_key() is not
        # predictable, but it is always the same (at least for a given
        # perl binary).
        my @pk_array = map { $pk_hash{ $_->name() } }
            @{ UserGroup->Table()->primary_key() };

        is_deeply(
            { $user->pk_values_hash() },
            \%pk_hash,
            'pk_values_list returns expected values'
        );

        is_deeply(
            [ $user->pk_values_list() ],
            \@pk_array,
            'pk_values_list returns expected values'
        );
    }

    {
        UserGroup->insert(
            user_id  => 1,
            group_id => 3,
        );

        # This addresses a bug where a "key-only" table blew up trying
        # to select a row.
        my $ug = UserGroup->new(
            user_id  => 1,
            group_id => 3,
        );
        is( $ug->user_id(),  1, 'UserGroup row user_id == 1' );
        is( $ug->group_id(), 3, 'UserGroup row group_id == 3' );

        $ug->delete();
    }

    {
        local $@ = 'an error';
        my $user = User->new( user_id => 1244124 );

        is( $@, 'an error', 'nonexistent rows do not overwrite $@' );
    }
}

sub tests_with_transform {
    {
        my $user = User->new( user_id => 1 );

        isa_ok( $user->email(), 'Email' );
    }

    {
        my $user = User->new( user_id => 1 );

        my $email = Email->new('another@example.com');

        $user->update( email => $email );

        is(
            $user->email()->as_string(), $email->as_string(),
            'deflator intercepts Email object passed to update and turns it into a string'
        );

        my $dbh = $user->_dbh();
        my $sql = q{SELECT email FROM "User" WHERE user_id = ?};
        my $email_in_dbms
            = ( $dbh->selectcol_arrayref( $sql, {}, $user->user_id() ) )->[0];

        is(
            $email_in_dbms, $email->as_string(),
            'check email in dbms after update with deflator'
        );
    }

    {
        my $email = Email->new('inserting@example.com');

        my $user = User->insert(
            username => 'inserting',
            email    => $email,
        );

        is(
            $user->email()->as_string(), $email->as_string(),
            'deflator intercepts Email object passed to insert and turns it into a string'
        );

        my $dbh = $user->_dbh();
        my $sql = q{SELECT email FROM "User" WHERE user_id = ?};
        my $email_in_dbms
            = ( $dbh->selectcol_arrayref( $sql, {}, $user->user_id() ) )->[0];

        is(
            $email_in_dbms, $email->as_string(),
            'check email in dbms after insert with deflator'
        );
    }
}

{
    my $user = User->new( user_id => 1 );
    $user->delete();

    ok(
        !User->new( user_id => 1 ),
        'after delete() user is no longer in dbms'
    );
}

## no critic (Subroutines::ProhibitNestedSubs, Modules::ProhibitMultiplePackages)
sub add_transform {
    package Email;

    sub new {
        my $string = $_[1];

        return bless \$string, $_[0];
    }

    sub as_string {
        return ${ $_[0] };
    }

    package User;

    use Scalar::Util qw( blessed );

    use Fey::ORM::Table;

    transform 'email' => inflate { return Email->new( $_[1] ) } =>
        deflate { return blessed $_[1] ? $_[1]->as_string() : $_[1] };
}

done_testing();
