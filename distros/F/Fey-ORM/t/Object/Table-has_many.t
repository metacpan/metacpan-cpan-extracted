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
    package User;

    use Fey::ORM::Table;

    has_many messages => ( table => Schema->Schema()->table('Message') );

    package Message;

    use Fey::ORM::Table;

    has_many 'child_messages' =>
        ( table => Schema->Schema()->table('Message') );
}

{
    my $parent = Message->insert(
        message_id => 1,
        message    => 'parent body',
        user_id    => 1,
    );

    for my $i ( 1 .. 3 ) {
        Message->insert(
            message_id        => $i * 3,
            message           => 'child body',
            parent_message_id => $parent->message_id(),
            user_id           => ( $i % 2 ? 1 : 42 ),
        );
    }

    my $user = User->new( user_id => 1 );

    my $messages = $user->messages();

    is_deeply(
        [ sort map { $_->message_id() } $messages->all() ],
        [ 1, 3, 9 ],
        'messages() method returns iterator with expected message data'
    );

    $messages = $parent->child_messages();

    is_deeply(
        [ sort map { $_->message_id() } $messages->all() ],
        [ 3, 6, 9 ],
        'child_messages() method returns iterator with expected message data'
    );
}

{
    package User;

    __PACKAGE__->meta()->remove_has_many('message');

    has_many messages => (
        table    => Schema->Schema()->table('Message'),
        order_by => [
            Schema->Schema()->table('Message')->column('message_id'), 'DESC'
        ],
    );
}

{
    my $user = User->new( user_id => 1 );

    my $messages = $user->messages();

    is_deeply(
        [ map { $_->message_id() } $messages->all() ],
        [ 9, 3, 1 ],
        'messages() method returns iterator with expected message data, respecting order_by'
    );
}

{
    package User;

    __PACKAGE__->meta()->remove_has_many('message');

    has_many messages => (
        table    => Schema->Schema()->table('Message'),
        cache    => 1,
        order_by => [
            Schema->Schema()->table('Message')->column('message_id'), 'ASC'
        ],
    );
}

{
    my $user = User->new( user_id => 1 );

    isa_ok( $user->messages(), 'Fey::Object::Iterator::FromSelect::Caching' );

    my $m1 = $user->messages();
    my $m2 = $user->messages();

    isnt(
        $m1, $m2,
        'cached has_many methods return a new iterator on each call'
    );
    is(
        $m1->next()->message_id(), 1,
        'first iterator ->next returns first message'
    );
    is(
        $m2->next()->message_id(), 1,
        'second iterator ->next returns first message (they do not share state)'
    );
    is(
        $m1->next()->message_id(), 3,
        'first iterator ->next returns second message'
    );
    is(
        $m1->next()->message_id(), 9,
        'first iterator ->next returns third message'
    );
    is(
        $m2->next()->message_id(), 3,
        'second iterator ->next returns second message (they do not share state)'
    );

    my $m3 = $user->messages();

    my @nested;
    while ( my $message = $m3->next() ) {
        my $m4 = $user->messages();

        push @nested,
            [
            $message->message_id(),
            map { $_->message_id() } $m4->all()
            ];
    }

    is_deeply(
        \@nested,
        [
            [ 1, 1, 3, 9 ],
            [ 3, 1, 3, 9 ],
            [ 9, 1, 3, 9 ],
        ],
        'Can access a cloned iterator while looping over the original'
    );
}

{
    my $schema = Schema->Schema();

    $schema->remove_foreign_key($_)
        for $schema->foreign_keys_between_tables( 'Message', 'User' );

    $schema->remove_foreign_key($_)
        for $schema->foreign_keys_between_tables( 'Message', 'Message' );

    # These definitions invert the source/target labeling of the
    # corresponding FKs in Fey::Test. The goal is to test that
    # has_many figures out the proper "direction" of the FK.
    my $fk1 = Fey::FK->new(
        source_columns => [ $schema->table('Message')->column('user_id') ],
        target_columns => [ $schema->table('User')->column('user_id') ],
    );

    my $fk2 = Fey::FK->new(
        source_columns =>
            [ $schema->table('Message')->column('parent_message_id') ],
        target_columns => [ $schema->table('Message')->column('message_id') ],
    );

    $schema->add_foreign_key($_) for $fk1, $fk2;

    package User;

    __PACKAGE__->meta()->remove_has_many('messages');

    has_many messages => ( table => Schema->Schema()->table('Message') );

    package Message;

    __PACKAGE__->meta()->remove_has_many('child_messages');

    has_many 'child_messages' =>
        ( table => Schema->Schema()->table('Message') );
}

inverted_fk_tests();

{
    # This next set of tests is the same as the last, except this time we
    # explicitly provide the Fey::FK object, and test that it gets inverted.

    my $schema = Schema->Schema();

    package User;

    __PACKAGE__->meta()->remove_has_many('messages');

    my ($fk)
        = $schema->foreign_keys_between_tables(
        $schema->tables( 'Message', 'User' ) );

    has_many messages => (
        table => Schema->Schema()->table('Message'),
        fk    => $fk,
    );

    package Message;

    __PACKAGE__->meta()->remove_has_many('child_messages');

    ($fk)
        = $schema->foreign_keys_between_tables(
        $schema->tables( 'Message', 'Message' ) );

    has_many 'child_messages' => (
        table => Schema->Schema()->table('Message'),
        fk    => $fk,
    );
}

inverted_fk_tests();

{
    package Message;

    my $schema = Schema->Schema();

    my $select
        = Schema->SQLFactoryClass()->new_select()
        ->select( $schema->table('User')->columns() )
        ->from( $schema->table('User'), $schema->table('Message') )->where(
        $schema->table('Message')->column('parent_message_id'),
        '=', Fey::Placeholder->new()
        )->order_by( $schema->table('Message')->column('message_id') );

    has_many 'child_message_users' => (
        table       => $schema->table('User'),
        select      => $select,
        bind_params => sub { $_[0]->message_id() },
    );
}

{
    my $message = Message->new( message_id => 1 );

    my @users = $message->child_message_users()->all();

    is(
        scalar @users, 3,
        'found two users from child_message_user()'
    );

    is_deeply(
        [ map { $_->user_id() } @users ],
        [ 1, 42, 1 ],
        'users are returned in expected order'
    );

    my $message2 = Message->new( message_id => 1 );
    isnt(
        $message->child_message_users(),
        $message2->child_message_users(),
        'two objects do not share a single iterator'
    );
}

sub inverted_fk_tests {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    {
        my $user = User->new( user_id => 1 );

        my $messages = $user->messages();

        is_deeply(
            [ sort map { $_->message_id() } $messages->all() ],
            [ 1, 3, 9 ],
            'messages() method returns iterator with expected message data'
        );

        my $parent = Message->new( message_id => 1 );

        $messages = $parent->child_messages();

        is_deeply(
            [ sort map { $_->message_id() } $messages->all() ],
            [ 3, 6, 9 ],
            'messages() method returns iterator with expected message data'
        );
    }

    {
        my $user = User->new( user_id => 1 );

        my $messages = $user->messages();

        $messages->next();
        $messages->next();

        $messages = $user->messages();

        is_deeply(
            [ sort map { $_->message_id() } $messages->all() ],
            [ 1, 3, 9 ],
            'messages() method resets iterator with each call'
        );
    }
}

done_testing();
