package EV::Telegram::TDLib::Business;

use strict;
use warnings;
use Carp qw(croak);
use overload ();

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Business - Telegram Business methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Business mixin">.

=cut

sub CLONE_SKIP { 1 }


# A business_connection_id arrives only through updateBusinessConnection, so
# without these handlers every method that takes one would be unreachable.
# edited and deleted business messages, and the quick-reply updates, carry no
# hook of their own and reach on_update like any other unhandled type
our %UPDATES = (
    updateBusinessConnection => \&update_connection,
    updateNewBusinessMessage => \&update_new_business_message,
);

sub update_connection {
    my ($self, $obj) = @_;
    if (my $cb = $self->{on_business_connection}) { $cb->($obj->{connection}) }
}

sub update_new_business_message {
    my ($self, $obj) = @_;
    if (my $cb = $self->{on_business_message}) {
        $cb->({ connection_id => $obj->{connection_id},
                message => $obj->{message} });
    }
}

sub on_business_connection {
    my ($self, $cb) = @_;
    $self->{on_business_connection} = $cb if @_ > 1;
    return $self->{on_business_connection};
}

sub on_business_message {
    my ($self, $cb) = @_;
    $self->{on_business_message} = $cb if @_ > 1;
    return $self->{on_business_message};
}

my @BOT_RIGHTS = qw(can_reply can_read_messages can_delete_sent_messages
                    can_delete_all_messages can_edit_name can_edit_bio
                    can_edit_profile_photo can_edit_username
                    can_view_gifts_and_stars can_sell_gifts
                    can_change_gift_settings can_transfer_and_upgrade_gifts
                    can_transfer_stars can_manage_stories);

my @RECIPIENT_FLAGS = qw(select_existing_chats select_new_chats select_contacts
                         select_non_contacts exclude_selected);

sub bot_rights {
    my ($r) = @_;
    $r ||= {};
    croak 'rights must be a hashref' unless ref $r eq 'HASH';
    for my $k (keys %$r) {
        croak "unknown bot right '$k'" unless grep { $_ eq $k } @BOT_RIGHTS;
    }
    return { '@type' => 'businessBotRights',
             map { $_ => json_bool($r->{$_}) } @BOT_RIGHTS };
}

sub recipients {
    my ($r) = @_;
    $r ||= {};
    croak 'recipients must be a hashref' unless ref $r eq 'HASH';
    for my $k (keys %$r) {
        next if $k eq 'chat_ids' || $k eq 'excluded_chat_ids';
        croak "unknown recipient option '$k'"
            unless grep { $_ eq $k } @RECIPIENT_FLAGS;
    }
    return {
        '@type'            => 'businessRecipients',
        chat_ids           => num_list('chat_ids', $r->{chat_ids} // []),
        excluded_chat_ids  => num_list('excluded_chat_ids',
                                       $r->{excluded_chat_ids} // []),
        map { $_ => json_bool($r->{$_}) } @RECIPIENT_FLAGS,
    };
}

sub away_schedule {
    my ($s) = @_;
    $s = 'always' unless defined $s;
    return $s if ref $s eq 'HASH' && $s->{'@type'};
    if (ref $s eq 'HASH') {
        need('schedule start, schedule end', @{$s}{qw(start end)});
        return { '@type' => 'businessAwayMessageScheduleCustom',
                 start_date => unix_time('schedule start', $s->{start}),
                 end_date   => unix_time('schedule end', $s->{end}) };
    }
    return { '@type' => 'businessAwayMessageScheduleAlways' }
        if $s eq 'always';
    return { '@type' => 'businessAwayMessageScheduleOutsideOfOpeningHours' }
        if $s eq 'outside_opening_hours';
    croak "away message schedule must be 'always', 'outside_opening_hours' "
        . "or { start => ..., end => ... }";
}

# --- connections and connected bots

sub business_connection {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('business_connection', 1, \@args);
    my ($id) = @args;
    need('connection_id', $id);
    $self->send({ '@type' => 'getBusinessConnection',
                  connection_id =>
                      plain_text('a business connection id', $id) }, $cb);
    return;
}

sub connected_bot {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('connected_bot', 0, \@args);
    $self->send({ '@type' => 'getBusinessConnectedBot' }, $cb);
    return;
}

sub set_connected_bot {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot_user_id, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id', $bot_user_id);
    $self->send({
        '@type' => 'setBusinessConnectedBot',
        bot => { '@type'      => 'businessConnectedBot',
                 bot_user_id  => 0 + $bot_user_id,
                 recipients   => recipients($opt{recipients}),
                 rights       => bot_rights($opt{rights}) },
    }, $cb);
    return;
}

sub confirm_connected_bot {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('confirm_connected_bot', 1, \@args);
    my ($bot_user_id) = @args;
    need('bot_user_id', $bot_user_id);
    $self->send({ '@type' => 'confirmBusinessConnectedBot',
                  bot_user_id => 0 + $bot_user_id }, $cb);
    return;
}

sub delete_connected_bot {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_connected_bot', 1, \@args);
    my ($bot_user_id) = @args;
    need('bot_user_id', $bot_user_id);
    $self->send({ '@type' => 'deleteBusinessConnectedBot',
                  bot_user_id => 0 + $bot_user_id }, $cb);
    return;
}

sub pause_connected_bot {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $paused, @rest) = @args;
    no_opts('pause_connected_bot', @rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'toggleBusinessConnectedBotChatIsPaused',
                  chat_id => 0 + $chat_id,
                  is_paused => json_bool(defined $paused ? $paused : 1) }, $cb);
    return;
}

sub remove_connected_bot_from_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('remove_connected_bot_from_chat', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'removeBusinessConnectedBotFromChat',
                  chat_id => 0 + $chat_id }, $cb);
    return;
}

# --- chat links

sub business_chat_links {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('business_chat_links', 0, \@args);
    $self->send({ '@type' => 'getBusinessChatLinks' }, $cb);
    return;
}

# returns undef after failing $cb, like input_text, so a parse failure
# reaches the caller instead of being embedded in the request
sub link_info {
    my ($self, $text, $opt, $cb) = @_;
    my $formatted = $self->format_text($text // '', $opt->{parse_mode});
    if (($formatted->{'@type'} // '') eq 'error') { $cb->(undef, $formatted); return }
    return { '@type' => 'inputBusinessChatLink',
             text  => $formatted,
             title => plain_text('a title', $opt->{title}) };
}

sub create_business_chat_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($text, @rest) = @args;
    my %opt = opts(@rest);
    my $info = $self->link_info($text, \%opt, $cb) or return;
    $self->send({ '@type' => 'createBusinessChatLink', link_info => $info }, $cb);
    return;
}

sub edit_business_chat_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($link, $text, @rest) = @args;
    my %opt = opts(@rest);
    need('link', $link);
    my $info = $self->link_info($text, \%opt, $cb) or return;
    $self->send({ '@type' => 'editBusinessChatLink',
                  link => plain_text('a link', $link),
                  link_info => $info }, $cb);
    return;
}

sub delete_business_chat_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_business_chat_link', 1, \@args);
    my ($link) = @args;
    need('link', $link);
    $self->send({ '@type' => 'deleteBusinessChatLink',
                  link => plain_text('a link', $link) }, $cb);
    return;
}

sub business_chat_link_info {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('business_chat_link_info', 1, \@args);
    my ($name) = @args;
    need('link_name', $name);
    $self->send({ '@type' => 'getBusinessChatLinkInfo',
                  link_name => plain_text('a link name', $name) }, $cb);
    return;
}

# --- account settings

sub set_business_account_name {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_business_account_name', 3, \@args);
    my ($conn, $first, $last) = @args;
    need('business_connection_id, first_name', $conn, $first);
    $self->send({ '@type' => 'setBusinessAccountName',
                  business_connection_id =>
                      plain_text('a business connection id', $conn),
                  first_name => plain_text('a first name', $first),
                  last_name => plain_text('a last name', $last) }, $cb);
    return;
}

sub set_business_account_bio {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_business_account_bio', 2, \@args);
    my ($conn, $bio) = @args;
    need('business_connection_id', $conn);
    croak 'set_business_account_bio needs a bio; pass the empty string to '
        . 'clear it' unless @args >= 2;
    $self->send({ '@type' => 'setBusinessAccountBio',
                  business_connection_id =>
                      plain_text('a business connection id', $conn),
                  bio => plain_text('a bio', $bio) }, $cb);
    return;
}

sub set_business_account_username {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_business_account_username', 2, \@args);
    my ($conn, $username) = @args;
    need('business_connection_id', $conn);
    croak 'set_business_account_username needs a username; pass the empty '
        . 'string to remove it' unless @args >= 2;
    $self->send({ '@type' => 'setBusinessAccountUsername',
                  business_connection_id =>
                      plain_text('a business connection id', $conn),
                  username => plain_text('a username', $username) }, $cb);
    return;
}

sub set_business_account_photo {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($conn, $photo, @rest) = @args;
    my %opt = opts(@rest);
    need('business_connection_id, photo', $conn, $photo);
    my $input = ref $photo eq 'HASH' ? $photo
              : { '@type' => 'inputChatPhotoStatic', photo => input_file($photo) };
    $self->send({ '@type' => 'setBusinessAccountProfilePhoto',
                  business_connection_id =>
                      plain_text('a business connection id', $conn), photo => $input,
                  is_public => json_bool($opt{public}) }, $cb);
    return;
}

sub business_account_star_amount {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('business_account_star_amount', 1, \@args);
    my ($conn) = @args;
    need('business_connection_id', $conn);
    $self->send({ '@type' => 'getBusinessAccountStarAmount',
                  business_connection_id =>
                      plain_text('a business connection id', $conn) }, $cb);
    return;
}

sub set_away_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($shortcut_id, @rest) = @args;
    my %opt = opts(@rest);
    need('shortcut_id', $shortcut_id);
    $self->send({
        '@type' => 'setBusinessAwayMessageSettings',
        away_message_settings => {
            '@type'       => 'businessAwayMessageSettings',
            shortcut_id   => 0 + $shortcut_id,
            recipients    => recipients($opt{recipients}),
            schedule      => away_schedule($opt{schedule}),
            offline_only  => json_bool($opt{offline_only}),
        },
    }, $cb);
    return;
}

sub set_greeting_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($shortcut_id, @rest) = @args;
    my %opt = opts(@rest);
    need('shortcut_id', $shortcut_id);
    my $days = num('inactivity_days', $opt{inactivity_days} // 7);
    # TDLib turns the greeting off for any other value and still reports success
    croak 'inactivity_days must be 7, 14, 21 or 28'
        unless grep { $days == $_ } 7, 14, 21, 28;
    $self->send({
        '@type' => 'setBusinessGreetingMessageSettings',
        greeting_message_settings => {
            '@type'          => 'businessGreetingMessageSettings',
            shortcut_id      => 0 + $shortcut_id,
            recipients       => recipients($opt{recipients}),
            inactivity_days  => $days,
        },
    }, $cb);
    return;
}

# each interval is [start_minute, end_minute] or { start => .., end => .. },
# counted from the start of the week
sub set_opening_hours {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_opening_hours', 2, \@args);
    my ($time_zone, $intervals) = @args;
    need('time_zone_id, intervals', $time_zone, $intervals);
    croak 'intervals must be an arrayref' unless ref $intervals eq 'ARRAY';
    my @out;
    for my $i (@$intervals) {
        my ($start, $end) = ref $i eq 'ARRAY' ? @$i
                          : ref $i eq 'HASH'  ? @{$i}{qw(start end)}
                          : croak 'each interval must be an arrayref or hashref';
        need('interval start, interval end', $start, $end);
        push @out, { '@type' => 'businessOpeningHoursInterval',
                     start_minute => num('interval start', $start),
                     end_minute   => num('interval end', $end) };
    }
    $self->send({
        '@type' => 'setBusinessOpeningHours',
        opening_hours => { '@type' => 'businessOpeningHours',
                           time_zone_id => plain_text('a time zone', $time_zone),
                           opening_hours => \@out },
    }, $cb);
    return;
}

sub set_business_location {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($address, @rest) = @args;
    my %opt = opts(@rest);
    croak 'set_business_location needs both latitude and longitude, or neither'
        if defined $opt{latitude} xor defined $opt{longitude};
    my %loc = ('@type' => 'businessLocation',
               address => plain_text('an address', $address));
    $loc{location} = { '@type' => 'location',
                       latitude => real('latitude', $opt{latitude}),
                       longitude => real('longitude', $opt{longitude}),
                       horizontal_accuracy => real('accuracy', $opt{accuracy} // 0) }
        if defined $opt{latitude} && defined $opt{longitude};
    $self->send({ '@type' => 'setBusinessLocation', location => \%loc }, $cb);
    return;
}

sub set_start_page {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    my %page = ('@type' => 'inputBusinessStartPage',
                title   => plain_text('a title', $opt{title}),
                message => plain_text('a message', $opt{message}));
    $page{sticker} = input_file($opt{sticker}) if defined $opt{sticker};
    $self->send({ '@type' => 'setBusinessStartPage', start_page => \%page }, $cb);
    return;
}

sub business_features {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    my %req = ('@type' => 'getBusinessFeatures');
    my $source = $opt{source};
    croak 'source must be a business feature name or a BusinessFeature hashref'
        if ref $source && ref $source ne 'HASH' && !overload::Method($source, '""');
    $req{source} = ref $source eq 'HASH' ? $source
                 : tl_class('businessFeature', 'BusinessFeature',
                            'business feature', $source)
        if defined $source;
    $self->send(\%req, $cb);
    return;
}

# --- messaging as a connected business account
#
# sendBusinessMessage takes disable_notification, protect_content and
# effect_id as flat fields and has no messageSendOptions and no topic_id, so
# it cannot go through send_content; effect_id is int64 and crosses as a
# string.
#
# Which also means it cannot honour the options send_content validates, so
# they are refused rather than dropped on the floor.
sub no_send_options {
    my ($what, $opt) = @_;
    for my $k (qw(wait schedule topic)) {
        croak "$what cannot take $k: sendBusinessMessage has no "
            . "message-send options and promises no delivery update"
            if exists $opt->{$k};
    }
}
sub send_business_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($conn, $chat_id, $text, @rest) = @args;
    my %opt = opts(@rest);
    need('business_connection_id, chat_id, text', $conn, $chat_id, $text);
    no_send_options('send_business_message', \%opt);
    my $content = $self->input_text($text, \%opt, $cb) or return;
    my %req = (
        '@type'                 => 'sendBusinessMessage',
        business_connection_id  => plain_text('a business connection id', $conn),
        chat_id                 => 0 + $chat_id,
        disable_notification    => json_bool($opt{silent}),
        protect_content         => json_bool($opt{protect_content}),
        effect_id               => plain_text('an effect id',
                                              $opt{effect_id} // 0),
        input_message_content   => $content,
    );
    $req{reply_to} = { '@type' => 'inputMessageReplyToMessage',
                       message_id => num('reply_to', $opt{reply_to}) }
        if $opt{reply_to};
    $req{reply_markup} = $opt{reply_markup} if $opt{reply_markup};
    $self->send(\%req, $cb);
    return;
}

sub send_business_file {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($conn, $chat_id, $path, @rest) = @args;
    my %opt = opts(@rest);
    need('business_connection_id, chat_id, path', $conn, $chat_id, $path);
    no_send_options('send_business_file', \%opt);
    my $content = $self->input_content($path, \%opt, $cb) or return;
    my %req = (
        '@type'                 => 'sendBusinessMessage',
        business_connection_id  => plain_text('a business connection id', $conn),
        chat_id                 => 0 + $chat_id,
        disable_notification    => json_bool($opt{silent}),
        protect_content         => json_bool($opt{protect_content}),
        effect_id               => plain_text('an effect id',
                                              $opt{effect_id} // 0),
        input_message_content   => $content,
    );
    $req{reply_to} = { '@type' => 'inputMessageReplyToMessage',
                       message_id => num('reply_to', $opt{reply_to}) }
        if $opt{reply_to};
    $req{reply_markup} = $opt{reply_markup} if $opt{reply_markup};
    $self->send(\%req, $cb);
    return;
}

sub edit_business_message_text {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($conn, $chat_id, $message_id, $text, @rest) = @args;
    my %opt = opts(@rest);
    need('business_connection_id, chat_id, message_id, text',
          $conn, $chat_id, $message_id, $text);
    my $content = $self->input_text($text, \%opt, $cb) or return;
    my %req = (
        '@type'                 => 'editBusinessMessageText',
        business_connection_id  => plain_text('a business connection id', $conn),
        chat_id                 => 0 + $chat_id,
        message_id              => 0 + $message_id,
        input_message_content   => $content,
    );
    $req{reply_markup} = $opt{reply_markup} if $opt{reply_markup};
    $self->send(\%req, $cb);
    return;
}

sub read_business_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('read_business_message', 3, \@args);
    my ($conn, $chat_id, $message_id) = @args;
    need('business_connection_id, chat_id, message_id',
          $conn, $chat_id, $message_id);
    $self->send({ '@type' => 'readBusinessMessage',
                  business_connection_id =>
                      plain_text('a business connection id', $conn),
                  chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id }, $cb);
    return;
}

sub delete_business_messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_business_messages', 2, \@args);
    my ($conn, $ids) = @args;
    need('business_connection_id, message_ids', $conn, $ids);
    $self->send({ '@type' => 'deleteBusinessMessages',
                  business_connection_id =>
                      plain_text('a business connection id', $conn),
                  message_ids => num_list('message_ids', $ids) }, $cb);
    return;
}

# --- quick replies

# the callback carries a bare Ok; the shortcuts arrive through
# updateQuickReplyShortcuts
sub load_quick_replies {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('load_quick_replies', 0, \@args);
    $self->send({ '@type' => 'loadQuickReplyShortcuts' }, $cb);
    return;
}

sub load_quick_reply_messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('load_quick_reply_messages', 1, \@args);
    my ($shortcut_id) = @args;
    need('shortcut_id', $shortcut_id);
    $self->send({ '@type' => 'loadQuickReplyShortcutMessages',
                  shortcut_id => 0 + $shortcut_id }, $cb);
    return;
}

sub add_quick_reply_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($name, $text, @rest) = @args;
    my %opt = opts(@rest);
    need('shortcut_name, text', $name, $text);
    my $content = $self->input_text($text, \%opt, $cb) or return;
    $self->send({ '@type' => 'addQuickReplyShortcutMessage',
                  shortcut_name => plain_text('a shortcut name', $name),
                  reply_to_message_id => num('reply_to', $opt{reply_to} // 0),
                  input_message_content => $content }, $cb);
    return;
}

sub edit_quick_reply_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($shortcut_id, $message_id, $text, @rest) = @args;
    my %opt = opts(@rest);
    need('shortcut_id, message_id, text', $shortcut_id, $message_id, $text);
    my $content = $self->input_text($text, \%opt, $cb) or return;
    $self->send({ '@type' => 'editQuickReplyMessage',
                  shortcut_id => 0 + $shortcut_id,
                  message_id => 0 + $message_id,
                  input_message_content => $content }, $cb);
    return;
}

sub delete_quick_reply {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_quick_reply', 1, \@args);
    my ($shortcut_id) = @args;
    need('shortcut_id', $shortcut_id);
    $self->send({ '@type' => 'deleteQuickReplyShortcut',
                  shortcut_id => 0 + $shortcut_id }, $cb);
    return;
}

sub delete_quick_reply_messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_quick_reply_messages', 2, \@args);
    my ($shortcut_id, $ids) = @args;
    need('shortcut_id, message_ids', $shortcut_id, $ids);
    $self->send({ '@type' => 'deleteQuickReplyShortcutMessages',
                  shortcut_id => 0 + $shortcut_id,
                  message_ids => num_list('message_ids', $ids) }, $cb);
    return;
}

sub set_quick_reply_name {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_quick_reply_name', 2, \@args);
    my ($shortcut_id, $name) = @args;
    need('shortcut_id, name', $shortcut_id, $name);
    $self->send({ '@type' => 'setQuickReplyShortcutName',
                  shortcut_id => 0 + $shortcut_id,
                  name => plain_text('a shortcut name', $name) }, $cb);
    return;
}

sub reorder_quick_replies {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('reorder_quick_replies', 1, \@args);
    my ($ids) = @args;
    need('shortcut_ids', $ids);
    $self->send({ '@type' => 'reorderQuickReplyShortcuts',
                  shortcut_ids => num_list('shortcut_ids', $ids) }, $cb);
    return;
}

sub send_quick_reply {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $shortcut_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, shortcut_id', $chat_id, $shortcut_id);
    croak "send_quick_reply cannot wait for delivery: it always returns once "
        . "Telegram accepts the messages"
        if defined $opt{wait} && $opt{wait} ne 'accepted';
    $self->send({ '@type' => 'sendQuickReplyShortcutMessages',
                  chat_id => 0 + $chat_id,
                  shortcut_id => 0 + $shortcut_id,
                  sending_id => num('sending_id', $opt{sending_id} // 0) }, $cb);
    return;
}

# documented as callable synchronously, so it does not go through send()
sub check_quick_reply_name {
    my ($self, $name, @rest) = @_;
    need('name', $name);
    croak 'check_quick_reply_name returns its result and takes no callback'
        if @rest;
    return $self->execute({ '@type' => 'checkQuickReplyShortcutName',
                            name => plain_text('a shortcut name', $name) });
}

1;
