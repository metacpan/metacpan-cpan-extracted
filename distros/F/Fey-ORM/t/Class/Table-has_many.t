use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Fey::ORM::Test qw( schema );
use Fey::Placeholder;
use List::Util qw( first );
use Test::Fatal;

my $Schema = schema();

## no critic (Modules::ProhibitMultiplePackages)
{
    package Schema;

    use Fey::ORM::Schema;

    has_schema $Schema;
}

{
    package User;

    use Fey::ORM::Table;

    has_table $Schema->table('User');

    has_many 'messages' => ( table => $Schema->table('Message') );
}

{
    can_ok( 'User', 'messages' );

    my @manies = User->meta()->has_manies();
    is(
        @manies, 1,
        'User has one has_many relationship'
    );

    my $hm = $manies[0];
    isa_ok( $hm, 'Fey::Meta::HasMany::ViaFK' );
    is(
        $hm->associated_class(), User->meta(),
        'associated_class is User->meta()'
    );
    is(
        $hm->name(), 'messages',
        'name is message'
    );
    is(
        $hm->table(), $Schema->table('User'),
        'table is User table object'
    );
    is(
        $hm->foreign_table(), $Schema->table('Message'),
        'foreign_table is Message table object'
    );
    ok( !$hm->is_cached(), 'is_cached is false' );
    is(
        $hm->fk()->source_table(), $Schema->table('User'),
        'fk source table is User'
    );
    is(
        $hm->fk()->target_table(), $Schema->table('Message'),
        'fk target table is Message'
    );
    is(
        $hm->associated_method(), User->meta()->get_method('messages'),
        'associated_method is same as messages meta method'
    );
    is(
        $hm->iterator_class(), 'Fey::Object::Iterator::FromSelect',
        'iterator class is Fey::Object::Iterator::FromSelect'
    );
    is(
        $hm->order_by(), undef,
        'order_by is undefined'
    );
}

{
    package User;

    __PACKAGE__->meta()->remove_has_many('messages');

    ::is(
        scalar User->meta()->has_manies(), 0,
        'no has manies after calling remove_has_many'
    );
    ::ok(
        !User->meta()->has_method('messages'),
        'no messages method after calling remove_has_many'
    );

    has_many 'messages' => (
        table => $Schema->table('Message'),
        cache => 1,
    );
}

{
    my @manies = User->meta()->has_manies();
    is(
        @manies, 1,
        'User has one has_many relationship'
    );

    my $hm = $manies[0];
    ok( $hm->is_cached(), 'is_cached is true' );
    is(
        $hm->iterator_class(), 'Fey::Object::Iterator::FromSelect::Caching',
        'iterator class is Fey::Object::Iterator::FromSelect::Caching'
    );
}

{
    ok(
        User->meta()->get_method('messages'),
        'found method for messages'
    );
}

{
    package User;

    __PACKAGE__->meta()->remove_has_many('messages');

    has_many 'messages' => (
        table    => $Schema->table('Message'),
        order_by => [ $Schema->table('Message')->column('message_id') ],
    );
}

{
    my @manies = User->meta()->has_manies();

    my @ob = map { $_->name() } @{ $manies[0]->order_by() };
    is_deeply(
        \@ob, ['message_id'],
        'order_by is just message_id column'
    );
}

{
    package Message;

    use Fey::ORM::Table;

    has_table $Schema->table('Message');

    ::like(
        ::exception { has_many( $Schema->table('Group') ) },
        qr/\QThere are no foreign keys between the table for this class, Message and the table you passed to has_many(), Group/,
        'Cannot declare a has_many relationship to a table with which we have no FK'
    );

    ::is(
        ::exception { has_many( $Schema->table('Message') ) },
        undef,
        'no exception declaring a self-referential has_many'
    );

    my $table = Fey::Table->new( name => 'NewTable' );
    ::like(
        ::exception { has_many $table },
        qr/\QA table used for has-one or -many relationships must have a schema/,
        'table without a schema passed to has_many()'
    );
}

{
    package Message;

    __PACKAGE__->meta()->remove_has_many('message');

    my $select
        = Schema->SQLFactoryClass()->new_select()
        ->select( $Schema->table('User') )
        ->from( $Schema->table('User'), $Schema->table('Message') )->where(
        $Schema->table('Message')->column('parent_message_id'),
        '=', Fey::Placeholder->new()
        );

    has_many 'child_message_users' => (
        table       => $Schema->table('User'),
        select      => $select,
        bind_params => sub { $_[0]->message_id() },
    );
}

{
    can_ok( 'Message', 'child_message_users' );

    my @manies = Message->meta()->has_manies();
    is(
        @manies, 1,
        'Message has one has_many relationship'
    );

    my $hm = $manies[0];
    isa_ok( $hm, 'Fey::Meta::HasMany::ViaSelect' );
    is(
        $hm->associated_class(), Message->meta(),
        'associated_class is Message->meta()'
    );
    is(
        $hm->name(), 'child_message_users',
        'name is message'
    );
    is(
        $hm->table(), $Schema->table('Message'),
        'table is Message table object'
    );
    is(
        $hm->foreign_table(), $Schema->table('User'),
        'foreign_table is User table object'
    );
    ok( !$hm->is_cached(), 'is_cached is false' );
    is(
        $hm->associated_method(),
        Message->meta()->get_method('child_message_users'),
        'associated_method is same as child_message_users meta method'
    );
    is(
        $hm->iterator_class(), 'Fey::Object::Iterator::FromSelect',
        'iterator class is Fey::Object::Iterator::FromSelect'
    );
}

{
    package Message;

    __PACKAGE__->meta()->remove_has_many('child_message_users');

    my $select
        = Schema->SQLFactoryClass()->new_select()
        ->select( $Schema->table('User') )
        ->from( $Schema->table('User'), $Schema->table('Message') )->where(
        $Schema->table('Message')->column('parent_message_id'),
        '=', Fey::Placeholder->new()
        );

    has_many 'child_message_users' => (
        table       => $Schema->table('User'),
        select      => $select,
        bind_params => sub { $_[0]->message_id() },
        cache       => 1,
    );
}

{
    can_ok( 'Message', 'child_message_users' );

    ok(
        Message->meta()->get_method('child_message_users'),
        'found method for child_message_users'
    );
}

{
    my $editor_user_id = Fey::Column->new(
        name => 'editor_user_id',
        type => 'integer',
    );

    $Schema->table('Message')->add_column($editor_user_id);

    my $fk = Fey::FK->new(
        source_columns =>
            [ $Schema->table('Message')->column('editor_user_id') ],
        target_columns => [ $Schema->table('User')->column('user_id') ],
    );

    $Schema->add_foreign_key($fk);
}

{
    package User;

    __PACKAGE__->meta()->remove_has_many('child_message_users');

    ::like(
        ::exception { has_many 'edited_messages' =>
                ( table => $Schema->table('Message') );
        },
        qr/\QThere is more than one foreign key between the table for this class, User and the table you passed to has_many(), Message. You must specify one explicitly/i,
        'exception is thrown if trying to make a has_many() when there is >1 fk between the two tables'
    );

    my ($fk)
        = grep { $_->source_columns()->[0]->name() eq 'editor_user_id' }
        $Schema->foreign_keys_between_tables( 'Message', 'User' );

    ::is(
        ::exception { has_many 'edited_messages' => (
                table => $Schema->table('Message'),
                fk    => $fk,
            );
        },
        undef,
        'no error when specifying passing a disambiguating fk to has_many'
    );
}

done_testing();
