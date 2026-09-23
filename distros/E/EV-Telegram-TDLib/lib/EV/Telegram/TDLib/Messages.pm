package EV::Telegram::TDLib::Messages;

use strict;
use warnings;
use Carp qw(croak);
use EV;
use Encode ();
use overload ();

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Messages - message methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Messages mixin">.

=cut

sub CLONE_SKIP { 1 }

my %PARSE_MODE = (
    markdown => { '@type' => 'textParseModeMarkdown', version => 2 },
    html     => { '@type' => 'textParseModeHTML' },
);

our %UPDATES = (
    updateNewMessage            => \&update_new_message,
    updateMessageSendSucceeded  => \&update_send_succeeded,
    updateMessageSendFailed     => \&update_send_failed,
    updateDeleteMessages        => \&update_delete_messages,
);

sub sending { $_[0]{cache}{sending} ||= {} }


sub update_new_message {
    my ($self, $obj) = @_;
    my $msg = $obj->{message} or return;
    # an answer to a pending ask is not offered to the command router: a reply
    # that happens to start with a slash would otherwise run two code paths
    my $answered = $self->answer_ask($msg);
    $self->route_command($msg) unless $answered;
    if (my $cb = $self->{on_message}) { $cb->($msg) }
    # Mini App data arrives as a message content, not as its own update
    my $c = $msg->{content};
    return unless ref $c eq 'HASH'
        && ($c->{'@type'} // '') eq 'messageWebAppDataReceived';
    if (my $cb = $self->{on_web_app_data}) {
        $cb->($msg, $c->{data}, $c->{button_text});
    }
}

# A yet-unsent message id is assigned from a per-chat counter, so the Nth send
# to one chat and the Nth to another share it. Keying on the id alone dropped
# one callback and handed the other the wrong chat's message.
sub sending_key {
    my ($chat_id, $message_id) = @_;
    return unless defined $chat_id && defined $message_id;
    return (0 + $chat_id) . ':' . (0 + $message_id);
}

sub update_send_succeeded {
    my ($self, $obj) = @_;
    my $key = sending_key($obj->{message}{chat_id}, $obj->{old_message_id})
        or return;
    my $cb = delete $self->sending->{$key} or return;
    $cb->($obj->{message}, undef);
}

sub update_send_failed {
    my ($self, $obj) = @_;
    my $key = sending_key($obj->{message}{chat_id}, $obj->{old_message_id})
        or return;
    my $cb = delete $self->sending->{$key} or return;
    $cb->(undef, $obj->{error} // { '@type' => 'error', code => -1,
                                    message => 'message send failed' });
}

# The schema says it outright: a message being sent that is irrecoverably
# deleted yields this instead of updateMessageSendFailed. Without it a caller
# waiting for delivery is owed an answer that never comes, and only close()
# ever resolves it.
sub update_delete_messages {
    my ($self, $obj) = @_;
    # a cache eviction is not a deletion: the schema says such a message can
    # be retrieved again, so the send is still outstanding
    return if $obj->{from_cache};
    my $sending = $self->sending;
    return unless %$sending;
    for my $id (@{ $obj->{message_ids} || [] }) {
        my $key = sending_key($obj->{chat_id}, $id) or next;
        my $cb = delete $sending->{$key} or next;
        # guarded: one update can carry many ids, and a die in an earlier
        # callback would strand the rest
        $self->guarded($cb, undef,
                        { '@type' => 'error', code => -1,
                          message => 'message deleted before it was sent' });
    }
}

sub on_message {
    my ($self, $cb) = @_;
    $self->{on_message} = $cb if @_ > 1;
    return $self->{on_message};
}

# Stringified here rather than at each caller: an SV that has ever been used
# as a number carries IOK, the encoder then emits a JSON Number, and TDLib
# refuses a Number in a text field. A bare numeric comparison is enough to
# set it, so the same string can send once and fail afterwards.
sub format_text {
    my ($self, $text, $parse_mode) = @_;
    # translate() and parse_markdown() answer with a formattedText, and
    # stringifying one sent HASH(0x...) to the chat: already-formatted text
    # passes straight through, and parse_mode has nothing left to do. An
    # object that stringifies, a URI say, is text like any other
    if (ref $text && !overload::Method($text, '""')) {
        return $text if ref $text eq 'HASH'
                     && ($text->{'@type'} // '') eq 'formattedText';
        croak 'text must be a string or a formattedText';
    }
    $text = defined $text ? "$text" : '';
    return { '@type' => 'formattedText', text => $text, entities => [] }
        unless $parse_mode;
    my $mode = $PARSE_MODE{$parse_mode}
        or croak "unknown parse_mode '$parse_mode'";
    return $self->execute({
        '@type' => 'parseTextEntities', text => $text, parse_mode => $mode,
    });
}

sub input_text {
    my ($self, $text, $opt, $cb) = @_;
    my $formatted = $self->format_text($text, $opt->{parse_mode});
    if (($formatted->{'@type'} // '') eq 'error') {
        $cb->(undef, $formatted);
        return;
    }
    my %content = ('@type' => 'inputMessageText', text => $formatted);
    $content{link_preview_options} = { '@type' => 'linkPreviewOptions',
                                       is_disabled => json_bool(1) }
        if $opt->{disable_preview};
    return \%content;
}

sub send_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $text, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, text', $chat_id, $text);
    my $content = $self->input_text($text, \%opt, $cb) or return;
    $self->send_content($chat_id, $content, \%opt, $cb);
    return;
}

# silent and schedule both live in messageSendOptions; built in one place so
# adding either never drops the other
sub send_options {
    my ($opt) = @_;
    return unless $opt->{silent} || $opt->{schedule};
    return {
        '@type' => 'messageSendOptions',
        ($opt->{silent} ? (disable_notification => json_bool(1)) : ()),
        ($opt->{schedule}
            ? (scheduling_state => { '@type' => 'messageSchedulingStateSendAtDate',
                                     send_date => unix_time('schedule', $opt->{schedule}),
                                     repeat_period => 0 })
            : ()),
    };
}

sub topic_id {
    my ($opt) = @_;
    return unless $opt->{topic};
    return { '@type' => 'messageTopicForum',
             forum_topic_id => num('topic', $opt->{topic}) };
}

# every send shares this tail so reply_to/silent/topic/reply_markup and the
# temporary-id dance are defined in exactly one place
sub send_content {
    my ($self, $chat_id, $content, $opt, $cb) = @_;
    # a scheduled message is not delivered until its due time, so the
    # send-succeeded update that 'sent' waits for would not arrive for days
    my $wait = $opt->{wait} // ($opt->{schedule} ? 'accepted' : 'sent');
    croak "wait => 'sent' cannot be combined with schedule: the confirmation "
        . "does not arrive until the message is actually delivered"
        if $opt->{schedule} && $wait eq 'sent';
    # every sender shares this check: validating in only some of them let
    # send_poll and friends accept a typo and silently mean 'sent'
    croak "unknown wait mode '$wait'"
        unless $wait eq 'sent' || $wait eq 'accepted';
    my %req = (
        '@type' => 'sendMessage',
        chat_id => num('chat_id', $chat_id),
        input_message_content => $content,
    );
    $req{reply_to} = { '@type' => 'inputMessageReplyToMessage',
                       message_id => num('reply_to', $opt->{reply_to}) }
        if $opt->{reply_to};
    if (my $o = send_options($opt)) { $req{options}  = $o }
    if (my $t = topic_id($opt))     { $req{topic_id} = $t }
    $req{reply_markup} = $opt->{reply_markup} if $opt->{reply_markup};
    $self->send(\%req, sub {
        my ($msg, $err) = @_;
        if ($err) { $cb->(undef, $err); return }
        if ($wait eq 'accepted') { $cb->($msg, undef); return }
        # the reply carries a temporary id; the real outcome arrives later as
        # updateMessageSendSucceeded/Failed carrying it, scoped to the chat
        my $key = sending_key($msg->{chat_id} // $chat_id, $msg->{id});
        if (!defined $key) { $cb->($msg, undef); return }
        $self->sending->{$key} = $cb;
    });
    return;
}

# each media content nests its InputFile inside a per-kind wrapper object;
# passing the InputFile directly yields only "InputFile is not specified"
# kind => [ content type, field, wrapper type, takes a caption ]
# stickers and video notes have no caption field in the schema at all
my %MEDIA = (
    document   => ['inputMessageDocument',  'document',   'inputDocument',  1],
    photo      => ['inputMessagePhoto',     'photo',      'inputPhoto',     1],
    video      => ['inputMessageVideo',     'video',      'inputVideo',     1],
    audio      => ['inputMessageAudio',     'audio',      'inputAudio',     1],
    animation  => ['inputMessageAnimation', 'animation',  'inputAnimation', 1],
    voice_note => ['inputMessageVoiceNote', 'voice_note', 'inputVoiceNote', 1],
    video_note => ['inputMessageVideoNote', 'video_note', 'inputVideoNote', 0],
    sticker    => ['inputMessageSticker',   'sticker',    'inputSticker',   0],
);

# optional wrapper fields worth exposing, per kind
my %MEDIA_EXTRA = (
    photo      => [qw(width height)],
    video      => [qw(duration width height)],
    audio      => [qw(duration title performer)],
    animation  => [qw(duration width height)],
    voice_note => [qw(duration)],
    video_note => [qw(duration length)],
    sticker    => [qw(width height)],
);
my %STRING_EXTRA = map { $_ => 1 } qw(title performer);

# Builds the inputMessage* content only. Split out from send_file so that
# senders which are not sendMessage -- sendBusinessMessage, for one -- can
# reuse it: send_content hardcodes sendMessage and its options.
# Returns undef after invoking $cb with the error, matching input_text.
sub input_content {
    my ($self, $path, $opt, $cb) = @_;
    my $kind = $opt->{kind} // 'document';
    my $spec = $MEDIA{$kind} or croak "unknown file kind '$kind'";
    my ($content_type, $field, $wrapper, $has_caption) = @$spec;
    my $input = input_file($path);
    my $content = {
        '@type' => $content_type,
        $field  => { '@type' => $wrapper, $field => $input },
    };
    if ($has_caption) {
        my $caption = $self->format_text($opt->{caption} // '', $opt->{parse_mode});
        if (($caption->{'@type'} // '') eq 'error') { $cb->(undef, $caption); return }
        $content->{caption} = $caption;
    }
    $content->{emoji} = plain_text('an emoji', $opt->{emoji})
        if $kind eq 'sticker' && defined $opt->{emoji};
    # Telegram classifies media by the metadata it is given: an animation
    # with no duration/width/height comes back as a plain document
    for my $extra (@{ $MEDIA_EXTRA{$kind} || [] }) {
        next unless defined $opt->{$extra};
        $content->{$field}{$extra} = $STRING_EXTRA{$extra}
            ? plain_text("a $extra", $opt->{$extra}) : num($extra, $opt->{$extra});
    }
    return $content;
}

sub send_file {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $path, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, path', $chat_id, $path);
    my $content = $self->input_content($path, \%opt, $cb) or return;
    $self->send_content($chat_id, $content, \%opt, $cb);
    return;
}

sub search_messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $query, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({
        '@type'           => 'searchChatMessages',
        chat_id           => 0 + $chat_id,
        query             => plain_text('a query', $query),
        from_message_id   => num('from_message_id', $opt{from_message_id} // 0),
        offset            => num('offset', $opt{offset} // 0),
        limit             => num('limit', $opt{limit} // 50),
        filter            => { '@type' => 'searchMessagesFilterEmpty' },
    }, sub {
        my ($res, $err) = @_;
        if ($err) { $cb->(undef, $err); return }
        $cb->($res->{messages} // [], undef, {
            total_count          => $res->{total_count},
            next_from_message_id => $res->{next_from_message_id},
        });
    });
    return;
}

sub history {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    my $want      = num('limit', $opt{limit} // 50);
    my $max_pages = num('max_pages', $opt{max_pages} // 10);
    my $from      = num('from_message_id', $opt{from_message_id} // 0);
    my @msgs;
    my $pages = 0;
    my $state = { complete => 0, last_message_id => undef };
    my ($fetch, $finish, $defer);
    $finish = sub {
        undef $fetch;  # break the fetch/finish closure cycle
        # a degenerate limit or max_pages finishes without ever sending a
        # request; firing inline would break the deferred-callback rule
        if (!$pages) {
            my @args = @_;
            # guarded: a die from a timer reaches EV, which prints and
            # ignores it, so on_error would never see what the same callback
            # dying on the reply path reports
            $defer = EV::timer 0, 0,
                sub { undef $defer; $self->guarded($cb, @args) };
            return;
        }
        $cb->(@_);
    };
    $fetch = sub {
        my $left = $want - @msgs;
        if ($left <= 0 || $pages >= $max_pages) {
            $state->{complete} = 1 if $left <= 0;
            $finish->(\@msgs, undef, $state);
            return;
        }
        $pages++;
        $self->send({
            '@type' => 'getChatHistory',
            chat_id => 0 + $chat_id,
            from_message_id => 0 + $from,
            offset => 0,
            limit => $left > 100 ? 100 : 0 + $left,
            only_local => json_bool(0),
        }, sub {
            my ($res, $err) = @_;
            if ($err) {
                $finish->(@msgs ? \@msgs : undef, $err, $state);
                return;
            }
            my $batch = $res->{messages} // [];
            if (!@$batch) { $state->{complete} = 1; $finish->(\@msgs, undef, $state); return }
            push @msgs, @$batch;
            my $last = $batch->[-1]{id};
            $state->{last_message_id} = $last;
            # a batch that does not advance would loop forever
            if ($last == $from) { $state->{complete} = 1; $finish->(\@msgs, undef, $state); return }
            $from = $last;
            $fetch->();
        });
    };
    $fetch->();
    return;
}

sub edit_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, $text, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id, text', $chat_id, $message_id, $text);
    my $content = $self->input_text($text, \%opt, $cb) or return;
    my %req = (
        '@type' => 'editMessageText',
        chat_id => 0 + $chat_id,
        message_id => 0 + $message_id,
        input_message_content => $content,
    );
    # an edit without reply_markup drops the buttons the message had
    $req{reply_markup} = $opt{reply_markup} if $opt{reply_markup};
    $self->send(\%req, $cb);
    return;
}

sub edit_message_markup {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('edit_message_markup', 3, \@args);
    my ($chat_id, $message_id, $markup) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({
        '@type'      => 'editMessageReplyMarkup',
        chat_id      => 0 + $chat_id,
        message_id   => 0 + $message_id,
        reply_markup => $markup,
    }, $cb);
    return;
}

sub scheduled {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('scheduled', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatScheduledMessages',
                  chat_id => 0 + $chat_id }, $cb);
    return;
}

sub react {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, $emoji, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id, emoji', $chat_id, $message_id, $emoji);
    my %req = (
        chat_id       => 0 + $chat_id,
        message_id    => 0 + $message_id,
        reaction_type => $self->reaction_type($emoji),
    );
    if ($opt{remove}) {
        $req{'@type'} = 'removeMessageReaction';
    } else {
        $req{'@type'} = 'addMessageReaction';
        $req{is_big} = json_bool($opt{is_big});
        $req{update_recent_reactions} =
            json_bool(exists $opt{update_recent} ? $opt{update_recent} : 1);
    }
    $self->send(\%req, $cb);
    return;
}

# replaces the whole set at once, where react() adds or removes one
sub set_reactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, $types, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id, reactions', $chat_id, $message_id, $types);
    croak 'reactions must be an arrayref' unless ref $types eq 'ARRAY';
    $self->send({
        '@type'         => 'setMessageReactions',
        chat_id         => 0 + $chat_id,
        message_id      => 0 + $message_id,
        reaction_types  => [ map { $self->reaction_type($_) } @$types ],
        is_big          => json_bool($opt{is_big}),
    }, $cb);
    return;
}

sub delete_reactions_from_sender {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_reactions_from_sender', 3, \@args);
    my ($chat_id, $message_id, $sender) = @args;
    need('chat_id, message_id, sender', $chat_id, $message_id, $sender);
    $self->send({ '@type' => 'deleteMessageReactionsFromSender',
                  chat_id => 0 + $chat_id, message_id => 0 + $message_id,
                  sender_id => $self->message_sender($sender) }, $cb);
    return;
}

sub clear_recent_reactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('clear_recent_reactions', 0, \@args);
    $self->send({ '@type' => 'clearRecentReactions' }, $cb);
    return;
}

# A paid reaction is staged and then committed, which is why it cannot go
# through react(): addMessageReaction rejects reactionTypePaid outright.
my %PAID_TYPE = (regular => 'paidReactionTypeRegular',
                 anonymous => 'paidReactionTypeAnonymous');

sub paid_reaction_type {
    my ($type) = @_;
    return { '@type' => 'paidReactionTypeRegular' } unless defined $type;
    return $type if ref $type eq 'HASH';
    return { '@type' => $PAID_TYPE{$type} } if $PAID_TYPE{$type};
    croak "paid reaction type must be 'regular', 'anonymous' or a chat id"
        unless $type =~ /\A\s*[+-]?[0-9]+\s*\z/;
    return { '@type' => 'paidReactionTypeChat', chat_id => 0 + $type };
}

sub add_paid_reaction {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, $stars, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id, star_count', $chat_id, $message_id, $stars);
    $self->send({ '@type' => 'addPendingPaidMessageReaction',
                  chat_id => 0 + $chat_id, message_id => 0 + $message_id,
                  star_count => 0 + $stars,
                  type => paid_reaction_type($opt{type}) }, $cb);
    return;
}

sub commit_paid_reactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('commit_paid_reactions', 2, \@args);
    my ($chat_id, $message_id) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'commitPendingPaidMessageReactions',
                  chat_id => 0 + $chat_id, message_id => 0 + $message_id }, $cb);
    return;
}

sub remove_paid_reactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('remove_paid_reactions', 2, \@args);
    my ($chat_id, $message_id) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'removePendingPaidMessageReactions',
                  chat_id => 0 + $chat_id, message_id => 0 + $message_id }, $cb);
    return;
}

sub set_paid_reaction_type {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_paid_reaction_type', 3, \@args);
    my ($chat_id, $message_id, $type) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'setPaidMessageReactionType',
                  chat_id => 0 + $chat_id, message_id => 0 + $message_id,
                  type => paid_reaction_type($type) }, $cb);
    return;
}

sub paid_reaction_senders {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('paid_reaction_senders', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatAvailablePaidMessageReactionSenders',
                  chat_id => 0 + $chat_id }, $cb);
    return;
}

# revoke deletes for everyone, not only for us; without it the message stays
# in the other side's history
sub delete_messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_ids, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_ids', $chat_id, $message_ids);
    croak 'delete_messages needs an arrayref of message ids'
        unless ref $message_ids eq 'ARRAY';
    $self->send({
        '@type' => 'deleteMessages',
        chat_id => 0 + $chat_id,
        message_ids => num_list('message_ids', $message_ids),
        revoke => json_bool(exists $opt{revoke} ? $opt{revoke} : 1),
    }, $cb);
    return;
}

sub forward_messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $from_chat_id, $message_ids, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, from_chat_id, message_ids',
          $chat_id, $from_chat_id, $message_ids);
    croak 'forward_messages needs an arrayref of message ids'
        unless ref $message_ids eq 'ARRAY';
    croak "forward_messages cannot wait for delivery: it always returns once "
        . "Telegram accepts the forward"
        if defined $opt{wait} && $opt{wait} ne 'accepted';
    my %req = (
        '@type' => 'forwardMessages',
        chat_id => 0 + $chat_id,
        from_chat_id => 0 + $from_chat_id,
        message_ids => num_list('message_ids', $message_ids),
        send_copy => json_bool($opt{send_copy}),
        remove_caption => json_bool($opt{remove_caption}),
    );
    if (my $o = send_options(\%opt)) { $req{options} = $o }
    if (my $t = topic_id(\%opt))    { $req{topic_id} = $t }
    $self->send(\%req, $cb);
    return;
}

sub send_poll {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $question, $options, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, question', $chat_id, $question);
    croak 'send_poll needs an arrayref of options' unless ref $options eq 'ARRAY';
    croak 'a poll needs at least two options' unless @$options >= 2;
    # a parse failure comes back as an error object; embedding it would send
    # TDLib nonsense instead of telling the caller what was wrong
    my $bad;
    my $fmt = sub {
        my $t = $self->format_text($_[0], $opt{parse_mode});
        $bad ||= $t if ($t->{'@type'} // '') eq 'error';
        return $t;
    };
    my $type = $opt{quiz}
        ? { '@type' => 'inputPollTypeQuiz',
            correct_option_ids => [ num('correct', $opt{correct} // 0) ],
            explanation => $fmt->($opt{explanation}) }
        : { '@type' => 'inputPollTypeRegular',
            allow_adding_options => json_bool($opt{allow_adding_options}) };
    my $content = {
        '@type'    => 'inputMessagePoll',
        question   => $fmt->($question),
        options    => [ map { +{ '@type' => 'inputPollOption',
                                 text => $fmt->($_) } } @$options ],
        type       => $type,
        # TDLib defaults is_anonymous to false, which surprises: Telegram's
        # own clients create anonymous polls
        is_anonymous => json_bool(exists $opt{anonymous} ? $opt{anonymous} : 1),
        allows_multiple_answers => json_bool($opt{multiple}),
        # left out, a vote could never be changed or taken back; a quiz is
        # the one poll whose answer is final
        allows_revoting => json_bool(exists $opt{revoting} ? $opt{revoting} : !$opt{quiz}),
        (defined $opt{open_period}
            ? (open_period => num('open_period', $opt{open_period})) : ()),
    };
    if ($bad) { $cb->(undef, $bad); return }
    $self->send_content($chat_id, $content, \%opt, $cb);
    return;
}

sub send_location {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $lat, $lon, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, latitude, longitude', $chat_id, $lat, $lon);
    $self->send_content($chat_id, {
        '@type'  => 'inputMessageLocation',
        location => { '@type' => 'location',
                      latitude => real('latitude', $lat),
                      longitude => real('longitude', $lon),
                      horizontal_accuracy => real('accuracy', $opt{accuracy} // 0) },
    }, \%opt, $cb);
    return;
}

sub send_contact {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $phone, $first, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, phone, first_name', $chat_id, $phone, $first);
    $self->send_content($chat_id, {
        '@type'  => 'inputMessageContact',
        contact  => { '@type' => 'contact',
                      phone_number => plain_text('a phone number', $phone),
                      first_name   => plain_text('a first name', $first),
                      last_name    => plain_text('a last name', $opt{last_name}),
                      vcard        => plain_text('a vcard', $opt{vcard}),
                      user_id      => num('user_id', $opt{user_id} // 0) },
    }, \%opt, $cb);
    return;
}

# TDLib counts entity offsets and lengths in UTF-16 code units, which is not
# what perl's substr counts: any character outside the BMP is two units but
# one character, so substr silently returns the wrong run. The offsets are
# left exactly as TDLib sent them -- they travel back unchanged when a
# message is forwarded, edited or copied, and rewriting them would corrupt
# that -- so slicing is offered here instead.
sub entity_text {
    my ($self, $ft, $entity) = @_;
    ($ft, $entity) = ($self, $ft) if @_ == 2;   # usable as a plain function
    croak 'entity_text needs a formattedText and an entity'
        unless ref $ft eq 'HASH' && ref $entity eq 'HASH';
    my $text = $ft->{text};
    return undef unless defined $text;
    my ($off, $len) = @{$entity}{qw(offset length)};
    return undef unless defined $off && defined $len;
    my $units = Encode::encode('UTF-16LE', $text);
    return undef if $off * 2 > length $units;
    return Encode::decode('UTF-16LE', substr $units, $off * 2, $len * 2);
}

# Every entity of a formattedText, already sliced. Each element carries the
# entity's own fields plus the text it covers, so a caller never touches an
# offset at all.
sub entity_texts {
    my ($self, $ft) = @_;
    $ft = $self if @_ == 1;
    croak 'entity_texts needs a formattedText' unless ref $ft eq 'HASH';
    my @out;
    for my $e (@{ $ft->{entities} || [] }) {
        push @out, {
            %$e,
            # guarded: reaching through a missing type would autovivify it
            # in the caller's own entity
            type => (ref $e->{type} eq 'HASH' ? $e->{type}{'@type'} : undef),
            text => entity_text($ft, $e),
        };
    }
    return \@out;
}

# option ids are zero-based positions in the list the poll was created with
sub answer_poll {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('answer_poll', 3, \@args);
    my ($chat_id, $message_id, $options) = @args;
    need('chat_id, message_id, option_ids', $chat_id, $message_id, $options);
    croak 'answer_poll needs an arrayref of option ids' unless ref $options eq 'ARRAY';
    $self->send({ '@type' => 'setPollAnswer', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id,
                  option_ids => num_list('option_ids', $options) }, $cb);
    return;
}

sub stop_poll {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id', $chat_id, $message_id);
    my %req = ('@type' => 'stopPoll', chat_id => 0 + $chat_id,
               message_id => 0 + $message_id);
    $req{reply_markup} = $opt{reply_markup} if $opt{reply_markup};
    $self->send(\%req, $cb);
    return;
}

sub message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('message', 2, \@args);
    my ($chat_id, $message_id) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'getMessage', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id }, $cb);
    return;
}

sub messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('messages', 2, \@args);
    my ($chat_id, $ids) = @args;
    need('chat_id, message_ids', $chat_id, $ids);
    croak 'messages needs an arrayref of message ids' unless ref $ids eq 'ARRAY';
    $self->send({ '@type' => 'getMessages', chat_id => 0 + $chat_id,
                  message_ids => num_list('message_ids', $ids) }, $cb);
    return;
}

sub replied_message {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('replied_message', 2, \@args);
    my ($chat_id, $message_id) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'getRepliedMessage', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id }, $cb);
    return;
}

sub message_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({
        '@type'             => 'getMessageLink',
        chat_id             => 0 + $chat_id,
        message_id          => 0 + $message_id,
        media_timestamp     => num('media_timestamp', $opt{media_timestamp} // 0),
        for_album           => json_bool($opt{for_album}),
        in_message_thread   => json_bool($opt{in_thread}),
    }, $cb);
    return;
}

sub message_link_info {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('message_link_info', 1, \@args);
    my ($url) = @args;
    need('url', $url);
    $self->send({ '@type' => 'getMessageLinkInfo',
                  url => plain_text('a url', $url) }, $cb);
    return;
}

sub message_count {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    # TDLib rejects searchMessagesFilterEmpty here, so an omitted filter would
    # produce a request that can never succeed; refuse it at the call site
    croak 'message_count needs a filter, such as Photo, Video, Document or Url '
        . '(TDLib cannot count unfiltered)'
        unless defined $opt{filter};
    my %req = ('@type' => 'getChatMessageCount', chat_id => 0 + $chat_id,
               filter => tl_class('searchMessagesFilter',
                                   'SearchMessagesFilter',
                                   'message filter', $opt{filter}),
               return_local => json_bool($opt{local}));
    if (my $t = topic_id(\%opt)) { $req{topic_id} = $t }
    $self->send(\%req, $cb);
    return;
}

sub available_reactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'getMessageAvailableReactions',
                  chat_id => 0 + $chat_id, message_id => 0 + $message_id,
                  row_size => num('row_size', $opt{row_size} // 8) }, $cb);
    return;
}

sub message_reactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id', $chat_id, $message_id);
    my %req = ('@type' => 'getMessageAddedReactions',
               chat_id => 0 + $chat_id, message_id => 0 + $message_id,
               offset => plain_text('an offset', $opt{offset}),
               limit  => num('limit', $opt{limit} // 50));
    $req{reaction_type} = $self->reaction_type($opt{reaction} // $opt{emoji})
        if defined $opt{reaction} || defined $opt{emoji};
    $self->send(\%req, $cb);
    return;
}

sub set_default_reaction {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_default_reaction', 1, \@args);
    my ($reaction) = @args;
    need('reaction', $reaction);
    $self->send({ '@type' => 'setDefaultReactionType',
                  reaction_type => $self->reaction_type($reaction) }, $cb);
    return;
}

# an empty text clears the draft, which is how TDLib spells "no draft"
sub set_draft {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $text, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    my %req = ('@type' => 'setChatDraftMessage', chat_id => 0 + $chat_id);
    if (my $t = topic_id(\%opt)) { $req{topic_id} = $t }
    if (defined $text && length $text) {
        my $formatted = $self->format_text($text, $opt{parse_mode});
        if (($formatted->{'@type'} // '') eq 'error') {
            $cb->(undef, $formatted);
            return;
        }
        $req{draft_message} = {
            '@type'  => 'draftMessage',
            # the field is required by the TL, but TDLib overwrites it with
            # its own clock before storing the draft, so there is nothing for
            # a caller to set here
            date     => 0,
            content  => { '@type' => 'draftMessageContentText', text => $formatted },
            ($opt{reply_to}
                ? (reply_to => { '@type' => 'inputMessageReplyToMessage',
                                 message_id => num('reply_to', $opt{reply_to}) })
                : ()),
        };
    }
    $self->send(\%req, $cb);
    return;
}

sub clear_drafts {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my (@rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'clearAllDraftMessages',
                  exclude_secret_chats =>
                      json_bool(exists $opt{exclude_secret} ? $opt{exclude_secret} : 1) }, $cb);
    return;
}

# an album is one message group: several media sent and shown together
sub send_album {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $contents, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, contents', $chat_id, $contents);
    croak 'send_album needs an arrayref of message contents'
        unless ref $contents eq 'ARRAY';
    croak 'an album needs at least one item' unless @$contents;
    # an album's reply carries one message per item, so there is no single
    # send-succeeded to wait for. Only the mode that cannot be honoured is
    # refused: wait => 'accepted' is a true statement of what happens, and
    # croaking on it broke callers who were describing the behaviour, not
    # asking to change it.
    croak "send_album cannot wait for delivery: it always returns once "
        . "Telegram accepts the album"
        if defined $opt{wait} && $opt{wait} ne 'accepted';
    my %req = ('@type' => 'sendMessageAlbum', chat_id => 0 + $chat_id,
               input_message_contents => $contents);
    $req{reply_to} = { '@type' => 'inputMessageReplyToMessage',
                       message_id => num('reply_to', $opt{reply_to}) }
        if $opt{reply_to};
    if (my $o = send_options(\%opt)) { $req{options}  = $o }
    if (my $t = topic_id(\%opt))     { $req{topic_id} = $t }
    $self->send(\%req, $cb);
    return;
}

sub edit_message_caption {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, $caption, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id', $chat_id, $message_id);
    my $formatted = $self->format_text($caption // '', $opt{parse_mode});
    if (($formatted->{'@type'} // '') eq 'error') {
        $cb->(undef, $formatted);
        return;
    }
    $self->send({
        '@type'   => 'editMessageCaption',
        chat_id   => 0 + $chat_id,
        message_id => 0 + $message_id,
        reply_markup => $opt{reply_markup},
        caption   => $formatted,
        show_caption_above_media => json_bool($opt{caption_above}),
    }, $cb);
    return;
}

sub edit_message_media {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, $content, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id, content', $chat_id, $message_id, $content);
    $self->send({ '@type' => 'editMessageMedia', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id,
                  reply_markup => $opt{reply_markup},
                  input_message_content => $content }, $cb);
    return;
}

# passing no schedule sends the message now
sub reschedule {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('reschedule', 3, \@args);
    my ($chat_id, $message_id, $when) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    my %req = ('@type' => 'editMessageSchedulingState',
               chat_id => 0 + $chat_id, message_id => 0 + $message_id);
    $req{scheduling_state} = { '@type' => 'messageSchedulingStateSendAtDate',
                               send_date => unix_time('when', $when),
                               repeat_period => 0 }
        if $when;
    $self->send(\%req, $cb);
    return;
}

# live_period and friends belong inside the liveLocation wrapper, as they do
# for the inline form
sub edit_message_location {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, $location, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({
        '@type'      => 'editMessageLiveLocation',
        chat_id      => 0 + $chat_id,
        message_id   => 0 + $message_id,
        reply_markup => $opt{reply_markup},
        location     => $location ? {
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

sub resend_messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('resend_messages', 2, \@args);
    my ($chat_id, $ids) = @args;
    need('chat_id, message_ids', $chat_id, $ids);
    croak 'resend_messages needs an arrayref of message ids' unless ref $ids eq 'ARRAY';
    $self->send({ '@type' => 'resendMessages', chat_id => 0 + $chat_id,
                  message_ids => num_list('message_ids', $ids) }, $cb);
    return;
}

sub message_thread {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('message_thread', 2, \@args);
    my ($chat_id, $message_id) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'getMessageThread', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id }, $cb);
    return;
}

sub thread_history {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $message_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'getMessageThreadHistory', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id,
                  from_message_id => num('from_message_id', $opt{from_message_id} // 0),
                  offset => num('offset', $opt{offset} // 0),
                  limit  => num('limit', $opt{limit} // 50) }, $cb);
    return;
}

sub read_date {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('read_date', 2, \@args);
    my ($chat_id, $message_id) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'getMessageReadDate', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id }, $cb);
    return;
}

sub message_viewers {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('message_viewers', 2, \@args);
    my ($chat_id, $message_id) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'getMessageViewers', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id }, $cb);
    return;
}

sub message_properties {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('message_properties', 2, \@args);
    my ($chat_id, $message_id) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'getMessageProperties', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id }, $cb);
    return;
}

# marks self-destructing media as opened, which starts its timer
sub open_content {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('open_content', 2, \@args);
    my ($chat_id, $message_id) = @args;
    need('chat_id, message_id', $chat_id, $message_id);
    $self->send({ '@type' => 'openMessageContent', chat_id => 0 + $chat_id,
                  message_id => 0 + $message_id }, $cb);
    return;
}

sub message_by_date {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('message_by_date', 2, \@args);
    my ($chat_id, $date) = @args;
    need('chat_id, date', $chat_id, $date);
    $self->send({ '@type' => 'getChatMessageByDate', chat_id => 0 + $chat_id,
                  date => unix_time('date', $date) }, $cb);
    return;
}

sub unpin_all {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('unpin_all', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'unpinAllChatMessages', chat_id => 0 + $chat_id }, $cb);
    return;
}

sub read_all_mentions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('read_all_mentions', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'readAllChatMentions', chat_id => 0 + $chat_id }, $cb);
    return;
}

sub delete_messages_by_sender {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_messages_by_sender', 2, \@args);
    my ($chat_id, $sender) = @args;
    need('chat_id, sender', $chat_id, $sender);
    $self->send({ '@type' => 'deleteChatMessagesBySender', chat_id => 0 + $chat_id,
                  sender_id => $self->message_sender($sender) }, $cb);
    return;
}

sub delete_messages_by_date {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $min, $max, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, min_date, max_date', $chat_id, $min, $max);
    $self->send({ '@type' => 'deleteChatMessagesByDate', chat_id => 0 + $chat_id,
                  min_date => unix_time('min_date', $min),
                  max_date => unix_time('max_date', $max),
                  revoke => json_bool(exists $opt{revoke} ? $opt{revoke} : 1) }, $cb);
    return;
}


# these three are synchronous in TDLib, but go through send() like the rest so
# one calling convention covers everything
sub parse_markdown {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('parse_markdown', 1, \@args);
    my ($text) = @args;
    need('text', $text);
    $self->send({ '@type' => 'parseMarkdown', text => $self->format_text($text) }, $cb);
    return;
}

sub markdown_text {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('markdown_text', 1, \@args);
    my ($formatted) = @args;
    need('text', $formatted);
    croak 'markdown_text needs a formattedText hashref'
        unless ref $formatted eq 'HASH';
    $self->send({ '@type' => 'getMarkdownText', text => $formatted }, $cb);
    return;
}

sub text_entities {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('text_entities', 1, \@args);
    my ($text) = @args;
    need('text', $text);
    $self->send({ '@type' => 'getTextEntities',
                  text => plain_text('the text', $text) }, $cb);
    return;
}

sub translate {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($text, $to, @rest) = @args;
    my %opt = opts(@rest);
    need('text, to_language_code', $text, $to);
    $self->send({ '@type' => 'translateText', text => $self->format_text($text),
                  to_language_code => plain_text('a language code', $to),
                  tone => plain_text('a tone', $opt{tone}) }, $cb);
    return;
}

sub link_preview {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('link_preview', 1, \@args);
    my ($text) = @args;
    need('text', $text);
    $self->send({ '@type' => 'getLinkPreview', text => $self->format_text($text) }, $cb);
    return;
}

sub search_hashtags {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($prefix, @rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'searchHashtags',
                  prefix => plain_text('a prefix', $prefix),
                  limit => num('limit', $opt{limit} // 20) }, $cb);
    return;
}

1;
