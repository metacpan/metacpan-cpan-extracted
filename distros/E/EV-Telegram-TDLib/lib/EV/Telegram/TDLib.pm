package EV::Telegram::TDLib;

use strict;
use warnings;
use Carp qw(croak);
use EV;
use Cpanel::JSON::XS;
use XSLoader;
use overload ();
use Scalar::Util ();
use EV::Telegram::TDLib::Users;
use EV::Telegram::TDLib::Chats;
use EV::Telegram::TDLib::Messages;
use EV::Telegram::TDLib::Files;
use EV::Telegram::TDLib::Connection;
use EV::Telegram::TDLib::Bots;
use EV::Telegram::TDLib::WebApps;
use EV::Telegram::TDLib::Forum;
use EV::Telegram::TDLib::Folders;
use EV::Telegram::TDLib::Payments;
use EV::Telegram::TDLib::Secret;
use EV::Telegram::TDLib::Stories;
use EV::Telegram::TDLib::Stickers;
use EV::Telegram::TDLib::Stars;
use EV::Telegram::TDLib::Business;
use EV::Telegram::TDLib::Schema;

our $VERSION = '0.04';

our @ISA = map { "EV::Telegram::TDLib::$_" }
    qw(Users Chats Messages Files Connection Bots WebApps Forum Folders Payments
       Secret Stories Stickers Stars Business);

XSLoader::load('EV::Telegram::TDLib', $VERSION);

sub CLONE_SKIP { 1 }

my $JSON = Cpanel::JSON::XS->new->utf8->canonical(0)->allow_nonref;

my %CLIENTS;

sub execute {
    my ($proto, $request) = @_;
    my $json = _execute($JSON->encode($request));
    return undef unless defined $json;
    return $JSON->decode($json);
}

# TDLib's own default verbosity is 5, which writes api_hash and bot_token to
# stderr in clear. So an unusable setting must fall back to our default, not
# to TDLib's: `//` does not fire for an exported-but-empty variable, and
# TDLib rejects a value it cannot parse, which would leave the level at 5.
sub set_log_verbosity {
    my ($level) = @_;
    $level = 1 unless defined $level && $level =~ /\A[0-9]+\z/;
    my $set = sub {
        my $json = _execute($JSON->encode({
            '@type' => 'setLogVerbosityLevel',
            new_verbosity_level => 0 + $_[0],
        }));
        my $r = defined $json ? eval { $JSON->decode($json) } : undef;
        return ref $r eq 'HASH' && ($r->{'@type'} // '') ne 'error';
    };
    # Shape alone is not enough: TDLib also has a range, and it refuses
    # anything outside it -- which leaves the level where it already was,
    # at TDLib's own 5. Ask whether it took, rather than pin the range to a
    # constant that a version bump can move underneath us.
    return $level if $set->($level);
    $set->(1);
    return 1;
}

set_log_verbosity($ENV{TDLIB_LOG_VERBOSITY});

sub login {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    # the callback went in a fixed first slot: login(undef, $cb) never called
    # back, and waiting on it waited forever. A lone undef still means none.
    shift @args if @args == 1 && !defined $args[0];
    no_extra('login', 0, \@args);
    # tdjson creates the client, and emits its first update, only once a request
    # reaches it; the auth flow is driven entirely by updateAuthorizationState,
    # so without this a fresh client waits forever
    $self->send({ '@type' => 'getAuthorizationState' }, sub {})
        if ($self->{state} // '') eq 'created' && !$self->{kicked}++;
    my $state = $self->{state} // '';
    if ($state ne 'authorizationStateReady'
            && $state ne 'authorizationStateClosed'
            && !$self->{login_failed}) {
        # chain, never replace: close() has the same contract
        push @{ $self->{login_cbs} }, $cb;
        return;
    }
    # fire deferred, never inline: an inconsistently timed callback is worse
    my $err = $state eq 'authorizationStateReady'  ? undef
            : $state eq 'authorizationStateClosed'
                ? { '@type' => 'error', code => -1,
                    message => 'client is already closed' }
            : $self->{login_failed};
    push @{ $self->{login_late} }, [ $cb, $err ];
    $self->{login_deferred} ||= EV::timer 0, 0, sub {
        delete $self->{login_deferred};
        for my $late (@{ delete $self->{login_late} || [] }) {
            my ($cb, $err) = @$late;
            $self->guarded($cb, undef, $err ? { %$err } : undef);
        }
    };
    return;
}

sub auth_state { shift->{state} }

sub fail_login {
    my ($self, $message, $code) = @_;
    # TDLib's own code is kept: a login refused with 429 must still be
    # readable by retry_after
    my $err = { '@type' => 'error', code => $code // -1, message => $message };
    # the FSM never re-emits a failed state, so a later login() must fail fast
    $self->{login_failed} //= $err;
    my $cbs = delete $self->{login_cbs};
    if ($cbs) {
        $self->guarded($_, undef, { %$err }) for @$cbs;
    } else {
        $self->emit_error($message);
    }
}

# only a correlated error matters, and only while the FSM is still in that state
sub auth_reply_cb {
    my ($self, $stype, $on_error) = @_;
    return sub {
        my ($res, $err) = @_;
        return unless $err;
        return unless $self->{client_id};
        return if ($self->{state} // '') ne $stype;
        $on_error->($err);
    };
}

# automatic steps take constructor values: no interactive retry path
sub auth_fail_cb {
    my ($self, $stype, $what) = @_;
    return $self->auth_reply_cb($stype, sub {
        my ($err) = @_;
        $self->fail_login("$what: $err->{message}", $err->{code});
    });
}

# A callback written before a method's options lands in its optional flag,
# where it read as true and was dropped without a word. \0 is refused rather
# than read as false: most flags are tested as perl sees them, where it is true.
sub json_bool {
    my ($v) = @_;
    _croak(ref $v eq 'CODE'
           ? 'a flag cannot be the callback; the callback goes last'
           : 'a flag must be true or false, not a ' . lc(ref $v) . ' reference'
             . (ref $v eq 'SCALAR' ? '; pass 0 or 1' : ''))
        if ref $v && !Scalar::Util::blessed($v);
    return $v ? \1 : \0;
}

# a missing required argument must fail at the call site: passing it on
# would warn from inside the module and send TDLib a malformed request
# An odd option list means a name landed in a positional slot: the pairs then
# shift by one and the request says something the caller never asked for --
# install_sticker_set(..., archived => 1) installed rather than archived, and
# mute_scope('private', preview => 0) unmuted. Perl only warns, from in here.
sub opts {
    if (!(@_ % 2)) {
        # An undef or a ref where a name belongs is the even-count half of the
        # same mistake -- method(undef, undef) forwarding two absent arguments
        # -- and it was handled worse than the odd one: a warning from inside
        # the module, then the request sent anyway with whatever the options it
        # never saw default to.
        for (my $i = 0; $i < @_; $i += 2) {
            next if defined $_[$i] && !ref $_[$i];
            _croak('an option name must be a string, not '
                 . (defined $_[$i] ? lc(ref $_[$i]) . ' reference' : 'undef'));
        }
        return @_;
    }
    # A lone trailing undef is ambiguous and cannot be resolved from here:
    # mark_read($chat, undef) forwarding an absent callback and
    # install_sticker_set($id, archived => undef) are the same list. Popping
    # it to help the first silently mispaired the second, which installed the
    # set instead of archiving it and, for process_join_requests, approved
    # every pending request. So neither is guessed: both croak, and the
    # message says what to write instead.
    _croak('options must be given as name => value pairs'
         . (@_ == 1 && !defined $_[0]
            ? '; to pass an optional callback through, omit it when it is'
            . ' undef rather than forwarding undef'
            : ''));
}

# Carp prints every frame's arguments when it produces a backtrace -- under
# Carp::Always or $Carp::Verbose, which is exactly what gets switched on when
# a login is misbehaving. The stack below any of our validators holds a
# constructor's or a sender's argument list, so it carries the api_hash, the
# bot token and the encryption key. MaxArgNums is the knob that suppresses
# them; MaxArgLen only shortens each one and still prints enough to matter.
sub _croak {
    local $Carp::MaxArgNums = -1;
    croak(@_);
}

# A short enum name is expanded into a TL class name. Checked against the
# pinned catalogue rather than a hand-kept list, so a typo croaks here instead
# of reaching TDLib as a class that does not exist, and the check follows the
# schema across a version bump.
sub tl_class {
    my ($prefix, $base, $what, $name) = @_;
    $name = plain_text($what, $name);
    my $class = $name =~ /\A\Q$prefix\E/ ? $name : $prefix . $name;
    croak "unknown $what '$name'"
        unless ($EV::Telegram::TDLib::Schema::CLASS_BASE{$class} // '') eq $base;
    return { '@type' => $class };
}

# For the methods whose last argument is a flag rather than an option list.
# close_topic($chat, $topic, closed => 0) put the string 'closed' in the flag
# and closed the topic -- the same inversion opts catches for the methods
# that do take options, which these never reached because they have none.
# A non-number in a numeric slot makes 0 + warn from inside this module, and
# Carp::Always longmesses warnings as well as deaths -- so on the handful of
# methods that take an account password, that warning carries it. _croak
# instead, which suppresses the arguments.
sub num {
    my ($what, $n) = @_;
    not_a_number($what, $n)
        unless defined $n && !ref $n && $n =~ /\A\s*[+-]?[0-9]+\s*\z/;
    return 0 + $n;
}

# 0 + numifies a reference to its address: reply_to => $message sent that as
# the message id, and TDLib quietly sent a plain message instead of a reply
my $REAL = qr/\A\s*[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?\s*\z/;

sub not_a_number {
    my ($what, $n) = @_;
    _croak("$what must be a "
         . (defined $n && !ref $n && $n =~ $REAL ? 'whole number' : 'number')
         . (ref $n eq 'CODE' ? ', not the callback; the callback goes last' : ''));
}

# the TL doubles: coordinates, and durations and timestamps in seconds
sub real {
    my ($what, $n) = @_;
    not_a_number($what, $n) unless defined $n && !ref $n && $n =~ $REAL;
    return 0 + $n;
}

sub num_list {
    my ($what, $list) = @_;
    _croak("$what must be an arrayref") unless ref $list eq 'ARRAY';
    return [ map { num("each of $what", $_) } @$list ];
}

sub text_list {
    my ($what, $list) = @_;
    _croak("$what must be an arrayref") unless ref $list eq 'ARRAY';
    return [ map { plain_text("each of $what", $_) } @$list ];
}

# A duration where a Unix time belongs lands in 1970, and TDLib does not say
# so: a message scheduled for then is sent at once, a status expiring then is
# cleared, and a ban ending then is made permanent.
sub unix_time {
    my ($what, $n) = @_;
    $n = num($what, $n);
    _croak("$what is a Unix time, not a duration: add time() to it")
        if $n != 0 && $n < 1_000_000_000;
    return $n;
}

# An option-less method given name => value where a value goes took the name
# as the value: set_chat_title($chat, title => 'New') renamed the chat "title".
sub no_extra {
    my ($what, $max, $args) = @_;
    return if @$args <= $max;
    _croak("$what takes "
         . ($max == 0 ? 'no arguments'
            : "at most $max argument" . ($max == 1 ? '' : 's'))
         . ' before its callback, and no options'
         . (@$args == $max + 1 && !defined $args->[-1]
            ? '; to pass an optional callback through, omit it when it is'
            . ' undef rather than forwarding undef'
            : ''));
}

# A name, title, bio, username or description is a plain string in the TL,
# with nowhere for a formattedText's entities to go: any reference but an
# object that stringifies would reach Telegram as HASH(0x...).
sub plain_text {
    my ($what, $v) = @_;
    _croak("$what must be a string") if ref $v && !overload::Method($v, '""');
    return defined $v ? "$v" : '';
}

# a path, or an already-built inputFile of any kind passed straight through.
# Shared rather than repeated: three mixins had a copy each, identical in
# behaviour.
sub input_file {
    my ($f) = @_;
    if (ref $f eq 'HASH') {
        # waving any hashref through sent a formattedText as the file and
        # TDLib answered "InputFile is not specified", naming nothing
        my $type = $f->{'@type'} // '';
        _croak('a file must be a path or an inputFile*, not '
               . ($type || 'a hashref without an @type'))
            unless ($EV::Telegram::TDLib::Schema::CLASS_BASE{$type} // '')
                   eq 'InputFile';
        return $f;
    }
    return { '@type' => 'inputFileLocal', path => plain_text('a path', $f) };
}

sub no_opts {
    my ($what, @rest) = @_;
    _croak("$what takes no options; its last argument is the flag itself, "
         . "so pass it positionally") if @rest;
}

# send and call name the callback before their options, and every other method
# takes it last. Both positions are accepted so the one rule CONVENTIONS states
# holds here too: writing an option where the callback belongs used to swallow
# the option and croak. An explicit undef in the leading slot still means none.
sub cb_slot {
    my ($what, $rest) = @_;
    return shift @$rest if @$rest && ref $rest->[0]  eq 'CODE';
    return pop   @$rest if @$rest && ref $rest->[-1] eq 'CODE';
    return shift @$rest if @$rest % 2 && !defined $rest->[0];
    _croak("$what takes its callback before or after its options, not a "
         . ref($rest->[0])) if @$rest % 2 && ref $rest->[0];
    return undef;
}

# Every handler new() accepts: the single-slot on_* methods, which may equally
# be set at construction, plus on_close and the login handlers, which have no
# method of their own. The keyed ones are deliberately absent -- they need a
# key, so a constructor option could only store a callback nothing looks up.
my %CTOR_HANDLER = map { $_ => 1 } qw(
    on_update on_error on_message on_chat on_user on_connection_state
    on_callback_query on_inline_query on_join_request on_web_app_data
    on_pre_checkout_query on_shipping_query on_business_connection
    on_business_message on_story on_story_deleted on_active_stories
    on_close on_code on_password on_email on_email_code on_qr
);

# every option new() consults; the handlers above are accepted on top of these
my %CTOR_OPT = map { $_ => 1 } qw(
    api_id api_hash phone_number bot_token register auto_auth retry
    database_directory files_directory database_encryption_key use_test_dc
    use_file_database use_chat_info_database use_message_database
    use_secret_chats application_name application_version
    system_language_code device_model system_version
);

# The argument names passed to need that the schema declares int32 or int53
# everywhere they appear, so they always cross as a JSON number. Names that
# are integer in some classes and something else in others are deliberately
# absent -- offset is also an opaque string cursor, position and duration are
# also an object and a double -- as are the int64 ids (session, sticker set,
# callback query, sound, profile photo), which cross as strings.
my %NUMERIC_ID = map { $_ => 1 } qw(
    chat_id from_chat_id story_poster_chat_id shared_chat_id message_id
    user_id bot_user_id opened_bot_user_id supergroup_id basic_group_id
    secret_chat_id file_id story_id story_album_id forum_topic_id
    chat_folder_id proxy_id shortcut_id accent_color_id button_id
    limit score date min_date max_date inactive_session_ttl_days star_count
);

sub need {
    my ($what, @args) = @_;
    my @names = split /,\s*/, $what;
    for my $i (0 .. $#args) {
        my $name = $names[$i] // 'argument';
        # _croak throughout: a login or a send is on the stack here, so the
        # backtrace would carry the phone number, the token or the key
        _croak("$name is required") unless defined $args[$i];
        # the callback landed in a positional slot: it is defined, so the
        # check above passes, and the coderef's address would go out as the id
        _croak("$name is required, but received the callback instead")
            if ref $args[$i] eq 'CODE';
        # An option name shifted into an id slot -- mark_unread(unread => 0)
        # with the chat omitted -- is defined and passes both checks above,
        # and then 0 + warns from inside the module and sends "chat_id":0.0,
        # a JSON float where the schema declares an integer.
        # Surrounding space and a leading sign are allowed because perl
        # numifies those silently and correctly: an id read from a config
        # file or the environment without a chomp is not the mistake here.
        _croak("$name must be a number")
            if $NUMERIC_ID{$name}
            && (ref $args[$i] || $args[$i] !~ /\A\s*[+-]?[0-9]+\s*\z/);
    }
    return 1;
}

# Registration methods, deliberately not constructor options: new() lifts every
# on_* key onto the object, so passing one there would store a dead scalar and
# never fire.
sub on_command {
    my ($self, $name, $cb) = @_;
    need('command name', $name);
    $name =~ s{\A/}{};
    if (@_ > 2 && !defined $cb) { delete $self->{commands}{$name}; return }
    croak 'on_command needs a callback' unless ref $cb eq 'CODE';
    $self->{commands}{$name} = $cb;
    # the ready transition resolves the username, but handlers registered from
    # inside login()'s callback arrive after it: resolve here as well, or the
    # /command@username form could never match for the life of the process
    $self->resolve_my_username
        if $self->{state} && $self->{state} eq 'authorizationStateReady'
        && !defined $self->{my_username} && !$self->{my_username_pending};
    return;
}

# an arrayref, not a hash: a hash keyed by pattern would iterate in a
# randomized order, so which handler ran first would vary per process
sub on_callback_data {
    my ($self, $pattern, $cb) = @_;
    need('pattern', $pattern);
    if (@_ > 2 && !defined $cb) {
        $self->{callback_routes} = [ grep { "$_->[0]" ne "$pattern" }
                                     @{ $self->{callback_routes} || [] } ];
        return;
    }
    croak 'on_callback_data needs a callback' unless ref $cb eq 'CODE';
    push @{ $self->{callback_routes} }, [ $pattern, $cb ];
    return;
}

# Entity offsets are UTF-16 code units, but a command is ASCII at offset 0, so
# indexing by one is safe here and nowhere else.
sub route_command {
    my ($self, $msg) = @_;
    return unless $self->{commands} && %{ $self->{commands} };
    return if $msg->{is_outgoing};
    my $content = $msg->{content} // {};
    # a command sent as a media caption is an ordinary way to talk to a bot,
    # and TDLib puts the same bot-command entity there. answer_ask already
    # accepts a media message, so refusing one here was inconsistent too.
    my $ft = ($content->{'@type'} // '') eq 'messageText'
           ? $content->{text} : $content->{caption};
    return unless ref $ft eq 'HASH';
    my $text = $ft->{text};
    return unless defined $text;
    my ($ent) = grep {
        ($_->{offset} // -1) == 0
            && (($_->{type}{'@type'} // '') eq 'textEntityTypeBotCommand')
    } @{ $ft->{entities} || [] };
    my $len = $ent ? $ent->{length} : undef;
    my $token = defined $len ? substr($text, 0, $len)
              : $text =~ /\A(\/\S+)/ ? $1 : return;
    return unless $token =~ m{\A/(\w+)(?:\@(\S+))?\z};
    my ($name, $addressed) = ($1, $2);
    if (defined $addressed) {
        my $mine = $self->{my_username};
        # a getMe that failed at the Ready transition would otherwise leave
        # every addressed command unmatched for the life of the process, since
        # nothing else asks again; ask now, so the next one matches
        $self->resolve_my_username unless defined $mine;
        return unless defined $mine && lc $addressed eq lc $mine;
    }
    my $cb = $self->{commands}{$name} or return;
    my $args = substr($text, length $token);
    $args =~ s/\A\s+//;
    $self->guarded($cb, $msg, $args);
    return 1;
}

# numified, not interpolated: the update side supplies integers, so a caller
# passing '1e15' or '007' would key a different slot from the answer
sub ask_key {
    my ($chat_id, $user_id) = @_;
    return (0 + $chat_id) . ':' . (0 + $user_id);
}

sub finish_ask {
    my ($self, $key, @args) = @_;
    # cleared before the callback runs, so an ask issued from inside it -- the
    # natural way to build a multi-step flow -- is not clobbered by its parent
    my $entry = delete $self->{asks}{$key} or return;
    $entry->{timer}->stop if $entry->{timer};
    undef $entry->{timer};
    $self->guarded($entry->{cb}, @args);
    return 1;
}

sub answer_ask {
    my ($self, $msg) = @_;
    return unless $self->{asks} && %{ $self->{asks} };
    return if $msg->{is_outgoing};
    my $sender = $msg->{sender_id} // {};
    return unless ($sender->{'@type'} // '') eq 'messageSenderUser';
    my $key = ask_key($msg->{chat_id}, $sender->{user_id});
    return unless $self->{asks}{$key};
    return $self->finish_ask($key, $msg, undef);
}

sub ask {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $user_id, $prompt, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, user_id, prompt', $chat_id, $user_id, $prompt);
    my $key = ask_key($chat_id, $user_id);

    $self->finish_ask($key, undef, { '@type' => 'error', code => -1,
                                      message => 'ask superseded' });

    my %entry = (cb => $cb);
    my ($installed, $failed) = (0, 0);

    # sent before anything is armed: send_message croaks on a bad parse_mode
    # or wait mode, and an ask left installed by a call that died would answer
    # the user's next message as though the call had succeeded
    $self->send_message($chat_id, $prompt, %opt, sub {
        my (undef, $err) = @_;
        # nothing to wait for if the prompt never arrived: leaving the ask
        # installed would sit until the timeout while the user saw nothing
        return unless $err;
        if (!$installed) { $failed = 1; $self->guarded($cb, undef, $err); return }
        # only our own entry: a cancel or a later ask may have replaced it
        # between the send and this reply, and dropping that one would strand
        # a callback still owed an answer
        return unless ($self->{asks}{$key} // 0) == \%entry;
        delete $self->{asks}{$key};
        $entry{timer}->stop if $entry{timer};
        $self->guarded($cb, undef, $err);
    });
    return if $failed;

    my $timeout = exists $opt{timeout} ? $opt{timeout} : 300;
    $timeout = real('timeout', $timeout) if defined $timeout;
    if ($timeout) {
        EV::now_update();
        $entry{timer} = EV::timer $timeout, 0, sub {
            $self->finish_ask($key, undef, { '@type' => 'error', code => -1,
                                              message => 'ask timed out' });
        };
    }
    # An ask issued from inside the supersede callback installs itself while
    # we are here, and its own supersede callback may do the same again, so
    # displace until the key is free: overwriting would strand a callback and
    # leave its timer armed to fire on whoever holds the key later. Bounded,
    # because the callbacks doing this are the caller's.
    my $superseded = sub { { '@type' => 'error', code => -1,
                             message => 'ask superseded' } };
    my $depth = 0;
    while ($self->{asks}{$key} && ++$depth <= 32) {
        $self->finish_ask($key, undef, $superseded->());
    }
    # a chain that will not settle inside the bound must still not be
    # overwritten: drop it, stop its timer so it cannot fire on whoever holds
    # the key next, and answer it from a fresh callback rather than inline,
    # which would re-enter the same chain
    if (my $stuck = delete $self->{asks}{$key}) {
        $stuck->{timer}->stop if $stuck->{timer};
        undef $stuck->{timer};
        my $w; $w = EV::timer 0, 0, sub {
            undef $w;
            $self->guarded($stuck->{cb}, undef, $superseded->());
        };
    }
    $installed = 1;
    $self->{asks}{$key} = \%entry;
    return;
}

sub cancel_ask {
    my ($self, $chat_id, $user_id) = @_;
    need('chat_id, user_id', $chat_id, $user_id);
    return $self->finish_ask(ask_key($chat_id, $user_id), undef,
        { '@type' => 'error', code => -1, message => 'ask cancelled' }) ? 1 : 0;
}

# only needed to tell /cmd@us from /cmd@otherbot, so it is fetched once and
# only when a command handler exists to care
sub resolve_my_username {
    my ($self) = @_;
    # answered once is answered: an account with no username at all replies
    # successfully and leaves my_username undef, so retrying on "still undef"
    # asked again for every addressed message forever. Only a failed fetch is
    # worth repeating.
    return if $self->{my_username_pending} || $self->{my_username_asked};
    # a fetch already in flight when set_username runs would land with the old
    # name and memo it, so nothing would ever ask again; the generation says
    # whether this reply is still the one we want, and a stale one must not
    # clear the pending flag that now belongs to a newer request
    my $gen = $self->{my_username_gen} //= 0;
    $self->{my_username_pending} = $gen + 1;
    $self->send({ '@type' => 'getMe' }, sub {
        my ($user, $err) = @_;
        return unless ($self->{my_username_gen} // 0) == $gen;
        delete $self->{my_username_pending};
        return if $err;
        $self->{my_username_asked} = 1;
        my $u = $user->{usernames} // {};
        $self->{my_username} = $u->{editable_username}
            // ($u->{active_usernames} || [])->[0];
    });
    return;
}

sub route_callback_data {
    my ($self, $query) = @_;
    my $routes = $self->{callback_routes} or return;
    my $data = $query->{data};
    return unless defined $data;
    # a snapshot: a handler may register a route, and iterating the live list
    # would dispatch to it for the very query that registered it, without end
    for my $r (@$routes[0 .. $#$routes]) {
        my ($pattern, $cb) = @$r;
        if (ref $pattern eq 'Regexp') {
            my @caps = ($data =~ $pattern) or next;
            # a match with no capture groups yields (1), which is
            # indistinguishable by value from a group that captured "1";
            # $#+ is the group count, so it tells them apart
            @caps = () unless $#+;
            $self->guarded($cb, $query, @caps);
        }
        elsif ($data eq $pattern) {
            $self->guarded($cb, $query);
        }
    }
    return;
}

# A TL bytes field is base64 of octets. A string with a character above 255
# has no defined encoding here, and passing it on would die inside MIME::Base64
# naming a line in this module rather than the caller's.
sub tl_bytes {
    my ($what, $data) = @_;
    # _croak, not croak: this one is called with the database encryption key
    # as its own second argument, so a backtrace here would print it
    _croak("$what must be a string") if ref $data && !overload::Method($data, '""');
    _croak("$what is bytes, not text: encode it first, "
         . "for example Encode::encode('UTF-8', \$string)")
        if $data =~ /[^\x00-\xff]/;
    return MIME::Base64::encode_base64($data, '');
}

# MessageSender is a union and a bare id does not say which arm: chat ids are
# negative, user ids are not.
sub message_sender {
    my (undef, $id) = @_;
    return $id if ref $id eq 'HASH';
    # not just defined: numifying a non-number would warn from in here and
    # put a JSON float into a slot the schema declares int53
    # _croak: star_withdrawal_url reaches here with the account's 2FA
    # password in the frame below
    _croak('a message sender needs a user id or a chat id')
        unless defined $id && !ref $id && $id =~ /\A\s*[+-]?[0-9]+\s*\z/;
    return $id < 0
        ? { '@type' => 'messageSenderChat', chat_id => 0 + $id }
        : { '@type' => 'messageSenderUser', user_id => 0 + $id };
}

# custom_emoji_id is int64: it must cross the JSON interface as a string
sub reaction_type {
    my (undef, $x) = @_;
    if (ref $x eq 'HASH') {
        return $x if $x->{'@type'};
        return { '@type' => 'reactionTypeCustomEmoji',
                 custom_emoji_id => plain_text('a custom emoji id',
                                               $x->{custom_emoji_id}) }
            if defined $x->{custom_emoji_id};
    }
    croak 'a reaction must be an emoji string or { custom_emoji_id => ... }'
        if !defined $x || ref $x && !overload::Method($x, '""');
    return { '@type' => 'reactionTypeEmoji',
             emoji => plain_text('an emoji', $x) };
}

# 429 carries its delay only in the message text; see the rate-limiting
# section in the POD for why no retry happens here
sub retry_after {
    my ($self, $err) = @_;
    $err = $self unless defined $err;   # usable as method or plain function
    return undef unless ref $err eq 'HASH';
    return undef unless ($err->{code} // 0) == 429;
    my ($n) = ($err->{message} // '') =~ /retry after ([0-9]+)/i;
    return defined $n ? 0 + $n : undef;
}

# The mixins call these as plain functions, so each needs the name in its own
# symbol table. Aliased in from here rather than written as a forwarding sub in
# every file: the alias costs no stack frame and no @_ pass-through, and a
# mixin can no longer call a helper whose shim someone forgot to add -- which
# had already happened twice, in each case on an error path nothing exercised.
# Safe at this point: the mixins are compiled by the `use` statements above,
# but nothing in them runs until the core has finished loading.
{
    no strict 'refs';
    no warnings 'once';
    for my $mixin (@ISA) {
        *{"${mixin}::$_"} = \&{"EV::Telegram::TDLib::$_"}
            for qw(json_bool need opts no_opts num real num_list text_list
                   unix_time no_extra plain_text tl_class tl_bytes input_file
                   _croak);
        # Carp trusts along @ISA, and a mixin has none: without this a croak
        # in one mixin's method called from another is reported at a line
        # inside the module instead of at the caller's
        @{"${mixin}::CARP_NOT"} = (__PACKAGE__);
    }
}

# derived from @ISA rather than listed again: a mixin left out of a second
# list still answers method calls, so its updates would go unrouted silently
our %UPDATE_HANDLERS;
{
    no strict 'refs';
    for my $mixin (@ISA) {
        %UPDATE_HANDLERS = (%UPDATE_HANDLERS, %{"${mixin}::UPDATES"});
    }
}

sub handle_update {
    my ($self, $obj) = @_;
    my $type = $obj->{'@type'} // '';
    $self->auth_update($obj) if $type eq 'updateAuthorizationState';
    if (my $h = $UPDATE_HANDLERS{$type}) { $h->($self, $obj) }
    if (my $cb = $self->{on_update}) { $cb->($obj); }
}

sub auth_update {
    my ($self, $obj) = @_;
    my $state = $obj->{authorization_state} // {};
    my $stype = $state->{'@type'} // '';
    $self->{state} = $stype;

    # lifecycle continuations run even with auto_auth off
    if ($stype eq 'authorizationStateReady') {
        # Out of band on purpose: login must not wait on this. Until the reply
        # lands the /command@username form cannot match, which is the small
        # documented race; gating login on it would deadlock any caller that
        # drives the state machine without a server.
        $self->resolve_my_username
            if $self->{commands} && !defined $self->{my_username};
        if (my $cbs = delete $self->{login_cbs}) {
            $self->guarded($_, undef, undef) for @$cbs;
        }
        return;
    }
    if ($stype eq 'authorizationStateClosed') {
        $self->closed;
        return;
    }
    return unless $self->{auto_auth};

    if ($stype eq 'authorizationStateWaitTdlibParameters') {
        # building the parameters can croak -- a wide-character encryption
        # key is the reachable case. The drain would report that and carry
        # on, leaving nothing sent and login() owed an answer forever, so
        # fail the login with it instead.
        unless (eval { $self->auth_parameters; 1 }) {
            my $why = $@;
            $why = eval { my $s = "$why"; $s =~ s/\s+at .*//s; $s };
            $self->fail_login($why // 'could not build the TDLib parameters');
        }
    }
    elsif ($stype eq 'authorizationStateWaitPhoneNumber') {
        my $opt = $self->{opt};
        if ($opt->{bot_token}) {
            $self->send({ '@type' => 'checkAuthenticationBotToken',
                          token => plain_text('a bot token',
                                              $opt->{bot_token}) },
                        $self->auth_fail_cb($stype, 'checkAuthenticationBotToken'));
        } elsif ($opt->{on_qr} && !$opt->{phone_number}) {
            $self->send({ '@type' => 'requestQrCodeAuthentication' },
                        $self->auth_fail_cb($stype, 'requestQrCodeAuthentication'));
        } elsif (!defined $opt->{phone_number}) {
            $self->fail_login(
                'no phone_number, bot_token or on_qr was given, so '
              . $stype . ' cannot be answered');
        } else {
            # a phone number written without quotes is a number, and TDLib
            # refuses a Number where it declares a string
            $self->send({ '@type' => 'setAuthenticationPhoneNumber',
                          phone_number => plain_text('a phone number',
                                                     $opt->{phone_number}) },
                        $self->auth_fail_cb($stype, 'setAuthenticationPhoneNumber'));
        }
    }
    elsif ($stype eq 'authorizationStateWaitEmailAddress') {
        $self->auth_credential(on_email => $stype, $state,
            sub { +{ '@type' => 'setAuthenticationEmailAddress',
                     email_address => $_[0] } });
    }
    elsif ($stype eq 'authorizationStateWaitEmailCode') {
        $self->auth_credential(on_email_code => $stype, $state,
            sub { +{ '@type' => 'checkAuthenticationEmailCode',
                     code => { '@type' => 'emailAddressAuthenticationCode',
                               code => $_[0] } } });
    }
    elsif ($stype eq 'authorizationStateWaitCode') {
        $self->auth_credential(on_code => $stype, $state->{code_info},
            sub { +{ '@type' => 'checkAuthenticationCode', code => $_[0] } });
    }
    elsif ($stype eq 'authorizationStateWaitRegistration') {
        my $reg = $self->{opt}{register};
        if (ref $reg eq 'HASH' && $reg->{first_name}) {
            $self->send({ '@type' => 'registerUser',
                          first_name => plain_text('a first name',
                                                   $reg->{first_name}),
                          last_name  => defined $reg->{last_name}
                                          ? plain_text('a last name',
                                                       $reg->{last_name}) : '',
                          disable_notification => json_bool(0) },
                        $self->auth_fail_cb($stype, 'registerUser'));
        } else {
            $self->fail_login("$stype reached but no register option was given");
        }
    }
    elsif ($stype eq 'authorizationStateWaitPassword') {
        $self->auth_credential(on_password => $stype, $state,
            sub { +{ '@type' => 'checkAuthenticationPassword', password => $_[0] } });
    }
    elsif ($stype eq 'authorizationStateWaitOtherDeviceConfirmation') {
        if (my $cb = $self->{on_qr}) {
            $cb->($state->{link});
        } else {
            $self->fail_login("$stype reached but no on_qr callback was given");
        }
    }
    elsif ($stype eq 'authorizationStateWaitPremiumPurchase') {
        $self->fail_login("$stype cannot be satisfied programmatically");
    }
}

# closed can only ever run once: a dying callback must not skip the rest
sub guarded {
    my ($self, $cb, @args) = @_;
    eval { $cb->(@args); 1 } or do {
        my $err = $@;
        # an exception object may overload bool or "" with something that
        # dies, and testing or interpolating it here would escape this guard
        # and clear $@ on the way out, so nothing would report it at all
        my $e = eval { my $s = "$err"; chomp $s; $s };
        $e = 'unstringifiable error' unless defined $e;
        $e = 'unknown error' unless length $e;
        # a dying on_error must not unwind the chain either
        eval { $self->emit_error("a callback died: $e") };
    };
}

sub closed {
    my ($self) = @_;
    my $cid = delete $self->{client_id} or return;
    delete $CLIENTS{$cid};
    # each credential submitter is a closure that refers to itself and
    # captures $self; clearing the pad slot is what frees the client
    for my $slot (@{ delete $self->{auth_submits} || [] }) { undef $$slot }
    # keepalive(0) already spent this ref; unref-ing twice steals another client's
    if ($self->{keepalive} // 1) {
        _pump_unref();
        $self->{keepalive} = 0;
    }
    for my $extra (keys %{ $self->{pending} }) {
        my $p = delete $self->{pending}{$extra};
        $p->{timer}->stop if $p->{timer};
        $self->guarded($p->{cb}, undef, { '@type' => 'error', code => -1,
                                           message => 'client closed' });
    }
    for my $key (keys %{ $self->{asks} || {} }) {
        my $entry = delete $self->{asks}{$key};
        $entry->{timer}->stop if $entry->{timer};
        undef $entry->{timer};
        $self->guarded($entry->{cb}, undef, { '@type' => 'error', code => -1,
                                               message => 'client closed' });
    }
    # a request waiting out a 429 backoff is in none of the other tables: its
    # pending entry was consumed by the 429 reply that started the wait
    for my $w (values %{ delete $self->{retry_waiters} // {} }) {
        ${ $w->{timer} }->stop if ${ $w->{timer} };
        undef ${ $w->{timer} };
        $self->guarded($w->{cb}, undef, { '@type' => 'error', code => -1,
                                           message => 'client closed' });
    }
    for my $cb (values %{ delete $self->{cache}{sending} // {} }) {
        $self->guarded($cb, undef, { '@type' => 'error', code => -1,
                                      message => 'client closed' });
    }
    # a story posted with wait => sent is parked here awaiting its update,
    # exactly as a message send is parked in {sending}
    for my $cb (values %{ delete $self->{cache}{posting} // {} }) {
        $self->guarded($cb, undef, { '@type' => 'error', code => -1,
                                      message => 'client closed' });
    }
    for my $dl (values %{ delete $self->{cache}{downloads} // {} }) {
        $self->guarded($dl->{cb}, undef, { '@type' => 'error', code => -1,
                                            message => 'client closed' });
    }
    # upload watchers are progress-only: no completion promise, nothing to fail
    delete $self->{cache}{uploads};
    if (my $cbs = delete $self->{login_cbs}) {
        $self->guarded($_, undef, { '@type' => 'error', code => -1,
                                     message => 'client closed during login' })
            for @$cbs;
    }
    # a login() answered from a settled state is deferred through a timer, so
    # closing before that timer runs would otherwise report the login as
    # having succeeded on a client that is already gone
    if (my $late = delete $self->{login_late}) {
        delete $self->{login_deferred};
        $self->guarded($_->[0], undef,
                        { '@type' => 'error', code => -1,
                          message => 'client closed during login' })
            for @$late;
    }
    if (my $cbs = delete $self->{close_cbs}) { $self->guarded($_) for @$cbs }
    if (my $cb = $self->{on_close}) { $self->guarded($cb) }
}

sub close {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    shift @args if @args == 1 && !defined $args[0];
    no_extra('close', 0, \@args);
    if (($self->{state} // '') eq 'authorizationStateClosed') {
        # deferred and chained, as login()
        push @{ $self->{close_late} }, $cb;
        $self->{close_deferred} ||= EV::timer 0, 0, sub {
            delete $self->{close_deferred};
            my $cbs = delete $self->{close_late} || [];
            $self->guarded($_) for @$cbs;
        };
        return;
    }
    # chain, not replace; TDLib needs the close request only once
    my $first = !$self->{close_cbs};
    push @{ $self->{close_cbs} }, $cb;
    $self->send({ '@type' => 'close' }) if $first;
    return;
}

sub is_registered {
    my ($client_id) = @_;
    return $CLIENTS{$client_id} ? 1 : 0;
}

# No DESTROY: %CLIENTS holds a strong reference for as long as a client is
# open, so an unclosed one is never freed, and closed removes client_id
# before unregistering, so by the time the object can go away there is
# nothing left to close. The END block is the only safety net, as the POD says.

sub auth_credential {
    my ($self, $handler, $stype, $info, $make_request) = @_;
    my $cb = $self->{$handler};
    if (!$cb) {
        $self->fail_login("$stype reached but no $handler callback was given");
        return;
    }
    # $submit has to refer to itself so a rejected credential can be asked
    # for again, and that cycle captures $self. Nothing collects it, so the
    # client would outlive its own close: keep a handle and clear it there.
    my $submit;
    $submit = sub {
        my ($value) = @_;
        # every credential lands in a TL string slot, and a code or password
        # typed as a bare number would go out as a JSON Number and be refused
        $value = plain_text('a credential', $value);
        # TDLib stays in the state on rejection: ask again, with the error
        $self->send($make_request->($value), $self->auth_reply_cb($stype, sub {
            my ($err) = @_;
            $cb->($info, $submit, $err) if $err;
        }));
    };
    push @{ $self->{auth_submits} }, \$submit;
    $cb->($info, $submit);
}

sub auth_parameters {
    my ($self) = @_;
    my $opt = $self->{opt};
    my $dbdir = $opt->{database_directory} // 'tdlib-db';
    $self->send({
        '@type' => 'setTdlibParameters',
        use_test_dc             => json_bool($opt->{use_test_dc}),
        database_directory      => plain_text('a database directory', $dbdir),
        files_directory         => defined $opt->{files_directory}
                                     ? plain_text('a files directory',
                                                  $opt->{files_directory})
                                     : plain_text('a database directory', $dbdir),
        database_encryption_key =>
            tl_bytes('database_encryption_key',
                      $opt->{database_encryption_key} // ''),
        use_file_database       => json_bool($opt->{use_file_database} // 1),
        use_chat_info_database  => json_bool($opt->{use_chat_info_database} // 1),
        use_message_database    => json_bool($opt->{use_message_database} // 1),
        use_secret_chats        => json_bool($opt->{use_secret_chats} // 1),
        api_id                  => 0 + ($opt->{api_id} // 0),
        # stringified: a version written as a number (application_version
        # => 1.5) would reach a string slot as a JSON Number and TDLib would
        # refuse the whole request, killing login before any credential
        api_hash                => plain_text('an api_hash', $opt->{api_hash}),
        system_language_code    => defined $opt->{system_language_code}
                                     ? plain_text('a language code',
                                                  $opt->{system_language_code})
                                     : 'en',
        device_model            => defined $opt->{device_model}
                                     ? plain_text('a device model',
                                                  $opt->{device_model})
                                     : 'EV::Telegram::TDLib',
        system_version          => defined $opt->{system_version}
                                     ? plain_text('a system version',
                                                  $opt->{system_version})
                                     : "$^O",
        application_version     => defined $opt->{application_version}
                                     ? plain_text('an application version',
                                                  $opt->{application_version})
                                     : "$VERSION",
    }, $self->auth_fail_cb('authorizationStateWaitTdlibParameters',
                            'setTdlibParameters'));
}

sub new {
    my ($class, @rest) = @_;
    # this frame holds api_id, api_hash, the bot token and the encryption key,
    # and the fork poison croaks from C -- from _create_client_id and
    # _pump_ref below -- so it never passes through _croak
    local $Carp::MaxArgNums = -1;
    my %opt = opts(@rest);
    my $self = bless {
        json      => Cpanel::JSON::XS->new->utf8->allow_nonref,
        seq       => 0,
        pending   => {},
        abandoned => {},
        cache     => {},
        opt       => \%opt,
        auto_auth => exists $opt{auto_auth} ? $opt{auto_auth} : 1,
        state     => 'created',
    }, $class;

    # the keyed handlers take a key as well as a callback, so a constructor
    # option can only store a callback nothing will ever look up
    for my $reg (qw(on_command on_callback_data on_upload)) {
        _croak("$reg is a method, not a constructor option: "
             . "call \$td->$reg(...) after new()") if exists $opt{$reg};
    }

    # An option new() does not know is inert, and silence about it is what
    # this module refuses everywhere else -- set_permissions croaks on an
    # unrecognised key for the same reason, call() against the schema, opts
    # on a mispaired list. Here the cost is higher than a lost setting: a
    # typo in database_encryption_key ships the session unencrypted, and one
    # in database_directory leaves it in the working directory.
    # named rather than matched as /\Aon_/: that let on_erorr and on_mesage
    # through as silently as any other typo, and a handler that never fires
    # is exactly as hard to diagnose as a setting that never applied
    my @unknown = grep { !$CTOR_OPT{$_} && !$CTOR_HANDLER{$_} } sort keys %opt;
    _croak('unknown option' . (@unknown > 1 ? 's' : '') . ' for new(): '
         . join(', ', @unknown)) if @unknown;
    # api_id is int32 to TDLib: a non-numeric one warned from inside the
    # module on the login path and then shipped "api_id":0.0, a JSON float,
    # which fails the login with nothing pointing back at the typo
    num('api_id', $opt{api_id}) if defined $opt{api_id};
    # checked here rather than at the login step, where the croak died inside
    # the update dispatch and the login never called back
    plain_text('a bot token', $opt{bot_token});
    plain_text('a phone number', $opt{phone_number});
    if (defined $opt{register}) {
        _croak('register takes a hashref of first_name and last_name')
            unless ref $opt{register} eq 'HASH';
        plain_text('a first name', $opt{register}{first_name});
        plain_text('a last name', $opt{register}{last_name});
    }
    # the retry policy is checked here as well as at send time: a typo in one
    # given to new() is otherwise accepted and then croaks on every request,
    # and from inside an update callback that croak is contained, so the
    # request simply never happens
    retry_policy(undef, { retry => $opt{retry} }) if $opt{retry};
    $self->{$_} = $opt{$_} for grep { /^on_/ } keys %opt;
    $self->{application_name} = EV::Telegram::TDLib::WebApps::check_application_name(
        $opt{application_name} // 'tdesktop');
    $self->{client_id} = _create_client_id();
    $CLIENTS{ $self->{client_id} } = $self;
    _pump_ref();
    return $self;
}

sub on_update {
    my ($self, $cb) = @_;
    $self->{on_update} = $cb if @_ > 1;
    return $self->{on_update};
}

sub on_error {
    my ($self, $cb) = @_;
    $self->{on_error} = $cb if @_ > 1;
    return $self->{on_error};
}

sub emit_error {
    my ($self, $message) = @_;
    if (my $cb = $self->{on_error}) {
        $cb->($message);
    } else {
        warn "EV::Telegram::TDLib: $message\n";
    }
}

# must never die: the C drain has no frame to unwind into, and would leak the batch
sub drain_error {
    my ($client_id, $err) = @_;
    # $err arrives unstringified: an exception object may overload "" with
    # something that dies, so every use of it happens inside an eval
    my $message = eval { "dispatch died: $err" }
        // 'dispatch died: (error object could not be stringified)';
    my $self = $CLIENTS{$client_id};
    return if $self && eval { $self->emit_error($message); 1 };
    eval { warn "EV::Telegram::TDLib: $message\n" };
}

sub dispatch_raw {
    my ($client_id, $json) = @_;
    my $self = $CLIENTS{$client_id} or return;
    my $obj  = eval { $self->{json}->decode($json) };
    if (!defined $obj) {
        $self->emit_error("cannot decode TDLib response: $@");
        return;
    }
    # allow_nonref means a bare scalar or an array decodes fine; every real
    # TDLib payload is an object, and treating anything else as one dies
    if (ref $obj ne 'HASH') {
        $self->emit_error('TDLib response is not an object: '
            . (ref $obj ? lc ref $obj : 'scalar'));
        return;
    }
    my $extra = delete $obj->{'@extra'};
    delete $obj->{'@client_id'};

    if (defined $extra) {
        my $p = delete $self->{pending}{$extra};
        if ($p) {
            $p->{timer}->stop if $p->{timer};
            my $is_err = ($obj->{'@type'} // '') eq 'error';
            $p->{cb}->($is_err ? (undef, $obj) : ($obj, undef));
            return;
        }
        if (delete $self->{abandoned}{$extra}) {
            warn "EV::Telegram::TDLib: late reply for timed-out request $extra\n";
            return;
        }
        # an unknown @extra is a reply, not an update
        warn "EV::Telegram::TDLib: reply for unknown request $extra dropped\n";
        return;
    }
    $self->handle_update($obj);
}

_set_dispatch(\&dispatch_raw);

# max_wait is a give-up threshold, never a clamp: retrying sooner than the
# server demanded is the behaviour that gets accounts limited.
sub retry_policy {
    my ($self, $opt) = @_;
    my $r = exists $opt->{retry} ? $opt->{retry} : $self->{opt}{retry};
    return undef unless $r;
    # a plain truthy value means "on, with the defaults"; anything else that
    # is a ref is a mistake rather than a shorthand
    _croak('retry takes a hashref of options, or a true value for the '
         . 'defaults') if ref $r && ref $r ne 'HASH';
    $r = {} unless ref $r eq 'HASH';
    # this is the one option surface that governs how hard we hit a server
    # already saying 429: retry => { attemtps => 0 } read as the default 3
    for my $k (sort keys %$r) {
        _croak("unknown retry option '$k'; retry takes attempts, max_wait, "
             . 'factor and margin')
            unless $k =~ /\A(?:attempts|max_wait|factor|margin)\z/;
    }
    return {
        attempts  => num('attempts',  $r->{attempts} // 3),
        max_wait  => real('max_wait', $r->{max_wait} // 300),
        factor    => real('factor',   $r->{factor}   // 2),
        margin    => real('margin',   $r->{margin}   // 1),
    };
}

# The retry state lives in a hashref driven by a named sub rather than a
# self-referential closure: a closure that names itself is never collected, and
# it captures $self, so a single retrying send would pin the client for good.
sub send_retrying {
    my ($self, $request, $cb, $opt, $policy) = @_;
    my $st = { request => $request, cb => $cb || sub {}, opt => $opt,
               policy => $policy, left => $policy->{attempts},
               margin => $policy->{margin} };
    $self->retry_attempt($st);
    return $st->{first};
}

sub retry_attempt {
    my ($self, $st) = @_;
    my $extra = $self->send_once($st->{request}, sub {
        my ($res, $err) = @_;
        my $wait = EV::Telegram::TDLib->retry_after($err);
        if (defined $wait && $st->{left} > 0 && $wait <= $st->{policy}{max_wait}) {
            $st->{left}--;
            my $delay = $st->{margin} + $wait;
            $st->{margin} *= $st->{policy}{factor};
            # a backing-off request has already had its pending entry
            # consumed by the 429 reply, so closed() would not see it
            my $id = ++$self->{seq};
            EV::now_update();
            my $w; $w = EV::timer $delay, 0, sub {
                undef $w;
                delete $self->{retry_waiters}{$id};
                $self->retry_attempt($st);
            };
            # a ref to the lexical, not the watcher: the timer closure undefs
            # $w to break its own cycle, and closed must be able to do the same
            $self->{retry_waiters}{$id} = { cb => $st->{cb}, timer => \$w };
            return;
        }
        $st->{cb}->($res, $err);
    }, $st->{opt});
    $st->{first} = $extra unless defined $st->{first};
    return;
}

sub send {
    my ($self, $request, @rest) = @_;
    my $cb = cb_slot('send', \@rest);
    my %opt = opts(@rest);
    if (my $policy = $self->retry_policy(\%opt)) {
        return $self->send_retrying($request, $cb, \%opt, $policy);
    }
    return $self->send_once($request, $cb, \%opt);
}

sub send_once {
    my ($self, $request, $cb, $opt) = @_;
    # a closed client has no client_id: _send would address client 0 and
    # the pending entry could never be flushed, so fail deferred instead
    if (!$self->{client_id}) {
        if ($cb) {
            my $w; $w = EV::timer 0, 0, sub {
                undef $w;
                # guarded like every other delivery: a die from a timer
                # reaches EV, which prints and ignores it, so on_error would
                # never see it and the documented containment would not hold
                $self->guarded($cb, undef,
                                { '@type' => 'error', code => -1,
                                  message => 'client is closed' });
            };
        }
        return undef;
    }
    my $extra = ++$self->{seq};
    my %req = (%$request, '@extra' => "$extra");
    # encode before registering anything: an unencodable request croaks, and
    # a pending entry left behind would later fire a timeout for a request
    # that was never sent, failing the same call twice through two channels
    my $payload = $self->{json}->encode(\%req);
    $self->{pending}{$extra} = { cb => $cb || sub {} };
    if (my $t = defined $opt->{timeout} ? real('timeout', $opt->{timeout}) : 0) {
        # ev_now may be seconds stale after the process blocked outside
        # the loop: without a refresh a fresh short timeout fires at once
        EV::now_update();
        $self->{pending}{$extra}{timer} = EV::timer $t, 0, sub {
            my $p = delete $self->{pending}{$extra} or return;
            $self->abandon($extra);
            # guarded: the same callback dying on the reply path is caught by
            # the drain and reported, so a timeout must not be the one route
            # where a die only reaches EV's own stderr
            $self->guarded($p->{cb}, undef, {
                '@type' => 'error', code => -1, message => 'timeout',
            });
        };
    }
    # the fork poison croaks from C, so it never passes through _croak: in a
    # forked child this is raised with a login submit -- and its code, email
    # or password -- one frame down
    local $Carp::MaxArgNums = -1;
    _send($self->{client_id}, $payload);
    return $extra;
}

sub abandon {
    my ($self, $extra) = @_;
    $self->{abandoned}{$extra} = 1;
    if (keys %{ $self->{abandoned} } > 1000) {
        my ($oldest) = sort { $a <=> $b } keys %{ $self->{abandoned} };
        delete $self->{abandoned}{$oldest};
    }
}

# a validated sibling of send: an unknown function passes straight through so
# a newer TDLib keeps working, but a typo in a known one is caught here
# instead of coming back as an opaque server error
sub call {
    my ($self, $function, $args, @rest) = @_;
    # \%args left out: a callback or an option name is in its slot instead
    if (ref $args eq 'CODE'
        || defined $args && !ref $args && $args =~ /\A(?:timeout|retry)\z/) {
        unshift @rest, $args;
        $args = {};
    }
    my $cb = cb_slot('call', \@rest);
    my %opt = opts(@rest);
    need('function', $function);
    $args //= {};
    croak 'call needs a hashref of arguments' unless ref $args eq 'HASH';
    if (defined(my $known = $EV::Telegram::TDLib::Schema::FUNCTIONS{$function})) {
        my %valid = map { $_ => 1 } split ' ', $known;
        for my $k (sort keys %$args) {
            next if $k eq '@type' || $valid{$k};
            croak "unknown argument '$k' for $function; valid arguments are: "
                . (length $known ? $known : '(none)');
        }
    }
    return $self->send({ %$args,
                         '@type' => plain_text('a function name', $function) },
                       $cb, %opt);
}

sub inject_raw {
    my ($self, $json) = @_;
    dispatch_raw($self->{client_id}, $json);
}

sub keepalive {
    my ($self, $on) = @_;
    my $cur = $self->{keepalive} // 1;
    # with no argument this is a getter, like every other optional-argument
    # accessor here: reading the setting used to turn it back on, so a program
    # that called keepalive(0) so EV::run could return re-pinned the loop just
    # by asking whether it had
    return $cur unless @_ > 1;
    # normalise first: an unnormalised truthy value compares unequal to the
    # stored 1, takes a second loop ref, and the loop is never released
    $on = defined $on ? ($on ? 1 : 0) : 1;
    # a closed client holds no loop ref: spending or taking one here
    # would corrupt the pump accounting for the clients still open
    return $cur if !$self->{client_id} || $on == $cur;
    $self->{keepalive} = $on;
    $on ? _pump_ref() : _pump_unref();
    return $on;
}

# close every still-open client and pump the loop for a bounded interval
# so TDLib flushes its database, then join the reader before TDLib's
# statics are torn down; evals keep a forked child's poison croaks from
# changing its exit status
END {
    eval {
        # A client created while we pump -- an on_close handler that
        # reconnects is the natural way to get one -- joins %CLIENTS after
        # the close-all has run, so closing once would leave it materialised
        # at exit, which is the abort window this block exists to avoid.
        my %asked;
        my $close_all = sub {
            for my $id (keys %CLIENTS) {
                next if $asked{$id}++;
                my $c = $CLIENTS{$id} or next;
                # A client whose close() croaks must not take the others with
                # it -- but the fork poison has to keep escaping, because that
                # is what abandons this block in a child, and close() croaks
                # before removing the entry, so %CLIENTS would never empty and
                # the child would block to the watchdog on every exit.
                unless (eval { $c->close(); 1 }) {
                    die $@ if $@ =~ /cannot be used after fork/;
                }
            }
        };
        $close_all->();
        if (%CLIENTS) {
            # compare against the watchdog flag, never the wall clock:
            # libev schedules the timer against its cached ev_now, so the
            # wake can land before EV::time reaches the deadline, and a
            # re-entered RUN_ONCE with no events left blocks forever
            my $timed_out = 0;
            # giving up here tears TDLib's statics down while it is still
            # closing, which can abort; the default is generous for a healthy
            # machine but a sanitizer build or a loaded box needs longer
            # same reasoning as the log level: a value we cannot use falls
            # back to the default rather than to 0, which would give the
            # pump a single iteration and warn from in here
            my $budget = $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT};
            # > 0 as well as numeric: 0 would give up at once, which is the
            # abort window this block exists to avoid, and the old || 3
            # coerced it away
            $budget = 3 unless defined $budget
                && $budget =~ /\A[0-9]+(?:\.[0-9]+)?\z/ && $budget > 0;
            # ev_now is only refreshed inside ev_run, and a program can spend
            # any amount of time between its last loop iteration and exit, so
            # without this the deadline is computed from a stale clock: the
            # watchdog is already expired when armed and fires on the first
            # RUN_ONCE, leaving the clients materialised that it exists to
            # close. Anything blocking for longer than the budget lost the
            # whole pump.
            EV::now_update();
            my $watchdog = EV::timer $budget, 0, sub { $timed_out = 1; EV::break };
            while (%CLIENTS && !$timed_out) {
                EV::run(EV::RUN_ONCE);
                $close_all->();
            }
            $watchdog->stop;
            # the only signal a caller ever gets that the database may not
            # have flushed. Not said when the budget is under a second: that
            # is a deliberate "do not wait" -- the suite and CI both set one
            # -- and advising such a caller to raise it is noise.
            warn "EV::Telegram::TDLib: gave up closing "
               . scalar(keys %CLIENTS) . " client(s) after ${budget}s; "
               . "raise EV_TDLIB_SHUTDOWN_TIMEOUT\n"
                if %CLIENTS && $budget >= 1;
        }
    };
    eval { EV::Telegram::TDLib::_shutdown() };
}

1;

=head1 NAME

EV::Telegram::TDLib - asynchronous Telegram client on TDLib and EV

=head1 SYNOPSIS

    use EV;
    use EV::Telegram::TDLib;

    my $chat_id = $ENV{TD_CHAT_ID};

    my $td = EV::Telegram::TDLib->new(
        api_id             => $ENV{TD_API_ID},
        api_hash           => $ENV{TD_API_HASH},
        phone_number       => '+10000000000',
        database_directory => 'tdlib-db',
        on_code    => sub {
            my ($info, $submit) = @_;
            print "code from Telegram: ";
            chomp(my $code = <STDIN>);
            $submit->($code);
        },
        on_message => sub {
            my ($msg) = @_;
            print "message $msg->{id} in chat $msg->{chat_id}\n";
        },
        on_error   => sub { warn "tdlib: $_[0]\n" },
    );

    # a die inside a callback is contained and reported, not propagated, so
    # leaving the loop is what ends the program; see L</ERROR HANDLING>
    my $status = 0;
    $td->login(sub {
        my (undef, $err) = @_;
        if ($err) {
            warn "login failed: $err->{message}\n";
            $status = 1;
            return EV::break;
        }
        $td->send_message($chat_id, 'hello', sub {
            my ($msg, $err) = @_;
            warn "send failed: $err->{message}\n" if $err;
            $status = 1 if $err;
            $td->close(sub { EV::break });
        });
    });

    EV::run;
    exit $status;

=head1 DESCRIPTION

EV::Telegram::TDLib binds TDLib's tdjson C interface to the L<EV>
event loop. A dedicated reader thread blocks in td_receive, copies each
JSON result, and wakes the loop through ev_async; the loop decodes,
correlates replies to pending requests by C<@extra>, drives the
authorization state machine, maintains user and chat caches, and calls
your handlers.

Asynchronous callbacks follow the family idiom: they receive
C<($result, $err)> where C<$err> is undef on success and a decoded
TDLib error object on failure. A TDLib error is never thrown; see
L</CONVENTIONS> for what does croak.

Requires a perl with 64-bit integers: Telegram ids are int64 and
message ids are shifted left by 20 bits, so they must never round-trip
through an NV. The Makefile refuses to build otherwise.

The bundled TDLib is 1.8.66, pinned by Alien::TDLib at commit
022d60202e446ad1287b9fb68e687c8a0760788b.

=head1 CONSTRUCTOR

=head2 new(%opt)

Creates a client and registers it in a process-global registry. The
client is held under a strong reference until close() completes; see
L</CAVEATS>. Options:

=over 4

=item api_id, api_hash

Telegram application credentials from https://my.telegram.org. Keep
them in the environment, not in source; see L</SECURITY>.

=item phone_number

Phone number in international format for user authorization. Used
when the state machine reaches authorizationStateWaitPhoneNumber,
unless bot_token is present. Setting on_qr as well does not override
it: a QR link is requested only when on_qr is set and no phone_number
was given.

=item bot_token

Bot token from BotFather. When present it is sent automatically at
authorizationStateWaitPhoneNumber and no further credential callbacks
are needed.

=item database_directory

Session and database directory. Default C<tdlib-db>. See L</SECURITY>.

=item files_directory

Downloaded files directory. Defaults to database_directory.

=item database_encryption_key

Encryption key for the local database. Empty by default; set it. Any
byte string will do, but it must be bytes: a character above 255 is
rejected while the first request is being built, which happens during
update dispatch, so it reaches C<on_error> rather than croaking out of
new(). It is base64-encoded on the way out, so what you pass is what
keys the database.

B<Changed in 0.04.> 0.03 sent this value raw, which TDLib refused for
most passphrases -- taking login with it -- while accepting one that
happened to look like base64 and keying the database with the decoded
bytes instead. If a 0.03 database opened with such a key, open it now
with C<MIME::Base64::decode_base64($old_key)>.

Changing it later needs
L<set_database_encryption_key()|/"set_database_encryption_key($key, $cb), session_accepts_secret_chats($session_id, $on, $cb)">,
and losing it loses the database.

=item use_test_dc

Use the Telegram test data centers instead of production. Always set
this in tests.

=item use_file_database, use_chat_info_database, use_message_database, use_secret_chats

TDLib feature switches, all defaulting to true. TDLib turns a switch
back on when a later one needs it -- the message database needs the
chat info database, which needs the file database -- so
C<< use_chat_info_database => 0 >> does nothing unless
C<< use_message_database => 0 >> too, and C<< use_file_database => 0 >>
needs both.

=item application_name

The platform identifier sent with every Mini App request, which the app
receives as C<tgWebAppPlatform>. Defaults to C<tdesktop>. See
L</MINI APPS> for why the value matters and what it may contain.

=item system_language_code, device_model, system_version, application_version

Client identification sent with setTdlibParameters. Defaults: C<en>,
C<EV::Telegram::TDLib>, C<$^O>, this distribution's version.

=item auto_auth

Drive the authorization state machine automatically (default true).
With auto_auth false, only the login and close lifecycle continuations
run; every credential step is left to you via send().

=item register

Hashref C<{ first_name =E<gt> ..., last_name =E<gt> ... }>. When set,
authorizationStateWaitRegistration is answered with registerUser;
without it the state fails login.

=item on_update, on_error, on_close, on_user, on_chat, on_message, on_connection_state

Update handlers; see L</UPDATES> and the mixin methods below.

=item on_code, on_password, on_email, on_email_code, on_qr

Authorization credential callbacks; see L</AUTHORIZATION>.

=back

=head1 CONVENTIONS

Three patterns run through the whole interface. Knowing them saves reading
300 method signatures.

=head2 Cache readers against remote getters

L</chat($id)> and L</user($id)> are B<synchronous cache reads>:
they take no callback, do no I/O, and return undef for something the
client has not seen. Everything else named after a noun -- C<folder>,
C<topic>, C<secret_chat>, C<supergroup>, C<basic_group>, C<message>,
C<file> -- is an B<asynchronous getter> that takes a callback and asks
TDLib.

The two cache readers predate the rest and are kept as they are because
renaming a method already published on CPAN would break working code.
When you want the server's answer for a chat rather than the cached one,
use L<fetch_chat()|/"fetch_chat($chat_id, $cb), close_chat($chat_id, $cb), user_full_info($user_id, $cb), supergroup($id, %opt, $cb), basic_group($id, %opt, $cb), supergroup_members($id, %opt, $cb), groups_in_common($user_id, %opt, $cb)">.

=head2 Options and handlers

Options are C<< name => value >> pairs after the positional arguments.
An odd number of them croaks: a name that lands in a positional slot
shifts every pair after it, so the request ends up saying something you
never asked -- C<< install_sticker_set($id, archived => 1) >> installed
rather than archived, because C<archived> was read as the C<$installed>
positional.

A flag is any true or false value, as perl reads it, and a JSON boolean
object works too. C<\0> is a reference, so it is true to perl, not the
false it is in JSON: pass C<0>. A flag passed straight through croaks on
a reference that is not an object.

The callback is the last argument and is recognised by being a coderef,
so an extra argument cannot displace it. Written anywhere else it
croaks rather than being taken for a value: before the options it would
land in an optional flag or number, and be dropped. send() and call()
are the exception, and take it before their options as well. A method
that takes no options croaks on anything past its positional
arguments, so C<< set_chat_title($chat, title => 'New') >> is refused
rather than renaming the chat "title".

A handler that holds one callback -- on_update, on_error, on_message and
the rest of the single-slot C<on_*> methods -- is a getter when called
with no argument, a setter when called with one, and is removed by
passing C<undef>. What counts is that an argument was passed at all, so
any false value removes it too: C<< $td->on_error($h{error}) >> with no
C<error> key in C<%h> B<takes the handler away>, including one given to
new(), and errors go back to warning on stderr. Forwarding a handler
you may not have is the way to lose one silently, so test for it before
passing it. B<Changed in 0.04:> 0.03 ignored a false value, so a handler
could not be removed at all. The keyed ones, on_command,
on_callback_data and on_upload, take the key first and remove that one
entry when passed C<undef>; they are not getters and croak without a
callback. C<on_close> and the login handlers (C<on_code>,
C<on_password>, C<on_email>, C<on_email_code>, C<on_qr>) are constructor
options with no method of their own.

Three options recur widely enough that the entries below do not repeat
them. C<parse_mode> (C<markdown> or C<html>) applies wherever a method
takes text or a caption to format, and a text that fails to parse is
reported to the callback with nothing sent. Wherever the text can
carry formatting -- a message, a caption, a poll, a gift or story text,
a contact note -- a formattedText hashref, which is what translate and
parse_markdown answer with, is also accepted and sent as it is. A
plain-text field such as a bio or a chat description refuses one. An
object that stringifies, such as a URI or a Path::Tiny path, is text
anywhere. Telegram limits how long a name or description may be, and
TDLib cuts an over-long one without an error: a chat description at 255
characters, a chat or topic title at 128, an account or business name
and a sticker set title at 64, a bio at 70 (140 for Premium), an invite
link name at 32 and a folder name at 12. A formatted text keeps at most
100 entities, links, code and pre spans first, and the rest are dropped
the same way.
C<reply_markup> takes a keyboard from L</inline_keyboard(\@rows)> or
L<reply_keyboard()|/"reply_keyboard(\@rows, %opt)"> wherever a message
is sent or edited. C<business_connection_id> makes a Stars or Payments
call act for a connected business account rather than for you --
invoice_link, received_gifts, sell_gift, transfer_gift and upgrade_gift
take it.

=head2 Paging

C<limit> is a page size everywhere except invite_link and
edit_invite_link, where it is the link's own member limit -- how many
people may join through it. TDLib caps it without saying so: message
history, search, load_chats, profile_photos, message_reactions,
search_stickers and the server half of search_chats at 100,
supergroup_members and search_members at 200, and top_chats at 30. So
C<< limit => 500 >> quietly returns a hundred, and a loop that stops on
a short page stops early.
C<offset> is B<two different things>,
because TDLib makes it two different things, and passing the wrong kind
gets you an error from the server rather than from here.

In six it is a number of entries to skip: blocked, profile_photos,
search_stickers, story_album_stories, supergroup_members and
trending_sticker_sets.

In twelve it is an B<opaque string cursor> that the previous response
gave you, and the empty string asks for the first page:
chat_revenue_transactions, chat_story_interactions,
connected_affiliate_programs, inline_query, message_reactions,
received_gifts, search_all, search_secret_messages, star_subscriptions,
star_transactions, story_interactions and story_public_forwards.

In the three that walk a chat's messages -- search_messages,
thread_history and topic_history -- it is neither. There it works with
C<from_message_id> and must be B<0 or negative>: 0 starts exactly at
that message, and a negative value additionally returns that many
B<newer> ones. A positive value is refused by the server, and so is one
larger than C<limit> allows: thread_history and topic_history want
C<< offset >= -limit >>, search_messages the stricter
C<< limit > -offset >>. At the default limit of 50 that is -50 to 0,
and -49 to 0 respectively. thread_history and topic_history also stop
at B<-99> however large C<limit> is.

Methods that page by an id of their own -- C<from_message_id>,
C<from_story_id>, C<offset_chat_id>, C<offset_sticker_set_id> -- name
it after what it is, and take the id to start from with 0 or the empty
string meaning the beginning.

=head2 Booleans

A method that turns something on or off takes the flag as its last
positional argument and B<defaults to true>, so C<pin_topic($chat, $id)>
pins and C<pin_topic($chat, $id, 0)> unpins. That covers close_topic,
pin_topic, pin_chat, mark_unread, hide_general_topic, folder_tags,
pause_download, protect_content, default_disable_notification,
toggle_username, toggle_bot_username, toggle_attachment_menu,
session_accepts_secret_chats, the supergroup switches, the
process_join_request pair, and in 0.04 install_sticker_set,
post_story_to_page, toggle_gift_saved, edit_star_subscription and
pause_connected_bot.

A C<< name => value >> pair written where the flag belongs puts the
B<name> in the flag, and a name is always truthy, so the call would do
the opposite of what it says. Every one of them refuses that rather
than acting on it.

Two older methods invert through an option instead
(C<< block_user($id, unblock => 1) >>, C<< react(..., remove => 1) >>),
and a few pairs are separate methods where the two directions differ in
more than a flag: C<mute>/C<unmute>, C<archive>/C<unarchive>,
C<enable_proxy>/C<disable_proxy>.

=head2 Identifiers

TL C<int64> values cross the JSON interface as strings, because a number
would lose precision above 2**53. This module does that for you, and
hands them back as strings: session ids, callback and inline query ids,
profile photo ids, custom emoji ids and Web App launch ids are all
strings you should keep as strings. Chat, message and user ids are
C<int53> and stay numbers.

Those numeric ids are B<checked for shape>, not just for presence, and
so is every other number an argument carries: a limit, an offset, a
duration, a coordinate, each id in a list. An integer is an optionally
signed run of digits, with surrounding space allowed; anything else
croaks rather than being coerced. That is what catches an option name
landing in an id slot -- C<< mark_unread(unread => 0) >> with the chat
omitted put C<unread> in C<chat_id> -- which perl otherwise turns into a
zero, with a warning from inside this module and a JSON float in a slot
the schema declares an integer. It also catches a reference, which perl
turns into its memory address: C<< reply_to => $message >>, the message
rather than its id, sent that address, and TDLib quietly sent a plain
message instead of a reply.

A point in time -- C<schedule>, reschedule's C<$when>, a ban's C<until>,
an emoji status's C<expires> -- is a Unix time, and a small positive
number there croaks as the duration it almost certainly is. TDLib would
read it as a moment in 1970 and, without an error, send the scheduled
message at once, make the ban permanent or clear the status.

=head1 USERS AND BOTS

TDLib refuses much of its API to one kind of account before anything
reaches the server. A user-only method called from a bot session fails
with C<The method is not available to bots>, and a bot-only one called
from a user session with C<Only bots can use the method>; both arrive at
the callback like any other error. It is set out once here, as TDLib
1.8.66 has it, and repeated below only where it shapes how a method is
used.

These are for bots only: answer_callback_query, answer_inline_query,
answer_pre_checkout_query, answer_shipping_query, answer_web_app_query,
bot_access_settings, bot_token, business_account_star_amount,
business_connection, callback_query_message, commands, delete_commands,
delete_business_messages, edit_business_message_text, the edit_inline_*
methods, edit_message_markup, game_high_scores,
inline_game_high_scores, invoice_link, menu_button,
read_business_message, refund_star_payment, send_business_file,
send_business_message, set_bot_access_settings, the
set_business_account_* setters, set_commands, set_default_admin_rights,
set_game_score, set_inline_game_score, set_menu_button, set_reactions
and set_updates_status. So are the updates behind on_callback_query,
on_inline_query, on_join_request, on_web_app_data, the pre-checkout and
shipping handlers and the business message handlers: a user session
never receives them.

Sending, editing, forwarding and deleting messages and files work for
both, as do creating and editing forum topics, sticker sets and
proxies. Chat administration is split. For both: a member's status and
bans, reading members and administrators, a chat's title, description,
photo and permissions, creating, editing and revoking an invite link,
and pinning. For users only: adding members, listing invite links and
who joined through one, the bulk deletions (delete_messages_by_sender,
delete_messages_by_date, delete_history), reschedule, and most
supergroup switches -- slow mode, auto-delete, protected content,
signatures, join rules, transfer_ownership and the event log.

Most of the rest is for users only, in particular anything that reads
the account's own view of Telegram: the chat list and history, message
search, contacts, folders, the forum topic list, reading, editing and
deleting stories (posting one works for both), sessions, privacy and
notification settings, and react. sell_gift, transfer_gift and
upgrade_gift are for users, or for a bot passing
C<business_connection_id>.

=head1 METHODS

=head2 Core

=head3 send(\%request, $cb, %opt)

Encodes the request, assigns a fresh C<@extra>, and hands it to TDLib.
The reply is delivered as C<< $cb->($result, $err) >>. Returns the
assigned C<@extra> sequence number.

The callback may be written after the options instead, as it is on
every other method: send and call are the only two that name it first,
and both positions are accepted. Before 0.04 only the first was, so
C<< send($request, timeout => 5, $cb) >> -- the shape L</CONVENTIONS>
describes -- croaked.

send() deliberately overwrites any caller-supplied C<@extra>: it is
the reply correlation channel, and a collision would misroute a reply
to the wrong callback.

Option: C<timeout> in seconds. A timed-out request fails its callback
with a synthetic error; the late reply, if it ever arrives, is dropped
with a warning, never delivered to a reused C<@extra>. See
L</ERROR HANDLING>.

Option: C<retry>, off unless asked for. See
L</Rate limiting: error code 429> for the policy and its one important
limit. Pass C<< retry => 1 >> for the defaults, or a hashref:

    retry => { attempts => 3, max_wait => 300, factor => 2, margin => 1 }

C<attempts> counts retries B<after> the first send, so the default of 3
means at most four requests. C<max_wait> is a give-up threshold, not a
clamp: if the server asks for longer than it, the 429 is returned
unchanged rather than retried sooner than demanded. C<factor>
multiplies the module's own added margin on repeated 429s; it never
shortens the delay the server stated. C<margin> is that added margin in
seconds, 1 by default, so the first retry waits the server's delay plus
a second. A retry is issued only for a 429 that carries a parseable
delay, never for any other error.

A retry carries a fresh C<@extra>, so the value send() returned
identifies the first attempt only.

B<C<timeout> and C<retry> are options of send() and call() only.> The
named methods have their own C<%opt> namespace -- C<kind>, C<caption>,
C<wait>, C<silent> and so on -- and do not forward transport options,
so C<< send_message($chat, $text, retry => 1, $cb) >> accepts the key
and ignores it. A named method that takes no options at all croaks on
one instead. Set C<retry> on the constructor to cover every request
a client makes, including those from the named methods; there is no
per-call equivalent for them.

On a closed client send() sends nothing, registers nothing and returns
undef: the callback is failed deferred with a synthetic
C<client is closed> error. A request waiting out a retry backoff when
the client closes is failed too, with C<client closed>.

=head3 execute(\%request)

Synchronous td_execute. No network, usable before authorization, and
usable as a class method as well as an instance method:

    my $me = EV::Telegram::TDLib->execute({ '@type' => 'getMe' });

Only the TDLib methods documented as synchronous return a meaningful
result here; anything else returns undef or an error.

=head3 login($cb)

Completes when the authorization state machine (see L</AUTHORIZATION>)
reaches authorizationStateReady: C<< $cb->(undef, undef) >>. On
failure the callback receives a decoded or synthetic error. The
callback never fires synchronously, even when the state is already
settled. Calling login() again before Ready chains the callbacks, as
with close(); none is dropped. A login that has already failed fails a
later login() deferred with the recorded error instead of hanging: the
state machine stays in the failed state and never re-emits it.

=head3 auth_state()

Returns the last seen authorization state name.

=head3 close($cb)

Sends C<{"@type":"close"}> and calls C<$cb> once
authorizationStateClosed arrives. close() is not optional; see
L</CAVEATS>. Calling close() a second time before Closed is legal: the
callbacks chain and none is dropped.

=head3 keepalive([$on])

An open client holds an ev_ref on the default loop so EV::run does not
return while TDLib traffic is pending. keepalive(0) releases it, so the
loop may exit with the client still open. Defaults to on. The reference
is accounted per client: close() releases it only while still held, and
keepalive() on a closed client is a no-op that returns off.

With no argument this is a B<getter>, like the C<on_*> accessors: it
reports the current setting and changes nothing. Before 0.04 it took
the reference back, so a program that had released it re-pinned the
loop merely by asking whether it had.

=head3 on_update($cb), on_error($cb)

Get or set the generic update and error handlers. on_error receives
non-fatal internal errors (undecodable frames, callback exceptions);
without it they go to warn.

=head3 retry_after($err)

Returns the delay in seconds that a 429 error asks for, parsed out of
its message text, or undef for any other error or when no delay is
stated. Usable as a method or a plain function. See
L</"Rate limiting: error code 429">; the module still performs no
retry of its own.

=head3 call($function, \%args, $cb, %opt)

Sends a raw request like L</send(\%request, $cb, %opt)>, but checks the
argument names first against a catalogue of every TDLib function,
generated from the C<td_api.h> that L<Alien::TDLib> ships. The C<@type>
is filled in from C<$function>, so it is not repeated.

    $td->call(getChatMember => { chat_id => $c, member_id => $m }, sub {
        my ($member, $err) = @_;
        ...
    });

A typo in a known function's arguments croaks and lists the valid
names. An unknown function is passed straight through, so a TDLib newer
than the shipped catalogue keeps working; a missing argument is not an
error, since TDLib supplies its own defaults. This makes call() a
usable way to reach the roughly 600 functions this module does not wrap
by hand, without losing every check.

C<\%args> may be left out for a function that takes none, so
C<< $td->call(getMe => sub { ... }) >> works. C<%opt> is passed through
to send(), so C<timeout> and C<retry> work here too.

=head3 on_command($name => $cb), on_callback_data($pattern => $cb)

Route incoming commands and inline-button presses. Both are B<methods,
not constructor options>: passing either to new() croaks, because new()
lifts every C<on_*> key onto the object and would otherwise store a
callback that never fires.

    $td->on_command(start => sub {
        my ($msg, $args) = @_;
        $td->send_message($msg->{chat_id}, "hello $args");
    });

The name is given without a leading slash, though one is accepted and
stripped. Matching is case sensitive. The
callback receives exactly C<($msg, $args)>, where C<$args> is the rest
of the line with leading whitespace removed, and the empty string when
nothing follows; split it yourself if you want fields.

C</name@username> fires only when the username is this account's own.
That username is fetched in the background, once, either on reaching the
ready state or when the first handler is registered, whichever comes
later -- so registering handlers inside C<login()>'s callback works. A
command addressed with C<@> that arrives before the fetch returns does
not match; the plain C</name> form is never affected.

Matching uses the bot-command entity at offset 0 when TDLib supplies
one, so a message merely containing C</start> later in the line does
not fire. Outgoing messages never fire a handler, so a bot echoing help
text cannot trigger itself.

C<< on_command($name => undef) >> unregisters.

on_callback_data takes a regex or a literal string. A literal is an
B<exact> match, so use a regex for the conventional C<prefix:value>
form. Handlers are tried in registration order and B<every> match
fires; the callback receives the query followed by any regex captures.
Callback data is decoded from its wire encoding first, so patterns are
written against the plaintext the bot set. Game callback queries, which
carry no data, are skipped.

C<< on_callback_data($pattern => undef) >> unregisters every route
registered with that pattern.

Both routers dispatch against a snapshot of their handlers, so a handler
may register or unregister routes while it runs: the change takes effect
from the next update, never the one being dispatched. Without that, a
handler that registers a route would dispatch to it immediately, and one
that re-registers itself would never stop.

Both routers fire B<in addition to> L</on_message($cb)> and
L</on_callback_query($cb)>: a matched command does not consume the
message.

=head3 ask($chat_id, $user_id, $prompt, %opt, $cb), cancel_ask($chat_id, $user_id)

Sends C<$prompt> and waits for that user's next message in that chat,
once. The callback receives C<($msg, undef)> on an answer and
C<(undef, $err)> on failure, as everything else here does.

    $td->ask($chat, $user, 'What is your name?', sub {
        my ($reply, $err) = @_;
        return warn "no answer: $err->{message}\n" if $err;
        $td->send_message($chat, "hello $reply->{content}{text}{text}");
    });

Options are those of L</send_message($chat_id, $text, %opt, $cb)>, plus
C<timeout> in seconds, defaulting to B<300>. C<< timeout => 0 >> waits
indefinitely; read the next paragraph before choosing it.

While an ask is pending it B<shadows the command router> for that user
in that chat: the answer goes to the ask and to on_message, but not to
a command handler. That is deliberate, so a reply that happens to start
with a slash cannot both answer the prompt and run a command. It does
mean an unanswered prompt suppresses that user's commands until it
resolves, which is why the timeout has a default and why cancel_ask
exists. cancel_ask fails the pending ask with an C<ask cancelled> error
and returns whether there was one; a timeout fails it with
C<ask timed out>.

Asking the same user in the same chat again replaces the pending ask,
failing the old one with C<ask superseded> rather than dropping it.
Asking from inside an answer or timeout callback is the intended way to
build a multi-step flow and works as expected. Anonymous and channel
senders never satisfy an ask, since it is keyed on a user, and neither
do outgoing messages. If the prompt itself fails to send, the ask fails
immediately rather than waiting out its timeout.

send() is unaffected and stays entirely unvalidated.

=head2 Users mixin

=head3 me($cb)

Fetches the current user (getMe) into the user cache and calls
C<< $cb->($user, $err) >>.

=head3 user($id)

Returns the cached user hashref, or undef.

=head3 set_name($first, $last, $cb), set_bio($text, $cb), set_username($name, $cb)

Change the signed-in account's own profile. set_name requires a first
name; the last name is optional. set_username takes the name with or
without a leading at-sign, and an empty string removes it.

These are user-account methods. A bot session is refused them by
TDLib with "The method is not available to bots"; a bot changes its
own profile through the Bots mixin instead.

=head3 set_profile_photo($path, %opt, $cb)

Sets the account's profile photo. C<animation> treats the file as a
video avatar, with C<main_frame_timestamp> (seconds, default 0)
selecting the still frame. C<< public => 1 >> sets the public
photo instead: the fallback shown to users whom privacy settings deny
the main one, which a user account alone can have. C<$path> may be an
InputFile hashref instead of a path. A bot sets its own photo this way
too, or through set_bot_photo in the Bots mixin.

B<Changed in 0.04.> 0.03 set the public photo, so the same call now
replaces the account's real one. Pass C<< public => 1 >> to keep 0.03's
behaviour.

=head3 on_user($cb)

Handler for updateUser, called with the decoded user after the cache
is updated.

=head3 user_by_username($name, $cb)

Resolves a public C<@name> to a user, with or without the leading
at-sign. A name that resolves to a channel or a group is reported as
an error saying so, since only a private chat has a user behind it.
Bots are users and resolve normally.

=head3 set_birthdate(%opt, $cb), set_accent_color($color_id, %opt, $cb), profile_photos($user_id, %opt, $cb), delete_profile_photo($photo_id, $cb)

Profile details. set_birthdate takes C<day> and C<month> and an
optional C<year>; calling it with none of the three clears the
birthdate, and a day, month or year without the other two date parts
croaks. The month runs from 1, not from the 0 that C<localtime>
gives, and a date that does not exist or a year outside 1800 to 3000
croaks: TDLib would take the first as a request to clear the birthdate
and drop the second, both without an error. set_accent_color
takes C<background_custom_emoji_id>, a custom emoji shown on the reply
header and link preview background; omitting it clears any current one.
Profile photo ids are TL C<int64> and are sent as strings.

=head3 contacts($cb), add_contact($user_id, %opt, $cb), remove_contacts(\@user_ids, $cb), search_contacts($query, %opt, $cb), import_contacts(\@contacts, $cb)

The address book. add_contact options are C<first_name>, C<last_name>,
C<phone>, C<note> and C<share_phone>, which offers your own number in
return. import_contacts takes hashrefs of the same shape and is how you
find which of a list of phone numbers are on Telegram; Telegram matches
on the number, so a contact with none is simply not matched.

=head3 search_by_phone($phone_number, %opt, $cb), my_link($cb), toggle_username($username, $active, $cb)

Finding a user by phone number, this account's own t.me link, and
turning one of your usernames on or off. C<< local => 1 >> restricts the
phone lookup to what is already cached.

=head3 privacy($setting, $cb), set_privacy($setting, \@rules, $cb)

Read and write one privacy setting, named C<status>, C<profile_photo>,
C<phone>, C<bio>, C<birthdate>, C<forwards>, C<invites>, C<calls> or
C<find_by_phone>. Rules are an ordered list of UserPrivacySettingRule
hashrefs and the first match wins, so their order is the policy.

=head2 Chats mixin

=head3 chat($id)

Returns the cached chat hashref, or undef. The cache is fed by
updateNewChat and kept current by the chat-field updates listed under
L</UPDATES>.

=head3 on_chat($cb)

Handler for updateNewChat, called with the decoded chat.

=head3 load_chats($limit, %opt, $cb)

Loads more chats from TDLib (loadChats). TDLib answers with a 404
error once the list is exhausted; that is reported as success, not
failure. Takes C<list>, so the archive and the folders can be paged
too; without it only the main list is ever fetched.

=head3 pin_message($chat_id, $message_id, %opt, $cb), unpin_message($chat_id, $message_id, $cb)

Pins or unpins a message. Options: C<silent> to pin without notifying,
C<only_for_self> to pin it just for you.

=head3 set_chat_title($chat_id, $title, $cb), set_chat_photo($chat_id, $path, %opt, $cb)

Changes a chat's title or photo. set_chat_photo takes the same
C<animation> and C<main_frame_timestamp> options as
L</set_profile_photo($path, %opt, $cb)>.

=head3 add_chat_member($chat_id, $user_id, %opt, $cb)

Adds a user to a chat. C<forward_limit> (default 0) is how many recent
messages they get to see, in a basic group only: a supergroup or
channel ignores it.

=head3 set_member_status($chat_id, $user_id, $status, %opt, $cb)

Sets a member's status: C<member>, C<left> or C<banned>. C<left> is
the plain kick, which leaves them free to come back; C<banned> removes
and blocks them. C<until> is a unix timestamp for a temporary ban, 0
(the default) meaning forever; TDLib ignores it for C<member>, so a
membership is always permanent. A temporary ban must fall between 30
seconds and 366 days from now: TDLib silently makes anything outside
that permanent, so a short cool-off computed from a config value bans
for good. An unknown status croaks.

=head3 block_user($user_id, %opt, $cb)

Blocks a user. C<unblock> reverses it, and C<stories> acts on the
stories block list rather than the main one.

=head3 join_chat($chat_id, $cb), leave_chat($chat_id, $cb)

Joins or leaves a chat. joinChat answers with a ChatJoinResult, which
reports a join request awaiting approval as well as a plain success.

=head3 chat_by_username($name, $cb)

Resolves a public username (with or without the leading @) to a chat
via searchPublicChat and caches it.

=head3 mark_read($chat_id, %opt, $cb)

Marks messages read with a single viewMessages, which TDLib honours on
a chat that is not open because the request names its source and forces
the read. Opening the chat would be worse than useless: it puts the
chat at the top of the account's recently opened list, where closing it
again does not remove it. C<message_ids> defaults to the
chat's last message, so C<< $td->mark_read($chat_id, sub {}) >> clears
a chat. Fails if nothing is known to mark.

=head3 chat_action($chat_id, $action, $cb)

Sends a chat action, the "typing..." class of indicator. C<$action> is
one of C<typing> (the default), C<upload_document>, C<upload_photo>,
C<upload_video>, C<upload_voice>, C<record_video>, C<record_voice>,
C<cancel>. An unknown action croaks. The indicator expires on its own
after a few seconds, so repeat it while the work lasts.

=head3 member($chat_id, $user_id, $cb), admins($chat_id, $cb), search_members($chat_id, $query, %opt, $cb)

Read a chat's membership. search_members options: C<limit> (default 50)
and C<filter>, one of C<contacts>, C<administrators>, C<members>,
C<restricted>, C<banned>, C<bots>; an unknown filter croaks.

=head3 set_permissions($chat_id, \%permissions, $cb)

Sets the default permissions for ordinary members. TDLib replaces the
whole set, so any permission not named is denied, and this method sends
all of them explicitly rather than leaving the difference implicit.
Valid keys are the chatPermissions fields: C<can_send_basic_messages>,
C<can_send_audios>, C<can_send_documents>, C<can_send_photos>,
C<can_send_videos>, C<can_send_video_notes>, C<can_send_voice_notes>,
C<can_send_polls>, C<can_send_other_messages>, C<can_add_link_previews>,
C<can_react_to_messages>, C<can_edit_tag>, C<can_change_info>,
C<can_invite_users>, C<can_pin_messages>, C<can_create_topics>.

An unrecognised key croaks rather than being ignored: since absence
means denial, a typo would quietly take a right away.

=head3 set_chat_description($chat_id, $description, $cb)

Sets the description shown on a group or channel's profile. It is plain
text, not formatted: pass the empty string to clear it. Leaving it out
croaks.

=head3 invite_link($chat_id, %opt, $cb), edit_invite_link($chat_id, $link, %opt, $cb), invite_links($chat_id, %opt, $cb), revoke_invite_link($chat_id, $link, $cb), replace_primary_invite_link($chat_id, $cb), invite_link_members($chat_id, $link, %opt, $cb)

Manage a chat's invite links. Creating and editing accept C<name>,
C<expires> (a Unix time), C<limit> (maximum members) and
C<join_request>, which makes the link produce join requests to approve
instead of admitting people directly; answer those with
L</join_requests($chat_id, %opt, $cb), process_join_request($chat_id, $user_id, $approve, $cb), process_join_requests($chat_id, $approve, %opt, $cb), on_join_request($cb)>. TDLib replaces the whole link on
an edit, so any option not passed reverts to its default: renaming a
link clears its expiry and member limit. invite_links lists them,
filtered by C<creator> and C<revoked> and paged with C<offset_date>,
C<offset_link> and C<limit>; invite_link_members lists who joined
through one, C<limit> at a time (up to 100), paged by passing the last
member of a page as C<offset_member>; C<< expired_only => 1 >>
returns only members whose subscription has lapsed, and applies only
when the link is a subscription link.

=head3 join_requests($chat_id, %opt, $cb), process_join_request($chat_id, $user_id, $approve, $cb), process_join_requests($chat_id, $approve, %opt, $cb), on_join_request($cb)

The other half of a C<join_request> invite link. join_requests lists who is
waiting, filtered by C<link> and C<query> and bounded by C<limit>; pass
the last request of a page as C<offset_request> for the next.
process_join_request answers one, and the plural form answers everyone at
once, optionally only those who used one C<link>. C<$approve> defaults to
true in both, so declining is explicit.

on_join_request is the handler for updateNewChatJoinRequest, called with a
flattened hashref carrying C<chat_id>, C<user_id>, C<date>, C<bio>,
C<invite_link> and C<user_chat_id>.

Which account may call what differs here. on_join_request fires only for
a bot, and join_requests and process_join_requests only work for a
user; process_join_request works for both. So a bot answers each
request as it arrives, and a user lists the queue.

=head3 check_invite_link($link, $cb), join_by_link($link, $cb)

Inspect or accept an invite link. These take only the link, since the
chat is whatever it points at, and work for a chat you are not in.

=head3 mute($chat_id, $seconds, $cb), unmute($chat_id, $cb)

Silences a chat for a number of seconds, or indefinitely when no
duration is given. Notification settings are a single object in TDLib,
and a write replaces all of it, so these send the chat's cached
settings back with only the mute changed: a chat's own sound and
preview choices survive. A chat this client has not seen has nothing
cached, and gets "use the default" for every other field.

=head3 archive($chat_id, $cb), unarchive($chat_id, $cb), pin_chat($chat_id, $pinned, %opt, $cb), mark_unread($chat_id, $unread, $cb)

Chat list housekeeping. The C<$pinned> and C<$unread> flags default to
true, so C<pin_chat($chat)> pins and C<pin_chat($chat, 0)> unpins.
pin_chat takes a C<list> option, since a chat can be pinned separately
in each list.

=head3 chats(%opt, $cb), search_all($query, %opt, $cb)

chats lists a chat list; search_all searches messages across every
chat, unlike L</search_messages($chat_id, $query, %opt, $cb)>, which
searches inside a single chat. Both take C<list> and C<limit>; search_all
also takes C<offset>, C<min_date> and C<max_date>.

Wherever a C<list> option appears it is C<main> (the default),
C<archive>, or a chat folder id as a number. search_all is the
exception: with no C<list> it searches every chat, archived ones
included, and it can be narrowed to C<main> or C<archive> but not to a
folder, which croaks.

B<Changed in 0.04.> search_all with no C<list> searched the main list
in 0.03, so the same call now returns archived matches too. Pass
C<< list => 'main' >> for the old result.

=head3 mute_scope($scope, $seconds, %opt, $cb), scope_settings($scope, $cb), reset_notifications($cb)

Notification defaults for a whole class of chat, where C<$scope> is
C<private>, C<groups> or C<channels>. Every scopeNotificationSettings
field is sent outright, and unlike the per-chat settings the scope ones
have no "use the value from elsewhere" flag at all -- its one
C<use_default_> field means something else, that story notifications
come from your top contacts whatever C<mute_stories> says. So B<every
call replaces all of them>, and anything you do not pass reverts to
this module's default rather than staying as it was. Muting a scope for
an hour therefore also turns previews back on unless you pass
C<< show_preview => 0 >> with it. Read the current values with
scope_settings and pass them back if you are changing one thing. The
defaults are: both sounds ask for the app default (the TL spells that
-1; B<0 would disable the sound>), previews and the story poster shown,
pinned and mention notifications enabled, and story notifications left
to that top-contacts rule unless you pass C<mute_stories> yourself. Options: C<show_preview>
(also accepted as C<preview>, its original spelling), C<no_pinned>,
C<no_mentions>, C<sound_id>, C<mute_stories>, C<story_sound_id>,
C<show_story_poster>. reset_notifications puts everything back,
including per-chat overrides.

=head3 set_chat_reactions($chat_id, $reactions, %opt, $cb)

Chooses which reactions a chat allows. Pass C<'all'> for everything the
chat's tier permits, or an arrayref to restrict it; each element is an
emoji string or C<< { custom_emoji_id => $id } >>. Option: C<max> for
how many a single message may carry.

=head3 read_all_reactions($chat_id, $cb), set_reaction_notifications(%opt, $cb)

Mark every reaction in a chat as read, and configure which reactions
raise a notification.

set_reaction_notifications takes all five fields, because TDLib offers
no getter for them: the current value arrives only through an update, so
defaulting a field would silently clear it. C<message_reaction_source>,
C<story_reaction_source> and C<poll_vote_source> are each 'none',
'contacts' or 'all'; C<sound_id> is an int64 notification sound id
(stringified for you), and C<show_preview> is a flag.

=head3 blocked(%opt, $cb)

Lists blocked senders. Options: C<offset>, C<limit>, and C<stories> to
read the separate list of senders whose stories are hidden.

=head3 add_members($chat_id, \@user_ids, $cb), ban_member($chat_id, $user_id, %opt, $cb), transfer_ownership($chat_id, $user_id, $password, $cb), set_default_admin_rights(\%rights, %opt, $cb)

Bulk membership and ownership. ban_member differs from
L</set_member_status($chat_id, $user_id, $status, %opt, $cb)> in taking
C<revoke>, which also deletes what the banned member already sent, and
C<until> for a temporary ban. C<revoke> reaches the server only for a
basic group; in a supergroup or channel TDLib drops it, so purge with
L<delete_messages_by_sender()|/"resend_messages($chat_id, \@message_ids, $cb), delete_messages_by_sender($chat_id, $sender, $cb), delete_messages_by_date($chat_id, $min_date, $max_date, %opt, $cb), unpin_all($chat_id, $cb), read_all_mentions($chat_id, $cb)">
instead. transfer_ownership needs the account
password, which Telegram requires for an irreversible act.
set_default_admin_rights sets what a bot asks for when added as an
administrator; C<< channel => 1 >> targets channels rather than groups.

=head3 create_group($title, %opt, $cb), upgrade_to_supergroup($chat_id, $cb), delete_chat($chat_id, $cb), delete_history($chat_id, %opt, $cb)

create_group makes a supergroup by default; C<channel> makes a channel
and C<forum> makes a forum. Passing C<members> instead creates a basic
group, which is a different TDLib call and needs its members up front.
Also takes C<description>, C<auto_delete> and C<for_import>, which
creates the group ready to receive an imported message history.
delete_history options:
C<remove_from_list> and C<revoke>, which deletes for everyone rather
than only for you.

=head3 set_slow_mode($chat_id, $seconds, $cb), set_auto_delete($chat_id, $seconds, $cb), set_discussion_group($chat_id, $discussion_chat_id, $cb), protect_content($chat_id, $on, $cb)

Group settings: how often a member may post, how long messages live,
which group holds a channel's comments, and whether forwarding and
saving are blocked. The value is required: passing 0 clears the first
two and unlinks the discussion group, and leaving it out or passing
undef croaks rather than doing the same, since an undef from a failed
lookup would otherwise unlink a channel's comments.

=head3 make_forum($id, $on, %opt, $cb), sign_messages($id, $on, %opt, $cb), join_by_request($id, $on, %opt, $cb), join_to_send($id, $on, $cb), all_history_available($id, $on, $cb), hide_members($id, $on, $cb), set_supergroup_username($id, $username, $cb)

Supergroup and channel switches. make_forum is what turns an ordinary
supergroup into one that has topics, which
L<create_topic()|/"create_topic($chat_id, $name, %opt, $cb), edit_topic($chat_id, $topic_id, %opt, $cb), delete_topic($chat_id, $topic_id, $cb)"> needs.

These take a B<supergroup id>, which is not the chat id you use
everywhere else: a supergroup's chat id is -1000000000000 minus its
supergroup id. Passing either works, because a negative id is converted
for you. The flag defaults to true in all of them.

make_forum takes C<< tabs => 1 >> to show the forum's topics as tabs
rather than as a list. B<It is sent every time>, so calling make_forum
on a supergroup that is already a forum with tabs, and not passing
C<tabs>, turns them off -- TDLib treats the call as setting both flags
and only ignores it when both already match. Read C<has_forum_tabs>
from L<supergroup()|/"fetch_chat($chat_id, $cb), close_chat($chat_id, $cb), user_full_info($user_id, $cb), supergroup($id, %opt, $cb), basic_group($id, %opt, $cb), supergroup_members($id, %opt, $cb), groups_in_common($user_id, %opt, $cb)">
first if you are toggling something else about an existing forum.

sign_messages adds a sender signature to channel posts;
C<< show_sender => 1 >> adds a link to the sender's account with it.
C<show_sender> is sent every time, like make_forum's C<tabs>, so
signing a channel that already shows senders without passing it takes
that link away.
join_by_request takes C<guard_bot>, the user id of the bot that guards
the group (0 for none, and B<ignored when the flag is false>), and
C<< apply_to_links => 1 >> to apply the change to existing invite
links, primary links included.

=head3 fetch_chat($chat_id, $cb), close_chat($chat_id, $cb), user_full_info($user_id, $cb), supergroup($id, %opt, $cb), basic_group($id, %opt, $cb), supergroup_members($id, %opt, $cb), groups_in_common($user_id, %opt, $cb)

Reading chat and user records. fetch_chat asks TDLib, unlike
L</chat($id)>, which reads the module's cache; it also loads a chat
the client has not seen. close_chat balances an openChat you sent
yourself through L</send(\%request, $cb, %opt)>; nothing in the module
opens a chat.
C<< full => 1 >> asks supergroup and basic_group for the fuller record.
supergroup_members takes C<filter> (C<recent>, C<contacts>,
C<administrators>, C<restricted>, C<banned>, C<bots>), C<offset> and
C<limit>. groups_in_common pages with C<limit> (up to 100) and
C<offset_chat_id>, the chat id to start from; 0 asks for the first
page.

=head3 chat_event_log($chat_id, %opt, $cb), chat_statistics($chat_id, %opt, $cb), pinned_message($chat_id, $cb), clear_action_bar($chat_id, $cb), message_senders($chat_id, $cb), set_message_sender($chat_id, $sender_id, $cb)

The administrator log, with C<query>, C<from_event_id>, C<limit> and
C<users>; channel statistics, with C<dark> for the dark-theme graphs;
the chat's pinned message; and dismissing the bar Telegram shows above a
chat it thinks may be spam.

message_senders lists the identities allowed to post in a chat and
set_message_sender chooses one, which is how an administrator posts as
the channel rather than as themselves. A negative sender id is a chat, a
positive one a user.

=head3 search_chats($query, %opt, $cb), search_public_chats($query, $cb), top_chats($category, %opt, $cb), recommended_chats($cb), recently_opened_chats(%opt, $cb)

Finding chats. search_chats looks through what this account already
knows; search_public_chats reaches Telegram's public directory.
top_chats takes a category: C<users>, C<bots>, C<groups>, C<channels>,
C<inline_bots>, C<calls> or C<forwards>.

=head3 check_chat_username($chat_id, $username, $cb), report_chat($chat_id, %opt, $cb), default_disable_notification($chat_id, $on, $cb)

Whether a public username is free for a chat, reporting a chat with
C<option_id>, C<messages> and C<text>, and whether messages sent to a
chat are silent by default.

=head2 Messages mixin

=head3 send_message($chat_id, $text, %opt, $cb)

Sends a text message.

C<topic> posts into a forum topic, and works on every sending method.
Without it a message goes to the chat's General topic, which is why a
bot answering in a forum must pass the topic it was addressed in.

C<schedule> takes a Unix time and has the server deliver the message
then. A time less than ten seconds away, or already past, is sent at
once, and the callback still looks like an accepted scheduled message;
a bot cannot schedule at all. Because a scheduled message is not sent
now, the confirmation
C<< wait => 'sent' >> waits for would not arrive until its due time, so
C<wait> defaults to C<accepted> when scheduling and asking for C<sent>
explicitly croaks. Read pending ones back with
L</scheduled($chat_id, $cb)>.


TDLib will not send to a chat it has not loaded, and answers
"Chat not found" instead. A chat id taken from an update or from
L</chat_by_username($name, $cb)> is already known; one you constructed
yourself may not be, and that includes your own Saved Messages, whose
chat id is your user id. Open it first with createPrivateChat and send
to the id that returns:

    $td->send({ '@type' => 'createPrivateChat',
                user_id => $me->{id} }, sub {
        my ($chat, $err) = @_;
        die "$err->{message}\n" if $err;
        $td->send_message($chat->{id}, 'note to self', sub { });
    });

Options:

=over 4

=item parse_mode

C<markdown> (MarkdownV2) or C<html>, parsed through the synchronous
parseTextEntities call. Unlike every other error path, a parse error
is delivered synchronously: send_message invokes C<$cb> with the error
before returning, because parseTextEntities never reaches the network.

=item wait

C<sent> (default) fires the callback on final delivery: sendMessage
returns a message with a temporary id, and the real outcome arrives
later as updateMessageSendSucceeded or updateMessageSendFailed keyed
by that id. C<accepted> fires the callback with the temporary message
as soon as TDLib accepts the request.

=item reply_to

Message id to reply to. If that message cannot be replied to -- it is in
another chat, has been deleted, or has not reached the server yet --
TDLib sends a plain message instead, and the callback hears nothing of
it.

=item silent

Send without a notification.

=item disable_preview

Suppress the link preview.

=item reply_markup

A reply markup hashref, as built by
L</inline_keyboard(\@rows)>.

=back

=head3 entity_text($formatted_text, $entity), entity_texts($formatted_text)

Returns the text a formatting entity covers. TDLib measures
C<offset> and C<length> in UTF-16 code units, so C<substr> is wrong
for any text containing a character outside the BMP -- an emoji is one
Perl character but two UTF-16 units, and every entity after it is
shifted. entity_text does the slicing; entity_texts does it for every
entity at once, returning an arrayref whose elements carry the
entity's own fields, its C<type> flattened to the type name, and the
C<text> it covers.

    for my $e (@{ $td->entity_texts($msg->{content}{text}) }) {
        print "$e->{type}: $e->{text}\n";
    }

The offsets themselves are left exactly as TDLib sent them. They are
sent back unchanged when a message is forwarded, edited or copied, so
rewriting them into character counts would corrupt the message.

=head3 history($chat_id, %opt, $cb)

Pages getChatHistory backwards. Options: C<limit> (messages wanted,
default 50), C<max_pages> (default 10), C<from_message_id>. The
callback receives C<(\@messages, $err, $state)>; C<< $state->{complete} >>
is true when the requested limit was reached or the history was
exhausted.

=head3 edit_message($chat_id, $message_id, $text, %opt, $cb)

Edits a text message. Accepts parse_mode and disable_preview; parse
errors are synchronous, as in send_message.

=head3 edit_message_markup($chat_id, $message_id, $markup, $cb)

Replaces a message's reply markup and nothing else, for updating
buttons after a tap. B<Omit the markup to remove the buttons>: the
request then carries an explicit null, which is how TDLib spells "no
markup". An empty hashref does not work -- TDLib refuses it for having
no C<@type>.

Note that L</edit_message($chat_id, $message_id, $text, %opt, $cb)>
takes C<reply_markup> as an option, and an edit that omits it drops
whatever buttons the message had.

=head3 answer_poll($chat_id, $message_id, \@option_ids, $cb), stop_poll($chat_id, $message_id, %opt, $cb)

Vote in a poll and close one. Option ids are zero-based positions in
the list the poll was created with, and a single-answer poll takes a
one-element arrayref. stop_poll takes C<reply_markup>.

=head3 message($chat_id, $message_id, $cb), messages($chat_id, \@message_ids, $cb), replied_message($chat_id, $message_id, $cb)

Fetch messages by id. replied_message returns the one a message replies
to, without needing its id.

=head3 message_link($chat_id, $message_id, %opt, $cb), message_link_info($url, $cb), message_count($chat_id, %opt, $cb)

message_link builds a t.me link to a message, with C<media_timestamp>,
C<for_album> and C<in_thread>; message_link_info resolves one back.
message_count counts messages in a chat. C<filter> is required, since
TDLib cannot count unfiltered: give it C<Photo>, C<Video>, C<Document>,
C<Url>, C<Pinned> or any other searchMessagesFilter name, with or
without the prefix. Also takes C<topic> and C<local>, which counts only
what is already cached.

=head3 available_reactions($chat_id, $message_id, %opt, $cb), message_reactions($chat_id, $message_id, %opt, $cb), set_default_reaction($reaction, $cb)

available_reactions lists what may be added to a message;
message_reactions lists what already was, optionally filtered to one
C<reaction> (also accepted as C<emoji>); set_default_reaction picks the
one a long press sends.
Both take the same forms as
L</react($chat_id, $message_id, $reaction, %opt, $cb)>, so a custom
emoji works as well as a plain one. Adding and removing a reaction is
react().

available_reactions takes C<row_size>, the keyboard width a client
would lay the reactions out in, 8 by default and silently 8 again for
anything outside 5 to 25; message_reactions takes
C<offset> and C<limit> (50).

=head3 set_draft($chat_id, $text, %opt, $cb), clear_drafts(%opt, $cb)

Saves an unsent message against a chat, which other clients on the same
account will see. An empty or undefined text clears the draft, which is
how TDLib spells "no draft". Options: C<parse_mode>, C<reply_to> and
C<topic>. The draft's timestamp is not among them: TDLib stamps it from
its own clock when it stores the draft, which is what decides between
two clients that saved one. clear_drafts empties every chat, keeping
secret chats unless
C<exclude_secret> is false.

=head3 send_album($chat_id, \@contents, %opt, $cb)

Sends several media as one group. C<\@contents> are InputMessageContent
hashrefs, such as those L</send_file($chat_id, $path, %opt, $cb)> builds;
C<reply_to>, C<topic>, C<silent> and C<schedule> work as they do there.
C<< wait => 'sent' >> is refused: the reply carries one message per
item, so there is no single delivery to wait for, and the callback
always runs once Telegram accepts the album, which is what
C<< wait => 'accepted' >> says.

=head3 edit_message_caption($chat_id, $message_id, $caption, %opt, $cb), edit_message_media($chat_id, $message_id, \%content, %opt, $cb), edit_message_location($chat_id, $message_id, \%location, %opt, $cb), reschedule($chat_id, $message_id, $when, $cb)

Editing a sent message beyond its text. The caption honours
C<parse_mode> and C<caption_above>; the location takes C<live_period>,
C<heading> and C<proximity_alert_radius>, which it nests in the
liveLocation object TDLib expects. An edit without C<\%location> stops
sharing a live location. C<proximity_alert_radius> is sent every time, 0
when left out, so an edit that does not repeat it switches an active
proximity alert off. reschedule moves a scheduled message, and sends it
now when C<$when> is omitted or is less than ten seconds away.

Two fields are sent every time here, as they are for edit_message:
C<caption_above>, so editing the caption of a message whose caption sat
above the media without passing it puts the caption back below, and
C<reply_markup>, so an edit that does not pass the keyboard takes the
buttons away. Pass both when you mean to keep them.

=head3 resend_messages($chat_id, \@message_ids, $cb), delete_messages_by_sender($chat_id, $sender, $cb), delete_messages_by_date($chat_id, $min_date, $max_date, %opt, $cb), unpin_all($chat_id, $cb), read_all_mentions($chat_id, $cb)

Bulk operations over a chat's messages. C<$sender> is a bare user id,
or a negative chat id for a channel posting in the group. Deleting by
date revokes for everyone unless C<< revoke => 0 >>, which a basic group
needs: it refuses the revoke. A supergroup cannot be cleared by date at
all. TDLib moves a C<$max_date> later than half a minute ago back to
it, so a range lying entirely within the last 30 seconds deletes
nothing and still reports success.

=head3 message_thread($chat_id, $message_id, $cb), thread_history($chat_id, $message_id, %opt, $cb), read_date($chat_id, $message_id, $cb), message_viewers($chat_id, $message_id, $cb), message_properties($chat_id, $message_id, $cb), message_by_date($chat_id, $date, $cb), open_content($chat_id, $message_id, $cb)

Reading around a message: its comment thread and that thread's history,
when it was read and by whom, what may be done with it, the message
nearest a timestamp. open_content marks self-destructing media as
opened, which starts its timer. thread_history pages with C<limit>,
C<offset> and C<from_message_id>, the message to read backwards from;
0 starts at the newest.

=head3 parse_markdown($text, $cb), markdown_text(\%formatted, $cb), text_entities($text, $cb), translate($text, $to_language, %opt, $cb), link_preview($text, $cb), search_hashtags($prefix, %opt, $cb)

Text utilities. parse_markdown turns markdown into a formattedText and
markdown_text turns one back; text_entities finds links, mentions and
the like in plain text without any markup. translate takes a string or
a formattedText and a language code, and C<tone>, one of C<formal>,
C<neutral> (the default) or C<casual>. link_preview asks what Telegram
would show for the links in a text, and fails with a 404 when the text
has none, which is an ordinary answer rather than a fault.

=head3 scheduled($chat_id, $cb)

Lists the messages scheduled in a chat but not yet delivered.

=head3 react($chat_id, $message_id, $reaction, %opt, $cb)

Adds a reaction. Options: C<remove> to take the reaction away again,
C<is_big> for the animated form, C<update_recent> (default on) to fold
the emoji into the sender's recent reactions.

C<$reaction> is an emoji string, or a hashref
C<< { custom_emoji_id => $id } >> for a custom emoji; the id is int64
and is stringified for you. A paid reaction is B<not> reachable here --
TDLib rejects it in this call and points at
L<add_paid_reaction()|/"add_paid_reaction($chat_id, $message_id, $star_count, %opt, $cb), commit_paid_reactions($chat_id, $message_id, $cb), remove_paid_reactions($chat_id, $message_id, $cb), set_paid_reaction_type($chat_id, $message_id, $type, $cb), paid_reaction_senders($chat_id, $cb)">.

=head3 set_reactions($chat_id, $message_id, \@reactions, %opt, $cb), delete_reactions_from_sender($chat_id, $message_id, $sender, $cb), clear_recent_reactions($cb)

Replace the whole set of our reactions on a message at once -- the bot
counterpart of react, which is for users; remove every reaction a given
sender left
(C<$sender> is a bare user id, or a negative chat id); and clear the
recent-reactions list. Each element of C<@reactions> takes the same
forms as react's C<$reaction>. C<is_big> applies.

=head3 add_paid_reaction($chat_id, $message_id, $star_count, %opt, $cb), commit_paid_reactions($chat_id, $message_id, $cb), remove_paid_reactions($chat_id, $message_id, $cb), set_paid_reaction_type($chat_id, $message_id, $type, $cb), paid_reaction_senders($chat_id, $cb)

Paid reactions are staged and then committed, which is why they are
separate from react: add one or more pending reactions, then commit
them, or drop them with remove. C<type> selects who is credited:
'regular' (the default), 'anonymous', or a chat id to react as that
chat. paid_reaction_senders lists the senders available for a chat.

=head3 delete_messages($chat_id, \@message_ids, %opt, $cb)

Deletes messages. C<revoke> defaults to true (delete for all
participants).

=head3 forward_messages($chat_id, $from_chat_id, \@message_ids, %opt, $cb)

Forwards messages. Options: C<send_copy>, C<remove_caption>, C<silent>.
The callback runs once Telegram accepts the forward, with the pending
messages; like send_album it refuses C<< wait => 'sent' >>.

=head3 on_message($cb)

Handler for updateNewMessage, called with the decoded message. Its
text is a character string, but any formatting entities on it are
measured in UTF-16 code units: slice them with
L</entity_text($formatted_text, $entity), entity_texts($formatted_text)>
rather than C<substr>.

=head3 send_file($chat_id, $path, %opt, $cb)

Sends a local file. C<kind> selects the content: C<document> (the
default), C<photo>, C<video>, C<audio>, C<animation>, C<voice_note>,
C<video_note>, C<sticker>; an unknown kind croaks.
C<$path> may instead be an InputFile hashref, as returned by
L</upload($path)>. C<caption> is formatted with the same
C<parse_mode> rules as L</send_message($chat_id, $text, %opt, $cb)>,
and C<reply_to>, C<silent>, C<wait> and C<reply_markup> behave as they
do there.

Each kind nests its InputFile inside a per-kind wrapper object --
inputMessageDocument takes an inputDocument, inputMessagePhoto an
inputPhoto, and so on. This method builds that nesting; handing TDLib
the InputFile directly yields only "InputFile is not specified".

Kinds accept the metadata their wrapper defines, and Telegram
classifies media by what it is given: C<width> and C<height> for
photo, animation, video and sticker; C<duration> for animation, video,
audio, voice_note and video_note; C<title> and C<performer> for audio;
C<length> for video_note; C<emoji> for sticker. C<sticker> and
C<video_note> have no caption field in the schema, so a caption passed
with them is dropped rather than sent.

A Telegram animation is an MP4, not a GIF. Sending a C<.gif> file as
C<animation> succeeds but arrives as a plain document: the conversion
is the sender's job, not the server's. Convert to MP4 first (H.264,
C<yuv420p>) and it arrives as a real animation. Sending an existing
sticker means sending its remote file id, since an arbitrary local
file will not pass Telegram's sticker validation.

=head3 send_poll($chat_id, $question, \@options, %opt, $cb)

Sends a poll, which needs at least two options. Polls are anonymous
unless C<anonymous> is turned off, which is the opposite of TDLib's own
default but matches what Telegram's clients create. For the same
reason a vote can be changed or taken back unless C<revoting> is turned
off; in a quiz it is final. Options: C<multiple> to allow several
answers, C<open_period> to close the poll after that many seconds,
C<allow_adding_options>, and C<quiz> with C<correct> (an option index,
default 0) and C<explanation> for a quiz.

B<Changed in 0.04.> 0.03 sent no re-voting setting, so every poll it
created refused a change of vote. Pass C<< revoting => 0 >> for that.

All three of these, like the other senders, accept C<reply_to>,
C<silent>, C<reply_markup> and C<wait>.

=head3 send_location($chat_id, $latitude, $longitude, %opt, $cb), send_contact($chat_id, $phone, $first_name, %opt, $cb)

Sends a location or a contact. send_location takes C<accuracy> in
metres; send_contact takes C<last_name>, C<vcard> and C<user_id>.

=head3 search_messages($chat_id, $query, %opt, $cb)

searchChatMessages over one chat. Options: C<limit> (default 50),
C<from_message_id>, C<offset>. The callback receives
C<(\@messages, $err, $info)>, where C<$info> carries C<total_count>
and C<next_from_message_id> for paging.

=head2 Files mixin

=head3 download($file_id, %opt, $cb)

Starts a download (downloadFile). C<on_progress> receives the decoded
file on every related updateFile; the main callback fires with the
file once local.is_downloading_completed is true. A file that is
already downloaded fires it from the downloadFile reply itself: TDLib
emits no updateFile when nothing changed. A download that fails after
starting (TDLib signals this only via updateFile, with
is_downloading_active and is_downloading_completed both false) fails
the callback with a synthetic C<download failed> error. Option:
C<priority> (default 1). C<on_progress> may be given without a main
callback, for a download followed only through its progress.

One registration per file id: a second download() for the same id while
the first is in flight fails its callback immediately with a synthetic
C<already in progress> error, delivered synchronously like a parse_mode
error since nothing is sent; the first download is left alone.

=head3 cancel_download($file_id)

Cancels a pending download and fails its callback. It takes no callback
of its own, and croaks on one.

=head3 upload($path)

Returns an inputFileLocal hashref for use as message content or
elsewhere in a request. It only builds the shape: nothing is sent
and nothing is tracked. The actual upload is reported by TDLib
through the same updateFile as downloads, but on the remote side of
the file (C<remote.uploaded_size> up to
C<remote.is_uploading_completed>), and is observed with
L</on_upload($file_id, $cb)>.

Every send that takes a path uploads asynchronously, so the file must
still be on disk when TDLib gets to it, not merely when the call
returns. A File::Temp object scoped to the enclosing block is the way
this goes wrong: it unlinks on destruction and the upload then fails
with "Need full local (or generate, or inactive remote) location for
upload". Keep the handle alive until the callback runs.

=head3 on_upload($file_id, $cb)

Registers C<$cb> to fire with the decoded file on every updateFile
for C<$file_id>. The registration is removed automatically once the
last update has been delivered: the one with
C<remote.is_uploading_completed> true, or the one showing an upload
that had started and stopped without completing. Pass an undef C<$cb>
to remove it earlier; leaving the callback out croaks. The file id
becomes known only after the send is accepted: read it from the
returned message content (for a document,
C<< $msg->{content}{document}{document}{id} >>) and register then.
Send with C<< wait => 'accepted' >> for that: the default calls back
on delivery, when the upload has already finished, so a watcher
registered then never fires and is never removed.

"Had started" means seen to start by this watcher, and TDLib reports
the start before the send is accepted. So an upload stopped before its
first progress update -- a send deleted at once, a file unreadable from
the first byte -- looks like one still queued, and its watcher stays:
remove it yourself when you cancel. On close the watchers are dropped
silently.

Unlike the other on_* methods, on_upload is a per-id registration,
not a single-handler setter, and it returns nothing.

=head3 file($file_id, $cb), remote_file($remote_id, %opt, $cb), delete_file($file_id, $cb), suggested_file_name($file_id, %opt, $cb)

Local file records. remote_file resolves the persistent id that travels
inside a message; its C<file_type> must match what the file actually is,
and may be given with or without the C<fileType> prefix. A name the
pinned schema does not have croaks rather than reaching the server.
suggested_file_name takes C<directory>, the directory the name is being
chosen for, so it can avoid colliding with what is already there.

=head3 add_to_downloads($file_id, $chat_id, $message_id, %opt, $cb), remove_from_downloads($file_id, %opt, $cb), pause_download($file_id, $paused, $cb)

The download list Telegram clients show. Options: C<priority>, and
C<delete_cache> to remove the downloaded bytes as well as the entry.

=head3 storage_statistics($cb), optimize_storage(%opt, $cb)

A long-lived client accumulates gigabytes of cached media.
optimize_storage prunes it, bounded by C<size>, C<ttl>, C<count> and
C<immunity_delay>, restricted to C<chats> or held back from
C<exclude_chats>, each an arrayref of chat ids. An unset limit is sent
as -1, which TDLib reads as B<its own default>, not as no limit: 100 MB
of files in total, nothing untouched for 23 hours, 40000 files, and an
hour before a new file may be deleted. So optimize_storage with no
options is a full prune at those defaults, not a no-op. Set every limit
you care about.

C<chat_limit> affects only the statistics that come back, never what is
deleted: it is the number of chats, largest usage first, reported
separately, with every other chat folded into an entry whose chat id is
0. C<statistics> likewise only changes what is returned.

=head2 Connection mixin

=head3 connection_state()

Returns the last seen connection state name, or undef before the
first updateConnectionState arrives. One of
connectionStateWaitingForNetwork, connectionStateConnectingToProxy,
connectionStateConnecting, connectionStateUpdating or
connectionStateReady. The first three mean there is no route to
Telegram, so a request waits for one. connectionStateUpdating means
the opposite: the connection is up and TDLib is fetching what it
missed, and requests go out normally, so do not treat it as offline.

=head3 option($name), my_id()

TDLib reports its options as updates rather than replies, so the
module caches them as they arrive; option() reads one back. Boolean
options are cached as 1 or 0 and an empty option as undef. An integer
option is TL int64 and so arrives as a string; numify one before
putting it in a request you build yourself.

my_id() is the signed-in account's own user id, which TDLib pushes
right after login. It is undef until then.

=head3 on_connection_state($cb)

Handler for updateConnectionState, called with the state name string
after connection_state() is updated.

=head3 sessions($cb), terminate_session($session_id, $cb), terminate_other_sessions($cb), set_session_ttl($days, $cb)

The devices logged into this account. sessions lists them;
terminate_session logs one out and terminate_other_sessions logs out
everything except this client. set_session_ttl sets how many days of
inactivity ends a session automatically. Session ids are TL C<int64> and
are sent as strings.

=head3 add_proxy(\%proxy, %opt, $cb), proxies($cb), enable_proxy($proxy_id, $cb), disable_proxy($cb), remove_proxy($proxy_id, $cb), ping_proxy(\%proxy, $cb)

Proxy configuration. A proxy hashref takes C<server>, C<port> and
C<type> (C<socks5>, C<http> or C<mtproto>), plus C<username> and
C<password> for the first two, C<http_only> for HTTP, and C<secret> for
MTProto. add_proxy enables the proxy unless C<< enable => 0 >>, and
takes C<comment>, a label of your own that TDLib stores with it.

=head3 set_network_type($type, $cb), network_statistics(%opt, $cb)

Telling TDLib the network changed (C<none>, C<mobile>, C<roaming>,
C<wifi>, C<other>) lets it reconnect promptly rather than waiting for
its own timers, which matters on a laptop that sleeps or a phone that
changes network. network_statistics takes C<< current => 1 >> to report
only the current session rather than everything since the counters were
last reset.

=head3 log_out($cb), password_state($cb), set_password($old, $new, %opt, $cb), account_ttl($days, $cb), register_device(\%token, %opt, $cb)

Account-level operations. set_password takes C<hint> and
C<recovery_email>. account_ttl reads the inactivity period after which
Telegram deletes the account when called with no C<$days>, and sets it
when given one. register_device takes a DeviceToken hashref for push
notifications, plus C<other_users>.

=head2 Bots mixin

=head3 inline_keyboard(\@rows)

Builds a replyMarkupInlineKeyboard for the C<reply_markup> option of
L</send_message($chat_id, $text, %opt, $cb)> and
L</send_file($chat_id, $path, %opt, $cb)>. Each row is an arrayref of
buttons, and each button is C<< { text => ..., data => ... } >> for a
callback button, C<< { text => ..., url => ... } >> for a link, or
C<< { text => ..., web_app => $url } >> to launch a Mini App. A
button with none of the three croaks.

Callback data is TL C<bytes>, which the JSON interface carries base64
encoded; this method encodes it, and L</on_callback_query($cb)>
decodes it again, so callers only ever handle the plain bytes.

=head3 reply_keyboard(\@rows, %opt)

Builds a replyMarkupShowKeyboard, the custom keyboard that replaces a
user's normal one. A button may be a plain string or a hashref;
C<< { text => ..., request => 'phone' } >> (or C<'location'>) asks the
user to share that instead of sending text. Options: C<one_time>,
C<resize> (default on), C<persistent>, C<placeholder>.

Three further button shapes are available.
C<< { text => ..., web_app => $url } >> launches a Mini App, and the
data it sends back arrives through
L</on_web_app_data($cb)>.
C<< { text => ..., request_chat => \%spec } >> and
C<< { text => ..., request_users => \%spec } >> ask the user to pick a
chat or some users. In both, a constraint is applied only for a key you
actually mention, so C<< { bot => 0 } >> means "not a bot" while
leaving it out means "either".

C<channel> is the exception, because TDLib gives it no "restrict" flag
of its own: it always applies, so omitting it asks for a group rather
than for either. Pass C<< channel => 1 >> to ask for a channel.

request_chat takes C<id>, C<channel>,
C<forum>, C<username>, C<created>, C<bot_is_member>, C<want_title>,
C<want_username>, C<want_photo>, and C<user_rights> / C<bot_rights> as
chatAdministratorRights hashrefs. request_users takes C<id>, C<bot>,
C<premium>, C<max> (default 1), C<want_name>, C<want_username>,
C<want_photo>.

=head3 remove_keyboard(%opt)

Builds a replyMarkupRemoveKeyboard, which takes a custom keyboard away
again. Option: C<personal>.

=head3 set_commands(\@commands, %opt, $cb)

Sets the "/" command menu a bot offers. Each command is
C<< ['start', 'Begin'] >> or
C<< { command => 'start', description => 'Begin' } >>; a leading slash
is stripped. An empty list clears the menu. Options: C<scope> (a
BotCommandScope hashref, default botCommandScopeDefault),
C<language_code>.

=head3 set_bot_name($name, %opt, $cb), set_bot_description($text, %opt, $cb), set_bot_short_description($text, %opt, $cb), set_bot_photo($path, %opt, $cb)

Change a bot's own profile. The description is the long text shown on
an empty chat screen with the bot; the short description is the
one-liner shown in its profile and in search results. set_bot_photo
takes the same C<animation> and C<main_frame_timestamp> options as
L</set_profile_photo($path, %opt, $cb)>.

TDLib addresses a bot by user id. These default to
L</option($name), my_id()>, which is what a bot session wants; pass C<bot_user_id> to
act on a bot from another account that owns it. The three text setters
accept C<language_code> for a localised value; set_bot_photo does not,
since TDLib keeps one photo per bot rather than one per language.

=head3 on_callback_query($cb)

Handler for updateNewCallbackQuery, called with a hashref carrying
C<id>, C<sender_user_id>, C<chat_id>, C<message_id>, C<type>, and the
decoded C<data>. Answer it with
L</answer_callback_query($id, %opt, $cb)>; Telegram shows the user a
spinner until you do.

A press on a message the bot sent through inline mode
(updateNewInlineCallbackQuery) arrives here and at the router too. It
has no chat: C<chat_id> and C<message_id> are undef, and
C<inline_message_id> names the message for the edit_inline_* methods.
So does a press on a message sent for a connected business account
(updateNewBusinessCallbackQuery), with its C<chat_id> and C<message_id>
and the C<connection_id> it came through -- which is what the
edit_business_message_* methods take, and they are what edits such a
message; the ordinary edit_message_* family addresses a different thing.

=head3 on_inline_query($cb)

Handler for updateNewInlineQuery, the typing-ahead queries an inline
bot answers. It is called with a hashref carrying C<id>,
C<sender_user_id>, C<query>, C<offset>, C<chat_type> and
C<user_location>, a location or undef. Inline mode
must be turned on for the bot first, through BotFather.

=head3 answer_inline_query($id, \@results, %opt, $cb)

Answers an inline query with a list of article results. Each result is
C<< { title => ..., message => ..., description => ..., url => ...,
thumbnail_url => ..., reply_markup => ... } >>; C<message> is the text
sent when the result is picked, defaulting to the title, and C<id>
is generated if you leave it out. Options: C<cache_time> (default
300), C<personal> for per-user results, C<next_offset> for paging.

=head3 answer_callback_query($id, %opt, $cb)

Answers a callback query. Options: C<text>, C<show_alert>, C<url>,
C<cache_time>. The id is sent as a string, since it is a TL C<int64>
and would lose precision as a number.

=head3 commands(%opt, $cb), delete_commands(%opt, $cb)

Read back or clear the "/" menu set by
L</set_commands(\@commands, %opt, $cb)>. Both take the same C<scope>
and C<language_code> options.

=head3 bot_name(%opt, $cb), bot_description(%opt, $cb), bot_short_description(%opt, $cb)

Read back the values set by the corresponding set_bot_* methods, with
the same C<bot_user_id> and C<language_code> options.

=head3 press($chat_id, $message_id, $data, $cb)

Presses an inline keyboard button on someone else's message, which is
what a user's client does when you tap one. This is the other side of
L</on_callback_query($cb)>: use it to drive a bot rather than to be
one. C<$data> is the plain payload, base64 encoded on the way out for
you. The callback receives a callbackQueryAnswer carrying C<text> and
C<url>.

=head3 inline_query($bot_user_id, $query, %opt, $cb), send_inline_result($chat_id, $query_id, $result_id, %opt, $cb)

The user side of inline mode: ask a bot for results as if you had typed
its username in a message box, then send one of them. inline_query
options are C<chat_id>, C<offset> and C<location>; send_inline_result
takes C<hide_via_bot>, and C<reply_to>, C<silent>, C<schedule> and
C<topic> as send_message does, but calls back once the message is
accepted and refuses C<< wait => 'sent' >>. The query id is sent as a
string, being a TL C<int64>.

=head3 start_bot($bot_user_id, $parameter, %opt, $cb)

Sends the C</start> that a deep link produces, passing C<$parameter>
along. Option: C<chat_id>, which defaults to the bot's own chat.

=head3 attachment_menu_bot($bot_user_id, $cb), toggle_attachment_menu($bot_user_id, $on, %opt, $cb)

Read and change whether a bot sits in the attachment menu. This matters
for Mini Apps: L<open_web_app()|/"open_web_app($chat_id, $bot_user_id, $url, %opt, $cb), close_web_app($launch_id, $cb)">
accepts an empty URL only for a bot that is in the menu, and answers
BOT_INVALID otherwise. Option: C<allow_write_access>.

=head3 edit_inline_text($inline_message_id, $text, %opt, $cb), edit_inline_caption($inline_message_id, $caption, %opt, $cb), edit_inline_media($inline_message_id, \%content, %opt, $cb), edit_inline_markup($inline_message_id, \%markup, $cb), edit_inline_location($inline_message_id, \%location, %opt, $cb)

Edit a message a bot sent through inline mode. These address it by its
C<inline_message_id> string, which is a different thing from the
C<(chat_id, message_id)> pair the edit_message_* methods take; the two
are not interchangeable. The id is not the result id you gave
L</answer_inline_query($id, \@results, %opt, $cb)>: it arrives with a
press on one of the message's buttons, as the callback query's
C<inline_message_id>, or in updateNewChosenInlineResult once the user
picks a result -- sent only when inline feedback is enabled for the bot
through BotFather, and carrying the id only for a result that went out
with buttons, which is what gives Telegram something to edit. Read that
update with L<on_update()|/"on_update($cb), on_error($cb)">.

edit_inline_text and edit_inline_caption honour C<parse_mode> and hand
a parse failure to the callback rather than to TDLib. All accept
C<reply_markup>, and all send it every time, so an edit that leaves it
out drops the message's buttons. edit_inline_caption also takes
C<caption_above>, sent every time in the same way, as
L<edit_message_caption()|/"edit_message_caption($chat_id, $message_id, $caption, %opt, $cb), edit_message_media($chat_id, $message_id, \%content, %opt, $cb), edit_message_location($chat_id, $message_id, \%location, %opt, $cb), reschedule($chat_id, $message_id, $when, $cb)"> does. edit_inline_location takes C<live_period>, C<heading>
and C<proximity_alert_radius>, which it nests in the liveLocation
object where TDLib expects them.

=head3 share_chat_with_bot($chat_id, $message_id, $button_id, $shared_chat_id, %opt, $cb), share_users_with_bot($chat_id, $message_id, $button_id, \@user_ids, %opt, $cb)

The user's answer to a C<request_chat> or C<request_users> keyboard
button. The chat and message ids identify the message the button was
on, and C<$button_id> is the C<id> given to that button when the
keyboard was built, which is how a bot tells two pickers apart. Option:
C<check_only>, to test whether the share would be allowed without
performing it.

=head3 allow_bot_messages($bot_user_id, $cb), can_bot_message($bot_user_id, $cb)

Whether a bot you have blocked or never started may message you.
can_bot_message asks; allow_bot_messages grants.

=head3 callback_query_message($chat_id, $message_id, $callback_query_id, $cb)

Fetches the message a callback query came from, for a bot that did not
keep it. The query id is TL C<int64> and is sent as a string.

=head3 check_bot_username($username, $cb), toggle_bot_username($bot_user_id, $username, $active, $cb)

Check whether a username is free for a bot, and turn one of a bot's
usernames on or off. The flag defaults to on.

=head3 create_bot($name, $username, %opt, $cb), owned_bots($cb), bot_token($bot_user_id, %opt, $cb), bot_access_settings($bot_user_id, $cb), set_bot_access_settings($bot_user_id, \%settings, $cb)

Creating and managing bots from an account rather than through
BotFather. create_bot takes C<manager>, the bot that will own the new
one, and C<via_link>. bot_token reads a managed bot's token; C<revoke>
issues a new one and invalidates the old, so anything still using it
stops working.

=head3 set_updates_status($pending_count, %opt, $cb), recent_inline_bots($cb), similar_bots($bot_user_id, $cb), similar_bot_count($bot_user_id, %opt, $cb), open_similar_bot($bot_user_id, $opened_bot_user_id, $cb)

set_updates_status reports a bot's backlog to Telegram, with an optional
C<error>. The rest are discovery: recently used inline bots, and bots
Telegram considers similar to a given one. similar_bot_count takes
C<< local => 1 >> to answer from what TDLib already holds rather than
asking the server, and then answers -1 when it holds no count at all.

=head3 bot_media_previews($bot_user_id, %opt, $cb), add_bot_media_preview($bot_user_id, \%content, %opt, $cb), edit_bot_media_preview($bot_user_id, $file_id, \%content, %opt, $cb), delete_bot_media_previews($bot_user_id, \@file_ids, %opt, $cb), reorder_bot_media_previews($bot_user_id, \@file_ids, %opt, $cb)

The sample media shown on a bot's profile, which are stored per
language. Passing C<language_code> to bot_media_previews asks for one
language's set rather than the list of languages. C<\%content> is an
InputStoryContent hashref, passed through as given.

=head3 set_game_score($chat_id, $message_id, $user_id, $score, %opt, $cb), game_high_scores($chat_id, $message_id, $user_id, $cb), set_inline_game_score($inline_message_id, $user_id, $score, %opt, $cb), inline_game_high_scores($inline_message_id, $user_id, $cb)

Reporting and reading HTML5 game results. C<edit> updates the message to
show the new score and is on by default; C<force> allows a score lower
than the player's best, which is otherwise refused.

=head3 set_menu_button($user_id, %opt, $cb), menu_button($user_id, $cb)

The button beside the message box in a chat with a bot. Options C<text>
and C<url>; a Mini App URL makes it open the app. C<< commands => 1 >>
puts back the list of commands instead, and a call with neither a text
nor a url puts back Telegram's default button. A url without a text
croaks, since TDLib refuses that pair. Passing user id 0 sets it for
every user.

=head2 WebApps mixin

Mini Apps, which Telegram also calls Web Apps. TDLib does not render
anything: it hands back a URL and a launch id, and hosting the webview
is the application's job. See L</MINI APPS>.

Every method here builds the webAppOpenParameters object itself from
the C<application_name> the client was constructed with, so C<%opt>
carries only C<mode> (C<full_size>, the default, C<compact> or
C<full_screen>), C<theme>, and a per-call C<application_name> override.

=head3 web_app($bot_user_id, $short_name, $cb)

Looks up one Mini App by the short name it was given in BotFather. The
callback receives a foundWebApp carrying the C<web_app> itself, plus
C<request_write_access> and C<skip_confirmation>.

=head3 web_app_link($chat_id, $bot_user_id, $short_name, %opt, $cb), web_app_url($bot_user_id, %opt, $cb), main_web_app($chat_id, $bot_user_id, %opt, $cb)

Three ways to get a launch URL: from a direct link short name, from a
button URL (C<url> option), and from a bot's main Mini App.
web_app_link and main_web_app accept C<start_parameter>; web_app_link
also accepts C<allow_write_access>.

=head3 open_web_app($chat_id, $bot_user_id, $url, %opt, $cb), close_web_app($launch_id, $cb)

Open and close a Mini App session. The callback of open_web_app
receives a webAppInfo carrying C<launch_id> and C<url>; pass that
launch id to close_web_app when the webview goes away. C<$url> should
be the one from a Web App button; an empty string is accepted only for
a bot in the attachment menu, and otherwise answers BOT_INVALID.

=head3 send_web_app_data($bot_user_id, $button_text, $data, $cb)

Sends data back to a bot as if the Mini App had called
C<Telegram.WebApp.sendData()>. The bot sees it through
L</on_web_app_data($cb)>. This is the reply-keyboard flow, so
C<$button_text> must be the text of the Web App button that was
pressed.

=head3 on_web_app_data($cb)

Handler for a messageWebAppDataReceived message. Called as
C<< $cb->($message, $data, $button_text) >> with the payload and button
text lifted out of the content for convenience. L</on_message($cb)>
still sees these messages too.

=head3 answer_web_app_query($query_id, \%result, $cb), web_app_request($bot_user_id, $method, $parameters, $cb), web_app_placeholder($bot_user_id, $cb)

answer_web_app_query is for a bot: an app opened from an inline button,
the menu button or the attachment menu receives a C<query_id> in its
init data, and the bot answers it with one InputInlineQueryResult,
which Telegram posts on the user's behalf; an app opened from a
keyboard button has no query id. web_app_request is for a user client:
it sends a custom method call on the Mini App's behalf, with
C<$parameters> as a JSON string. web_app_placeholder fetches the
outline shown while an app loads.

=head2 Forum mixin

Topics in a forum supergroup. A topic id is the topic's
C<forum_topic_id>, an int32 of its own and not a message id: read it
from C<< $msg->{topic_id}{forum_topic_id} >> or from topics(), never
from the message that opened the topic.

To post into a topic, pass C<topic> to any sending method rather than
calling something different; see
L</send_message($chat_id, $text, %opt, $cb)>.

=head3 create_topic($chat_id, $name, %opt, $cb), edit_topic($chat_id, $topic_id, %opt, $cb), delete_topic($chat_id, $topic_id, $cb)

Create, rename and remove topics. create_topic options: C<color> (an
RGB integer) and C<custom_emoji_id> for the icon, and C<name_implicit>.
edit_topic options: C<name> and C<custom_emoji_id>; the icon is only
touched when C<custom_emoji_id> is given, so renaming leaves it alone,
and leaving C<name> out keeps the current name.

=head3 topic($chat_id, $topic_id, $cb), topics($chat_id, %opt, $cb), topic_history($chat_id, $topic_id, %opt, $cb), topic_link($chat_id, $topic_id, $cb)

Read topics and their messages. topics options: C<query>, C<limit>
(default 100) and the C<offset_date>, C<offset_message_id>,
C<offset_forum_topic_id> triple for paging. topic_history takes
C<from_message_id>, C<offset> and C<limit>.

=head3 close_topic($chat_id, $topic_id, $closed, $cb), pin_topic($chat_id, $topic_id, $pinned, $cb), unpin_topic_messages($chat_id, $topic_id, $cb), hide_general_topic($chat_id, $hidden, $cb), topic_icons($cb)

State changes. The flag defaults to true, so C<close_topic($chat, $id)>
closes and C<close_topic($chat, $id, 0)> reopens. hide_general_topic
takes no topic id, since the General topic is identified by its absence.
topic_icons lists the icons a client may offer.

=head3 read_all_topic_reactions($chat_id, $topic_id, $cb)

Marks every reaction in one forum topic as read.

=head2 Folders mixin

Chat folders, which Telegram's own clients show as tabs above the chat
list. The folder list itself arrives through updateChatFolders rather
than being fetched.

A folder's name is a chatFolderName wrapping a formattedText, not a
plain string; these methods build that from the C<name> you give, so a
folder spec is an ordinary hashref.

=head3 folder($id, $cb), create_folder(\%spec, $cb), edit_folder($id, \%spec, $cb), delete_folder($id, %opt, $cb), reorder_folders(\@ids, %opt, $cb)

Telegram truncates a folder name to 12 characters and does not say so,
which is worth knowing before a longer name comes back shortened.

A folder spec takes C<name> (required; a string, or a formattedText for
a name with custom emoji, then animated with C<animate_emoji>), C<icon>
(an icon name such as C<Work> or C<Party>), C<color_id>, C<shareable>,
the chat lists C<pinned_chat_ids>, C<included_chat_ids> and
C<excluded_chat_ids>, and the flags C<exclude_muted>, C<exclude_read>,
C<exclude_archived>, C<include_contacts>, C<include_non_contacts>,
C<include_bots>, C<include_groups> and C<include_channels>. An unknown
key croaks. TDLib replaces the whole folder on an edit, so any key not
passed reverts to its default: editing only the name empties the
membership.

delete_folder takes C<leave_chats>, the chats to leave along with the
folder rather than merely un-filing. reorder_folders takes
C<main_position>, where the unfiled main list sits among the tabs; only
a Premium account can move it, and for any other TDLib puts it back
first without an error.

=head3 recommended_folders($cb), folder_chat_count(\%spec, $cb), folder_tags($on, $cb)

recommended_folders lists the ready-made folders Telegram suggests.
folder_chat_count reports how many chats a spec would match without
creating it. folder_tags turns the coloured tags on or off.

=head3 folder_invite_link($id, %opt, $cb), folder_invite_links($id, $cb), edit_folder_invite_link($id, $link, %opt, $cb), delete_folder_invite_link($id, $link, $cb), check_folder_invite_link($link, $cb), add_folder_by_link($link, %opt, $cb)

A shareable folder is handed out as a link that adds its chats to
someone else's folder list. Creating and editing take C<name> and
C<chats>, the chats the link includes. TDLib replaces the whole link on
an edit, so an edit needs C<chats> every time: without them it fails
with "At least one chat must be included". The
last two take only the link, and C<add_folder_by_link> takes C<chats>
to choose which of the offered chats to actually join.

=head2 Payments mixin

The seller's half of Telegram payments: offering something and answering
the checkout. Actually paying for something is the buyer's half and is
not wrapped; reach it through L</call($function, \%args, $cb, %opt)>.

Amounts are integers in the currency's smallest unit, so 500 is five
euros in C<EUR>. The exception is C<XTR>, Telegram Stars, where one unit
is one Star, and where selling digital goods needs no payment provider
at all: leave C<provider_token> unset.

=head3 send_invoice($chat_id, \%invoice, %opt, $cb), invoice_link(\%invoice, %opt, $cb)

Sends an invoice as a message, or builds a shareable link to one. The
invoice hashref takes C<title>, C<description>, C<payload>, C<currency>
and C<prices> (all required), where each price is
C<< [ $label => $amount ] >> or C<< { label => ..., amount => ... } >>.
Optional: C<provider_token> and C<provider_data> for a real payment
provider, C<photo_url> and its dimensions, C<start_parameter>,
C<max_tip> and C<tips>, C<test>, and the C<need_name>, C<need_phone>,
C<need_email>, C<need_shipping> and C<flexible> flags. send_invoice also
takes the usual sending options, C<topic> and C<silent> included.

C<payload> is your own order identifier and comes back at checkout. It
is TL C<bytes>, so it is base64 encoded on the way out for you.

=head3 on_pre_checkout_query($cb), answer_pre_checkout_query($id, %opt, $cb)

The last gate before money moves. Telegram gives a bot only seconds to
answer, and an unanswered query fails the payment, so answer from the
handler. The handler receives C<id>, C<sender_user_id>, C<currency>,
C<total_amount>, C<payload>, C<shipping_option_id> and C<order_info>.
Answering with no C<error> approves; any C<error> string declines and is
shown to the buyer.

=head3 on_shipping_query($cb), answer_shipping_query($id, %opt, $cb)

Only fires for an invoice with a flexible price, C<< flexible => 1 >>,
which is how the shipping options -- and so the final price -- get to
depend on the address; C<need_shipping> alone collects an address and
asks nothing. The handler
receives C<id>, C<sender_user_id>, C<payload> and C<shipping_address>;
answer with C<options>, an arrayref of
C<< { id => ..., title => ..., prices => [...] } >>, or with an C<error>
to refuse delivery there.

The C<payload> in this handler is a plain string, while the one in
L</on_pre_checkout_query($cb), answer_pre_checkout_query($id, %opt, $cb)>
is TL C<bytes>. Both arrive already in their correct form; the
difference is TDLib's, and is noted here only because it looks like an
inconsistency worth double-checking rather than a bug.

=head2 Secret mixin

End-to-end encrypted chats. A secret chat is a separate object from the
chat that displays it: creating one yields a chat whose type is
chatTypeSecret, and the methods below take the B<secret chat id> found
in that type, not the chat id.

Secret chats live only in the local database. They are not on the
server, cannot be read from another device, and do not survive losing
the database.

=head3 new_secret_chat($user_id, $cb), open_secret_chat($secret_chat_id, $cb), secret_chat($secret_chat_id, $cb), close_secret_chat($secret_chat_id, $cb)

Start a secret chat with a user, reopen a known one, read its state, and
close it.

=head3 search_secret_messages($query, %opt, $cb)

Searches the local database, since secret messages exist nowhere else.
Options: C<chat_id> to scope to one chat, C<filter> (a
searchMessagesFilter name, with or without the prefix), C<offset>,
C<limit>.

=head3 set_database_encryption_key($key, $cb), session_accepts_secret_chats($session_id, $on, $cb)

Change the key the local database is encrypted with, and choose whether
a logged-in session may accept secret chats at all. Losing the key loses
every secret chat with it, as nothing on the server can restore them.

The key is TL C<bytes> and is base64-encoded on the way out, exactly as
the C<database_encryption_key> constructor option is -- 0.03 sent both
raw, so a database opened by 0.03 with a key that happened to look like
base64 is keyed with different bytes. See L</new(%opt)> for what to
pass in that case.

=head2 Stories mixin

Stories are int32 ids scoped to the chat that posted them, so every
method here takes a poster chat id alongside the story id. Note the
asymmetry with the rest of the API: a story id is B<not> an int64 and
stays a JSON number.

=head3 post_story($chat_id, $content, %opt, $cb)

Posts a story and, by default, waits for it to finish uploading.

TDLib answers immediately with a provisional story whose id changes once
the upload completes, so C<wait> works exactly as it does for
L</send_message($chat_id, $text, %opt, $cb)>: C<sent> (the default)
calls back with the final story from updateStoryPostSucceeded, and
C<accepted> calls back at once with the provisional one. Deleting by a
provisional id does not work, so prefer the default unless you have a
reason not to.

C<$content> is a path for a photo story. A video story needs the
explicit form, because TDLib requires a duration and a cover frame
timestamp and neither can be inferred from a file. A story video may
run no longer than 60 seconds:

    $td->post_story($chat, 'sunset.jpg', sub { ... });
    $td->post_story($chat,
        { video => 'clip.mp4', duration => 12, cover_frame_timestamp => 1.5 },
        sub { ... });

Options: C<privacy> ('everyone' by default, or 'contacts',
'close_friends', or an arrayref of user ids; TDLib ignores it for a
story posted as a supergroup or channel, which everyone in the chat
sees), C<except> (an arrayref of
user ids to exclude, for the first two), C<caption> with C<parse_mode>,
C<active_period> (86400 by default; other values are a Premium
feature), C<album_ids>, C<post_to_page>, C<protect_content>, C<areas>
and C<from_story>.

C<areas> and C<from_story> reach TDLib as they are given, so they take
the TL objects rather than anything friendlier. C<areas> is an
B<inputStoryAreas object wrapping the list>, not the list itself --
passing an arrayref is refused outright with "Expected Object, but
receive Array" -- and C<from_story>, which marks the story a repost, is
a storyFullId:

    areas => { '@type' => 'inputStoryAreas', areas => [
        { '@type'   => 'inputStoryArea',
          position  => { '@type' => 'storyAreaPosition', ... },
          type      => { '@type' => 'inputStoryAreaTypeLocation', ... } },
    ] },
    from_story => { '@type'         => 'storyFullId',
                    poster_chat_id  => $chat_id,
                    story_id        => $story_id },

edit_story takes C<areas> in the same form.

=head3 edit_story($chat_id, $story_id, %opt, $cb), edit_story_cover($chat_id, $story_id, $timestamp, $cb), delete_story($chat_id, $story_id, $cb)

Change a posted story's content, caption or areas; move a video story's
cover frame; remove one. edit_story takes C<content> in the same forms
post_story accepts, C<caption> with C<parse_mode>, and C<areas> as the
inputStoryAreas object described under
L<post_story()|/"post_story($chat_id, $content, %opt, $cb)">. Each is
sent only when given, so an edit changes what you name and leaves the
rest alone -- with one constraint of TDLib's: B<areas cannot be edited
unless the content changes too>, so pass C<content> alongside them.

=head3 story($chat_id, $story_id, %opt, $cb), active_stories($chat_id, $cb), archived_stories($chat_id, %opt, $cb), page_stories($chat_id, %opt, $cb)

Read one story, a chat's currently active stories, its archive, or the
stories it has pinned to its profile page. story takes
C<< only_local => 1 >> to answer from what TDLib already holds rather
than asking the server. archived_stories and page_stories page with
C<limit> and C<from_story_id>, the story to start from; 0 starts at the
most recent.

=head3 load_active_stories(%opt, $cb)

Asks TDLib to load a story list, named by C<list>: 'main' by default,
or 'archive'. The
callback receives a bare Ok and B<no stories>: they arrive through
updateChatActiveStories, so register L<on_story()|/"on_story($cb), on_story_deleted($cb), on_active_stories($cb)"> family handlers
to see them. Call it again for more; once the list is exhausted TDLib
answers 404, which is reported as success with an undef result, as
load_chats does.

=head3 story_interactions($story_id, %opt, $cb), chat_story_interactions($chat_id, $story_id, %opt, $cb)

Who viewed, forwarded or reacted. The first reads our own stories and
takes no chat id; the second is the variant for a chat's stories and
takes a C<reaction> option to filter by reaction type. Both page with
C<offset> and C<limit> and take C<< prefer_forwards => 1 >> to put
forwards and reposts first, then reactions, then other views;
story_interactions also takes C<query> to search names, usernames and
titles, C<only_contacts>, and C<prefer_with_reaction>, which puts
interactions carrying a reaction first and is B<ignored when
prefer_forwards is set>. Without either, the order is by date.

=head3 set_story_privacy($story_id, $privacy, %opt, $cb), post_story_to_page($chat_id, $story_id, $on, $cb), can_post_story($chat_id, $cb), chats_to_post_stories($cb)

Change who can see a story, pin it to the chat page, and ask in advance
whether posting is allowed at all. set_story_privacy takes the same
C<$privacy> forms as post_story, with C<except> an arrayref of user ids
to exclude from 'everyone' or 'contacts'.

=head3 open_story($chat_id, $story_id, $cb), close_story($chat_id, $story_id, $cb), report_story($chat_id, $story_id, %opt, $cb), story_public_forwards($chat_id, $story_id, %opt, $cb)

View bookkeeping, reporting, and public reposts of a story. Pair every
open_story with a close_story: while a story is open TDLib refetches it
every minute, and one of your own every ten seconds for its view count,
and only close_story stops that. report_story
takes C<option_id>, a reason id from a previous report_story reply, and
C<text> for the free-text form some reasons ask for.

=head3 story_reactions(%opt, $cb), set_story_reaction($chat_id, $story_id, $reaction, %opt, $cb)

The reactions available for stories, and reacting to one. C<$reaction>
takes the same forms as L</react($chat_id, $message_id, $reaction, %opt, $cb)>.
story_reactions takes C<row_size>, the keyboard width a client would
lay the reactions out in, 8 by default and silently 8 again for
anything outside 5 to 25. set_story_reaction takes
C<update_recent>, on by default.

=head3 story_albums($chat_id, $cb), create_story_album($chat_id, $name, \@story_ids, $cb), set_story_album_name($chat_id, $album_id, $name, $cb), delete_story_album($chat_id, $album_id, $cb)

Albums group posted stories on a profile.

=head3 story_album_stories($chat_id, $album_id, %opt, $cb), add_album_stories($chat_id, $album_id, \@ids, $cb), remove_album_stories($chat_id, $album_id, \@ids, $cb), reorder_album_stories($chat_id, $album_id, \@ids, $cb), reorder_story_albums($chat_id, \@album_ids, $cb)

Read and amend an album's contents, and order the albums themselves.

=head3 on_story($cb), on_story_deleted($cb), on_active_stories($cb)

Story updates. on_story receives a story object; on_story_deleted
receives C<($poster_chat_id, $story_id)>; on_active_stories receives a
chatActiveStories, which is how the results of load_active_stories
arrive.

=head2 Stickers mixin

Sticker set ids and custom emoji ids are int64 and cross the JSON
interface as strings, including inside a vector: a list of set ids is a
list of B<strings>.

=head3 sticker_set($set_id, $cb), search_sticker_set($name, %opt, $cb), search_sticker_sets($query, %opt, $cb)

Fetch a set by id, by its exact name, or search for sets by a query.
The middle one resolves a known name and takes
C<< ignore_cache => 1 >> to re-ask the server rather than answer from
what TDLib already holds; the last is the discovery call and takes
C<type>.

=head3 installed_sticker_sets(%opt, $cb), archived_sticker_sets(%opt, $cb), trending_sticker_sets(%opt, $cb), owned_sticker_sets(%opt, $cb)

The sets installed, archived, trending, or created by this account. The
first three take C<type>, one of 'regular' (the default), 'mask' or
'custom_emoji'; owned_sticker_sets does not, since TDLib returns every
type you own. All but installed_sticker_sets page with C<limit>, and
archived_sticker_sets and owned_sticker_sets page with
C<offset_sticker_set_id> while trending_sticker_sets uses a numeric
C<offset>.

=head3 stickers($query, %opt, $cb), search_stickers($emojis, %opt, $cb), custom_emoji_stickers(\@ids, $cb)

Find individual stickers, by query or by the emoji they represent, and
resolve custom emoji ids to their stickers. Both searches take C<type>,
one of 'regular' (the default), 'mask' or 'custom_emoji'. stickers also
takes C<chat_id>, which changes nothing unless C<type> is
'custom_emoji': it admits premium custom emoji when the chat is your
own Saved Messages, and returns none for an old secret chat;
search_stickers takes C<languages>, an arrayref of language codes for
the emoji-to-sticker mapping, and C<query> to narrow the emoji match
further.

=head3 favorite_stickers($cb), add_favorite_sticker($sticker, $cb), remove_favorite_sticker($sticker, $cb), recent_stickers(%opt, $cb), add_recent_sticker($sticker, %opt, $cb), remove_recent_sticker($sticker, %opt, $cb), clear_recent_stickers(%opt, $cb)

Favourites and recents. Each takes an InputFile, so a path works, and
the recents calls take C<attached> to address the attached-sticker list
instead.

=head3 upload_sticker_file($user_id, $sticker, %opt, $cb)

Uploads one file for later use in a set. A set is built from uploaded
files rather than local paths, so this comes first; C<format> is
'webp' (the default), 'tgs' or 'webm'. See the cookbook for the full
upload-then-create sequence.

=head3 create_sticker_set($user_id, $title, $name, \@stickers, %opt, $cb)

Creates a set. Each element of C<@stickers> is a hashref:

    { file => $uploaded_or_path, emojis => '...', keywords => [...],
      format => 'webp', mask_position => {...} }

C<file> and C<emojis> are required. C<%opt> takes C<type>
('regular', 'mask' or 'custom_emoji'), C<needs_repainting> and
C<source>. C<$name> must be globally unique and, for a bot-owned set,
must end in C<_by_E<lt>bot usernameE<gt>>; check it first with
L<check_sticker_set_name()|/"set_sticker_set_title($name, $title, $cb), set_sticker_set_thumbnail($user_id, $name, $thumbnail, %opt, $cb), delete_sticker_set($name, $cb), install_sticker_set($set_id, $installed, %opt, $cb), reorder_sticker_sets(\@set_ids, %opt, $cb), check_sticker_set_name($name, $cb)">.

=head3 add_sticker_to_set($user_id, $name, $sticker, $cb), replace_sticker_in_set($user_id, $name, $old, $new, $cb), remove_sticker_from_set($sticker, $cb), set_sticker_position($sticker, $position, $cb)

Amend a set. C<$sticker> and C<$new> take the same hashref as
create_sticker_set; C<$old> is a plain InputFile.

=head3 set_sticker_set_title($name, $title, $cb), set_sticker_set_thumbnail($user_id, $name, $thumbnail, %opt, $cb), delete_sticker_set($name, $cb), install_sticker_set($set_id, $installed, %opt, $cb), reorder_sticker_sets(\@set_ids, %opt, $cb), check_sticker_set_name($name, $cb)

Set housekeeping. install_sticker_set installs by default and
uninstalls when passed a false second argument; C<archived> archives
instead. delete_sticker_set removes a set you own completely.
set_sticker_set_thumbnail takes C<format> ('webp' by default, or 'tgs'
or 'webm'), which must match the thumbnail file. reorder_sticker_sets
takes C<type>, since each sticker type has its own order.

=head3 set_emoji_status($custom_emoji_id, %opt, $cb), default_emoji_statuses($cb)

Set the account's emoji status, or clear it by passing undef.
C<expires> is the Unix time it ends; one already past clears the status
instead, without an error. Premium accounts only.

=head2 Stars mixin

Telegram Stars: gifts, subscriptions, revenue and affiliate programs.
The seller-side invoice and checkout flow is in the
L</Payments mixin> instead.

Gift ids are int64 and cross as strings; a received gift id is a TL
string already and is passed through unchanged.

=head3 available_gifts($cb), can_send_gift($gift_id, $cb), send_gift($gift_id, $owner, %opt, $cb)

The gifts on offer, whether one can be sent, and sending it. C<$owner>
is a bare user id or a negative chat id, coerced to the right message
sender. Options: C<text> with C<parse_mode>, C<private> and
C<pay_for_upgrade>.

=head3 received_gifts($owner, %opt, $cb), received_gift($received_gift_id, $cb)

Gifts an account has received. C<$owner> is required. Paging is
C<offset> (a string cursor) and C<limit>; C<sort_by_price> orders the
list and C<collection_id> narrows it to one collection. The filters are
C<exclude_saved>, C<exclude_unsaved>, C<exclude_unlimited>,
C<exclude_upgradable>, C<exclude_non_upgradable>, C<exclude_upgraded>,
C<exclude_without_colors> and C<exclude_hosted>.

=head3 toggle_gift_saved($id, $saved, $cb), sell_gift($id, %opt, $cb), upgrade_gift($id, %opt, $cb), transfer_gift($id, $new_owner, %opt, $cb), gift_upgrade_preview($gift_id, $cb)

Display a received gift on the profile, convert it to Stars, upgrade it
to a unique gift, or hand it to someone else. The preview shows what an
upgrade would produce before paying for one. upgrade_gift takes
C<< keep_original_details => 1 >> to keep the original gift's text,
sender and receiver on the upgraded one, and C<star_count>, the Stars
the upgrade costs: pass the gift's own C<upgrade_star_count>, or 0 when
it already carries a C<prepaid_upgrade_star_count>. It defaults to 0,
which is the wrong value for a gift that was not prepaid.
transfer_gift takes C<star_count> the same way, for a transfer the
receiving side charges for, and defaults it to 0 with the same trap.

=head3 set_gift_settings(%opt, $cb)

Which gifts this account accepts: C<show_button>, C<unlimited>,
C<limited>, C<upgraded>, C<from_channels> and
C<premium_subscription>. Every flag is sent, so one left out is turned
off -- pass the whole set, as with set_permissions. An unknown name
croaks.

=head3 star_transactions(%opt, $cb), star_subscriptions(%opt, $cb), edit_star_subscription($id, $canceled, $cb), reuse_star_subscription($id, $cb), star_payment_options($cb)

The Star ledger and recurring Star subscriptions. star_transactions
takes C<owner> (this account by default), C<direction> ('incoming' or
'outgoing'), C<subscription_id>, C<offset> and C<limit>.
star_subscriptions pages with C<offset> and takes
C<< only_expiring => 1 >>, which is narrower than it sounds: it returns
only subscriptions there are not enough Stars to extend.

=head3 refund_star_payment($user_id, $charge_id, $cb)

Refunds a Star payment. The charge id comes from the successful payment
message.

=head3 star_revenue_statistics(%opt, $cb), chat_revenue_statistics($chat_id, %opt, $cb), chat_revenue_transactions($chat_id, %opt, $cb)

Earnings for an account or a channel. C<dark> selects graph colours.
star_revenue_statistics takes C<owner>, a user or chat id to read
instead of this account.

=head3 star_withdrawal_url($owner, $star_count, $password, $cb), chat_revenue_withdrawal_url($chat_id, $password, $cb)

Begin a withdrawal. Both require the account's two-factor password as a
required argument, not an option, because omitting it would otherwise
read as a request that merely failed.

=head3 connected_affiliate_programs(%opt, $cb), connect_affiliate_program($bot_user_id, %opt, $cb), disconnect_affiliate_program($url, %opt, $cb)

Affiliate programs. C<affiliate> selects who is affiliating: this
account by default, or C<< { bot => $id } >> or
C<< { channel => $chat_id } >>.

=head2 Business mixin

Telegram Business: connections to a business account, quick replies,
away and greeting messages, and acting on a connected account as a bot.

B<This plane is unverified against a live server> and is covered by
offline tests only; see L</LIMITATIONS> for which methods need a
Business subscription and which do not.

A C<business_connection_id> is a string, not a number, and arrives only
through L<on_business_connection()|/"on_business_connection($cb), on_business_message($cb)">. There is no other source for
it, so a bot must keep the handler registered to send anything at all.

=head3 on_business_connection($cb), on_business_message($cb)

Connection changes, and messages arriving in a connected business
account. on_business_message receives
C<< { connection_id => ..., message => ... } >>, where C<message> is a
businessMessage: the message itself is C<< $ev->{message}{message} >>,
and C<< $ev->{message}{reply_to_message} >> is the one it answers. Edited and deleted
business messages reach L</on_update($cb), on_error($cb)> rather than
having hooks of their own.

=head3 business_connection($connection_id, $cb), connected_bot($cb), set_connected_bot($bot_user_id, %opt, $cb), confirm_connected_bot($bot_user_id, $cb), delete_connected_bot($bot_user_id, $cb)

Inspect a connection, and manage the bot connected to this business
account. set_connected_bot takes C<rights> and C<recipients>, each a
hashref of flags; an unknown flag name croaks rather than being
ignored. Both are sent whole, so leaving C<rights> out connects a bot
that may do nothing, and leaving C<recipients> out selects no chats.

=head3 pause_connected_bot($chat_id, $paused, $cb), remove_connected_bot_from_chat($chat_id, $cb)

Suspend the connected bot in one chat, or detach it from that chat.

=head3 send_business_message($connection_id, $chat_id, $text, %opt, $cb), send_business_file($connection_id, $chat_id, $path, %opt, $cb)

Send as the connected business account. Options: C<parse_mode>,
C<disable_preview>, C<silent>, C<protect_content>, C<effect_id>,
C<reply_to> and C<reply_markup>, plus C<kind> and C<caption> for the
file form.

Unlike L</send_message($chat_id, $text, %opt, $cb)> these take no
C<schedule>, no C<wait> and no C<topic>: TDLib gives
sendBusinessMessage flat notification and protection fields rather than
a message-send options object, and does not promise a delivery update.

=head3 edit_business_message_text($connection_id, $chat_id, $message_id, $text, %opt, $cb), read_business_message($connection_id, $chat_id, $message_id, $cb), delete_business_messages($connection_id, \@message_ids, $cb)

Edit, mark read, and delete messages in a connected account.

=head3 set_business_account_name($id, $first, $last, $cb), set_business_account_bio($id, $bio, $cb), set_business_account_username($id, $username, $cb), set_business_account_photo($id, $photo, %opt, $cb), business_account_star_amount($id, $cb)

Change the connected account's profile, and read its Star balance.
set_business_account_photo takes C<< public => 1 >> to set the public
photo, the fallback for users whom privacy settings deny the main one,
rather than the main photo itself.

=head3 set_away_message($shortcut_id, %opt, $cb), set_greeting_message($shortcut_id, %opt, $cb)

Automatic replies, each pointing at a quick-reply shortcut.
set_away_message takes C<schedule>: 'always' (the default),
'outside_opening_hours', or C<< { start => $ts, end => $ts } >>, plus
C<offline_only>. set_greeting_message takes C<inactivity_days>, which
must be 7, 14, 21 or 28 and croaks otherwise: TDLib turns the greeting
off for any other value and reports success. Both take C<recipients>,
and select no chat at all without it, so the replies go to nobody until
you say which chats they cover. C<$shortcut_id> must name a shortcut
the server already has; one still being created counts as none, which
turns the reply off the same silent way.

=head3 set_opening_hours($time_zone_id, \@intervals, $cb), set_business_location($address, %opt, $cb), set_start_page(%opt, $cb), business_features(%opt, $cb)

Opening hours are minutes from the start of the week, each interval
either C<[$start, $end]> or C<< { start => .., end => .. } >>. An
interval must start before it ends and end within eight days, so one
running past the end of the week continues past 10080 rather than
wrapping back to the start. TDLib drops an invalid interval without an
error, and removes the opening hours altogether when none is left.
set_business_location takes C<latitude>, C<longitude> and C<accuracy>
in metres, the first two together or not at all; set_start_page takes C<title>, C<message> and C<sticker>.
The sticker must already be on Telegram's servers, as one taken from a
message is: a local path is dropped without an error, and with no title
or message either the start page is removed.
business_features takes C<source>, the feature whose promotion screen
prompted the call, as a BusinessFeature name with or without its
prefix (C<Location> or C<businessFeatureLocation>).

=head3 business_chat_links($cb), create_business_chat_link($text, %opt, $cb), edit_business_chat_link($link, $text, %opt, $cb), delete_business_chat_link($link, $cb), business_chat_link_info($link_name, $cb)

Links that open a chat with a prefilled message. The text is formatted
text, so C<parse_mode> applies; C<title> names the link.

=head3 load_quick_replies($cb), load_quick_reply_messages($shortcut_id, $cb)

Ask TDLib to load quick-reply shortcuts or one shortcut's messages.
Both call back with a bare Ok: the data arrives through updates, so
watch L</on_update($cb), on_error($cb)> for updateQuickReplyShortcut
and updateQuickReplyShortcuts, and for a shortcut's own messages
updateQuickReplyShortcutMessages.

=head3 add_quick_reply_message($shortcut_name, $text, %opt, $cb), edit_quick_reply_message($shortcut_id, $message_id, $text, %opt, $cb), delete_quick_reply($shortcut_id, $cb), delete_quick_reply_messages($shortcut_id, \@ids, $cb)

Build and amend quick replies. Adding takes a shortcut B<name> and
creates the shortcut if it does not exist; the rest take its id.
add_quick_reply_message takes C<reply_to>, the id of an earlier message
in the same shortcut to reply to.

=head3 set_quick_reply_name($shortcut_id, $name, $cb), reorder_quick_replies(\@ids, $cb), send_quick_reply($chat_id, $shortcut_id, %opt, $cb), check_quick_reply_name($name)

Rename, order and send a shortcut. send_quick_reply takes
C<sending_id>, a non-persistent id of your own choosing that comes back
in the messages' messageSendingStatePending, which is how you match
them to the updateNewMessage updates that follow. It calls back once
Telegram accepts the messages, and refuses C<< wait => 'sent' >>.
check_quick_reply_name is synchronous: it returns the result, and
croaks if given a callback.

=head1 MINI APPS

A Mini App (Telegram also calls it a Web App) is a web page a bot
offers, opened inside a Telegram client. TDLib does not render it. It
resolves the app, returns a URL and a launch id, and relays the data
the page sends back; hosting a webview and loading the URL is the
application's job. Nothing here needs a browser if all you want is the
data channel.

The usual flow is:

    $td->web_app($bot_id, 'probe', sub {
        my ($found, $err) = @_;
        ...
    });
    $td->open_web_app($chat_id, $bot_id, $button_url, sub {
        my ($info, $err) = @_;
        # hand $info->{url} to a webview, keep $info->{launch_id}
    });
    $td->close_web_app($launch_id, sub { });

Data flows back either through
L</send_web_app_data($bot_user_id, $button_text, $data, $cb)>, which a
client calls on the page's behalf and the bot receives through
L</on_web_app_data($cb)>, or through
L<answer_web_app_query()|/"answer_web_app_query($query_id, \%result, $cb), web_app_request($bot_user_id, $method, $parameters, $cb), web_app_placeholder($bot_user_id, $cb)"> for the inline
variant.

=head2 The platform identifier

C<application_name> is not a free-form label. It is sent to Telegram as
the platform string and handed to the page as C<tgWebAppPlatform>.
Telegram accepts 0-64 characters from C<A-Za-z0-9_> and rejects
anything else with C<PLATFORM_INVALID>, an error that names nothing
near the real cause; a hyphen is the easy way to trip it. This module
validates the value when the client is constructed, so the failure
arrives with an explanation instead.

Any accepted value works, but the value still matters. Real clients
send a conventional identifier (C<android>, C<ios>, C<macos>,
C<tdesktop>, C<weba>, C<webk>) and Mini App pages branch on it to pick
layout, theming and available features. An invented name passes
validation and then lands in whatever an app does with an unrecognised
platform. The default is C<tdesktop>.

=head2 Launch URLs carry credentials

The URL returned by open_web_app and the web_app_*_url methods has the
signed init data in its fragment: the user's name, username, photo URL
and an authentication hash. It is a credential. Do not log it, paste it
into a bug report, or store it anywhere the page itself would not go.

=head1 AUTHORIZATION

TDLib drives authorization as a state machine reported through
updateAuthorizationState; L</auth_state()> exposes the current state.
With auto_auth on (the default), each state is answered automatically
or routed to a credential callback:

=over 4

=item authorizationStateWaitTdlibParameters

setTdlibParameters is sent automatically from the constructor options.
No callback. An error reply (bad api credentials, an unwritable
database_directory) fails login: the values come from the constructor,
so there is no interactive channel to retry through.

=item authorizationStateWaitPhoneNumber

bot_token is sent when given; otherwise requestQrCodeAuthentication
when on_qr is set and no phone_number was given; otherwise the
phone_number is sent. No callback in any branch. An error reply
(an invalid phone number or bot token) fails login, for the same
reason as above.

=item authorizationStateWaitCode

C<on_code> receives C<($info, $submit)>: $info is the decoded
authenticationCodeInfo, $submit is a code ref that sends the code.
The split exists so the code can come from anywhere (a prompt, a GUI,
a queue) without blocking the loop. A missing callback fails login.

A rejected submission does not fail login: TDLib stays in the state
after an error reply (a mistyped code, an expired one), so the
handler is called again as C<($info, $submit, $err)> with the decoded
error as the third argument, and may submit a corrected value. To
give up instead, close the client.

=item authorizationStateWaitPassword

C<on_password> receives C<($info, $submit)>; $info carries the
password_hint. A missing callback fails login. A rejected password
re-asks with the error as a third argument, as above.

=item authorizationStateWaitEmailAddress, authorizationStateWaitEmailCode

C<on_email> and C<on_email_code>, same C<($info, $submit)> shape and
the same retry-on-error behaviour.

=item authorizationStateWaitOtherDeviceConfirmation

C<on_qr> receives C<($link)> only. The signature is deliberately
asymmetric: QR confirmation has nothing to submit, the other device
confirms the login, so there is no $submit callback.

=item authorizationStateWaitRegistration

Answered automatically from the register option; without it login
fails. An error reply from registerUser fails login: like the other
automatic steps, it has no interactive channel.

=item authorizationStateWaitPremiumPurchase

Cannot be satisfied programmatically; login fails with an error.

=item authorizationStateReady

The login() callback succeeds.

=item authorizationStateClosed

Pending requests, in-flight sends and downloads are failed, close()
callbacks run, then on_close fires.

=back

A login failure that arrives when no login() is pending is reported
to the on_error handler instead (or warn, when none is set), and
recorded: a login() called after the failure fails deferred with the
same error rather than waiting for a state that never comes.

=head1 UPDATES

Anything arriving without a pending C<@extra> is an update -- with one
exception: a reply whose C<@extra> matches no pending and no recently
timed-out request is a stray, dropped with a warning rather than
dispatched as an update. Dispatch
order: the authorization state machine, then the per-type handlers
that maintain the user and chat caches, track the connection state
and drive downloads, upload watchers and in-flight sends, then the
generic on_update handler.

A live client emits updateOption traffic (and other service updates)
that reaches on_update as soon as a loop runs, before any request is
made. Handlers must tolerate updates they do not recognize.

The chat cache is maintained against a fixed table of chat-field
updates: twenty-one of the forty-one chat-field updates TDLib 1.8.66
sends, covering what a client normally reads -- including the chat's
C<positions> in each list and C<chat_lists>, the lists it belongs to. The rest -- among them
updateChatUnreadReactionCount, updateChatEmojiStatus,
updateChatHasProtectedContent, updateChatVideoChat and the accent
colours -- reach on_update but are B<not> merged. A field outside the
table therefore keeps whatever value it had when the chat entered the
cache, for as long as the client runs, and no amount of waiting
refreshes it: call
L<fetch_chat()|/"fetch_chat($chat_id, $cb), close_chat($chat_id, $cb), user_full_info($user_id, $cb), supergroup($id, %opt, $cb), basic_group($id, %opt, $cb), supergroup_members($id, %opt, $cb), groups_in_common($user_id, %opt, $cb)">
to re-read one from TDLib, or watch the update yourself.

The table targets the pinned TDLib 1.8.66, commit
022d60202e446ad1287b9fb68e687c8a0760788b. A newer TDLib that renames
these updates would leave the cache stale; the unknown updates would
fall through to on_update only.

Payload fields the schema marks nullable (last_message, draft_message,
photo, action_bar, theme, block_list, pending_join_requests) are
assigned even when the update omits them: TDLib drops null object
fields from its JSON entirely, so an absent key means the value was
cleared, not that it stayed unchanged.

Neither cache is evicted: they hold every chat and user the client has
been told about, for as long as the client lives, and a chat record is
whatever TDLib sent. That is what makes L</chat($id)> and L</user($id)>
answer without a round trip, but it means a long-lived client in many
chats keeps them all resident. Nothing else accumulates: updates about
chats already cached, and file updates for ids nothing is watching, do
not grow anything.

=head1 ESCAPE HATCH

The convenience methods cover under half the API. send() and execute()
take any raw TDLib request hashref, so the roughly 600 unwrapped TDLib
methods remain fully usable:

    $td->send({ '@type' => 'getCountries' }, sub {
        my ($res, $err) = @_;
        ...
    });

Do not set C<@extra> yourself; see L</send(\%request, $cb, %opt)>.

For offline tests, inject_raw($json) feeds a JSON string through the
normal dispatch path. It is an internal test hook, not part of the
supported API.

Injecting an authorizationStateClosed makes the module forget the
client. That is only safe while nothing has been sent to it: tdjson
creates a client on its first request, so an id that never carried one
has nothing behind it. Inject it after real traffic and the module
stops tracking a client TDLib still holds.

=head1 UNICODE

Work in character strings. Text you pass in is encoded for you, and
text you get back is decoded for you; the conversion happens at the XS
boundary, where TDLib's JSON is read and written as UTF-8 octets.

    $td->send_message($chat_id, "\x{41F}\x{440}\x{438}\x{432}\x{435}\x{442}", sub { });

    $td->on_message(sub {
        my ($msg) = @_;
        my $text = $msg->{content}{text}{text};
        # a character string: length is in characters, not bytes
        printf "%d characters\n", length $text;
    });

Do not encode it yourself. Passing bytes you have already run through
C<Encode::encode> sends those bytes as though each one were a
character, and Telegram stores the result:

    use Encode ();
    my $text = "\x{410}\x{411}";               # two characters

    $td->send_message($chat_id, $text, sub { });
    # on the wire: d0 90 d0 91   -- correct

    $td->send_message($chat_id, Encode::encode('UTF-8', $text), sub { });
    # on the wire: c3 90 c2 90 c3 90 c2 91   -- mojibake, and no error

Nothing warns about this. Both calls succeed, and the damage is only
visible in the message itself, so it is worth being deliberate about
where text enters your program: decode once at the edge, and pass
characters from there on.

B<File paths are strings too, and are where this bites hardest.>
C<readdir>, C<glob>, C<@ARGV> and C<%ENV> hand you octets, not
characters, so a path with a non-ASCII name in it goes out
double-encoded and names a file that does not exist -- TDLib then fails
with an error about the wrong filename. Decode a path before passing it
to L<upload($path)|/"upload($path)">, send_file, or as
C<database_directory> or C<files_directory>:

    use Encode ();
    my $path = Encode::decode('UTF-8', $bytes_from_readdir);

Paths coming back from TDLib are already characters and need nothing.

Formatting entities are counted differently again: TDLib gives
C<offset> and C<length> in UTF-16 code units, not characters. Use
L</entity_text($formatted_text, $entity), entity_texts($formatted_text)>
rather than C<substr>, which is right only while the text stays inside
the BMP.

The same applies to every string the module sends -- captions, chat
titles, bot descriptions, poll questions and options, keyboard labels,
inline query results, search queries -- and to the C<@extra>
correlation ids, which are generated internally and never contain
anything but digits.

A few fields are the exception, because TDLib declares them as
B<bytes> rather than text: callback button data, the data given to
L</press($chat_id, $message_id, $data, $cb)>, an invoice payload, and
the two database encryption keys. The module base64-encodes them for
you, so pass the value you mean -- a C<database_encryption_key> of
C<hunter2> is stored as exactly those seven octets. A character above 255
is rejected rather than guessed at, since there is no encoding the
module can pick on your behalf:

    data => Encode::encode('UTF-8', $label)

Printing text you received to a filehandle with no encoding layer
raises "Wide character in print". Set the layer once:

    binmode STDOUT, ':encoding(UTF-8)';

Reading a code or password from STDIN in an interactive login is the
mirror image: C<binmode STDIN, ':encoding(UTF-8)'> if it may contain
anything but ASCII, so that what you submit is characters.

=head1 ERROR HANDLING

A TDLib error is never thrown: invalid arguments croak at the call
site, but anything the server rejects arrives through the callback.
Every asynchronous callback follows the
contract C<< $cb->($result, $err) >>: C<$err> is undef on success and
a hashref on failure, and C<$result> is undef whenever C<$err> is
set. Test C<$err>, not C<$result>.

L</history($chat_id, %opt, $cb)> is the one exception, and it is
deliberate: paging can fail partway, so a failure after some pages
have arrived hands you both the messages collected so far and the
error that stopped it.

A TDLib error arrives as the decoded object:

    { '@type' => 'error', code => 400, message => 'PHONE_NUMBER_INVALID' }

Synthetic errors generated by the module itself use the same shape
with code -1:

=over 4

=item *

C<timeout> -- a L<send()|/"send(\%request, $cb, %opt)"> request whose
C<timeout> option expired. The late reply, if it ever arrives, is
dropped with a warning; it is never delivered to a reused C<@extra>.

=item *

C<client closed> -- delivered to every in-flight request, pending
send and active download when the client closes; a pending login()
fails with C<client closed during login>.

=item *

C<client is closed> -- a L<send()|/"send(\%request, $cb, %opt)">
attempted after the client closed; nothing is sent and the callback
fails deferred.

=item *

C<download canceled> -- delivered by L</cancel_download($file_id)>.

=item *

C<download failed> -- a L</download($file_id, %opt, $cb)> that failed
after starting; TDLib reports a permanent download failure only
through updateFile, never as a request reply.

=item *

C<download of file N already in progress> -- a second download() of a
file whose first one has not finished.

=item *

C<message deleted before it was sent> -- a send waiting for delivery
whose message TDLib deleted first. C<message send failed> and
C<story post failed> stand in for the error object on the rare failure
update that carries none.

=item *

C<ask timed out>, C<ask cancelled> and C<ask superseded> -- the module's
own reasons an L<ask()|/"ask($chat_id, $user_id, $prompt, %opt, $cb), cancel_ask($chat_id, $user_id)">
ends without an answer. A prompt that TDLib refuses fails the ask with
TDLib's own error, and a close fails it with C<client closed>.

=item *

C<@name is not a user> -- L<user_by_username()|/"user_by_username($name, $cb)">
resolved the name to a chat that is not a user; C<nothing to mark read
in chat N> -- L<mark_read()|/"mark_read($chat_id, %opt, $cb)"> with no
message ids and no cached last message.

=item *

A failed login. The module's own failures -- C<client is already
closed>, a credential callback that was not given, a state no option
can satisfy -- use code -1. A step TDLib refused keeps TDLib's code
behind a message that names the step, so
L<retry_after()|/"retry_after($err)"> reads a login flood wait.

=back

=head2 Rate limiting: error code 429

Telegram answers too-frequent requests with error code 429 and a
message of the form C<Too Many Requests: retry after N>, where N is
the number of seconds to wait. In this TDLib the generic error type
carries only C<code> and C<message>, so the delay exists only in the
message text and must be parsed from it. Do not retry immediately,
and never retry in a tight loop: that is the pattern that gets an
account limited. Back off for at least the stated delay, with a
timer rather than a blocking sleep. TDLib performs its own internal
rate limiting for many operations -- it queues and paces requests on
its own -- so a 429 that reaches you is a hard signal, not routine
operation.

The module never retries unless you ask it to: a retry policy imposed
by a binding hides the signal and can make limiting worse. Without the
C<retry> option nothing has changed, and the back-off policy is yours
to write; see L<EV::Telegram::TDLib::Cookbook/"Handling rate limits">.

Passing C<retry> to L</send(\%request, $cb, %opt)> or
L</call($function, \%args, $cb, %opt)>, or to the constructor as a
default, opts in to a capped back-off. It waits at least the delay the
server stated, lengthens on repeated 429s, gives up rather than
retrying a delay longer than C<max_wait>, and stops after C<attempts>.
It fires only for a 429 that states a delay.

B<It does not cover message sends.> A flood wait on a send is not a 429
reply at all, as the next paragraph explains, so no reply-level retry
can see it.

A failed message send surfaces through updateMessageSendFailed. The
L</send_message($chat_id, $text, %opt, $cb)> callback receives that
update's error, a 429 whose message states the delay, so
L</retry_after($err)> reads it there. The update's message also carries
a messageSendingStateFailed with a numeric C<retry_after> field in
seconds, next to C<can_retry>; watch updateMessageSendFailed via
L</on_update($cb), on_error($cb)> when you need the structured field.

=head2 Internal failures

Internal failures that own no request -- a TDLib frame that fails JSON
decoding, a user callback that dies -- are reported to the C<on_error>
handler, or to warn when none is set. A dying callback is contained by
the dispatch (wrapped in G_EVAL): it is reported, and the remaining
updates in the same batch still run; the drain does not abort. The
close chain is contained per callback as well: one dying callback
during close cannot skip the remaining pending failures, the close()
callbacks or on_close.

One update can reach more than one of your callbacks: a new message
goes to a command handler, then on_message, then on_web_app_data if it
carries Mini App data. How far a die travels depends on which callback
it is. The module guards each one it dispatches itself -- command
handlers, ask answers, callback data routes, on_callback_query,
on_inline_query and the file watchers -- so a die there is reported and
the rest of the update still runs; you cannot use it to stop
on_message from seeing the message too. A die in one of the plain
handlers (on_message, on_user, on_chat and the rest) skips what is left
of B<that> update, on_update included. Either way the next update is
unaffected. The two read differently in the report: C<a callback died>
for a guarded one, C<dispatch died> for the rest.

The practical consequence is that B<die is not how a callback ends the
program>. It is reported and the loop keeps running, so a script whose
only exit path was the die simply hangs. Leave the loop instead, and
let the exit status carry the failure:

    $td->login(sub {
        my (undef, $err) = @_;
        if ($err) {
            warn "login failed: $err->{message}\n";
            $status = 1;
            return EV::break;
        }
        ...
    });

    EV::run;
    exit $status;

The containment covers every asynchronous delivery, not only the ones
that arrive through the dispatch. A callback answered from a timer --
a L<send()|/"send(\%request, $cb, %opt)"> timeout, an ask timing out, a
deferred failure on a closed client -- is guarded the same way, so a
die there reaches C<on_error> rather than only EV's own stderr.

Some errors are delivered synchronously, before the method returns:
a parse_mode failure in
L</send_message($chat_id, $text, %opt, $cb)> or
L</edit_message($chat_id, $message_id, $text, %opt, $cb)>, and equally
in send_file, send_poll and answer_inline_query, invokes the callback
with the parseTextEntities error before the method returns, and
nothing is sent. A download already in progress and a mark_read with
nothing to mark report the same way.

=head1 ENVIRONMENT

=over 4

=item EV_TDLIB_SHUTDOWN_TIMEOUT

Seconds the END block waits for open clients to finish closing before
giving up, default 3. Giving up tears TDLib's statics down while it is
still closing, which can abort the process at exit -- TDLib detaches
its scheduler thread rather than joining it once exit has begun, so
the crash is a race and will not show on every run. Raise this on a
heavily loaded machine or under a sanitizer, where everything runs
several times slower.

=item TDLIB_LOG_VERBOSITY

TDLib's log verbosity level, applied once when the module is loaded.
Defaults to 1; TDLib's own default of 5 is very noisy on stderr.

=item TD_API_ID, TD_API_HASH, TD_PHONE, TD_BOT_TOKEN, TD_DATABASE_DIRECTORY

Not the module's API: the credential convention shared by the scripts
in F<eg/> and by F<xt/live_auth.t>. The module itself takes
credentials only as constructor options; see L</new(%opt)>.

=back

=head1 EXAMPLES

Runnable scripts live in F<eg/>. Once the module is installed, run one
from anywhere with C<perl eg/NAME.pl>; from an unpacked distribution
C<perl -Mblib eg/NAME.pl> works after C<make>, and not before it, since
there is no F<blib> until then. Credentials come from the environment,
see L</ENVIRONMENT>:

=over 4

=item F<eg/01-login.pl>

user login with phone, SMS code and 2FA; creates the session database

=item F<eg/02-bot-echo.pl>

bot login via token; echoes incoming text messages

=item F<eg/03-list-chats.pl>

loads the chat list and prints id and title per chat

=item F<eg/04-send-message.pl>

sends a markdown message and waits for real delivery

=item F<eg/05-download-file.pl>

downloads a file id with progress percentage

=item F<eg/06-raw-method.pl>

raw send()/execute() for methods the mixins do not wrap

=item F<eg/07-gtk4-chat.pl>

a two-pane GTK4 chat window driven by EV rather than by gtk_main

=item F<eg/08-tickit-chat.pl>

the same two panes in a terminal, on the same single loop

=item F<eg/09-mcp-server.pl>

exposes Telegram as MCP tools over JSON-RPC on stdio

=item F<eg/10-webapp-bot.pl>

offers a Mini App button and prints the data the page sends back

=item F<eg/11-command-bot.pl>

command routing, inline button routing and ask()

=back

L<EV::Telegram::TDLib::Cookbook> has task-oriented recipes.

=head1 CAVEATS

=over 4

=item *

Not fork-safe. TDLib itself is not fork-safe, so every method that
reaches it croaks after fork: new, send, call, close, execute and every
convenience method built on them. What does B<not> croak is everything
answered from this process's own memory -- L</chat($id)>, L</user($id)>,
L<option()|/"option($name), my_id()"> and the C<on_*> accessors -- so a forked
child can read a plausible-looking cache and only fails when it tries
to do something with it. Do not fork with an open client. Forking
before this process has ever made one is allowed, and is how a
preforking worker pool should be built: the child inherits a pump that
was never used.

=item *

One reader thread per process, shared by all clients. It starts with
the first client and runs until the process ends: closing every
client releases the loop reference, so EV::run can return, but the
reader itself is only joined by the END-block shutdown.

=item *

The default EV loop only. Requests are delivered on EV_DEFAULT; a
non-default loop cannot receive them. Destroying the default loop
(L<EV/default_destroy>) while a client is open is out of contract: the
reader thread would keep signalling the freed loop through
ev_async_send. Close every client first.

=item *

Re-entering the loop from inside a callback reorders deliveries. TDLib
orders its updates, and this module preserves that order only as long
as the loop is not re-entered: the drain takes a whole batch from the
reader, then calls your callbacks one by one, so a nested C<EV::run>
inside one of them -- the "wait for just this reply" helper a GUI or an
embedded host tends to write -- drains and delivers whatever has
arrived since, ahead of the rest of the batch it interrupted. Nothing
is lost or delivered twice, and internal state stays consistent; only
the order you observe changes. If order matters, return from the
callback and let the loop come back to you.

=item *

Not safe with Perl ithreads. The pump initialises once per process, and
nothing stops a thread created after this module is loaded: perl clones
the interpreter without re-running XS bootstrap, so both interpreters
silently share one pump and the dispatch callback the parent owns. The
"cannot serve a second interpreter" guard only fires when a second
interpreter loads the module itself, which is the rarer case. Do not
create threads in a process that has loaded this module; fork instead,
subject to the fork rules above.

Pinned assumption: TDLib's receive/execute buffer is thread-local. The
no-lock design -- the reader thread copies every td_receive result
before anything else runs, and execute() needs no lock against it --
rests on the C<current_output> buffer in TDLib's ClientJson.cpp being
C<TD_THREAD_LOCAL>. That is an implementation detail, not a public
guarantee: the header only promises the pointer stays valid until the
next call. Verified against the bundled TDLib 1.8.66, commit
022d60202e446ad1287b9fb68e687c8a0760788b; re-verify whenever the pin
moves, because a process-global buffer would make concurrent execute()
a use-after-free race.

=item *

Not designed for subclassing. Hold a client in your own object instead:
the class is assembled from mixins, keeps its state in the object hash,
and calls many of its own methods internally, so a subclass method of
the same name replaces part of the machinery. The methods documented
here are the interface; anything else is internal and may change.

=item *

Clients stay registered until closed. The registry holds a strong
reference on purpose: TDLib requires every client to be closed before
process exit, so an object must not vanish when the caller drops its
last reference. L</close($cb)> is not optional; dropping your last
Perl reference does not close anything. See L</AUTHORIZATION> for the
Closed state that ends the lifecycle.

=item *

An END block closes leftover clients and pumps the loop for a bounded
interval (three seconds, or C<EV_TDLIB_SHUTDOWN_TIMEOUT>) so TDLib
flushes its database, then joins the reader thread. B<Pumping the loop
runs your callbacks>, so a program that exits early -- from a
login-failure path, say, or one that never ran the loop at all -- still
sees on_update and reply callbacks fire during global destruction,
after its own END blocks have run. Write them so they are safe to run
then, or close() before you leave. The three seconds
bound the pump only: the join has its own two-second wait, after which
it prods TDLib to wake the reader and then waits without a deadline,
and a reader sitting in td_receive can take up to ten seconds more to
notice. Shutdown is bounded, but by the sum rather than by the three.
It is a safety net, not a substitute for close().

=item *

A callback that dies is contained and reported through on_error; the
drain continues. See L</ERROR HANDLING>.

=back

=head1 SECURITY

The database directory holds the session: whoever reads it owns the
account. Treat it as exactly as sensitive as a password: restrictive
permissions, no commits, no backups to third-party storage.

TDLib creates that directory 0750 and its binlog 0600, but the sqlite
files are created 0644 masked by your umask, so 022 and 002 both leave
them world-readable and only a narrower umask changes that: 027 gives
0640, 077 gives 0600. The 0750 directory is what keeps other users
out. This module does not set a umask, which
is the caller's to choose; set one before creating a client if the
default is not what you want. Note also that the examples default to a
C<tdlib-db> in the working directory, so running one from a checkout
leaves a live session there.

Credentials stay in the object. api_id, api_hash, bot_token, the phone
number and the encryption key are held for the life of the client, so a
core dump or a process-memory read exposes them. Perl cannot reliably
erase a string, so this is a property to design around rather than
something the module can fix: disable cores where it matters.

Set database_encryption_key so the local database is encrypted at
rest, and keep the key out of source control.

api_id and api_hash identify your application to Telegram. Pass them
from your environment rather than hardcoding them; new() does not read
any environment variable itself, but the examples in F<eg/> take them
from TD_API_ID and TD_API_HASH.

The login callbacks receive credentials from wherever you choose to
read them. If that is a terminal, do not echo the 2FA password: it
lands in the scrollback, in a screen recording and in whatever the
session is logged to. F<eg/01-login.pl> shows the shape -- turn echo
off through a guard object, so an interrupt cannot leave the terminal
silent for whatever runs next.

B<TDLib's log can carry credentials.> Above the lowest levels it writes
the requests it makes, and those include the ones carrying your
api_hash and bot token; logging in with verbosity raised has been
observed to put both on stderr in clear. TDLib's own default is 5, so
this module sets 1 at load, and a C<TDLIB_LOG_VERBOSITY> it cannot read
as a level falls back to 1 rather than leaving TDLib at 5. Raise it to
debug something and whatever collects your stderr collects that too.

=head1 REQUIREMENTS

=over 4

=item *

perl 5.12 or later, built with 64-bit integers. Makefile.PL refuses to
configure when ivsize is below 8: Telegram chat and user ids are
int64, and message ids are shifted left by 20 bits, so they must
never round-trip through an NV.

=item *

L<EV> 4.11 or later.

=item *

L<Cpanel::JSON::XS> 4.00 or later.

=item *

L<Alien::TDLib>, at configure and build time. It provides TDLib
1.8.66, pinned at commit 022d60202e446ad1287b9fb68e687c8a0760788b;
TDLib itself is licensed under the Boost Software License 1.0.

=back

=head1 LIMITATIONS

Deliberately out of scope:

=over 4

=item *

No Bot API (HTTP) client; this binding speaks tdjson only.

=item *

No voice or video calls.

=item *

No group calls or video chats.

=item *

Around 418 of TDLib's roughly one thousand methods have a
hand-written wrapper. For the rest,
L<call()|/"call($function, \%args, $cb, %opt)"> validates argument names
against a shipped schema catalogue, and
L<send()|/"send(\%request, $cb, %opt)"> and L</execute(\%request)>
are the escape hatch (see L</ESCAPE HATCH>).

=item *

The Business plane is unverified against a live server: exercising it
needs a Telegram Business subscription, which the author does not have.
Its methods are covered by offline tests only. Note that the
requirement differs across the plane. The bot-side calls
(business_connection, send_business_message, read_business_message,
delete_business_messages, business_account_star_amount and the
set_business_account_* setters) are documented "for bots only" and need
no subscription on the bot itself, since the bot acts on a connected
business account. The TL marks eight as needing the current account to
hold a Business subscription: set_away_message, set_greeting_message,
send_quick_reply, set_business_location, set_opening_hours,
set_start_page, create_business_chat_link and edit_business_chat_link.
business_features, business_chat_link_info, check_quick_reply_name,
connected_bot and load_quick_replies are callable by anyone.

=item *

Gift auctions, gift crafting and live-story streaming are not wrapped.

=item *

No log message callback (TDLib's setLogMessageCallback is not bound);
TDLIB_LOG_VERBOSITY (see L</ENVIRONMENT>) is the only log control.

=item *

Linux and macOS are CI-tested. The BSDs are unsupported: Alien::TDLib
ships no prebuilt TDLib for them, so a build there means compiling
TDLib from source, which is impractical inside a CI runner.

=item *

The default EV loop only; see L</CAVEATS>.

=back

=head1 SEE ALSO

L<Alien::TDLib>, L<EV>, L<EV::Telegram::TDLib::Cookbook>,
L<https://core.telegram.org/tdlib> and the td_api documentation
linked from it, L<Telegram::JsonAPI> (synchronous prior art on CPAN).

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
