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
    package Message;

    use Fey::ORM::Table;

    has_table $Schema->table('Message');

    has_one $Schema->table('User');
}

{
    can_ok( 'Message', 'user' );

    my $attr = Message->meta()->get_attribute('user');
    ok( $attr, 'found attribute for user' );
    is(
        ref $attr->default(), 'CODE',
        'user attribute default is a coderef'
    );
    is(
        $attr->type_constraint()->name(), 'Fey::Object::Table',
        'user attribute type constraint is Fey::Object::Table'
    );

    my @ones = Message->meta()->has_ones();
    is(
        scalar @ones, 1,
        'one has_one for Message class'
    );

    my $ho = $ones[0];
    isa_ok( $ho, 'Fey::Meta::HasOne::ViaFK' );
    is(
        $ho->associated_class(), Message->meta(),
        'associated_class is Message->meta()'
    );
    is(
        $ho->name(), 'user',
        'name is user'
    );
    is(
        $ho->table(), $Schema->table('Message'),
        'table is Message table object'
    );
    is(
        $ho->foreign_table(), $Schema->table('User'),
        'foreign_table is User table object'
    );
    ok( $ho->is_cached(),     'is_cached is true' );
    ok( !$ho->allows_undef(), 'allows_undef is false' );
    is(
        $ho->fk()->source_table(), $Schema->table('Message'),
        'fk source table is Message'
    );
    is(
        $ho->fk()->target_table(), $Schema->table('User'),
        'fk target table is User'
    );
    is(
        $ho->associated_method(), undef,
        'associated_method is undef'
    );

    my $assoc_attr = $ho->associated_attribute();
    is(
        $assoc_attr, $attr,
        'associated attribute is same as the one in the metaclass'
    );
}

{
    package Message;

    use Fey::ORM::Table;

    __PACKAGE__->meta()->remove_has_one('user');

    ::is(
        scalar __PACKAGE__->meta()->has_ones(), 0,
        'no has_ones after calling remove_has_one'
    );
    ::ok(
        !__PACKAGE__->meta()->has_attribute('user'),
        'does not have a user attribute after calling remove_has_one'
    );

    has_one 'user' => (
        table => $Schema->table('User'),
        undef => 1,
    );
}

{
    my $attr = Message->meta()->get_attribute('user');
    is(
        $attr->type_constraint()->name(), 'Maybe[Fey::Object::Table]',
        'user attribute type constraint is Maybe[Fey::Object::Table]'
    );

    my @ones = Message->meta()->has_ones();
    is(
        scalar @ones, 1,
        'one has_one for Message class'
    );
    ok( $ones[0]->allows_undef, 'allows_undef is true' );
}

{
    package Message;

    __PACKAGE__->meta()->remove_has_one('user');

    has_one 'my_user' => (
        table => $Schema->table('User'),
        cache => 1,
    );
}

{
    can_ok( 'Message', 'my_user' );
    can_ok( 'Message', '_clear_my_user' );

    my $attr = Message->meta()->get_attribute('my_user');
    ok( $attr, 'found attribute for my_user' );
    is(
        ref $attr->default(), 'CODE',
        'my_user attribute default is a coderef'
    );
    is(
        $attr->type_constraint()->name(), 'Fey::Object::Table',
        'my_user attribute type constraint is Fey::Object::Table'
    );
}

{
    package Message;

    __PACKAGE__->meta()->remove_has_one('my_user');

    has_one 'user' => (
        table => $Schema->table('User'),
        cache => 0,
    );
}

{
    can_ok( 'Message', 'user' );
    ok( !Message->can('_clear_user'), 'no clearer for non-cached has_one' );

    ok(
        !Message->meta()->has_attribute('user'),
        'Message does not have an attribute for user (but does have a user() method)'
    );

    my @ones = Message->meta()->has_ones();
    is(
        scalar @ones, 1,
        'one has_one for Message class'
    );
    is(
        $ones[0]->associated_method(), Message->meta()->get_method('user'),
        'associated_method matches user method in Message class'
    );
}

{
    package Message;

    use Fey::ORM::Table;

    __PACKAGE__->meta()->remove_has_one('user');

    has_one 'user' => (
        table   => $Schema->table('User'),
        handles => [qw( username email )],
    );
}

{
    can_ok( 'Message', 'username' );
    can_ok( 'Message', 'email' );
}

{
    package Message;

    ::like(
        ::exception { has_one $Schema->table('Group') },
        qr/\QThere are no foreign keys between the table for this class, Message and the table you passed to has_one(), Group/,
        'Cannot declare a has_one relationship to a table with which we have no FK'
    );

    ::is(
        ::exception { has_one $Schema->table('Message') },
        undef,
        'no exception declaring a self-referential has_one'
    );

    my $table = Fey::Table->new( name => 'NewTable' );
    ::like(
        ::exception { has_one $table },
        qr/\QA table used for has-one or -many relationships must have a schema/,
        'table without a schema passed to has_one()'
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
    package Message;

    __PACKAGE__->meta()->remove_has_one('user');

    ::like(
        ::exception { has_one 'editor' => ( table => $Schema->table('User') );
        },
        qr/\QThere is more than one foreign key between the table for this class, Message and the table you passed to has_one(), User. You must specify one explicitly/i,
        'exception is thrown if trying to make a has_one() when there is >1 fk between the two tables'
    );

    my ($fk)
        = grep { $_->source_columns()->[0]->name() eq 'editor_user_id' }
        $Schema->foreign_keys_between_tables( 'Message', 'User' );

    ::is(
        ::exception { has_one 'editor' => (
                table => $Schema->table('User'),
                fk    => $fk,
            );
        },
        undef,
        'no error when specifying passing a disambiguating fk to has_one'
    );

    my @ones = grep { $_->fk()->target_table()->name() eq 'User' }
        Message->meta()->has_ones();
    ::is(
        $ones[0]->fk(), $fk,
        'fk matches the one passed to has_one'
    );
}

{
    package Message;

    __PACKAGE__->meta()->remove_has_one( $_->name() )
        for __PACKAGE__->meta()->has_ones();

    my $select
        = Fey::SQL->new_select()->select( $Schema->table('Message') )->where(
        $Schema->table('Message')->column('parent_message_id'),
        '=', Fey::Placeholder->new()
        )
        ->order_by( $Schema->table('Message')->column('message_id'), 'DESC' )
        ->limit(1);

    has_one 'most_recent_child' => (
        table       => $Schema->table('Message'),
        select      => $select,
        bind_params => sub { $_[0]->message_id() },
    );
}

{
    can_ok( 'Message', 'most_recent_child' );

    my $attr = Message->meta()->get_attribute('most_recent_child');
    ok( $attr, 'found attribute for most_recent_child' );
    is(
        ref $attr->default(), 'CODE',
        'most_recent_child attribute default is a coderef'
    );
    is(
        $attr->type_constraint()->name(), 'Maybe[Fey::Object::Table]',
        'most_recent_child attribute type constraint is Maybe[Fey::Object::Table]'
    );

    my @ones = Message->meta()->has_ones();
    is(
        scalar @ones, 1,
        'one has_one for Message class'
    );

    my $ho = $ones[0];
    isa_ok( $ho, 'Fey::Meta::HasOne::ViaSelect' );
    is(
        $ho->name(), 'most_recent_child',
        'name is most_recent_child'
    );
    ok( $ho->allows_undef(), 'allows_undef is true' );
}

{
    package Message;

    __PACKAGE__->meta()->remove_has_one('most_recent_child');

    my $select
        = Fey::SQL->new_select()->select( $Schema->table('Message') )
        ->from( $Schema->table('Message') )->where(
        $Schema->table('Message')->column('parent_message_id'),
        '=', Fey::Placeholder->new()
        )
        ->order_by( $Schema->table('Message')->column('message_id'), 'DESC' )
        ->limit(1);

    has_one 'most_recent_child' => (
        table       => $Schema->table('Message'),
        select      => $select,
        bind_params => sub { $_[0]->message_id() },
        cache       => 0,
    );
}

{
    can_ok( 'Message', 'most_recent_child' );

    ok(
        !Message->meta()->get_attribute('most_recent_child'),
        'Message does not have a most_recent_child attribute, but does have a method for it'
    );
}

done_testing();
