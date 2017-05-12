use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use lib 't/lib';

use Fey::ORM::Test qw( schema );
use Test::Fatal;

my $Schema = schema();

## no critic (Modules::ProhibitMultiplePackages)
{
    package Group;

    use Fey::ORM::Table;

    ::like(
        ::exception { has_table $Schema->table('Group') },
        qr/must load your schema class/,
        'cannot call has_table() before schema class is loaded'
    );
}

{
    package Schema;

    use Fey::ORM::Schema;

    has_schema $Schema;

    package Email;

    sub new {
        return bless \$_[1], $_[0];
    }

    sub as_string {
        return ${ $_[0] };
    }

    package User;

    use Fey::ORM::Table;

    has_table $Schema->table('User');

    transform 'email' => inflate { return Email->new( $_[1] ) } =>
        deflate { return $_[1]->as_string() };

    ::like(
        ::exception { has_table $Schema->table('User') },
        qr/more than once per class/,
        'cannot call has_table() more than once for a class'
    );

    package User2;

    use Fey::ORM::Table;

    ::like(
        ::exception { has_table $Schema->table('User') },
        qr/associate the same table with multiple classes/,
        'cannot associate the same table with multiple classes'
    );

    my $table = Fey::Table->new( name => 'User2' );

    ::like(
        ::exception { has_table $table },
        qr/must have a schema/,
        'tables passed to has_table() must have a schema'
    );

    $Schema->add_table($table);

    ::like(
        ::exception { has_table $table },
        qr/must have at least one key/,
        'tables passed to has_table() must have at least one key'
    );
}

{
    package Group;

    use Fey::ORM::Table;

    has_table $Schema->table('Group');
}

{
    ok(
        User->isa('Fey::Object::Table'),
        q{User->isa('Fey::Object::Table')}
    );
    can_ok( 'User', 'Table' );
    is(
        User->Table()->name(), 'User',
        'User->Table() returns User table'
    );

    is(
        Fey::Meta::Class::Table->TableForClass('User')->name(), 'User',
        q{Fey::Meta::Class::Table->TableForClass('User') returns User table}
    );

    is(
        Fey::Meta::Class::Table->ClassForTable( $Schema->table('User') ),
        'User',
        q{Fey::Meta::Class::Table->ClassForTable('User') returns User class}
    );

    is_deeply(
        [
            Fey::Meta::Class::Table->ClassForTable(
                $Schema->tables( 'User', 'Group' )
            )
        ],
        [ 'User', 'Group' ],
        q{Fey::Meta::Class::Table->ClassForTable( 'User', 'Group' ) returns expected classes}
    );

    for my $column ( $Schema->table('User')->columns() ) {
        my $name = $column->name();

        can_ok( 'User', $name );
        is(
            User->meta()->get_attribute($name)->column(),
            $column,
            "column for $name meta-attribute matches column from table"
        );
    }

    is(
        ref User->meta()->get_attribute('email')->inflator(),
        'CODE',
        'inflator for email attribute is a code ref'
    );

    can_ok( 'User', 'email_raw' );

    is(
        User->meta()->get_attribute('user_id')->type_constraint()->name(),
        'Int',
        'type for user_id is Int'
    );

    is(
        User->meta()->get_attribute('username')->type_constraint()->name(),
        'Str',
        'type for username is Str'
    );

    is(
        User->meta()->get_attribute('email_raw')->type_constraint()->name(),
        'Str|Undef',
        'type for email is Str|Undef'
    );

    ok(
        User->meta()->has_inflator('email'),
        'User has an inflator coderef for email'
    );
    ok(
        User->meta()->has_deflator('email'),
        'User has a deflator coderef for email'
    );

    my $user = User->new(
        user_id     => 1,
        email       => 'test@example.com',
        _from_query => 1,
    );

    ok(
        !ref $user->email_raw(),
        'email_raw() returns a plain string'
    );
    is(
        $user->email_raw(), 'test@example.com',
        'email_raw = test@example.com'
    );

    my $email = $user->email();
    isa_ok( $email, 'Email' );
    is( $email, $user->email(), 'inflated values are cached' );

    $user->_clear_email();
    ok(
        !$user->has_email(),
        'predicate for email is false after is cleared'
    );
    ok(
        !$user->_has_inflated_email(),
        'clearer also clears inflated value'
    );
}

{
    my $user = User->new(
        user_id     => 2,
        email       => 'test@example.com',
        _from_query => 1,
    );

    # makes sure that the default gets built
    $user->email();

    $user->_set_email('test2@example.com');
    is(
        $user->email()->as_string(), 'test2@example.com',
        'setting an inflated attribute clears the inflated value so it gets rebuilt'
    );
}

{
    like(
        exception {
            User->new(
                user_id     => 42,
                bad_attr    => 'x',
                _from_query => 1,
            );
        },
        qr/Found unknown attribute.+bad_attr/,
        'User class has a strict constructor'
    );
}

{
    package Message;

    use Fey::ORM::Table;

    sub message_id {
        return 'foo';
    }

    has_table $Schema->table('Message');

    # Testing passing >1 attribute to transform
    transform qw( message quality ) => inflate { $_[0] } => deflate { $_[0] };

    ::like(
        ::exception { transform 'message' => inflate { $_[0] };
        },
        qr/more than one inflator/,
        'cannot provide more than one inflator for a column'
    );

    ::like(
        ::exception { transform 'message' => deflate { $_[0] };
        },
        qr/more than one deflator/,
        'cannot provide more than one deflator for a column'
    );

    ::like(
        ::exception { transform 'nosuchcolumn' => deflate { $_[0] };
        },
        qr/\QThe column nosuchcolumn does not exist as an attribute/,
        'cannot transform a nonexistent column'
    );
}

{
    ok(
        Message->meta()->has_deflator('message'),
        'Message has a deflator coderef for message'
    );
    ok(
        Message->meta()->has_deflator('quality'),
        'Message has a deflator coderef for quality'
    );

    is(
        Message->message_id(), 'foo',
        'column attributes do not overwrite existing methods'
    );
}

my $Schema2 = schema();
$Schema2->set_name('Schema2');

{
    package Schema2;

    use Fey::ORM::Schema;

    has_schema $Schema2;

    package User2;

    has_table $Schema2->table('User');

    #<<<
    transform 'email'
        => inflate { return Email->new( $_[1] ) }
        => deflate { return $_[1]->as_string() }
        => handles { address => 'as_string' };
    #>>>
}

{
    is(
        User2->Table()->name(), 'User',
        'table for User2 class is User'
    );
    is(
        User2->Table()->schema()->name(), 'Schema2',
        'schema for User2 class table is Schema2'
    );
    ok( User2->can('address'), 'delegation for address was created' );

    my $user = User2->new(
        user_id     => 2,
        email       => 'test@example.com',
        _from_query => 1,
    );
    is(
        $user->address(), 'test@example.com',
        'address method return stringified email address'
    );
}

done_testing();
