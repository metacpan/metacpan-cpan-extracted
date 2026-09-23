package EV::Telegram::TDLib::Forum;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Forum - forum topic methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Forum mixin">.

=cut

sub CLONE_SKIP { 1 }


our %UPDATES;

sub icon {
    my ($opt) = @_;
    return () unless defined $opt->{color} || defined $opt->{custom_emoji_id};
    return (icon => {
        '@type'          => 'forumTopicIcon',
        color            => num('color', $opt->{color} // 0),
        custom_emoji_id  => plain_text('a custom emoji id',
                                       $opt->{custom_emoji_id} // 0),
    });
}

sub create_topic {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat, $name, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, name', $chat, $name);
    $self->send({
        '@type'           => 'createForumTopic',
        chat_id           => 0 + $chat,
        name              => plain_text('a topic name', $name),
        is_name_implicit  => json_bool($opt{name_implicit}),
        icon(\%opt),
    }, $cb);
    return;
}

sub edit_topic {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat, $topic, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, forum_topic_id', $chat, $topic);
    $self->send({
        '@type'                 => 'editForumTopic',
        chat_id                 => 0 + $chat,
        forum_topic_id          => 0 + $topic,
        name                    => plain_text('a topic name', $opt{name}),
        edit_icon_custom_emoji  => json_bool(exists $opt{custom_emoji_id}),
        icon_custom_emoji_id    => plain_text('a custom emoji id',
                                              $opt{custom_emoji_id} // 0),
    }, $cb);
    return;
}

sub delete_topic {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_topic', 2, \@args);
    my ($chat, $topic) = @args;
    need('chat_id, forum_topic_id', $chat, $topic);
    $self->send({ '@type' => 'deleteForumTopic',
                  chat_id => 0 + $chat, forum_topic_id => 0 + $topic }, $cb);
    return;
}

sub topic {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('topic', 2, \@args);
    my ($chat, $topic) = @args;
    need('chat_id, forum_topic_id', $chat, $topic);
    $self->send({ '@type' => 'getForumTopic',
                  chat_id => 0 + $chat, forum_topic_id => 0 + $topic }, $cb);
    return;
}

sub topics {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat);
    $self->send({
        '@type'                  => 'getForumTopics',
        chat_id                  => 0 + $chat,
        query                    => plain_text('a query', $opt{query}),
        offset_date              => num('offset_date', $opt{offset_date} // 0),
        offset_message_id        => num('offset_message_id',
                                        $opt{offset_message_id} // 0),
        offset_forum_topic_id    => num('offset_forum_topic_id',
                                        $opt{offset_forum_topic_id} // 0),
        limit                    => num('limit', $opt{limit} // 100),
    }, $cb);
    return;
}

sub topic_history {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat, $topic, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, forum_topic_id', $chat, $topic);
    $self->send({
        '@type'          => 'getForumTopicHistory',
        chat_id          => 0 + $chat,
        forum_topic_id   => 0 + $topic,
        from_message_id  => num('from_message_id', $opt{from_message_id} // 0),
        offset           => num('offset', $opt{offset} // 0),
        limit            => num('limit', $opt{limit} // 50),
    }, $cb);
    return;
}

sub topic_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('topic_link', 2, \@args);
    my ($chat, $topic) = @args;
    need('chat_id, forum_topic_id', $chat, $topic);
    $self->send({ '@type' => 'getForumTopicLink',
                  chat_id => 0 + $chat, forum_topic_id => 0 + $topic }, $cb);
    return;
}

sub close_topic {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat, $topic, $closed, @rest) = @args;
    no_opts('close_topic', @rest);
    need('chat_id, forum_topic_id', $chat, $topic);
    $self->send({ '@type' => 'toggleForumTopicIsClosed', chat_id => 0 + $chat,
                  forum_topic_id => 0 + $topic,
                  is_closed => json_bool(defined $closed ? $closed : 1) }, $cb);
    return;
}

sub pin_topic {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat, $topic, $pinned, @rest) = @args;
    no_opts('pin_topic', @rest);
    need('chat_id, forum_topic_id', $chat, $topic);
    $self->send({ '@type' => 'toggleForumTopicIsPinned', chat_id => 0 + $chat,
                  forum_topic_id => 0 + $topic,
                  is_pinned => json_bool(defined $pinned ? $pinned : 1) }, $cb);
    return;
}

sub unpin_topic_messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('unpin_topic_messages', 2, \@args);
    my ($chat, $topic) = @args;
    need('chat_id, forum_topic_id', $chat, $topic);
    $self->send({ '@type' => 'unpinAllForumTopicMessages',
                  chat_id => 0 + $chat, forum_topic_id => 0 + $topic }, $cb);
    return;
}

sub hide_general_topic {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat, $hidden, @rest) = @args;
    no_opts('hide_general_topic', @rest);
    need('chat_id', $chat);
    $self->send({ '@type' => 'toggleGeneralForumTopicIsHidden', chat_id => 0 + $chat,
                  is_hidden => json_bool(defined $hidden ? $hidden : 1) }, $cb);
    return;
}

sub read_all_topic_reactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('read_all_topic_reactions', 2, \@args);
    my ($chat, $topic) = @args;
    need('chat_id, forum_topic_id', $chat, $topic);
    $self->send({ '@type' => 'readAllForumTopicReactions',
                  chat_id => 0 + $chat, forum_topic_id => 0 + $topic }, $cb);
    return;
}

sub topic_icons {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('topic_icons', 0, \@args);
    $self->send({ '@type' => 'getForumTopicDefaultIcons' }, $cb);
    return;
}

1;
