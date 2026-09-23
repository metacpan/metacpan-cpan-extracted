package EV::Telegram::TDLib::Bots;

use strict;
use warnings;
use Carp qw(croak);
use MIME::Base64 ();

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Bots - bot methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Bots mixin">.

=cut

sub CLONE_SKIP { 1 }


our %UPDATES = (
    updateNewCallbackQuery         => \&update_callback_query,
    updateNewInlineCallbackQuery   => \&update_callback_query,
    updateNewBusinessCallbackQuery => \&update_callback_query,
    updateNewInlineQuery           => \&update_inline_query,
);

# TL `bytes` travels base64-encoded over the JSON interface, so callback
# payloads are decoded on the way in and encoded on the way out; a caller
# that never sees the encoding cannot get it wrong
# the query is decoded before the on_callback_query guard, so a bot that only
# registers on_callback_data still receives one
sub update_callback_query {
    my ($self, $obj) = @_;
    my $payload = $obj->{payload} // {};
    my %q = (
        id             => $obj->{id},
        sender_user_id => $obj->{sender_user_id},
        chat_id        => $obj->{chat_id},
        message_id     => $obj->{message_id},
        type           => $payload->{'@type'},
    );
    # a press on a message sent through inline mode has no chat: it names
    # the message by inline_message_id instead
    $q{inline_message_id} = $obj->{inline_message_id}
        if defined $obj->{inline_message_id};
    # one on a business message carries the message itself, and the
    # connection it came through
    if (ref $obj->{message} eq 'HASH' && ref $obj->{message}{message} eq 'HASH') {
        @q{qw(chat_id message_id)} = @{ $obj->{message}{message} }{qw(chat_id id)};
        $q{connection_id} = $obj->{connection_id};
    }
    $q{data} = MIME::Base64::decode_base64($payload->{data})
        if defined $payload->{data};
    $q{game_short_name} = $payload->{game_short_name}
        if defined $payload->{game_short_name};
    $self->route_callback_data(\%q);
    my $cb = $self->{on_callback_query} or return;
    $self->guarded($cb, \%q);
}

sub on_callback_query {
    my ($self, $cb) = @_;
    $self->{on_callback_query} = $cb if @_ > 1;
    return $self->{on_callback_query};
}

sub answer_callback_query {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, @rest) = @args;
    my %opt = opts(@rest);
    need('callback_query_id', $id);
    # int64 crosses the JSON interface as a string; a number would lose
    # precision on ids above 2^53
    $self->send({
        '@type'           => 'answerCallbackQuery',
        callback_query_id => plain_text('a callback query id', $id),
        text              => plain_text('an answer text', $opt{text}),
        show_alert        => json_bool($opt{show_alert}),
        url               => plain_text('a url', $opt{url}),
        cache_time        => num('cache_time', $opt{cache_time} // 0),
    }, $cb);
    return;
}

# rows: [ [ { text => 'Yes', data => 'yes' }, { text => 'Docs', url => '...' } ] ]
sub inline_keyboard {
    my ($self, $rows) = @_;
    croak 'inline_keyboard needs an arrayref of rows'
        unless ref $rows eq 'ARRAY';
    my @out;
    for my $row (@$rows) {
        croak 'each keyboard row must be an arrayref' unless ref $row eq 'ARRAY';
        my @buttons;
        for my $b (@$row) {
            croak 'each button needs a text' unless defined $b->{text};
            my $type = defined $b->{data}
                ? { '@type' => 'inlineKeyboardButtonTypeCallback',
                    data => tl_bytes('callback button data', $b->{data}) }
                : defined $b->{url}
                ? { '@type' => 'inlineKeyboardButtonTypeUrl', url => $b->{url} }
                : defined $b->{web_app}
                ? { '@type' => 'inlineKeyboardButtonTypeWebApp', url => $b->{web_app} }
                : croak 'each button needs data, url or web_app';
            push @buttons, { '@type' => 'inlineKeyboardButton',
                             text => plain_text('a button text', $b->{text}),
                             type => $type };
        }
        push @out, \@buttons;
    }
    return { '@type' => 'replyMarkupInlineKeyboard', rows => \@out };
}

# a restrict_X flag means "X must match"; deriving it from whether the
# caller mentioned the key keeps both halves from drifting apart
sub request_chat_type {
    my ($s) = @_;
    croak 'request_chat needs a hashref' unless ref $s eq 'HASH';
    return {
        '@type'                    => 'keyboardButtonTypeRequestChat',
        id                         => num('request_chat id', $s->{id} // 0),
        chat_is_channel            => json_bool($s->{channel}),
        restrict_chat_is_forum     => json_bool(exists $s->{forum}),
        chat_is_forum              => json_bool($s->{forum}),
        restrict_chat_has_username => json_bool(exists $s->{username}),
        chat_has_username          => json_bool($s->{username}),
        chat_is_created            => json_bool($s->{created}),
        bot_is_member              => json_bool($s->{bot_is_member}),
        request_title              => json_bool($s->{want_title}),
        request_username           => json_bool($s->{want_username}),
        request_photo              => json_bool($s->{want_photo}),
        (defined $s->{user_rights} ? (user_administrator_rights => $s->{user_rights}) : ()),
        (defined $s->{bot_rights}  ? (bot_administrator_rights  => $s->{bot_rights})  : ()),
    };
}

sub request_users_type {
    my ($s) = @_;
    croak 'request_users needs a hashref' unless ref $s eq 'HASH';
    return {
        '@type'                  => 'keyboardButtonTypeRequestUsers',
        id                       => num('request_users id', $s->{id} // 0),
        restrict_user_is_bot     => json_bool(exists $s->{bot}),
        user_is_bot              => json_bool($s->{bot}),
        restrict_user_is_premium => json_bool(exists $s->{premium}),
        user_is_premium          => json_bool($s->{premium}),
        max_quantity             => num('request_users max', $s->{max} // 1),
        request_name             => json_bool($s->{want_name}),
        request_username         => json_bool($s->{want_username}),
        request_photo            => json_bool($s->{want_photo}),
    };
}

# rows: [ [ 'Yes', { text => 'Share number', request => 'phone' } ], ... ]
sub reply_keyboard {
    my ($self, $rows, @rest) = @_;
    my %opt = opts(@rest);
    croak 'reply_keyboard needs an arrayref of rows' unless ref $rows eq 'ARRAY';
    my @out;
    for my $row (@$rows) {
        croak 'each keyboard row must be an arrayref' unless ref $row eq 'ARRAY';
        push @out, [ map {
            my $b = ref $_ eq 'HASH' ? $_ : { text => $_ };
            croak 'each button needs a text' unless defined $b->{text};
            my $type = defined $b->{web_app}
                ? { '@type' => 'keyboardButtonTypeWebApp', url => $b->{web_app} }
                : defined $b->{request_chat}  ? request_chat_type($b->{request_chat})
                : defined $b->{request_users} ? request_users_type($b->{request_users})
                : { '@type' =>
                      !defined $b->{request}      ? 'keyboardButtonTypeText'
                    : $b->{request} eq 'phone'    ? 'keyboardButtonTypeRequestPhoneNumber'
                    : $b->{request} eq 'location' ? 'keyboardButtonTypeRequestLocation'
                    : croak "unknown button request '$b->{request}'" };
            +{ '@type' => 'keyboardButton',
               text => plain_text('a button text', $b->{text}), type => $type };
        } @$row ];
    }
    return {
        '@type'         => 'replyMarkupShowKeyboard',
        rows            => \@out,
        resize_keyboard => json_bool(exists $opt{resize} ? $opt{resize} : 1),
        one_time        => json_bool($opt{one_time}),
        is_persistent   => json_bool($opt{persistent}),
        (defined $opt{placeholder}
            ? (input_field_placeholder =>
                   plain_text('a placeholder', $opt{placeholder})) : ()),
    };
}

sub remove_keyboard {
    my ($self, @rest) = @_;
    my %opt = opts(@rest);
    return { '@type' => 'replyMarkupRemoveKeyboard',
             is_personal => json_bool($opt{personal}) };
}

# the "/" menu a bot offers; an empty list clears it
sub set_commands {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($commands, @rest) = @args;
    my %opt = opts(@rest);
    croak 'set_commands needs an arrayref' unless ref $commands eq 'ARRAY';
    my @cmds;
    for my $c (@$commands) {
        my ($name, $desc) = ref $c eq 'ARRAY' ? @$c
                          : ref $c eq 'HASH'  ? @{$c}{qw(command description)}
                          : croak 'each command must be an arrayref or hashref';
        croak 'each command needs a name and a description'
            unless defined $name && defined $desc;
        $name =~ s{^/}{};
        push @cmds, { '@type' => 'botCommand',
                      command => plain_text('a command name', $name),
                      description => plain_text('a command description', $desc) };
    }
    $self->send({
        '@type'        => 'setCommands',
        scope          => $opt{scope} // { '@type' => 'botCommandScopeDefault' },
        language_code  => plain_text('a language code', $opt{language_code}),
        commands       => \@cmds,
    }, $cb);
    return;
}

# TDLib addresses a bot's own profile by its user id, which for a bot session
# is the account's own id; my_id comes from updateOption, so the common case
# needs no getMe first
sub bot_id {
    my ($self, $opt) = @_;
    my $id = $opt->{bot_user_id} // $self->my_id;
    croak 'bot_user_id is not known yet: pass it, or wait for login'
        unless $id;
    return num('bot_user_id', $id);
}

sub set_bot_name {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    croak 'set_bot_name needs a name; pass the empty string to clear it'
        unless @args;
    my ($name, @rest) = @args;
    my %opt = opts(@rest);
    $self->send({
        '@type'        => 'setBotName',
        bot_user_id    => $self->bot_id(\%opt),
        language_code  => plain_text('a language code', $opt{language_code}),
        name           => plain_text('a bot name', $name),
    }, $cb);
    return;
}

sub set_bot_description {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    croak 'set_bot_description needs a description; pass the empty string '
        . 'to clear it' unless @args;
    my ($text, @rest) = @args;
    my %opt = opts(@rest);
    # the long text, shown on the bot's empty chat screen
    $self->send({
        '@type'        => 'setBotInfoDescription',
        bot_user_id    => $self->bot_id(\%opt),
        language_code  => plain_text('a language code', $opt{language_code}),
        description    => plain_text('a description', $text),
    }, $cb);
    return;
}

sub set_bot_short_description {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    croak 'set_bot_short_description needs a description; pass the empty '
        . 'string to clear it' unless @args;
    my ($text, @rest) = @args;
    my %opt = opts(@rest);
    # the one-liner shown in the bot's profile and in search results
    $self->send({
        '@type'            => 'setBotInfoShortDescription',
        bot_user_id        => $self->bot_id(\%opt),
        language_code      => plain_text('a language code', $opt{language_code}),
        short_description  => plain_text('a description', $text),
    }, $cb);
    return;
}

sub set_bot_photo {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($path, @rest) = @args;
    my %opt = opts(@rest);
    $self->send({
        '@type'      => 'setBotProfilePhoto',
        bot_user_id  => $self->bot_id(\%opt),
        photo        => $self->input_chat_photo($path, \%opt),
    }, $cb);
    return;
}

sub update_inline_query {
    my ($self, $obj) = @_;
    my $cb = $self->{on_inline_query} or return;
    $self->guarded($cb, {
        id             => $obj->{id},
        sender_user_id => $obj->{sender_user_id},
        query          => $obj->{query},
        offset         => $obj->{offset},
        chat_type      => ($obj->{chat_type} || {})->{'@type'},
        user_location  => $obj->{user_location},
    });
}

sub on_inline_query {
    my ($self, $cb) = @_;
    $self->{on_inline_query} = $cb if @_ > 1;
    return $self->{on_inline_query};
}

# results: [ { id => '1', title => 'A', message => 'sent when picked' }, ... ]
sub answer_inline_query {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $results, @rest) = @args;
    my %opt = opts(@rest);
    need('inline_query_id', $id);
    croak 'answer_inline_query needs an arrayref of results'
        unless ref $results eq 'ARRAY';
    my $n = 0;
    my @out;
    my $bad;
    for my $r (@$results) {
        croak 'each inline result must be a hashref' unless ref $r eq 'HASH';
        croak 'each result needs a title' unless defined $r->{title};
        my $text = defined $r->{message} ? $r->{message} : $r->{title};
        push @out, {
            '@type'      => 'inputInlineQueryResultArticle',
            id           => defined $r->{id}
                                ? plain_text('a result id', $r->{id})
                                : "" . ++$n,
            title        => plain_text('a result title', $r->{title}),
            description  => plain_text('a result description', $r->{description}),
            url          => plain_text('a url', $r->{url}),
            thumbnail_url    => defined $r->{thumbnail_url}
                                  ? plain_text('a thumbnail url',
                                               $r->{thumbnail_url}) : '',
            thumbnail_width  => num('thumbnail_width', $r->{thumbnail_width} // 0),
            thumbnail_height => num('thumbnail_height', $r->{thumbnail_height} // 0),
            input_message_content => {
                '@type' => 'inputMessageText',
                text    => do {
                    my $t = $self->format_text($text,
                        $r->{parse_mode} // $opt{parse_mode});
                    # a parse failure must reach the caller, not TDLib
                    $bad ||= $t if ($t->{'@type'} // '') eq 'error';
                    $t;
                },
            },
            ($r->{reply_markup} ? (reply_markup => $r->{reply_markup}) : ()),
        };
    }
    if ($bad) { $cb->(undef, $bad); return }
    $self->send({
        '@type'           => 'answerInlineQuery',
        # int64 over the JSON interface: a number would lose precision
        inline_query_id   => plain_text('an inline query id', $id),
        is_personal       => json_bool($opt{personal}),
        results           => \@out,
        cache_time        => num('cache_time', $opt{cache_time} // 300),
        next_offset       => plain_text('an offset', $opt{next_offset}),
    }, $cb);
    return;
}

sub commands {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my (@rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'getCommands',
                  scope => $opt{scope} // { '@type' => 'botCommandScopeDefault' },
                  language_code =>
                      plain_text('a language code', $opt{language_code}) }, $cb);
    return;
}

sub delete_commands {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my (@rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'deleteCommands',
                  scope => $opt{scope} // { '@type' => 'botCommandScopeDefault' },
                  language_code =>
                      plain_text('a language code', $opt{language_code}) }, $cb);
    return;
}

for my $spec ([ bot_name              => 'getBotName' ],
              [ bot_description       => 'getBotInfoDescription' ],
              [ bot_short_description => 'getBotInfoShortDescription' ]) {
    my ($name, $type) = @$spec;
    no strict 'refs';
    *{$name} = sub {
        my ($self, @args) = @_;
        my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
        my (@rest) = @args;
        my %opt = opts(@rest);
        $self->send({ '@type' => $type, bot_user_id => $self->bot_id(\%opt),
                      language_code =>
                      plain_text('a language code', $opt{language_code}) }, $cb);
        return;
    };
}

# these address a message by inline_message_id, which a press on its buttons
# or a chosen-result update carries; edit_message_* take a (chat_id,
# message_id) pair
sub edit_inline_text {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $text, @rest) = @args;
    my %opt = opts(@rest);
    need('inline_message_id, text', $id, $text);
    my $content = $self->input_text($text, \%opt, $cb) or return;
    $self->send({ '@type' => 'editInlineMessageText',
                  inline_message_id => plain_text('an inline message id', $id),
                  reply_markup => $opt{reply_markup},
                  input_message_content => $content }, $cb);
    return;
}

sub edit_inline_caption {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $caption, @rest) = @args;
    my %opt = opts(@rest);
    need('inline_message_id, caption', $id, $caption);
    my $formatted = $self->format_text($caption, $opt{parse_mode});
    if (($formatted->{'@type'} // '') eq 'error') {
        $cb->(undef, $formatted);
        return;
    }
    $self->send({ '@type' => 'editInlineMessageCaption',
                  inline_message_id => plain_text('an inline message id', $id),
                  reply_markup => $opt{reply_markup}, caption => $formatted,
                  show_caption_above_media => json_bool($opt{caption_above}) }, $cb);
    return;
}

sub edit_inline_media {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $content, @rest) = @args;
    my %opt = opts(@rest);
    need('inline_message_id, content', $id, $content);
    $self->send({ '@type' => 'editInlineMessageMedia',
                  inline_message_id => plain_text('an inline message id', $id),
                  reply_markup => $opt{reply_markup},
                  input_message_content => $content }, $cb);
    return;
}

sub edit_inline_markup {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('edit_inline_markup', 2, \@args);
    my ($id, $markup) = @args;
    need('inline_message_id, reply_markup', $id, $markup);
    $self->send({ '@type' => 'editInlineMessageReplyMarkup',
                  inline_message_id => plain_text('an inline message id', $id),
                  reply_markup => $markup }, $cb);
    return;
}

# live_period and friends belong to the liveLocation wrapper; at top level
# TDLib drops them and the location silently never expires
sub edit_inline_location {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $location, @rest) = @args;
    my %opt = opts(@rest);
    need('inline_message_id', $id);
    $self->send({
        '@type'            => 'editInlineMessageLiveLocation',
        inline_message_id  => plain_text('an inline message id', $id),
        reply_markup       => $opt{reply_markup},
        location           => $location ? {
            '@type'                => 'liveLocation',
            location               => $location,
            live_period            => num('live_period', $opt{live_period} // 0),
            heading                => num('heading', $opt{heading} // 0),
            proximity_alert_radius => num('proximity_alert_radius',
                                          $opt{proximity_alert_radius} // 0),
        } : undef,
    }, $cb);
    return;
}

# the user side of an inline keyboard: presses a button on someone else's
# message, the way a client answers a bot's prompt
sub press {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('press', 3, \@args);
    my ($chat, $message_id, $data) = @args;
    need('chat_id, message_id, data', $chat, $message_id, $data);
    $self->send({ '@type' => 'getCallbackQueryAnswer',
                  chat_id => 0 + $chat, message_id => 0 + $message_id,
                  payload => { '@type' => 'callbackQueryPayloadData',
                               data => tl_bytes('callback data', $data) } }, $cb);
    return;
}

sub inline_query {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, $query, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id, query', $bot, $query);
    $self->send({ '@type' => 'getInlineQueryResults', bot_user_id => 0 + $bot,
                  chat_id => num('chat_id', $opt{chat_id} // 0),
                  user_location => $opt{location},
                  query => plain_text('a query', $query),
                  offset => plain_text('an offset', $opt{offset}) }, $cb);
    return;
}

sub send_inline_result {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat, $query_id, $result_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, query_id, result_id', $chat, $query_id, $result_id);
    croak "send_inline_result cannot wait for delivery: it always returns "
        . "once Telegram accepts the message"
        if defined $opt{wait} && $opt{wait} ne 'accepted';
    my %req = ('@type' => 'sendInlineQueryResultMessage', chat_id => 0 + $chat,
               query_id => plain_text('a query id', $query_id),
               result_id => plain_text('a result id', $result_id),
               hide_via_bot => json_bool($opt{hide_via_bot}));
    $req{reply_to} = { '@type' => 'inputMessageReplyToMessage',
                       message_id => num('reply_to', $opt{reply_to}) }
        if $opt{reply_to};
    if (my $o = EV::Telegram::TDLib::Messages::send_options(\%opt)) { $req{options} = $o }
    if (my $t = EV::Telegram::TDLib::Messages::topic_id(\%opt))     { $req{topic_id} = $t }
    $self->send(\%req, $cb);
    return;
}

sub start_bot {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, $parameter, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id', $bot);
    $self->send({ '@type' => 'sendBotStartMessage', bot_user_id => 0 + $bot,
                  chat_id => num('chat_id', $opt{chat_id} // $bot),
                  parameter => plain_text('a parameter', $parameter) }, $cb);
    return;
}

sub attachment_menu_bot {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('attachment_menu_bot', 1, \@args);
    my ($bot) = @args;
    need('bot_user_id', $bot);
    $self->send({ '@type' => 'getAttachmentMenuBot', bot_user_id => 0 + $bot }, $cb);
    return;
}

# openWebApp with an empty url needs the bot to be in the attachment menu
sub toggle_attachment_menu {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, $on, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id', $bot);
    $self->send({ '@type' => 'toggleBotIsAddedToAttachmentMenu',
                  bot_user_id => 0 + $bot,
                  is_added => json_bool(defined $on ? $on : 1),
                  allow_write_access => json_bool($opt{allow_write_access}) }, $cb);
    return;
}

# the user's answer to a request_chat / request_users keyboard button; the
# source identifies the message the button was on, and button_id is the id
# you gave that button when building the keyboard
sub button_source {
    my ($chat_id, $message_id) = @_;
    return { '@type' => 'keyboardButtonSourceMessage',
             chat_id => num('chat_id', $chat_id),
             message_id => num('message_id', $message_id) };
}

sub share_chat_with_bot {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, $button_id, $shared_chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id, button_id, shared_chat_id',
          $chat_id, $message_id, $button_id, $shared_chat_id);
    $self->send({
        '@type'          => 'shareChatWithBot',
        source           => button_source($chat_id, $message_id),
        button_id        => 0 + $button_id,
        shared_chat_id   => 0 + $shared_chat_id,
        only_check       => json_bool($opt{check_only}),
    }, $cb);
    return;
}

sub share_users_with_bot {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, $button_id, $user_ids, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id, button_id, user_ids',
          $chat_id, $message_id, $button_id, $user_ids);
    croak 'share_users_with_bot needs an arrayref of user ids'
        unless ref $user_ids eq 'ARRAY';
    $self->send({
        '@type'            => 'shareUsersWithBot',
        source             => button_source($chat_id, $message_id),
        button_id          => 0 + $button_id,
        shared_user_ids    => num_list('user_ids', $user_ids),
        only_check         => json_bool($opt{check_only}),
    }, $cb);
    return;
}

sub allow_bot_messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('allow_bot_messages', 1, \@args);
    my ($bot) = @args;
    need('bot_user_id', $bot);
    $self->send({ '@type' => 'allowBotToSendMessages',
                  bot_user_id => 0 + $bot }, $cb);
    return;
}

sub can_bot_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('can_bot_message', 1, \@args);
    my ($bot) = @args;
    need('bot_user_id', $bot);
    $self->send({ '@type' => 'canBotSendMessages',
                  bot_user_id => 0 + $bot }, $cb);
    return;
}

# callback query ids are TL int64
sub callback_query_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('callback_query_message', 3, \@args);
    my ($chat_id, $message_id, $query_id) = @args;
    need('chat_id, message_id, callback_query_id',
          $chat_id, $message_id, $query_id);
    $self->send({ '@type' => 'getCallbackQueryMessage',
                  chat_id => 0 + $chat_id, message_id => 0 + $message_id,
                  callback_query_id =>
                      plain_text('a callback query id', $query_id) }, $cb);
    return;
}

sub check_bot_username {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('check_bot_username', 1, \@args);
    my ($username) = @args;
    need('username', $username);
    $self->send({ '@type' => 'checkBotUsername',
                  username => plain_text('a username', $username) }, $cb);
    return;
}

sub toggle_bot_username {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, $username, $active, @rest) = @args;
    no_opts('toggle_bot_username', @rest);
    need('bot_user_id, username', $bot, $username);
    $self->send({ '@type' => 'toggleBotUsernameIsActive', bot_user_id => 0 + $bot,
                  username => plain_text('a username', $username),
                  is_active => json_bool(defined $active ? $active : 1) }, $cb);
    return;
}

# --- bot provisioning: owning and managing bots from an account, rather than
# through BotFather. createBot names a manager bot that will own the new one.
sub create_bot {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($name, $username, @rest) = @args;
    my %opt = opts(@rest);
    need('name, username', $name, $username);
    $self->send({
        '@type'                => 'createBot',
        manager_bot_user_id    => num('manager', $opt{manager} // 0),
        name                   => plain_text('a name', $name),
        username               => plain_text('a username', $username),
        via_link               => json_bool($opt{via_link}),
    }, $cb);
    return;
}

sub owned_bots {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('owned_bots', 0, \@args);
    $self->send({ '@type' => 'getOwnedBots' }, $cb);
    return;
}

# revoke invalidates the old token, so anything still using it stops working
sub bot_token {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id', $bot);
    $self->send({ '@type' => 'getManagedBotToken', bot_user_id => 0 + $bot,
                  revoke => json_bool($opt{revoke}) }, $cb);
    return;
}

sub bot_access_settings {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('bot_access_settings', 1, \@args);
    my ($bot) = @args;
    need('bot_user_id', $bot);
    $self->send({ '@type' => 'getManagedBotAccessSettings',
                  bot_user_id => 0 + $bot }, $cb);
    return;
}

sub set_bot_access_settings {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_bot_access_settings', 2, \@args);
    my ($bot, $settings) = @args;
    need('bot_user_id, settings', $bot, $settings);
    croak 'set_bot_access_settings needs a settings hashref'
        unless ref $settings eq 'HASH';
    $self->send({ '@type' => 'setManagedBotAccessSettings',
                  bot_user_id => 0 + $bot, settings => $settings }, $cb);
    return;
}

sub set_updates_status {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($pending, @rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'setBotUpdatesStatus',
                  pending_update_count => num('pending_count', $pending // 0),
                  error_message =>
                      plain_text('an error message', $opt{error}) }, $cb);
    return;
}

sub recent_inline_bots {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('recent_inline_bots', 0, \@args);
    $self->send({ '@type' => 'getRecentInlineBots' }, $cb);
    return;
}

sub similar_bots {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('similar_bots', 1, \@args);
    my ($bot) = @args;
    need('bot_user_id', $bot);
    $self->send({ '@type' => 'getBotSimilarBots', bot_user_id => 0 + $bot }, $cb);
    return;
}

sub similar_bot_count {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id', $bot);
    $self->send({ '@type' => 'getBotSimilarBotCount', bot_user_id => 0 + $bot,
                  return_local => json_bool($opt{local}) }, $cb);
    return;
}

sub open_similar_bot {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('open_similar_bot', 2, \@args);
    my ($bot, $opened) = @args;
    need('bot_user_id, opened_bot_user_id', $bot, $opened);
    $self->send({ '@type' => 'openBotSimilarBot', bot_user_id => 0 + $bot,
                  opened_bot_user_id => 0 + $opened }, $cb);
    return;
}

# --- media previews: the sample media shown on a bot's profile, per language
sub bot_media_previews {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id', $bot);
    my %req = ('@type' => 'getBotMediaPreviews', bot_user_id => 0 + $bot);
    if (defined $opt{language_code}) {
        $req{'@type'} = 'getBotMediaPreviewInfo';
        $req{language_code} = plain_text('a language code', $opt{language_code});
    }
    $self->send(\%req, $cb);
    return;
}

sub add_bot_media_preview {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, $content, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id, content', $bot, $content);
    $self->send({ '@type' => 'addBotMediaPreview', bot_user_id => 0 + $bot,
                  language_code =>
                      plain_text('a language code', $opt{language_code}),
                  content => $content }, $cb);
    return;
}

sub edit_bot_media_preview {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, $file_id, $content, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id, file_id, content', $bot, $file_id, $content);
    $self->send({ '@type' => 'editBotMediaPreview', bot_user_id => 0 + $bot,
                  language_code =>
                      plain_text('a language code', $opt{language_code}),
                  file_id => 0 + $file_id, content => $content }, $cb);
    return;
}

sub delete_bot_media_previews {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, $file_ids, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id, file_ids', $bot, $file_ids);
    croak 'delete_bot_media_previews needs an arrayref of file ids'
        unless ref $file_ids eq 'ARRAY';
    $self->send({ '@type' => 'deleteBotMediaPreviews', bot_user_id => 0 + $bot,
                  language_code =>
                      plain_text('a language code', $opt{language_code}),
                  file_ids => num_list('file_ids', $file_ids) }, $cb);
    return;
}

sub reorder_bot_media_previews {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, $file_ids, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id, file_ids', $bot, $file_ids);
    croak 'reorder_bot_media_previews needs an arrayref of file ids'
        unless ref $file_ids eq 'ARRAY';
    $self->send({ '@type' => 'reorderBotMediaPreviews', bot_user_id => 0 + $bot,
                  language_code =>
                      plain_text('a language code', $opt{language_code}),
                  file_ids => num_list('file_ids', $file_ids) }, $cb);
    return;
}

# --- games: a game bot cannot report a result without these
sub set_game_score {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, $user_id, $score, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id, user_id, score',
          $chat_id, $message_id, $user_id, $score);
    $self->send({
        '@type'        => 'setGameScore',
        chat_id        => 0 + $chat_id,
        message_id     => 0 + $message_id,
        edit_message   => json_bool(exists $opt{edit} ? $opt{edit} : 1),
        user_id        => 0 + $user_id,
        score          => 0 + $score,
        # without force a lower score is refused, which is usually what you want
        force          => json_bool($opt{force}),
    }, $cb);
    return;
}

sub game_high_scores {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('game_high_scores', 3, \@args);
    my ($chat_id, $message_id, $user_id) = @args;
    need('chat_id, message_id, user_id', $chat_id, $message_id, $user_id);
    $self->send({ '@type' => 'getGameHighScores', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id, user_id => 0 + $user_id }, $cb);
    return;
}

sub set_inline_game_score {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($inline_id, $user_id, $score, @rest) = @args;
    my %opt = opts(@rest);
    need('inline_message_id, user_id, score', $inline_id, $user_id, $score);
    $self->send({
        '@type'             => 'setInlineGameScore',
        inline_message_id   => plain_text('an inline message id', $inline_id),
        edit_message        => json_bool(exists $opt{edit} ? $opt{edit} : 1),
        user_id             => 0 + $user_id,
        score               => 0 + $score,
        force               => json_bool($opt{force}),
    }, $cb);
    return;
}

sub inline_game_high_scores {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('inline_game_high_scores', 2, \@args);
    my ($inline_id, $user_id) = @args;
    need('inline_message_id, user_id', $inline_id, $user_id);
    $self->send({ '@type' => 'getInlineGameHighScores',
                  inline_message_id =>
                      plain_text('an inline message id', $inline_id),
                  user_id => 0 + $user_id }, $cb);
    return;
}


# the button beside the message box; a web_app url makes it open a Mini App
sub set_menu_button {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($user_id, @rest) = @args;
    my %opt = opts(@rest);
    # TDLib reads a null button as the commands menu and an empty text with
    # the url "default" as Telegram's default; any other empty text is refused
    my $text = plain_text('a button text', $opt{text});
    # an empty text is refused unless the url is "default", so a url with no
    # text would silently put the default button back instead of failing
    croak 'set_menu_button needs a text for its url' if !length $text && $opt{url};
    my $button = $opt{commands} ? undef
        : length $text
        ? { '@type' => 'botMenuButton', text => $text,
            url => plain_text('a url', $opt{url}) }
        : { '@type' => 'botMenuButton', text => '', url => 'default' };
    $self->send({
        '@type'      => 'setMenuButton',
        user_id      => num('user_id', $user_id // 0),
        menu_button  => $button,
    }, $cb);
    return;
}

sub menu_button {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('menu_button', 1, \@args);
    my ($user_id) = @args;
    $self->send({ '@type' => 'getMenuButton',
                  user_id => num('user_id', $user_id // 0) }, $cb);
    return;
}

1;
