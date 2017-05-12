use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Fey::ORM::Test;
use Fey::Literal::String;
use Fey::Placeholder;
use Fey::Test;

Fey::ORM::Test::define_live_classes();
Fey::ORM::Test::insert_user_data();

## no critic (Modules::ProhibitMultiplePackages)
{
    package Message;

    use Fey::ORM::Table;

    has_one Schema->Schema()->table('User');

    has_one 'parent_message' =>
        ( table => Schema->Schema()->table('Message') );
}

{
    my $parent = Message->insert(
        message => 'parent body',
        user_id => 1,
    );

    is(
        $parent->user()->user_id(), 1,
        'user() for parent message returns expected user object'
    );

    is(
        $parent->user(), $parent->user(),
        'user() attribute is cached'
    );

    is(
        $parent->parent_message(), undef,
        'parent message has no parent itself'
    );

    my $child = Message->insert(
        message           => 'child body',
        parent_message_id => $parent->message_id(),
        user_id           => 1,
    );

    my $parent_from_attr = $child->parent_message();

    is(
        $parent_from_attr->message_id(), $parent->message_id(),
        'parent_message() attribute created via has_one returns expected message'
    );
}

{
    package Message;

    __PACKAGE__->meta()->remove_has_one('user');

    has_one 'user' => (
        table => Schema->Schema()->table('User'),
        cache => 0,
    );
}

{
    my $message = Message->insert(
        message => 'message body',
        user_id => 1,
    );

    is(
        $message->user()->user_id(), 1,
        'user() for parent message returns expected user object'
    );

    isnt(
        $message->user(), $message->user(),
        'user() attribute is not cached'
    );
}

{
    my $schema = Schema->Schema();

    $schema->remove_foreign_key($_)
        for $schema->foreign_keys_between_tables( 'Message', 'User' );

    $schema->remove_foreign_key($_)
        for $schema->foreign_keys_between_tables( 'Message', 'Message' );

    # These definitions invert the source/target labeling of the
    # corresponding FKs in Fey::Test. The goal is to test that has_one
    # figures out the proper "direction" of the FK.
    my $fk1 = Fey::FK->new(
        source_columns => [ $schema->table('User')->column('user_id') ],
        target_columns => [ $schema->table('Message')->column('user_id') ],
    );

    my $fk2 = Fey::FK->new(
        source_columns => [ $schema->table('Message')->column('message_id') ],
        target_columns =>
            [ $schema->table('Message')->column('parent_message_id') ],
    );

    $schema->add_foreign_key($_) for $fk1, $fk2;

    package Message;

    __PACKAGE__->meta()->remove_has_one('user');

    has_one $schema->table('User');

    __PACKAGE__->meta()->remove_has_one('parent_message');

    has_one 'parent_message' => ( table => $schema->table('Message') );
}

inverted_fk_tests();

{
    # This next set of tests is the same as the last, except this time we
    # explicitly provide the Fey::FK object, and test that it gets inverted.

    package Message;

    my $schema = Schema->Schema();

    __PACKAGE__->meta()->remove_has_one('user');

    my ($fk)
        = $schema->foreign_keys_between_tables(
        $schema->tables( 'Message', 'User' ) );

    has_one user => (
        table => $schema->table('User'),
        fk    => $fk,
    );

    __PACKAGE__->meta()->remove_has_one('parent_message');

    ($fk)
        = $schema->foreign_keys_between_tables(
        $schema->tables( 'Message', 'Message' ) );

    has_one 'parent_message' => (
        table => $schema->table('Message'),
        fk    => $fk,
    );
}

inverted_fk_tests();

{
    package User;

    use Fey::ORM::Table;

    my $select
        = Schema->SQLFactoryClass()->new_select()
        ->select( Schema->Schema()->table('Message') )
        ->from( Schema->Schema()->table('Message') )->where(
        Schema->Schema()->table('Message')->column('user_id'),
        '=', Fey::Placeholder->new()
        )->order_by(
        Schema->Schema()->table('Message')->column('message_id'),
        'DESC'
        )->limit(1);

    has_one 'most_recent_message' => (
        table       => Schema->Schema()->table('Message'),
        select      => $select,
        bind_params => sub { $_[0]->user_id() },
    );
}

{
    my $user = User->new( user_id => 1 );
    my $message = $user->most_recent_message();

    isa_ok(
        $message, 'Message',
        'most_recent_message() returns Message object'
    );

    my ($most_recent_message_id)
        = ( Schema->DBIManager()->default_source()->dbh()
            ->selectcol_arrayref('SELECT MAX(message_id) FROM Message') )
        ->[0];

    is(
        $message->message_id(), $most_recent_message_id,
        'message object is the most recently inserted message'
    );
    is(
        $message->user_id(), $user->user_id(),
        'message belongs to the user'
    );
}

sub inverted_fk_tests {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $parent = Message->insert(
        message => 'parent body',
        user_id => 1,
    );

    is(
        $parent->user()->user_id(), 1,
        'user() for parent message returns expected user object'
    );

    is(
        $parent->parent_message(), undef,
        'parent message has no parent itself'
    );

    my $child = Message->insert(
        message           => 'child body',
        parent_message_id => $parent->message_id(),
        user_id           => 1,
    );

    my $parent_from_attr = $child->parent_message();

    is(
        $parent_from_attr->message_id(), $parent->message_id(),
        'parent_message() attribute created via has_one returns expected message'
    );
}

done_testing();
