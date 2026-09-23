package EV::Telegram::TDLib::Chats;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Chats - chat methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Chats mixin">.

=cut

sub CLONE_SKIP { 1 }


# updates whose payload fields overwrite the same-named cached chat fields;
# two of them also carry the chat's complete position set, which replaces it
my %CHAT_FIELDS = (
    updateChatTitle                      => ['title'],
    updateChatPhoto                      => ['photo'],
    updateChatPermissions                => ['permissions'],
    updateChatLastMessage                => ['last_message'],
    updateChatDraftMessage               => ['draft_message'],
    updateChatReadInbox                  => ['last_read_inbox_message_id', 'unread_count'],
    updateChatReadOutbox                 => ['last_read_outbox_message_id'],
    updateChatUnreadMentionCount         => ['unread_mention_count'],
    updateChatNotificationSettings       => ['notification_settings'],
    updateChatIsMarkedAsUnread           => ['is_marked_as_unread'],
    updateChatBlockList                  => ['block_list'],
    updateChatHasScheduledMessages       => ['has_scheduled_messages'],
    updateChatDefaultDisableNotification => ['default_disable_notification'],
    updateChatActionBar                  => ['action_bar'],
    updateChatTheme                      => ['theme'],
    updateChatAvailableReactions         => ['available_reactions'],
    updateChatPendingJoinRequests        => ['pending_join_requests'],
    updateChatMessageAutoDeleteTime      => ['message_auto_delete_time'],
);

our %UPDATES = (
    updateNewChatJoinRequest    => \&update_join_request,
    updateNewChat      => \&update_new_chat,
    updateChatPosition => \&update_chat_position,
    updateChatAddedToList     => \&update_chat_list,
    updateChatRemovedFromList => \&update_chat_list,
    (map { $_ => \&update_chat_fields } keys %CHAT_FIELDS),
);

sub _chats { $_[0]{cache}{chats} ||= {} }

sub update_new_chat {
    my ($self, $obj) = @_;
    my $chat = $obj->{chat} or return;
    $self->_chats->{ $chat->{id} } = $chat;
    if (my $cb = $self->{on_chat}) { $cb->($chat) }
}

# a chat list is its type plus, for a folder, the folder's id: every folder is
# a chatListFolder, so keying on the type alone let folders overwrite each other
sub position_key {
    my ($list) = @_;
    my $type = $list->{'@type'} // '';
    return $type eq 'chatListFolder'
        ? "$type:" . ($list->{chat_folder_id} // '') : $type;
}

# updateChatPosition carries the one position that changed; order 0 means the
# chat left that list
sub merge_position {
    my ($chat, $pos) = @_;
    my $key = position_key($pos->{list});
    my $positions = $chat->{positions} ||= [];
    @$positions = grep { position_key($_->{list}) ne $key } @$positions;
    push @$positions, $pos unless ($pos->{order} // 0) eq '0';
}

# payload fields the schema marks nullable: TDLib omits a null object
# field from the JSON entirely, so for these an absent key means
# "now null", not "unchanged"
my %NULLABLE = map { $_ => 1 } qw(
    last_message draft_message photo action_bar theme block_list
    pending_join_requests
);

sub update_chat_fields {
    my ($self, $obj) = @_;
    my $fields = $CHAT_FIELDS{ $obj->{'@type'} } or return;
    return unless defined $obj->{chat_id};
    my $chat = $self->_chats->{ $obj->{chat_id} } or return;
    for my $f (@$fields) {
        $chat->{$f} = $obj->{$f} if $NULLABLE{$f} || exists $obj->{$f};
    }
    # updateChatLastMessage and updateChatDraftMessage carry the chat's
    # complete set of positions and are sent instead of updateChatPosition,
    # so a list the chat has left is signalled only by its absence: replace
    $chat->{positions} = [ grep { ($_->{order} // 0) ne '0' } @{ $obj->{positions} } ]
        if ref $obj->{positions} eq 'ARRAY';
}

sub update_chat_position {
    my ($self, $obj) = @_;
    return unless defined $obj->{chat_id};
    my $chat = $self->_chats->{ $obj->{chat_id} } or return;
    merge_position($chat, $obj->{position}) if $obj->{position};
}

# chat_lists is membership, which the schema keeps apart from positions:
# updateNewChat carries it as it stood, usually empty, and these two keep it
# current
sub update_chat_list {
    my ($self, $obj) = @_;
    return unless defined $obj->{chat_id} && $obj->{chat_list};
    my $chat = $self->_chats->{ $obj->{chat_id} } or return;
    my $key = position_key($obj->{chat_list});
    my $lists = $chat->{chat_lists} ||= [];
    @$lists = grep { position_key($_) ne $key } @$lists;
    push @$lists, $obj->{chat_list} if $obj->{'@type'} eq 'updateChatAddedToList';
}

sub chat {
    my ($self, $id) = @_;
    # documented to answer undef for a chat this client has not seen, and
    # `my $c = $td->chat($id) or return` is the idiomatic call, so an undef id
    # answers the same way rather than croaking. Returning early only to keep
    # the lookup from warning from inside the module.
    return undef unless defined $id;
    # keyed as TDLib sends ids, so a padded or signed one -- accepted
    # everywhere else -- is normalised to find the same entry
    $id = 0 + $id if !ref $id && $id =~ /\A\s*[+-]?[0-9]+\s*\z/;
    return $self->_chats->{$id};
}

sub on_chat {
    my ($self, $cb) = @_;
    $self->{on_chat} = $cb if @_ > 1;
    return $self->{on_chat};
}

sub load_chats {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($limit, @rest) = @args;
    my %opt = opts(@rest);
    need('limit', $limit);
    # loadChats is what makes TDLib fetch more of a list, so without this the
    # archive and the folders could never be paged past whatever was cached
    $self->send({ '@type' => 'loadChats', limit => 0 + $limit,
                  chat_list => chat_list($opt{list}) }, sub {
        my ($res, $err) = @_;
        # TDLib answers 404 once the chat list is exhausted; that is the
        # normal end of a load, not a failure
        $err = undef if $err && ($err->{code} // 0) == 404;
        $cb->($res, $err);
    });
    return;
}

sub chat_by_username {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('chat_by_username', 1, \@args);
    my ($name) = @args;
    need('username', $name);
    $name = plain_text('a username', $name);
    $name =~ s/^\@//;
    $self->send({ '@type' => 'searchPublicChat', username => $name }, sub {
        my ($chat, $err) = @_;
        $self->_chats->{ $chat->{id} } = $chat if $chat;
        $cb->($chat, $err);
    });
    return;
}

# TDLib only makes a read stick while the chat is open, so both requests
# are sent as a pair
sub mark_read {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    my $ids = num_list('message_ids', $opt{message_ids} // []);
    if (!@$ids) {
        # not chat($id)->{last_message}{id}: reading through a missing
        # last_message autovivifies it to {} in the cached chat, and the
        # idiomatic `if ($chat->{last_message})` is true for ever after
        my $chat = $self->chat($chat_id);
        my $lm = $chat && $chat->{last_message};
        my $last = ref $lm eq 'HASH' ? $lm->{id} : undef;
        $ids = $last ? [0 + $last] : [];
    }
    if (!@$ids) {
        $cb->(undef, { '@type' => 'error', code => -1,
                       message => 'nothing to mark read in chat ' . $chat_id });
        return;
    }
    # no openChat: an explicit source with force_read is honoured on a closed
    # chat, and opening one writes the chat into the account's recently-opened
    # list, which is persistent and which closeChat does not undo
    $self->send({
        '@type'      => 'viewMessages',
        chat_id      => 0 + $chat_id,
        message_ids  => $ids,
        source       => { '@type' => 'messageSourceChatHistory' },
        force_read   => json_bool(1),
    }, $cb);
    return;
}

my %CHAT_ACTION = (
    typing           => 'chatActionTyping',
    upload_document  => 'chatActionUploadingDocument',
    upload_photo     => 'chatActionUploadingPhoto',
    upload_video     => 'chatActionUploadingVideo',
    upload_voice     => 'chatActionUploadingVoiceNote',
    record_video     => 'chatActionRecordingVideo',
    record_voice     => 'chatActionRecordingVoiceNote',
    cancel           => 'chatActionCancel',
);

sub chat_action {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('chat_action', 2, \@args);
    my ($chat_id, $action) = @args;
    need('chat_id', $chat_id);
    $action = 'typing' unless defined $action;
    my $type = $CHAT_ACTION{$action}
        or croak "unknown chat action '$action'";
    $self->send({ '@type' => 'sendChatAction', chat_id => 0 + $chat_id,
                  action => { '@type' => $type } }, $cb);
    return;
}

sub join_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('join_chat', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'joinChat', chat_id => 0 + $chat_id }, $cb);
    return;
}

sub leave_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('leave_chat', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'leaveChat', chat_id => 0 + $chat_id }, $cb);
    return;
}

sub pin_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({
        '@type'              => 'pinChatMessage',
        chat_id              => 0 + $chat_id,
        message_id           => 0 + $message_id,
        disable_notification => json_bool($opt{silent}),
        only_for_self        => json_bool($opt{only_for_self}),
    }, $cb);
    return;
}

sub unpin_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('unpin_message', 2, \@args);
    my ($chat_id, $message_id) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'unpinChatMessage', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id }, $cb);
    return;
}

sub set_chat_title {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_chat_title', 2, \@args);
    my ($chat_id, $title) = @args;
    # need rather than a length check: a coderef is defined and has a length,
    # so omitting the title renamed the chat to CODE(0x...)
    need('chat_id, title', $chat_id, $title);
    $title = plain_text('a title', $title);
    croak 'set_chat_title needs a title' unless length $title;
    $self->send({ '@type' => 'setChatTitle', chat_id => 0 + $chat_id,
                  title => $title }, $cb);
    return;
}

sub set_chat_photo {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $path, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'setChatPhoto', chat_id => 0 + $chat_id,
                  photo => $self->input_chat_photo($path, \%opt) }, $cb);
    return;
}

sub add_chat_member {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $user_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, user_id', $chat_id, $user_id);
    $self->send({
        '@type'        => 'addChatMember',
        chat_id        => 0 + $chat_id,
        user_id        => 0 + $user_id,
        forward_limit  => num('forward_limit', $opt{forward_limit} // 0),
    }, $cb);
    return;
}

my %MEMBER_STATUS = (
    member  => 'chatMemberStatusMember',
    left    => 'chatMemberStatusLeft',
    banned  => 'chatMemberStatusBanned',
);

# 'banned' removes and blocks; 'left' is the plain kick that lets them back
sub set_member_status {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $user_id, $status, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, user_id', $chat_id, $user_id);
    my $type = $MEMBER_STATUS{ $status // '' }
        or croak "unknown member status '" . ($status // '') . "'";
    my %st = ('@type' => $type);
    $st{banned_until_date} = unix_time('until', $opt{until} // 0) if $status eq 'banned';
    $st{member_until_date} = unix_time('until', $opt{until} // 0) if $status eq 'member';
    $self->send({
        '@type'    => 'setChatMemberStatus',
        chat_id    => 0 + $chat_id,
        member_id  => { '@type' => 'messageSenderUser', user_id => 0 + $user_id },
        status     => \%st,
    }, $cb);
    return;
}

sub block_user {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($user_id, @rest) = @args;
    my %opt = opts(@rest);
    need('user_id', $user_id);
    $self->send({
        '@type'      => 'setMessageSenderBlockList',
        sender_id    => { '@type' => 'messageSenderUser', user_id => 0 + $user_id },
        # an undefined block list is what unblocking is
        block_list   => $opt{unblock} ? undef
                      : { '@type' => $opt{stories} ? 'blockListStories' : 'blockListMain' },
    }, $cb);
    return;
}

sub sender { { '@type' => 'messageSenderUser', user_id => num('user_id', $_[0]) } }

sub member {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('member', 2, \@args);
    my ($chat_id, $user_id) = @args;
    need('chat_id, user_id', $chat_id, $user_id);
    $self->send({ '@type' => 'getChatMember', chat_id => 0 + $chat_id,
                  member_id => sender($user_id) }, $cb);
    return;
}

sub admins {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('admins', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatAdministrators', chat_id => 0 + $chat_id }, $cb);
    return;
}

# spelled out rather than derived: xt/schema_pin.t verifies these against
# td_api.h, and a name built by interpolation is invisible to that check
my %MEMBER_FILTER = (
    contacts       => 'chatMembersFilterContacts',
    administrators => 'chatMembersFilterAdministrators',
    members        => 'chatMembersFilterMembers',
    restricted     => 'chatMembersFilterRestricted',
    banned         => 'chatMembersFilterBanned',
    bots           => 'chatMembersFilterBots',
);

sub search_members {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $query, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    my %req = ('@type' => 'searchChatMembers', chat_id => 0 + $chat_id,
               query => plain_text('a query', $query),
               limit => num('limit', $opt{limit} // 50));
    if (defined $opt{filter}) {
        my $t = $MEMBER_FILTER{ $opt{filter} }
            or croak "unknown member filter '$opt{filter}'";
        $req{filter} = { '@type' => $t };
    }
    $self->send(\%req, $cb);
    return;
}

# every permission chatPermissions defines; the order is the schema's
my @PERMISSIONS = qw(
    can_send_basic_messages can_send_audios can_send_documents can_send_photos
    can_send_videos can_send_video_notes can_send_voice_notes can_send_polls
    can_send_other_messages can_add_link_previews can_react_to_messages
    can_edit_tag can_change_info can_invite_users can_pin_messages
    can_create_topics
);
my %PERMISSION = map { $_ => 1 } @PERMISSIONS;

# TDLib replaces the whole set, so anything absent is denied. An unknown key
# is refused rather than ignored: a typo would silently take a right away.
sub set_permissions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_permissions', 2, \@args);
    my ($chat_id, $perms) = @args;
    need('chat_id, permissions', $chat_id, $perms);
    croak 'set_permissions needs a hashref of permissions' unless ref $perms eq 'HASH';
    if (my @bad = sort grep { !$PERMISSION{$_} } keys %$perms) {
        croak "unknown permission(s): @bad";
    }
    $self->send({
        '@type'      => 'setChatPermissions',
        chat_id      => 0 + $chat_id,
        permissions  => { '@type' => 'chatPermissions',
                          map { $_ => json_bool($perms->{$_}) } @PERMISSIONS },
    }, $cb);
    return;
}

sub set_chat_description {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_chat_description', 2, \@args);
    my ($chat_id, $text) = @args;
    need('chat_id', $chat_id);
    croak 'set_chat_description needs a description; pass the empty string '
        . 'to clear it' unless @args >= 2;
    $self->send({ '@type' => 'setChatDescription', chat_id => 0 + $chat_id,
                  description => plain_text('a description', $text) }, $cb);
    return;
}

sub invite_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({
        '@type'                => 'createChatInviteLink',
        chat_id                => 0 + $chat_id,
        name                   => plain_text('an invite link name', $opt{name}),
        expiration_date        => unix_time('expires', $opt{expires} // 0),
        member_limit           => num('limit', $opt{limit} // 0),
        creates_join_request   => json_bool($opt{join_request}),
    }, $cb);
    return;
}

sub edit_invite_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $link, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, invite_link', $chat_id, $link);
    $self->send({
        '@type'                => 'editChatInviteLink',
        chat_id                => 0 + $chat_id,
        invite_link            => plain_text('an invite link', $link),
        name                   => plain_text('an invite link name', $opt{name}),
        expiration_date        => unix_time('expires', $opt{expires} // 0),
        member_limit           => num('limit', $opt{limit} // 0),
        creates_join_request   => json_bool($opt{join_request}),
    }, $cb);
    return;
}

sub invite_links {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({
        '@type'              => 'getChatInviteLinks',
        chat_id              => 0 + $chat_id,
        creator_user_id      => num('creator', $opt{creator} // 0),
        is_revoked           => json_bool($opt{revoked}),
        offset_date          => unix_time('offset_date', $opt{offset_date} // 0),
        offset_invite_link   => plain_text('an invite link', $opt{offset_link}),
        limit                => num('limit', $opt{limit} // 100),
    }, $cb);
    return;
}

sub revoke_invite_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('revoke_invite_link', 2, \@args);
    my ($chat_id, $link) = @args;
    need('chat_id, invite_link', $chat_id, $link);
    $self->send({ '@type' => 'revokeChatInviteLink', chat_id => 0 + $chat_id,
                  invite_link => plain_text('an invite link', $link) }, $cb);
    return;
}

sub replace_primary_invite_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('replace_primary_invite_link', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'replacePrimaryChatInviteLink',
                  chat_id => 0 + $chat_id }, $cb);
    return;
}

sub invite_link_members {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $link, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, invite_link', $chat_id, $link);
    $self->send({
        '@type'                          => 'getChatInviteLinkMembers',
        chat_id                          => 0 + $chat_id,
        invite_link                      => plain_text('an invite link', $link),
        only_with_expired_subscription   => json_bool($opt{expired_only}),
        (defined $opt{offset_member}
            ? (offset_member => $opt{offset_member}) : ()),
        limit                            => num('limit', $opt{limit} // 100),
    }, $cb);
    return;
}

# these two take only the link: the chat is whatever the link points at
sub check_invite_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('check_invite_link', 1, \@args);
    my ($link) = @args;
    need('invite_link', $link);
    $self->send({ '@type' => 'checkChatInviteLink',
                  invite_link => plain_text('an invite link', $link) }, $cb);
    return;
}

sub join_by_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('join_by_link', 1, \@args);
    my ($link) = @args;
    need('invite_link', $link);
    $self->send({ '@type' => 'joinChatByInviteLink',
                  invite_link => plain_text('an invite link', $link) }, $cb);
    return;
}

my %CHAT_LIST = (
    main    => 'chatListMain',
    archive => 'chatListArchive',
);

# a chat list is either of the two built-in ones or a folder by id
sub chat_list {
    my ($which) = @_;
    $which = 'main' unless defined $which;
    return { '@type' => 'chatListFolder', chat_folder_id => 0 + $which }
        if $which =~ /\A\s*[0-9]+\s*\z/;
    my $t = $CHAT_LIST{$which} or croak "unknown chat list '$which'";
    return { '@type' => $t };
}

# TDLib rebuilds every notification setting from the request, so muting sends
# the chat's cached settings back with only the mute changed, or its own sound
# and preview choices would be reset to the defaults
sub mute {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('mute', 2, \@args);
    my ($chat_id, $seconds) = @args;
    need('chat_id', $chat_id);
    my $chat = $self->chat($chat_id);
    my $cur = $chat && ref $chat->{notification_settings} eq 'HASH'
            ? $chat->{notification_settings} : undef;
    my %settings = $cur ? %$cur : (map { $_ => json_bool(1) } qw(
        use_default_sound use_default_show_preview
        use_default_mute_stories use_default_story_sound
        use_default_show_story_poster
        use_default_disable_pinned_message_notifications
        use_default_disable_mention_notifications));
    $self->send({
        '@type'  => 'setChatNotificationSettings',
        chat_id  => 0 + $chat_id,
        notification_settings => {
            %settings,
            '@type'               => 'chatNotificationSettings',
            use_default_mute_for  => json_bool(0),
            mute_for              => num('seconds', $seconds // 2147483647),
        },
    }, $cb);
    return;
}

sub unmute {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('unmute', 1, \@args);
    $self->mute($args[0], 0, $cb);
    return;
}

sub archive {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('archive', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'addChatToList', chat_id => 0 + $chat_id,
                  chat_list => chat_list('archive') }, $cb);
    return;
}

sub unarchive {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('unarchive', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'addChatToList', chat_id => 0 + $chat_id,
                  chat_list => chat_list('main') }, $cb);
    return;
}

sub pin_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $pinned, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'toggleChatIsPinned', chat_id => 0 + $chat_id,
                  chat_list => chat_list($opt{list}),
                  is_pinned => json_bool(defined $pinned ? $pinned : 1) }, $cb);
    return;
}

sub mark_unread {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $unread, @rest) = @args;
    no_opts('mark_unread', @rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'toggleChatIsMarkedAsUnread', chat_id => 0 + $chat_id,
                  is_marked_as_unread =>
                      json_bool(defined $unread ? $unread : 1) }, $cb);
    return;
}

sub chats {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my (@rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'getChats', chat_list => chat_list($opt{list}),
                  limit => num('limit', $opt{limit} // 100) }, $cb);
    return;
}

# the global counterpart of search_messages, which searches one chat
sub search_all {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($query, @rest) = @args;
    my %opt = opts(@rest);
    need('query', $query);
    # a null list is every chat; TDLib takes only main or archive otherwise
    croak "search_all takes list => 'main' or 'archive'; TDLib cannot search "
        . "a folder" if defined $opt{list}
                     && $opt{list} ne 'main' && $opt{list} ne 'archive';
    $self->send({
        '@type'    => 'searchMessages',
        chat_list  => defined $opt{list} ? chat_list($opt{list}) : undef,
        query      => plain_text('a query', $query),
        offset     => plain_text('an offset', $opt{offset}),
        limit      => num('limit', $opt{limit} // 50),
        min_date   => unix_time('min_date', $opt{min_date} // 0),
        max_date   => unix_time('max_date', $opt{max_date} // 0),
    }, $cb);
    return;
}

my %SCOPE = (
    private  => 'notificationSettingsScopePrivateChats',
    groups   => 'notificationSettingsScopeGroupChats',
    channels => 'notificationSettingsScopeChannelChats',
);

sub scope {
    my ($which) = @_;
    my $t = $SCOPE{ $which // '' } or croak "unknown notification scope '"
        . ($which // '') . "'";
    return { '@type' => $t };
}

# all nine fields are sent outright. use_default_mute_stories is not a
# keep-what-was-there flag: it asks TDLib for story notifications from the
# top contacts only, whatever mute_stories says, so it is sent exactly when
# the caller did not choose for itself
sub mute_scope {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($scope, $seconds, @rest) = @args;
    my %opt = opts(@rest);
    need('scope', $scope);
    $self->send({
        '@type' => 'setScopeNotificationSettings',
        scope   => scope($scope),
        notification_settings => {
            '@type'        => 'scopeNotificationSettings',
            mute_for       => num('seconds', $seconds // 2147483647),
            # -1, not 0: the TL says 0 disables the sound and -1 asks for the
            # app default, so defaulting to 0 silenced the scope for anyone
            # who only wanted to mute for a while
            sound_id       => plain_text('a sound id', $opt{sound_id} // -1),
            # show_preview is what the field is called here and in
            # set_reaction_notifications; preview was the original spelling and
            # still works, so neither name is silently ignored
            show_preview   => json_bool(exists $opt{show_preview} ? $opt{show_preview}
                                       : exists $opt{preview}      ? $opt{preview} : 1),
            use_default_mute_stories => json_bool(!exists $opt{mute_stories}),
            mute_stories   => json_bool($opt{mute_stories}),
            story_sound_id => plain_text('a sound id', $opt{story_sound_id} // -1),
            show_story_poster =>
                json_bool(exists $opt{show_story_poster} ? $opt{show_story_poster} : 1),
            disable_pinned_message_notifications => json_bool($opt{no_pinned}),
            disable_mention_notifications        => json_bool($opt{no_mentions}),
        },
    }, $cb);
    return;
}

sub scope_settings {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('scope_settings', 1, \@args);
    my ($scope) = @args;
    need('scope', $scope);
    $self->send({ '@type' => 'getScopeNotificationSettings',
                  scope => scope($scope) }, $cb);
    return;
}

sub reset_notifications {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('reset_notifications', 0, \@args);
    $self->send({ '@type' => 'resetAllNotificationSettings' }, $cb);
    return;
}

# 'all' allows every reaction the chat's tier permits; an arrayref names them
sub set_chat_reactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $reactions, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, reactions', $chat_id, $reactions);
    my $avail;
    if (ref $reactions eq 'ARRAY') {
        $avail = {
            '@type'    => 'chatAvailableReactionsSome',
            reactions  => [ map { $self->reaction_type($_) } @$reactions ],
            max_reaction_count => num('max', $opt{max} // 11),
        };
    }
    elsif ($reactions eq 'all') {
        $avail = { '@type' => 'chatAvailableReactionsAll',
                   max_reaction_count => num('max', $opt{max} // 11) };
    }
    else { croak "set_chat_reactions takes 'all' or an arrayref of emoji" }
    $self->send({ '@type' => 'setChatAvailableReactions',
                  chat_id => 0 + $chat_id, available_reactions => $avail }, $cb);
    return;
}

sub read_all_reactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('read_all_reactions', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'readAllChatReactions',
                  chat_id => 0 + $chat_id }, $cb);
    return;
}

my %REACTION_SOURCE = (none     => 'reactionNotificationSourceNone',
                       contacts => 'reactionNotificationSourceContacts',
                       all      => 'reactionNotificationSourceAll');

sub reaction_source {
    my ($which, $v) = @_;
    need($which, $v);
    my $t = $REACTION_SOURCE{$v}
        or croak "$which must be 'none', 'contacts' or 'all'";
    return { '@type' => $t };
}

# TDLib offers no getter: the current value arrives only through
# updateReactionNotificationSettings, so every field must be given or this
# would silently clear whatever it did not mention.
sub set_reaction_notifications {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    # all five, as documented: TDLib replaces the whole object and offers no
    # getter, so a field left out is a field silently cleared. The three
    # sources croaked already; these two defaulted, and show_preview
    # defaulting to false turned previews off for anyone who omitted it.
    need('sound_id, show_preview', @opt{qw(sound_id show_preview)});
    $self->send({
        '@type' => 'setReactionNotificationSettings',
        notification_settings => {
            '@type' => 'reactionNotificationSettings',
            message_reaction_source =>
                reaction_source('message_reaction_source', $opt{message_reaction_source}),
            story_reaction_source =>
                reaction_source('story_reaction_source', $opt{story_reaction_source}),
            poll_vote_source =>
                reaction_source('poll_vote_source', $opt{poll_vote_source}),
            sound_id     => plain_text('a sound id', $opt{sound_id} // 0),
            show_preview => json_bool($opt{show_preview}),
        },
    }, $cb);
    return;
}

sub blocked {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my (@rest) = @args;
    my %opt = opts(@rest);
    $self->send({
        '@type'      => 'getBlockedMessageSenders',
        block_list   => { '@type' => ($opt{stories} ? 'blockListStories'
                                                    : 'blockListMain') },
        offset       => num('offset', $opt{offset} // 0),
        limit        => num('limit', $opt{limit} // 100),
    }, $cb);
    return;
}

sub join_requests {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({
        '@type'          => 'getChatJoinRequests',
        chat_id          => 0 + $chat_id,
        invite_link      => plain_text('an invite link', $opt{link}),
        query            => plain_text('a query', $opt{query}),
        (defined $opt{offset_request}
            ? (offset_request => $opt{offset_request}) : ()),
        limit            => num('limit', $opt{limit} // 100),
    }, $cb);
    return;
}

sub process_join_request {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $user_id, $approve, @rest) = @args;
    no_opts('process_join_request', @rest);
    need('chat_id, user_id', $chat_id, $user_id);
    $self->send({ '@type' => 'processChatJoinRequest', chat_id => 0 + $chat_id,
                  user_id => 0 + $user_id,
                  approve => json_bool(defined $approve ? $approve : 1) }, $cb);
    return;
}

# approves or declines everyone at once, optionally only those from one link
sub process_join_requests {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $approve, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'processChatJoinRequests', chat_id => 0 + $chat_id,
                  invite_link => plain_text('an invite link', $opt{link}),
                  approve => json_bool(defined $approve ? $approve : 1) }, $cb);
    return;
}

sub on_join_request {
    my ($self, $cb) = @_;
    $self->{on_join_request} = $cb if @_ > 1;
    return $self->{on_join_request};
}

sub update_join_request {
    my ($self, $obj) = @_;
    my $cb = $self->{on_join_request} or return;
    my $r = $obj->{request} || {};
    $cb->({
        chat_id       => $obj->{chat_id},
        user_id       => $r->{user_id},
        date          => $r->{date},
        bio           => $r->{bio},
        invite_link   => $obj->{invite_link},
        user_chat_id  => $obj->{user_chat_id},
    });
}

# A supergroup's chat id is -1000000000000 minus its supergroup id, and the
# supergroup_* methods want the latter. Everything else in this module takes a
# chat id, so accept either and convert rather than let the mismatch surface as
# an unhelpful server error.
sub supergroup_id {
    my ($id) = @_;
    return 0 + $id unless $id < 0;
    return -1000000000000 - $id;
}

# A basic group's chat id is its group id negated, with no offset: DialogId
# builds one as -chat_id and reads it back as ChatId(-id). Same reasoning as
# supergroup_id -- take either rather than send a negative id TDLib rejects.
sub basic_group_id {
    my ($id) = @_;
    return $id < 0 ? -$id : 0 + $id;
}

sub add_members {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('add_members', 2, \@args);
    my ($chat_id, $user_ids) = @args;
    need('chat_id, user_ids', $chat_id, $user_ids);
    croak 'add_members needs an arrayref of user ids' unless ref $user_ids eq 'ARRAY';
    $self->send({ '@type' => 'addChatMembers', chat_id => 0 + $chat_id,
                  user_ids => num_list('user_ids', $user_ids) }, $cb);
    return;
}

# revoke also deletes what they already sent, which set_member_status does
# not; TDLib passes it on for a basic group only
sub ban_member {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $user_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, user_id', $chat_id, $user_id);
    $self->send({ '@type' => 'banChatMember', chat_id => 0 + $chat_id,
                  member_id => sender($user_id),
                  banned_until_date => unix_time('until', $opt{until} // 0),
                  revoke_messages => json_bool($opt{revoke}) }, $cb);
    return;
}

sub transfer_ownership {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('transfer_ownership', 3, \@args);
    my ($chat_id, $user_id, $password) = @args;
    need('chat_id, user_id, password', $chat_id, $user_id, $password);
    $self->send({ '@type' => 'transferChatOwnership',
                  chat_id => num('chat_id', $chat_id),
                  user_id => num('user_id', $user_id),
                  password => plain_text('a password', $password) }, $cb);
    return;
}

sub set_default_admin_rights {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($rights, @rest) = @args;
    my %opt = opts(@rest);
    need('rights', $rights);
    croak 'set_default_admin_rights needs a chatAdministratorRights hashref'
        unless ref $rights eq 'HASH';
    my $channel = $opt{channel} ? 1 : 0;
    $self->send($channel
        ? { '@type' => 'setDefaultChannelAdministratorRights',
            default_channel_administrator_rights => $rights }
        : { '@type' => 'setDefaultGroupAdministratorRights',
            default_group_administrator_rights => $rights }, $cb);
    return;
}

sub create_group {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($title, @rest) = @args;
    my %opt = opts(@rest);
    need('title', $title);
    # a basic group needs its members up front; a supergroup is created empty
    if ($opt{members}) {
        croak 'members must be an arrayref' unless ref $opt{members} eq 'ARRAY';
        $self->send({ '@type' => 'createNewBasicGroupChat',
                      user_ids => num_list('members', $opt{members}),
                      title => plain_text('a title', $title),
                      message_auto_delete_time =>
                          num('auto_delete', $opt{auto_delete} // 0) }, $cb);
        return;
    }
    $self->send({
        '@type'                   => 'createNewSupergroupChat',
        title                     => plain_text('a title', $title),
        is_forum                  => json_bool($opt{forum}),
        is_channel                => json_bool($opt{channel}),
        description               => plain_text('a description', $opt{description}),
        message_auto_delete_time  => num('auto_delete', $opt{auto_delete} // 0),
        for_import                => json_bool($opt{for_import}),
    }, $cb);
    return;
}

sub upgrade_to_supergroup {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('upgrade_to_supergroup', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'upgradeBasicGroupChatToSupergroupChat',
                  chat_id => 0 + $chat_id }, $cb);
    return;
}

sub delete_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_chat', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'deleteChat', chat_id => 0 + $chat_id }, $cb);
    return;
}

# revoke deletes the history for everyone, not only for us
sub delete_history {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'deleteChatHistory', chat_id => 0 + $chat_id,
                  remove_from_chat_list => json_bool($opt{remove_from_list}),
                  revoke => json_bool($opt{revoke}) }, $cb);
    return;
}

sub set_slow_mode {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_slow_mode', 2, \@args);
    my ($chat_id, $seconds) = @args;
    need('chat_id', $chat_id);
    croak 'set_slow_mode needs a delay in seconds; pass 0 to turn slow mode off'
        unless defined $seconds;
    $self->send({ '@type' => 'setChatSlowModeDelay', chat_id => 0 + $chat_id,
                  slow_mode_delay => num('seconds', $seconds) }, $cb);
    return;
}

sub set_auto_delete {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_auto_delete', 2, \@args);
    my ($chat_id, $seconds) = @args;
    need('chat_id', $chat_id);
    croak 'set_auto_delete needs a time in seconds; pass 0 to turn auto-delete off'
        unless defined $seconds;
    $self->send({ '@type' => 'setChatMessageAutoDeleteTime', chat_id => 0 + $chat_id,
                  message_auto_delete_time => num('seconds', $seconds) }, $cb);
    return;
}

sub set_discussion_group {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_discussion_group', 2, \@args);
    my ($chat_id, $discussion) = @args;
    need('chat_id', $chat_id);
    croak 'set_discussion_group needs a chat id; pass 0 to remove the discussion group'
        unless defined $discussion;
    $self->send({ '@type' => 'setChatDiscussionGroup', chat_id => 0 + $chat_id,
                  discussion_chat_id => num('discussion_chat_id', $discussion) }, $cb);
    return;
}

sub protect_content {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $on, @rest) = @args;
    no_opts('protect_content', @rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'toggleChatHasProtectedContent', chat_id => 0 + $chat_id,
                  has_protected_content =>
                      json_bool(defined $on ? $on : 1) }, $cb);
    return;
}

# --- supergroup switches. These take a supergroup id, but accept a chat id too.
sub make_forum {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $on, @rest) = @args;
    my %opt = opts(@rest);
    need('supergroup_id', $id);
    $self->send({ '@type' => 'toggleSupergroupIsForum',
                  supergroup_id => supergroup_id($id),
                  is_forum       => json_bool(defined $on ? $on : 1),
                  has_forum_tabs => json_bool($opt{tabs}) }, $cb);
    return;
}

sub sign_messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $on, @rest) = @args;
    my %opt = opts(@rest);
    need('supergroup_id', $id);
    $self->send({ '@type' => 'toggleSupergroupSignMessages',
                  supergroup_id => supergroup_id($id),
                  sign_messages => json_bool(defined $on ? $on : 1),
                  show_message_sender => json_bool($opt{show_sender}) }, $cb);
    return;
}

sub join_by_request {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $on, @rest) = @args;
    my %opt = opts(@rest);
    need('supergroup_id', $id);
    $self->send({ '@type' => 'toggleSupergroupJoinByRequest',
                  supergroup_id  => supergroup_id($id),
                  join_by_request => json_bool(defined $on ? $on : 1),
                  guard_bot_user_id => num('guard_bot', $opt{guard_bot} // 0),
                  apply_to_invite_links => json_bool($opt{apply_to_links}) }, $cb);
    return;
}

sub join_to_send {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $on, @rest) = @args;
    no_opts('join_to_send', @rest);
    need('supergroup_id', $id);
    $self->send({ '@type' => 'toggleSupergroupJoinToSendMessages',
                  supergroup_id => supergroup_id($id),
                  join_to_send_messages =>
                      json_bool(defined $on ? $on : 1) }, $cb);
    return;
}

sub all_history_available {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $on, @rest) = @args;
    no_opts('all_history_available', @rest);
    need('supergroup_id', $id);
    $self->send({ '@type' => 'toggleSupergroupIsAllHistoryAvailable',
                  supergroup_id => supergroup_id($id),
                  is_all_history_available =>
                      json_bool(defined $on ? $on : 1) }, $cb);
    return;
}

sub hide_members {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $on, @rest) = @args;
    no_opts('hide_members', @rest);
    need('supergroup_id', $id);
    $self->send({ '@type' => 'toggleSupergroupHasHiddenMembers',
                  supergroup_id => supergroup_id($id),
                  has_hidden_members =>
                      json_bool(defined $on ? $on : 1) }, $cb);
    return;
}

sub set_supergroup_username {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_supergroup_username', 2, \@args);
    my ($id, $username) = @args;
    need('supergroup_id', $id);
    croak 'set_supergroup_username needs a username; pass the empty string '
        . 'to remove it' unless @args >= 2;
    $self->send({ '@type' => 'setSupergroupUsername',
                  supergroup_id => supergroup_id($id),
                  username => plain_text('a username', $username) }, $cb);
    return;
}

# chat() reads the module's cache; this asks TDLib, which also loads a chat
# the client has not seen yet
sub fetch_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('fetch_chat', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChat', chat_id => 0 + $chat_id }, $cb);
    return;
}

# balances an openChat sent by hand; TDLib never unloads an open chat
sub close_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('close_chat', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'closeChat', chat_id => 0 + $chat_id }, $cb);
    return;
}

sub user_full_info {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('user_full_info', 1, \@args);
    my ($user_id) = @args;
    need('user_id', $user_id);
    $self->send({ '@type' => 'getUserFullInfo', user_id => 0 + $user_id }, $cb);
    return;
}

# takes a chat id or a supergroup id; full => 1 asks for the fuller record
sub supergroup {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, @rest) = @args;
    my %opt = opts(@rest);
    need('supergroup_id', $id);
    $self->send({ '@type' => $opt{full} ? 'getSupergroupFullInfo' : 'getSupergroup',
                  supergroup_id => supergroup_id($id) }, $cb);
    return;
}

sub basic_group {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, @rest) = @args;
    my %opt = opts(@rest);
    need('basic_group_id', $id);
    $self->send({ '@type' => $opt{full} ? 'getBasicGroupFullInfo' : 'getBasicGroup',
                  basic_group_id => basic_group_id($id) }, $cb);
    return;
}

my %SUPERGROUP_FILTER = (
    recent         => 'supergroupMembersFilterRecent',
    contacts       => 'supergroupMembersFilterContacts',
    administrators => 'supergroupMembersFilterAdministrators',
    restricted     => 'supergroupMembersFilterRestricted',
    banned         => 'supergroupMembersFilterBanned',
    bots           => 'supergroupMembersFilterBots',
);

sub supergroup_members {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, @rest) = @args;
    my %opt = opts(@rest);
    need('supergroup_id', $id);
    my %req = ('@type' => 'getSupergroupMembers',
               supergroup_id => supergroup_id($id),
               offset => num('offset', $opt{offset} // 0),
               limit  => num('limit', $opt{limit} // 200));
    if (defined $opt{filter}) {
        my $t = $SUPERGROUP_FILTER{ $opt{filter} }
            or croak "unknown supergroup member filter '$opt{filter}'";
        $req{filter} = { '@type' => $t };
    }
    $self->send(\%req, $cb);
    return;
}

sub groups_in_common {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($user_id, @rest) = @args;
    my %opt = opts(@rest);
    need('user_id', $user_id);
    $self->send({ '@type' => 'getGroupsInCommon', user_id => 0 + $user_id,
                  offset_chat_id => num('offset_chat_id', $opt{offset_chat_id} // 0),
                  limit => num('limit', $opt{limit} // 100) }, $cb);
    return;
}

sub chat_event_log {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({
        '@type'        => 'getChatEventLog',
        chat_id        => 0 + $chat_id,
        query          => plain_text('a query', $opt{query}),
        from_event_id  => plain_text('an event id', $opt{from_event_id} // 0),
        limit          => num('limit', $opt{limit} // 100),
        user_ids       => num_list('users', $opt{users} // []),
    }, $cb);
    return;
}

sub chat_statistics {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatStatistics', chat_id => 0 + $chat_id,
                  is_dark => json_bool($opt{dark}) }, $cb);
    return;
}

sub pinned_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('pinned_message', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatPinnedMessage', chat_id => 0 + $chat_id }, $cb);
    return;
}

sub clear_action_bar {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('clear_action_bar', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'removeChatActionBar', chat_id => 0 + $chat_id }, $cb);
    return;
}

# which identities may post here, and which one to post as: a channel admin
# can speak as the channel rather than as themselves
sub message_senders {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('message_senders', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatAvailableMessageSenders',
                  chat_id => 0 + $chat_id }, $cb);
    return;
}

sub set_message_sender {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_message_sender', 2, \@args);
    my ($chat_id, $sender_id) = @args;
    need('chat_id, sender_id', $chat_id, $sender_id);
    $self->send({ '@type' => 'setChatMessageSender', chat_id => 0 + $chat_id,
                  message_sender_id => $self->message_sender($sender_id) }, $cb);
    return;
}


my %TOP_CATEGORY = (
    users        => 'topChatCategoryUsers',
    bots         => 'topChatCategoryBots',
    groups       => 'topChatCategoryGroups',
    channels     => 'topChatCategoryChannels',
    inline_bots  => 'topChatCategoryInlineBots',
    calls        => 'topChatCategoryCalls',
    forwards     => 'topChatCategoryForwardChats',
);

# searches chats this account knows; search_public_chats reaches the directory
sub search_chats {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($query, @rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'searchChats',
                  query => plain_text('a query', $query),
                  limit => num('limit', $opt{limit} // 50) }, $cb);
    return;
}

sub search_public_chats {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('search_public_chats', 1, \@args);
    my ($query) = @args;
    need('query', $query);
    $self->send({ '@type' => 'searchPublicChats',
                  query => plain_text('a query', $query) }, $cb);
    return;
}

sub top_chats {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($category, @rest) = @args;
    my %opt = opts(@rest);
    my $t = $TOP_CATEGORY{ $category // 'users' }
        or croak "unknown top chat category '" . ($category // '') . "'";
    $self->send({ '@type' => 'getTopChats', category => { '@type' => $t },
                  limit => num('limit', $opt{limit} // 30) }, $cb);
    return;
}

sub recommended_chats {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('recommended_chats', 0, \@args);
    $self->send({ '@type' => 'getRecommendedChats' }, $cb);
    return;
}

sub recently_opened_chats {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my (@rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'getRecentlyOpenedChats',
                  limit => num('limit', $opt{limit} // 30) }, $cb);
    return;
}

sub check_chat_username {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('check_chat_username', 2, \@args);
    my ($chat_id, $username) = @args;
    need('chat_id, username', $chat_id, $username);
    $self->send({ '@type' => 'checkChatUsername', chat_id => 0 + $chat_id,
                  username => plain_text('a username', $username) }, $cb);
    return;
}

sub report_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'reportChat', chat_id => 0 + $chat_id,
                  option_id => plain_text('a report option id', $opt{option_id}),
                  message_ids => num_list('messages', $opt{messages} // []),
                  text => plain_text('the report text', $opt{text}) }, $cb);
    return;
}

sub default_disable_notification {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $on, @rest) = @args;
    no_opts('default_disable_notification', @rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'toggleChatDefaultDisableNotification',
                  chat_id => 0 + $chat_id,
                  default_disable_notification =>
                      json_bool(defined $on ? $on : 1) }, $cb);
    return;
}

1;
