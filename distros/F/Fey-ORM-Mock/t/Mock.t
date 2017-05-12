use strict;
use warnings;

use Test::Exception;
use Test::More;

use Fey::ORM::Mock;
use Fey::Test;

{
    my $Schema = Fey::Test->mock_test_schema_with_fks();

    package Test::Schema;

    use Fey::ORM::Schema;

    has_schema $Schema;

    my $source = Fey::DBIManager::Source->new( dsn => 'dbi:SQLite:' );

    __PACKAGE__->DBIManager()->add_source($source);

    package User;

    use Fey::ORM::Table;

    has_table( $Schema->table('User') );

    # to test method modifier re-application
    before 'update' => sub { push @User::Modifiers, 'before2' };
    before 'update' => sub { push @User::Modifiers, 'before1' };
    around 'update' => sub {
        push @User::Modifiers, 'around2';
        my $orig = shift;
        return shift->$orig(@_);
    };
    around 'update' => sub {
        push @User::Modifiers, 'around1';
        my $orig = shift;
        return shift->$orig(@_);
    };
    after 'update' => sub { push @User::Modifiers, 'after1' };
    after 'update' => sub { push @User::Modifiers, 'after2' };

    package Message;

    use Fey::ORM::Table;

    has_table( $Schema->table('Message') );

    package Group;

    use Fey::ORM::Table;

    has_table( $Schema->table('Group') );

    package UserGroup;

    use Fey::ORM::Table;

    has_table( $Schema->table('UserGroup') );

    # Want to test with at least one immutable class
    __PACKAGE__->meta()->make_immutable();
}

my $mock = Fey::ORM::Mock->new( schema_class => 'Test::Schema' );

ok(
    Test::Schema->isa('Fey::Object::Mock::Schema'),
    'after mock_schema() Test::Schema inherits from Fey::Object::Mock::Schema'
);

for my $class (qw( User Message Group UserGroup )) {
    ok(
        $class->isa('Fey::Object::Mock::Table'),
        "after mock_schema() $class inherits from Fey::Object::Mock::Table"
    );
}

isa_ok(
    Test::Schema->Recorder(), 'Fey::ORM::Mock::Recorder',
    'Test::Schema->Recorder() returns a new recorder object'
);

is(
    $mock->recorder(), Test::Schema->Recorder(),
    'recorder for mock object and schema class are identical'
);

is(
    User->_dbh()->{Driver}{Name}, 'Mock',
    'DBI handle is for DBD::Mock'
);

{
    my $user = User->insert( username => 'Bob' );

    isa_ok(
        $user, 'User',
        'mocked insert() return an object'
    );

    is(
        scalar $mock->recorder()->actions_for_class('Message'), 0,
        'no actions for the Message class'
    );

    my @actions = $mock->recorder()->actions_for_class('User');
    is(
        scalar @actions, 1,
        'one action for the User class'
    );

    is(
        $actions[0]->type(), 'insert',
        'action type is insert'
    );
    is(
        $actions[0]->class(), 'User',
        'action class is User'
    );
    is_deeply(
        $actions[0]->values(),
        { username => 'Bob' },
        'action values contains expected data'
    );

    $mock->recorder()->clear_class('User');
    is(
        scalar $mock->recorder()->actions_for_class('User'), 0,
        'no actions for the User class after clearing'
    );
}

{
    my $user = User->insert(
        user_id  => 33,
        username => 'Bob'
    );

    $user->update(
        username => 'John',
        email    => 'john@example.com',
    );

    is_deeply(
        \@User::Modifiers,
        [
            qw( before1 before2
                around1 around2
                after1 after2 )
        ],
        'method modifiers are reapplied properly'
    );

    my $message = Message->insert( message => 'blah blah' );

    is(
        scalar $mock->recorder()->actions_for_class('Message'), 1,
        'one action for the Message class'
    );

    my @actions = $mock->recorder()->actions_for_class('User');
    is(
        scalar @actions, 2,
        'two actions for the User class'
    );

    is(
        $actions[0]->type(), 'insert',
        'first action type is insert'
    );
    is(
        $actions[1]->type(), 'update',
        'second action type is update'
    );
    is_deeply(
        $actions[1]->values(), {
            username => 'John',
            email    => 'john@example.com',
        },
        'update values contains expected data'
    );
    is_deeply(
        $actions[1]->pk(),
        { user_id => 33 },
        'update pk contains expected data'
    );

    $user->delete();

    @actions = $mock->recorder()->actions_for_class('User');
    is(
        scalar @actions, 3,
        'three actions for the User class after deleting user'
    );
    is(
        $actions[2]->type(), 'delete',
        'third action type is delete'
    );
    is_deeply(
        $actions[2]->pk(),
        { user_id => 33 },
        'delete pk contains expected data'
    );

    $mock->recorder()->clear_all();

    is(
        scalar $mock->recorder()->actions_for_class('Message'), 0,
        'no actions for the Message class after clear_all'
    );
    is(
        scalar $mock->recorder()->actions_for_class('User'), 0,
        'no actions for the User class after clear_all'
    );
}

{
    $mock->seed_class(
        User => {
            user_id  => 42,
            username => 'Doug',
        }, {
            user_id  => 666,
            username => 'Beelzy',
        },
    );

    my $user = User->new( user_id => 2 );

    is(
        $user->user_id(), 42,
        'got database value for class even with a value passed in the constructor'
    );
    is(
        $user->username(), 'Doug',
        'also got seeded values for class'
    );

    $user = User->new( user_id => 666 );

    is(
        $user->user_id(), 666,
        'got constructor value for class'
    );
    is(
        $user->username(), 'Beelzy',
        'also got seeded values for class'
    );

    throws_ok(
        sub { User->new( user_id => 10 ) },
        qr/bind_columns/,
        'cannot get a new user once seeder is exhausted'
    );
}

done_testing();
