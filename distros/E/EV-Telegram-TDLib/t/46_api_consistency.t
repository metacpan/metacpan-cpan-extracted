use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
sub last_req  { Cpanel::JSON::XS->new->utf8->decode($sent[-1]) }
sub last_json { $sent[-1] }
sub last_extra { last_req()->{'@extra'} }

my $n = 0;
sub new_client {
    return EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x',
        database_directory => 't/tmp-consistency' . $n++, @_);
}

my $td = new_client();

# --- a ref is defined and has a length, so a "defined && length" guard lets
# an omitted argument through as CODE(0x...) or ARRAY(0x...)
{
    @sent = ();
    my $e = do { local $@; eval { $td->set_chat_title(42, sub {}) }; $@ };
    like $e, qr/required/, 'set_chat_title refuses a callback as the title';
    is scalar(@sent), 0, 'and renames nothing';

    $e = do { local $@; eval { $td->create_folder({ name => [] }, sub {}) }; $@ };
    like $e, qr/must be a string/, 'create_folder refuses a ref as the name';
}

# --- an odd option list means a name landed in a positional slot, so the
# pairs shift and the request says the opposite of what was asked
{
    @sent = ();
    my $e = do { local $@;
        eval { $td->install_sticker_set(123, archived => 1, sub {}) }; $@ };
    like $e, qr/name => value pairs/,
        'an option in a positional slot croaks rather than inverting the request';
    is scalar(@sent), 0, 'and sends nothing';

    $e = do { local $@; eval { $td->mute_scope('private', preview => 0, sub {}) }; $@ };
    like $e, qr/name => value pairs/, 'the same for mute_scope';

    # the correct spellings still work
    ok eval { $td->install_sticker_set(123, 1, archived => 1, sub {}); 1 },
        'the documented call still works';
    like last_json(), qr/"is_archived":true/, 'and archives';
}

# --- show_preview is the field name; preview was the original spelling. One
# of them was silently ignored.
{
    $td->mute_scope('private', 60, show_preview => 0, sub {});
    is last_req()->{notification_settings}{show_preview}, Cpanel::JSON::XS::false,
        'mute_scope honours show_preview';
    $td->mute_scope('private', 60, preview => 0, sub {});
    is last_req()->{notification_settings}{show_preview}, Cpanel::JSON::XS::false,
        'and still honours the original preview spelling';
}

# --- a basic group's chat id is its group id negated; supergroup already
# accepted either form, basic_group did not
{
    $td->basic_group(-123456, sub {});
    is last_req()->{basic_group_id}, 123456, 'basic_group accepts a chat id';
    $td->basic_group(123456, sub {});
    is last_req()->{basic_group_id}, 123456, 'and a bare group id';
}

# --- a callback taken in a fixed slot is displaced by any extra argument and
# silently lost; taken from the end, the extra argument is refused instead
{
    for my $call ([ join_chat => 7, timeout => 5 ], [ leave_chat => 7, timeout => 5 ],
                  [ unpin_message => 7, 9, extra => 1 ]) {
        my ($m, @args) = @$call;
        @sent = ();
        my $e = do { local $@; eval { $td->$m(@args, sub {}); 1 } ? '' : $@ };
        like $e, qr/\A$m takes at most \d arguments? before its callback, and no options at \Q${\__FILE__}\E/,
            "$m refuses an extra argument at the call site";
        is scalar @sent, 0, "and $m sends nothing";
    }
    my $ran = 0;
    $td->unpin_message(7, 9, sub { $ran++ });
    $td->inject_raw(qq({"\@type":"ok","\@extra":"@{[last_extra()]}"}));
    is $ran, 1, 'unpin_message still keeps its callback';

    # set_bio and set_username take a value that may legally be the empty
    # string, so "no value" must not read as "clear it". The old fixed slot
    # put the coderef in the value and Telegram rejected it; popping the
    # callback made the same call succeed and wipe the field, which for
    # set_username frees the account's public username.
    for my $m (qw(set_bio set_username)) {
        @sent = ();
        my $e = do { local $@; eval { $td->$m(sub {}) }; $@ };
        like $e, qr/needs a/, "$m refuses a callback where the value belongs";
        is scalar(@sent), 0, "$m sends nothing";
        $e = do { local $@; eval { $td->$m([]) }; $@ };
        like $e, qr/must be a string/, "$m refuses a ref";
        # and the documented way to clear still works
        ok eval { $td->$m('', sub {}); 1 }, "$m still clears on an empty string";
        like last_json(), qr/"(?:bio|username)":""/, "$m sends the empty value";
    }
}

# --- a singleton handler can be removed, like on_command and on_upload can
{
    my $c = new_client();
    my @got;
    $c->on_message(sub { push @got, 1 });
    my $ret = $c->on_message(undef);
    is $ret, undef, 'on_message(undef) reports the handler is gone';
    $c->inject_raw(
        q({"@type":"updateNewMessage","message":{"@type":"message","id":1,)
      . q("chat_id":-100,"is_outgoing":false,)
      . q("content":{"@type":"messageText","text":{"@type":"formattedText",)
      . q("text":"hi"}}}}));
    is scalar(@got), 0, 'and it no longer fires';
    is $c->on_message, undef, 'the getter agrees';

    # the getter must still be a getter
    $c->on_message(sub { push @got, 1 });
    ok $c->on_message, 'calling it with no argument reads rather than clears';
}

# --- the schema says a message being sent that is irrecoverably deleted
# yields updateDeleteMessages instead of updateMessageSendFailed
{
    my $c = new_client();
    @sent = ();
    my @done;
    $c->send_message(-100, 'hi', sub { push @done, [@_] });
    my $extra = last_extra();
    $c->inject_raw(qq({"\@type":"message","id":1048576,"chat_id":-100,"\@extra":"$extra"}));
    is scalar(@done), 0, 'the send is waiting for delivery';

    # a cache eviction is not a deletion: the schema says it can come back
    $c->inject_raw(q({"@type":"updateDeleteMessages","chat_id":-100,)
                   . q("message_ids":[1048576],"is_permanent":false,"from_cache":true}));
    is scalar(@done), 0, 'a from_cache deletion does not resolve it';

    $c->inject_raw(q({"@type":"updateDeleteMessages","chat_id":-100,)
                   . q("message_ids":[1048576],"is_permanent":true,"from_cache":false}));
    is scalar(@done), 1, 'a real deletion resolves the waiting send';
    is $done[0][0], undef, 'with no message';
    like $done[0][1]{message}, qr/deleted before it was sent/, 'and an error saying so';
    is scalar keys %{ $c->{cache}{sending} || {} }, 0, 'the registry drains';

    # an unrelated deletion must not touch anything
    my @other;
    $c->send_message(-100, 'again', sub { push @other, [@_] });
    $c->inject_raw(qq({"\@type":"message","id":2097152,"chat_id":-100,"\@extra":"@{[last_extra()]}"}));
    $c->inject_raw(q({"@type":"updateDeleteMessages","chat_id":-100,)
                   . q("message_ids":[999999],"is_permanent":true,"from_cache":false}));
    is scalar(@other), 0, 'a deletion of some other message resolves nothing';
}

# --- a cancelled story post. The schema says updateStoryDeleted arrives
# instead of updateStoryPostFailed, but that is stale for 1.8.66: the deleted
# update is only ever sent for a server id, and a yet-unsent story is
# numbered above the server range, so a cancel takes the 406 path and comes
# back as updateStoryPostFailed like any other failure.
{
    my $c = new_client();
    @sent = ();
    my @done;
    $c->post_story(-100, '/tmp/x.jpg', sub { push @done, [@_] });
    my $extra = last_extra();
    $c->inject_raw(qq({"\@type":"story","id":2000000000,"poster_chat_id":-100,"\@extra":"$extra"}));
    is scalar(@done), 0, 'the post is waiting';

    # what TDLib cannot send: a deleted update carrying a provisional id
    $c->inject_raw(q({"@type":"updateStoryDeleted",)
                   . q("story_poster_chat_id":-100,"story_id":2000000000}));
    is scalar(@done), 0, 'updateStoryDeleted does not resolve a pending post';

    $c->inject_raw(q({"@type":"updateStoryPostFailed","story":{"@type":"story",)
                   . q("id":2000000000,"poster_chat_id":-100},)
                   . q("error":{"@type":"error","code":406,"message":"Canceled"}}));
    is scalar(@done), 1, 'the 406 that a cancel really produces resolves it';
    is $done[0][1]{code}, 406, 'with the error TDLib sent';
    is scalar keys %{ $c->{cache}{posting} || {} }, 0, 'the registry drains';
}

# --- a getMe that failed at the Ready transition left every addressed command
# unmatched for the life of the process
{
    my $c = new_client();
    @sent = ();
    my @fired;
    $c->on_command(help => sub { push @fired, 1 });
    $c->{state} = 'authorizationStateReady';
    $c->resolve_my_username;
    my $extra = last_extra();
    $c->inject_raw(qq({"\@type":"error","code":429,"message":"Too Many Requests","\@extra":"$extra"}));
    is $c->{my_username}, undef, 'the username fetch failed';

    @sent = ();
    $c->inject_raw(
        q({"@type":"updateNewMessage","message":{"@type":"message","id":1,)
      . q("chat_id":-100,"is_outgoing":false,)
      . q("sender_id":{"@type":"messageSenderUser","user_id":42},)
      . q("content":{"@type":"messageText","text":{"@type":"formattedText",)
      . q("text":"/help@mybot"}}}}));
    is scalar(@fired), 0, 'the addressed command does not match yet';
    ok scalar(@sent), 'but the failure is retried rather than given up on';
    is last_req()->{'@type'}, 'getMe', 'with another getMe';

    $c->inject_raw(qq({"\@type":"user","id":7,"usernames":{"editable_username":"mybot"},)
                   . qq("\@extra":"@{[last_extra()]}"}));
    is $c->{my_username}, 'mybot', 'which succeeds this time';
    $c->inject_raw(
        q({"@type":"updateNewMessage","message":{"@type":"message","id":2,)
      . q("chat_id":-100,"is_outgoing":false,)
      . q("sender_id":{"@type":"messageSenderUser","user_id":42},)
      . q("content":{"@type":"messageText","text":{"@type":"formattedText",)
      . q("text":"/help@mybot"}}}}));
    is scalar(@fired), 1, 'and the addressed command matches from then on';
}

# --- every list argument is checked where the caller can see it. A method
# that only deref'd it died inside the module, naming a line the caller has
# no reason to look at, and the surrounding methods all croaked properly.
{
    my @cases = (
      [messages                    => sub { $td->messages(-100, 'nope', sub {}) }],
      [send_album                  => sub { $td->send_album(-100, 'nope', sub {}) }],
      [resend_messages             => sub { $td->resend_messages(-100, 'nope', sub {}) }],
      [set_reactions               => sub { $td->set_reactions(-100, 5, 'nope', sub {}) }],
      [delete_messages             => sub { $td->delete_messages(-100, 'nope', sub {}) }],
      [forward_messages            => sub { $td->forward_messages(-100, -200, 'nope', sub {}) }],
      [send_poll                   => sub { $td->send_poll(-100, 'q', 'nope', sub {}) }],
      [set_privacy                 => sub { $td->set_privacy('status', 'nope', sub {}) }],
      [inline_keyboard             => sub { EV::Telegram::TDLib->inline_keyboard('nope') }],
      [reply_keyboard              => sub { EV::Telegram::TDLib->reply_keyboard('nope') }],
      [set_commands                => sub { $td->set_commands('nope', sub {}) }],
      [answer_inline_query         => sub { $td->answer_inline_query('1', 'nope', sub {}) }],
      [share_users_with_bot        => sub { $td->share_users_with_bot(-100, 5, 1, 'nope', sub {}) }],
      [delete_bot_media_previews   => sub { $td->delete_bot_media_previews(7, 'nope', sub {}) }],
      [reorder_bot_media_previews  => sub { $td->reorder_bot_media_previews(7, 'nope', sub {}) }],
      [reorder_folders             => sub { $td->reorder_folders('nope', sub {}) }],
      [create_story_album          => sub { $td->create_story_album(-100, 'n', 'nope', sub {}) }],
      [add_album_stories           => sub { $td->add_album_stories(-100, 1, 'nope', sub {}) }],
      [remove_album_stories        => sub { $td->remove_album_stories(-100, 1, 'nope', sub {}) }],
      [reorder_album_stories       => sub { $td->reorder_album_stories(-100, 1, 'nope', sub {}) }],
      [reorder_story_albums        => sub { $td->reorder_story_albums(-100, 'nope', sub {}) }],
      [custom_emoji_stickers       => sub { $td->custom_emoji_stickers('nope', sub {}) }],
      [create_sticker_set          => sub { $td->create_sticker_set(7, 't', 'n', 'nope', sub {}) }],
      [reorder_sticker_sets        => sub { $td->reorder_sticker_sets('nope', sub {}) }],
      [delete_business_messages    => sub { $td->delete_business_messages('c', 'nope', sub {}) }],
      [set_opening_hours           => sub { $td->set_opening_hours('UTC', 'nope', sub {}) }],
      [delete_quick_reply_messages => sub { $td->delete_quick_reply_messages(1, 'nope', sub {}) }],
      [reorder_quick_replies       => sub { $td->reorder_quick_replies('nope', sub {}) }],
      [import_contacts             => sub { $td->import_contacts('nope', sub {}) }],
      [remove_contacts             => sub { $td->remove_contacts('nope', sub {}) }],
    );
    my @inside;
    for my $c (@cases) {
        my ($name, $code) = @$c;
        my $err = do { local $@; eval { $code->(); 1 } ? '' : $@ };
        push @inside, "$name (accepted it)" and next unless $err;
        push @inside, "$name: $err" if $err =~ m{ at \S*(?:lib|blib)/EV/};
    }
    is_deeply \@inside, [],
        'a scalar where a list belongs croaks at the call site, not inside';
    diag $_ for @inside;
    cmp_ok scalar(@cases), '>', 25, 'and the scan covered the list arguments';
}

# --- a short enum name is expanded into a TL class; a typo must not reach
# TDLib as a class that does not exist
{
    for my $c (['remote_file file type',
                sub { $td->remote_file('r', file_type => 'Nope', sub {}) }],
               ['message_count filter',
                sub { $td->message_count(-100, filter => 'Nope', sub {}) }],
               ['search_secret_messages filter',
                sub { $td->search_secret_messages('q', filter => 'Nope', sub {}) }]) {
        my ($label, $code) = @$c;
        my $e = do { local $@; eval { $code->() }; $@ };
        like $e, qr/unknown (?:file type|message filter) 'Nope'/,
            "$label refuses a name the schema does not have";
    }
    # and the valid ones still build the class they always did
    $td->remote_file('r', file_type => 'Video', sub {});
    is last_req()->{file_type}{'@type'}, 'fileTypeVideo', 'a valid short name expands';
    $td->remote_file('r', file_type => 'fileTypeVideo', sub {});
    is last_req()->{file_type}{'@type'}, 'fileTypeVideo', 'as does the full class name';
    $td->remote_file('r', sub {});
    is last_req()->{file_type}{'@type'}, 'fileTypeUnknown', 'and the default';
}

# --- a convenience method returns nothing; four used to hand back the
# internal correlation id, which nothing accepts
{
    my @ret = (
        [me               => sub { $td->me(sub {}) }],
        [load_chats       => sub { $td->load_chats(5, sub {}) }],
        [chat_by_username => sub { $td->chat_by_username('x', sub {}) }],
        [user_by_username => sub { $td->user_by_username('x', sub {}) }],
        [account_ttl_get  => sub { $td->account_ttl(sub {}) }],
        [account_ttl_set  => sub { $td->account_ttl(30, sub {}) }],
    );
    for my $r (@ret) {
        my ($name, $code) = @$r;
        is scalar($code->()), undef, "$name returns nothing";
    }
}

# --- a lone trailing undef is ambiguous and must not be guessed. Forwarding
# an absent callback and giving an option a value of undef produce the same
# argument list, so popping it to help the first mispaired the second: it
# installed a sticker set instead of archiving it, unmuted a scope, and
# approved every pending join request. Both croak instead.
{
    for my $c (['install_sticker_set',
                sub { $td->install_sticker_set(123, archived => undef, sub {}) }],
               ['process_join_requests',
                sub { $td->process_join_requests(7, approve => undef, sub {}) }],
               ['mute_scope',
                sub { $td->mute_scope('private', preview => undef, sub {}) }]) {
        my ($name, $code) = @$c;
        @sent = ();
        my $e = do { local $@; eval { $code->() }; $@ };
        like $e, qr/name => value pairs/, "$name refuses an undef option value";
        is scalar(@sent), 0, "$name sends nothing";
    }
    # and the message tells a pass-through wrapper what to write instead
    my $e = do { local $@; eval { $td->block_user(7, undef) }; $@ };
    like $e, qr/omit it when it is undef/,
        'the croak names the forwarded-callback case';
}

# --- send and call name the callback before their options and every other
# method takes it last, so CONVENTIONS asserted a rule these two broke: the
# documented shape croaked, and the option was lost with it
{
    for my $c (['send', sub { $td->send({ '@type' => 'getMe' }, timeout => 5, @_) }],
               ['call', sub { $td->call('getMe', {}, timeout => 5, @_) }]) {
        my ($name, $code) = @$c;
        @sent = ();
        ok eval { $code->(sub {}); 1 },
            "$name takes the callback last, as CONVENTIONS says"
            or diag $@;
        is last_req()->{'@type'}, 'getMe', "and $name still sends the request";
        ok eval { $code->(); 1 }, "$name takes options with no callback at all"
            or diag $@;
    }
    # the shapes that already worked must keep working
    ok eval { $td->send({ '@type' => 'getMe' }, sub {}, timeout => 5); 1 },
        'send takes a callback then options';
    ok eval { $td->send({ '@type' => 'getMe' }, undef, timeout => 5); 1 },
        'and an explicit undef callback with options';
    ok eval { $td->send({ '@type' => 'getMe' }); 1 }, 'and neither';
    # a ref that is not a callback in the leading slot is still a mistake
    my $e = do { local $@; eval { $td->send({ '@type' => 'getMe' }, [], timeout => 5) }; $@ };
    like $e, qr/callback before or after its options/,
        'send still refuses a non-callback ref where the callback belongs';
}

# --- an account with no username answers getMe successfully and leaves the
# username undef, so retrying on "still undef" asked again for every
# addressed message forever
{
    my $c = new_client();
    $c->on_command(help => sub {});
    @sent = ();
    for my $i (1 .. 5) {
        $c->inject_raw(
            q({"@type":"updateNewMessage","message":{"@type":"message","id":) . $i
          . q(,"chat_id":-100,"is_outgoing":false,)
          . q("sender_id":{"@type":"messageSenderUser","user_id":42},)
          . q("content":{"@type":"messageText","text":{"@type":"formattedText",)
          . q("text":"/help@bot"}}}}));
        my ($x) = ($sent[-1] // '') =~ /"\@extra":"(\d+)"/;
        $c->inject_raw(qq({"\@type":"user","id":7,"usernames":{},"\@extra":"$x"}))
            if defined $x;
    }
    is scalar(grep { /getMe/ } @sent), 1,
        'a successful getMe is not repeated just because there was no username';

    # ...but changing the username must invalidate what was cached, or every
    # /command@newname stays unmatched for the life of the process
    $c->set_username('newname', sub {});
    @sent = ();
    $c->inject_raw(
        q({"@type":"updateNewMessage","message":{"@type":"message","id":99,)
      . q("chat_id":-100,"is_outgoing":false,)
      . q("sender_id":{"@type":"messageSenderUser","user_id":42},)
      . q("content":{"@type":"messageText","text":{"@type":"formattedText",)
      . q("text":"/help@newname"}}}}));
    ok scalar(grep { /getMe/ } @sent),
        'set_username re-asks rather than serving the stale answer';
}

# --- TDLib's own default log level is 5, which writes api_hash and
# bot_token to stderr in clear. A setting we cannot use must fall back to
# ours, not to TDLib's -- and an exported-but-empty variable is defined, so
# the // that used to do this never fired.
{
    # asserted against what TDLib ended up at, not against our return value:
    # a level of the right shape but outside TDLib's range is refused, and
    # refusing it leaves the level exactly where it must not be left
    my $ask = sub {
        my $r = EV::Telegram::TDLib->execute({ '@type' => 'getLogVerbosityLevel' });
        return $r->{verbosity_level};
    };
    for my $v ('', 'abc', ' 1', '-1', '1.0', '1025', '2000', '4294967296') {
        EV::Telegram::TDLib::set_log_verbosity($v);
        is $ask->(), 1, "TDLIB_LOG_VERBOSITY '$v' leaves TDLib at 1";
    }
    EV::Telegram::TDLib::set_log_verbosity(undef);
    is $ask->(), 1, 'as does an unset one';
    EV::Telegram::TDLib::set_log_verbosity(0);
    is $ask->(), 0, 'and 0 is honoured';
    EV::Telegram::TDLib::set_log_verbosity(3);
    is $ask->(), 3, 'as is a real level';
    # leave the process quiet for whatever runs next
    EV::Telegram::TDLib::set_log_verbosity(1);
    # assigned first: "is Class->method(...)" parses as "Class->is(...)"
    my $level = EV::Telegram::TDLib->execute({ '@type' => 'getLogVerbosityLevel' });
    is $level->{verbosity_level}, 1, 'and TDLib agrees with what we asked for';
}

# --- the documented way to remove a keyboard has to be the one that works.
# The POD said "an empty hashref"; TDLib refuses that for having no @type.
{
    @sent = ();
    $td->edit_message_markup(-100, 5, sub {});
    my $r = last_req();
    delete $r->{'@extra'};
    ok exists $r->{reply_markup} && !defined $r->{reply_markup},
        'omitting the markup sends an explicit null';
    my $parsed = EV::Telegram::TDLib->execute($r);
    unlike $parsed->{message} // '', qr/Failed to parse/,
        'and TDLib accepts that as the removal';

    @sent = ();
    $td->edit_message_markup(-100, 5, {}, sub {});
    my $r2 = last_req();
    delete $r2->{'@extra'};
    my $p2 = EV::Telegram::TDLib->execute($r2);
    like $p2->{message} // '', qr/\@type/,
        'while an empty hashref is refused, as the POD now says';
}

# --- building the TDLib parameters can croak, and a wide-character
# encryption key is the reachable case. The drain reports the croak and
# carries on, so nothing was sent and login() was owed an answer forever.
{
    my @errs;
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x',
        database_encryption_key => "wide\x{263a}key",
        database_directory => 't/tmp-widekey',
        on_error => sub { push @errs, $_[0] });
    my @login;
    $c->login(sub { push @login, [@_] });
    @sent = ();
    ok eval {
        $c->inject_raw(
            q({"@type":"updateAuthorizationState","authorization_state":)
          . q({"@type":"authorizationStateWaitTdlibParameters"}}));
        1;
    }, 'a wide encryption key does not escape the dispatch';
    is scalar(@sent), 0, 'and nothing is sent';
    is scalar(@login), 1, 'but the login is answered rather than left hanging';
    like $login[0][1]{message}, qr/bytes, not text/,
        'with the reason it could not proceed';
}

# --- login() on a settled client answers through a timer. Closing before
# that timer runs used to report the login as having succeeded on a client
# that was already gone.
{
    my $c = new_client();
    $c->{state} = 'authorizationStateReady';
    my @got;
    $c->login(sub { push @got, [@_] });
    is scalar(@{ $c->{login_late} || [] }), 1, 'the answer is parked';
    $c->inject_raw(
        q({"@type":"updateAuthorizationState","authorization_state":)
      . q({"@type":"authorizationStateClosed"}}));
    is scalar(@{ $c->{login_late} || [] }), 0, 'and closing clears it';
    is scalar(@got), 1, 'the caller is answered once';
    like $got[0][1]{message}, qr/closed during login/,
        'and told the client closed, not that the login succeeded';
}

# --- a command can arrive as a media caption, which is an ordinary way to
# talk to a bot. TDLib puts the same bot-command entity there, and
# answer_ask already accepts a media message as an answer.
{
    my $c = new_client();
    my @fired;
    $c->on_command(scan => sub { push @fired, $_[1] // '' });
    my $ent = q("entities":[{"@type":"textEntity","offset":0,"length":5,)
            . q("type":{"@type":"textEntityTypeBotCommand"}}]);
    my $msg = sub {
        q({"@type":"updateNewMessage","message":{"@type":"message","id":1,)
      . q("chat_id":-100,"is_outgoing":false,)
      . q("sender_id":{"@type":"messageSenderUser","user_id":42},)
      . qq("content":$_[0]}});
    };
    $c->inject_raw($msg->(qq({"\@type":"messageText","text":)
        . qq({"\@type":"formattedText","text":"/scan now",$ent}})));
    is scalar(@fired), 1, 'a command in a text message fires';
    $c->inject_raw($msg->(qq({"\@type":"messagePhoto","caption":)
        . qq({"\@type":"formattedText","text":"/scan now",$ent}})));
    is scalar(@fired), 2, 'and one in a photo caption fires too';
    is $fired[1], 'now', 'with its arguments';
    # a message with neither must still be ignored
    $c->inject_raw($msg->(q({"@type":"messageSticker"})));
    is scalar(@fired), 2, 'a message with no text or caption is ignored';
}

# --- an option new() does not know is inert, and staying silent about it
# ships the session unencrypted or into the working directory
{
    my $e = do { local $@; eval {
        EV::Telegram::TDLib->new(api_id => 1, api_hash => 'x',
            database_encryption_ke => 'secret',
            database_directory => 't/tmp-unk') }; $@ };
    like $e, qr/unknown option for new\(\): database_encryption_ke/,
        'a mistyped constructor option croaks rather than being dropped';
    # the documented ones, and any on_* handler, still pass
    ok eval { EV::Telegram::TDLib->new(api_id => 1, api_hash => 'x',
        database_directory => 't/tmp-unk2', use_test_dc => 1, retry => 1,
        on_message => sub {}, on_qr => sub {}); 1 },
        'documented options and on_* handlers are accepted' or diag $@;
}

# --- the methods whose last argument is a flag take no options, and an
# option written there used to land in the flag and invert the call
{
    my @cases = (
        ['close_topic',  sub { $td->close_topic(-100, 7, closed => 0, sub {}) }],
        ['pin_topic',    sub { $td->pin_topic(-100, 7, pinned => 0, sub {}) }],
        ['mark_unread',  sub { $td->mark_unread(-100, unread => 0, sub {}) }],
        ['folder_tags',  sub { $td->folder_tags(enabled => 0, sub {}) }],
        ['process_join_request',
         sub { $td->process_join_request(-100, 7, approve => 0, sub {}) }],
        ['toggle_gift_saved',
         sub { $td->toggle_gift_saved(1, saved => 0, sub {}) }],
        ['pause_download', sub { $td->pause_download(5, paused => 0, sub {}) }],
        ['post_story_to_page',
         sub { $td->post_story_to_page(-100, 5, on => 0, sub {}) }],
        ['pause_connected_bot',
         sub { $td->pause_connected_bot(-100, paused => 0, sub {}) }],
        ['protect_content', sub { $td->protect_content(-100, on => 0, sub {}) }],
        ['edit_star_subscription',
         sub { $td->edit_star_subscription(1, canceled => 0, sub {}) }],
        ['hide_general_topic',
         sub { $td->hide_general_topic(-100, hidden => 0, sub {}) }],
    );
    for my $c (@cases) {
        my ($name, $code) = @$c;
        @sent = ();
        my $e = do { local $@; eval { $code->() }; $@ };
        like $e, qr/takes no options/, "$name refuses an option in the flag slot";
        is scalar(@sent), 0, "$name sends nothing";
    }
    # and the positional form still works, both ways
    $td->close_topic(-100, 7, 0, sub {});
    like last_json(), qr/"is_closed":false/, 'close_topic(c, t, 0) reopens';
    $td->close_topic(-100, 7, sub {});
    like last_json(), qr/"is_closed":true/, 'and defaults to closing';
}

# --- Carp prints every frame's arguments when it builds a backtrace, which
# is what Carp::Always and $Carp::Verbose ask for -- and that is exactly
# what gets switched on when a login is misbehaving. No croak reachable with
# a credential on the stack may show one.
{
    local $Carp::Verbose = 1;
    my $all = '';
    $all .= do { local $@; eval {
        EV::Telegram::TDLib->new(api_id => 1, api_hash => 'SENTINELHASH',
            bot_token => 'SENTINELTOKEN', application_name => 'bad-name',
            database_directory => 't/tmp-carp-a') }; $@ };
    $all .= do { local $@; eval {
        EV::Telegram::TDLib->new(api_id => 1, api_hash => 'SENTINELHASH',
            database_encryption_key => "wide\x{263a}", 'odd',
            database_directory => 't/tmp-carp-b') }; $@ };
    my $c = new_client();
    $all .= do { local $@; eval {
        $c->star_withdrawal_url('notanid', 5, 'SENTINELPASSWORD', sub {}) }; $@ };
    $all .= do { local $@; eval {
        $c->transfer_ownership('notanid', 7, 'SENTINELPASSWORD', sub {}) }; $@ };
    is scalar(() = $all =~ /SENTINEL/g), 0,
        'no croak reachable with a credential on the stack prints one';
    like $all, qr/application_name must be/, 'and the messages still say why';
}

# --- a getMe already in flight when the username changes must not land and
# memo the old name, which would leave every addressed command unmatched
{
    my $c = new_client();
    $c->on_command(help => sub {});
    $c->{state} = 'authorizationStateReady';
    @sent = ();
    $c->resolve_my_username;
    my ($x) = ($sent[-1] // '') =~ /"\@extra":"(\d+)"/;
    $c->set_username('newname', sub {});
    $c->inject_raw(qq({"\@type":"user","id":7,)
        . qq("usernames":{"editable_username":"oldname"},"\@extra":"$x"}));
    is $c->{my_username}, undef, 'a reply from before the rename is discarded';
    ok !$c->{my_username_asked}, 'and does not memo the stale name';

    @sent = ();
    $c->inject_raw(
        q({"@type":"updateNewMessage","message":{"@type":"message","id":1,)
      . q("chat_id":-100,"is_outgoing":false,)
      . q("sender_id":{"@type":"messageSenderUser","user_id":42},)
      . q("content":{"@type":"messageText","text":{"@type":"formattedText",)
      . q("text":"/help@newname"}}}}));
    ok scalar(grep { /getMe/ } @sent), 'so the next addressed command re-asks';
}

# --- a numeric slot on a method that also takes a password must croak
# rather than let 0 + warn, because Carp::Always longmesses warnings too
{
    my $c = new_client();
    for my $t (['star_withdrawal_url',
                sub { $c->star_withdrawal_url(7, 'lots', 'pw', sub {}) }],
               ['transfer_ownership',
                sub { $c->transfer_ownership('nope', 7, 'pw', sub {}) }]) {
        my ($name, $code) = @$t;
        my @warns;
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        my $e = do { local $@; eval { $code->() }; $@ };
        like $e, qr/must be a number/, "$name croaks on a non-numeric id";
        is scalar(@warns), 0, "$name warns from nowhere inside the module";
    }
}

# --- every method whose last positional is a flag. The first sweep matched a
# pattern and covered twelve of them; the POD's own Booleans list was the
# complete oracle and named more, and three more used the same idiom without
# being listed at all. An option written in the flag slot puts its name in the
# flag, which is truthy, so each of these did the opposite of what was asked.
{
    my $c = new_client();
    my @flags = (
        [ close_topic                  => [-100, 7] ],
        [ pin_topic                    => [-100, 7] ],
        [ hide_general_topic           => [-100] ],
        [ mark_unread                  => [-100] ],
        [ protect_content              => [-100] ],
        [ folder_tags                  => [] ],
        [ pause_download               => [7] ],
        [ process_join_request         => [-100, 9] ],
        [ post_story_to_page           => [-100, 7] ],
        [ toggle_gift_saved            => ['g1'] ],
        [ edit_star_subscription       => ['s1'] ],
        [ pause_connected_bot          => [-100] ],
        [ join_to_send                 => [7] ],
        [ all_history_available        => [7] ],
        [ hide_members                 => [7] ],
        [ session_accepts_secret_chats => ['s1'] ],
        [ default_disable_notification => [-100] ],
        [ toggle_username              => ['name'] ],
        [ toggle_bot_username          => [5, 'name'] ],
    );
    for my $f (@flags) {
        my ($m, $args) = @$f;
        my $e = do { local $@; eval { $c->$m(@$args, enabled => 0, sub {}) }; $@ };
        like $e, qr/takes no options/, "$m refuses an option in the flag slot";
        @sent = ();
        ok eval { $c->$m(@$args, 0, sub {}); 1 }, "and $m still takes the flag itself"
            or diag $@;
        like last_json(), qr/false/, "and $m sends it as false";
    }
}

# --- an option name shifted into a numeric id slot. It is defined and it is
# not a coderef, so the required-argument checks pass it; then 0 + warns from
# inside the module and sends a JSON float where the schema declares int53.
{
    my $c = new_client();
    for my $t (['mark_unread',   sub { $c->mark_unread(unread => 0, sub {}) }],
               ['protect_content', sub { $c->protect_content(on => 0, sub {}) }],
               ['close_topic',   sub { $c->close_topic(-100, closed => 0, sub {}) }],
               ['leave_chat',    sub { $c->leave_chat('not an id', sub {}) }]) {
        my ($name, $code) = @$t;
        my @warns;
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        @sent = ();
        my $e = do { local $@; eval { $code->() }; $@ };
        like $e, qr/must be a number/, "$name croaks rather than coercing";
        is scalar(@warns), 0, "$name warns from nowhere inside the module";
        is scalar(@sent), 0, "and $name sends nothing";
    }
    # the int64 ids cross as strings and must not be caught by that check
    ok eval { $c->session_accepts_secret_chats('7f3a', 0, sub {}); 1 },
        'a string session id is still accepted' or diag $@;
}

# --- an undef or a ref where an option name belongs. The odd-count half of
# this croaks; the even count warned from inside the module and then sent the
# request anyway, with whatever the options it never saw default to.
{
    my $c = new_client();
    for my $m (qw(chats blocked clear_drafts archived_sticker_sets)) {
        my @warns;
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        @sent = ();
        my $e = do { local $@; eval { $c->$m(undef, undef) }; $@ };
        like $e, qr/option name must be a string/, "$m refuses an undef option name";
        is scalar(@warns), 0, "$m warns from nowhere inside the module";
        is scalar(@sent), 0, "and $m sends nothing";
    }
    my $e = do { local $@; eval { $c->chats([] => 1) }; $@ };
    like $e, qr/option name must be a string/, 'and refuses a ref as a name';
}

# --- the cache readers took an undef id straight into a hash lookup, which
# warned from inside the module. They are documented to answer undef for
# something the client has not seen, and `$td->chat($id) or return` is the
# idiomatic call, so they answer undef rather than croaking.
{
    my $c = new_client();
    for my $m (qw(user chat option)) {
        my @warns;
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        my $got = do { local $@; my $v = eval { $c->$m(undef) }; $@ ? 'CROAK' : $v };
        is $got, undef, "$m answers undef for an undef id";
        is scalar(@warns), 0, "$m warns from nowhere inside the module";
    }
}

# --- an id read without a chomp still works: perl numifies surrounding space
# and a leading sign silently, so refusing them would break working callers
# without catching any mistake
{
    my $c = new_client();
    for my $id ("-100123\n", ' -100123', '+100123', '100123') {
        @sent = ();
        ok eval { $c->send_message($id, 'hi', sub {}); 1 },
            'an id with space or a sign is accepted' or diag $@;
        like last_json(), qr/"chat_id":[+-]?100123[,}]/,
            'and reaches TDLib as a plain integer';
    }
}

# --- new() used to exempt anything matching /\Aon_/, so a typo'd handler was
# accepted as silently as any other unknown option, and on_upload -- which is
# keyed -- stored a callback nothing could ever look up
{
    my @handlers;
    for my $f (glob 'lib/EV/Telegram/TDLib.pm lib/EV/Telegram/TDLib/*.pm') {
        next if $f =~ /Schema/;
        open my $h, '<', $f or die "$f: $!";
        while (<$h>) { push @handlers, $1 if /^sub (on_\w+)/ }
        close $h;
    }
    push @handlers, qw(on_close on_code on_password on_email on_email_code on_qr);
    cmp_ok scalar(@handlers), '>', 20, 'found the on_* handlers to check';
    my %keyed = map { $_ => 1 } qw(on_command on_callback_data on_upload);
    my (@refused, @accepted_keyed);
    for my $h (@handlers) {
        my $ok = eval { new_client($h => sub {}); 1 };
        push @refused, $h        if !$ok && !$keyed{$h};
        push @accepted_keyed, $h if $ok && $keyed{$h};
    }
    is "@refused", '', 'new() accepts every single-slot and login handler';
    is "@accepted_keyed", '', 'and refuses every keyed one, which needs a key';
    for my $typo (qw(on_mesage on_erorr on_updates)) {
        my $e = do { local $@; eval { new_client($typo => sub {}) }; $@ };
        like $e, qr/unknown option/, "a typo'd handler ($typo) croaks";
    }
}

# --- keepalive with no argument is a getter. Its only no-argument test was on
# a closed client, where the early return hides the mutation, so reading the
# setting on an open one silently re-took the loop reference that keepalive(0)
# was called to release.
{
    my $c = new_client();
    is $c->keepalive(0), 0, 'keepalive(0) turns it off';
    is $c->keepalive, 0, 'and reading it back does not turn it on again';
    is $c->{keepalive}, 0, 'nor change the stored setting';
    is $c->keepalive(1), 1, 'keepalive(1) turns it back on';
    is $c->keepalive, 1, 'and reads back on';
}

# --- retry is the one option surface that decides how hard a 429 is retried
{
    my $c = new_client();
    my $e = do { local $@; eval { $c->send({ '@type' => 'getMe' },
                                           retry => { attemtps => 0 }) }; $@ };
    like $e, qr/unknown retry option 'attemtps'/,
        'a typo in the retry policy croaks rather than restoring the default';
    ok eval { $c->send({ '@type' => 'getMe' },
                       retry => { attempts => 2, max_wait => 1,
                                  factor => 2, margin => 0 }); 1 },
        'and every documented retry key is accepted' or diag $@;
}

# --- a setter whose value was left out sent the empty string, which clears:
# set_password($old, $cb) switched two-step verification off
{
    my $c = new_client();
    for my $t (
        [ set_password                  => sub { $c->set_password('old', sub {}) } ],
        [ 'set_password given undef'    => sub { $c->set_password('old', undef, sub {}) } ],
        [ set_chat_description          => sub { $c->set_chat_description(-100, sub {}) } ],
        [ set_supergroup_username       => sub { $c->set_supergroup_username(-1001, sub {}) } ],
        [ set_business_account_bio      => sub { $c->set_business_account_bio('c1', sub {}) } ],
        [ set_business_account_username => sub { $c->set_business_account_username('c1', sub {}) } ],
        [ set_story_privacy             => sub { $c->set_story_privacy(5, sub {}) } ],
    ) {
        my ($name, $code) = @$t;
        @sent = ();
        my $e = do { local $@; eval { $code->() }; $@ };
        like $e, qr/needs|required/, "$name with the value left out croaks";
        is scalar(@sent), 0, "and $name sends nothing";
    }
    $c->set_password('old', '', sub {});
    is last_req()->{new_password}, '', 'the empty string still removes the password';
    $c->set_chat_description(-100, '', sub {});
    is last_req()->{description}, '', 'and still clears a description';
}

# --- a press on a message sent through inline mode has no chat, and reached
# neither the router nor on_callback_query
{
    my $c = new_client();
    my (@routed, @handled);
    $c->on_callback_data(again => sub { push @routed, $_[0] });
    $c->on_callback_query(sub { push @handled, $_[0] });
    $c->inject_raw(q({"@type":"updateNewInlineCallbackQuery","id":"77","sender_user_id":5,)
                 . q("inline_message_id":"AAQx","chat_instance":"1",)
                 . q("payload":{"@type":"callbackQueryPayloadData","data":"YWdhaW4="}}));
    is scalar(@routed), 1, 'an inline-mode press reaches the router';
    is $routed[0]{inline_message_id}, 'AAQx', 'carrying its inline message id';
    ok !defined $routed[0]{chat_id}, 'and no chat';
    is scalar(@handled), 1, 'and reaches on_callback_query';
    is $handled[0]{data}, 'again', 'with its data decoded';

    my $q;
    $c->on_inline_query(sub { $q = shift });
    $c->inject_raw(q({"@type":"updateNewInlineQuery","id":"9","sender_user_id":5,)
                 . q("user_location":{"@type":"location","latitude":1.5,"longitude":2.5},)
                 . q("query":"x","offset":""}));
    is $q && $q->{user_location}{latitude}, 1.5, 'an inline query keeps the user location';
}

# --- a login step TDLib refused kept only its message, under code -1, so
# retry_after could not read a login flood wait
{
    my $c = new_client(bot_token => '1:x');
    my $auth = sub {
        qq({"\@type":"updateAuthorizationState","authorization_state":{"\@type":"$_[0]"}});
    };
    my ($err, $late);
    $c->login(sub { $err = $_[1] });
    $c->inject_raw($auth->('authorizationStateWaitTdlibParameters'));
    @sent = ();
    $c->inject_raw($auth->('authorizationStateWaitPhoneNumber'));
    my $x = last_extra();
    $c->inject_raw(qq({"\@type":"error","code":429,)
                 . qq("message":"Too Many Requests: retry after 42","\@extra":"$x"}));
    is $err && $err->{code}, 429, 'a refused login step keeps its code';
    is $c->retry_after($err), 42, 'so retry_after reads the wait';
    $c->login(sub { $late = $_[1] });
    my $t = EV::timer(0.05, 0, sub { EV::break });
    EV::run;
    is $late && $c->retry_after($late), 42, 'and so does a login() after the failure';
}

# --- small surfaces that dropped a mistake silently
{
    my $c = new_client();
    my $e = do { local $@; eval { $c->set_gift_settings(unlimted => 1, sub {}) }; $@ };
    like $e, qr/unknown gift setting\(s\): unlimted/, 'a typo in a gift setting croaks';

    @sent = ();
    $c->business_features(source => 'Location', sub {});
    is_deeply last_req()->{source}, { '@type' => 'businessFeatureLocation' },
        'business_features expands a short feature name';
    $e = do { local $@; eval { $c->business_features(source => 'Nope', sub {}) }; $@ };
    like $e, qr/unknown business feature/, 'and croaks on one the schema lacks';

    $e = do { local $@; eval { $c->check_quick_reply_name('hi', sub {}) }; $@ };
    like $e, qr/takes no callback/,
        'check_quick_reply_name refuses a callback it would never call';

    @sent = ();
    $c->delete_messages_by_sender(-100, -1001234, sub {});
    is_deeply last_req()->{sender_id},
        { '@type' => 'messageSenderChat', chat_id => -1001234 },
        'delete_messages_by_sender takes a chat as the sender';

    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    $e = do { local $@; eval { $c->set_message_sender(-100, 'abc', sub {}) }; $@ };
    like $e, qr/message sender/, 'set_message_sender refuses a non-number';
    is scalar(@warns), 0, 'without a warning from inside the module';
}

# --- options the TL has, which these methods dropped without a word
{
    my $c = new_client();
    @sent = ();
    $c->send_inline_result(-100, '5', 'r1', topic => 77, reply_to => 9, silent => 1, sub {});
    my $r = last_req();
    is_deeply $r->{topic_id}, { '@type' => 'messageTopicForum', forum_topic_id => 77 },
        'send_inline_result honours topic, as every sending method does';
    is $r->{reply_to}{message_id}, 9, 'and reply_to';
    ok $r->{options}{disable_notification}, 'and silent';

    my $last = { '@type' => 'chatJoinRequest', user_id => 5, date => 1, bio => '' };
    $c->join_requests(-100, offset_request => $last, sub {});
    is_deeply last_req()->{offset_request}, $last,
        'join_requests pages past its first page with offset_request';
}

# --- every name, title, bio, username and description setter: the TL slot is
# a plain string, so a formattedText refuses where it would have reached
# Telegram as HASH(0x...), and an object that stringifies is text
{
    package StringyName;
    use overload '""' => sub { 'Stringy' }, fallback => 1;
}
{
    my $c = new_client();
    $c->{cache}{options}{my_id} = 777;
    my $ft = { '@type' => 'formattedText', text => 'x', entities => [] };
    for my $t (
        [ set_name                  => sub { $c->set_name($_[0], sub {}) } ],
        [ set_bio                   => sub { $c->set_bio($_[0], sub {}) } ],
        [ set_username              => sub { $c->set_username($_[0], sub {}) } ],
        [ set_chat_title            => sub { $c->set_chat_title(-100, $_[0], sub {}) } ],
        [ set_chat_description      => sub { $c->set_chat_description(-100, $_[0], sub {}) } ],
        [ set_supergroup_username   => sub { $c->set_supergroup_username(-1001, $_[0], sub {}) } ],
        [ set_bot_name              => sub { $c->set_bot_name($_[0], sub {}) } ],
        [ set_bot_description       => sub { $c->set_bot_description($_[0], sub {}) } ],
        [ set_bot_short_description => sub { $c->set_bot_short_description($_[0], sub {}) } ],
        [ set_business_account_name => sub { $c->set_business_account_name('c1', $_[0], sub {}) } ],
        [ set_business_account_bio  => sub { $c->set_business_account_bio('c1', $_[0], sub {}) } ],
        [ set_business_account_username => sub { $c->set_business_account_username('c1', $_[0], sub {}) } ],
        [ create_topic              => sub { $c->create_topic(-100, $_[0], sub {}) } ],
        [ edit_topic                => sub { $c->edit_topic(-100, 7, name => $_[0], sub {}) } ],
        [ text_entities             => sub { $c->text_entities($_[0], sub {}) } ],
        [ create_group              => sub { $c->create_group($_[0], sub {}) } ],
        [ 'create_group description' => sub { $c->create_group('G', description => $_[0], sub {}) } ],
        [ check_chat_username       => sub { $c->check_chat_username(-100, $_[0], sub {}) } ],
        [ invite_link               => sub { $c->invite_link(-100, name => $_[0], sub {}) } ],
        [ report_chat               => sub { $c->report_chat(-100, text => $_[0], sub {}) } ],
        [ send_contact              => sub { $c->send_contact(-100, '+1', $_[0], wait => 'accepted', sub {}) } ],
        [ create_sticker_set        => sub { $c->create_sticker_set(5, $_[0], 'set_by_bot', [{ file => 'a.png', emojis => 'x' }], sub {}) } ],
        [ set_sticker_set_title     => sub { $c->set_sticker_set_title('s', $_[0], sub {}) } ],
        [ answer_callback_query     => sub { $c->answer_callback_query('7', text => $_[0], sub {}) } ],
        [ set_commands              => sub { $c->set_commands([[ 'start', $_[0] ]], sub {}) } ],
        [ answer_inline_query       => sub { $c->answer_inline_query('7', [{ title => $_[0] }], sub {}) } ],
        [ create_story_album        => sub { $c->create_story_album(-100, $_[0], [1], sub {}) } ],
        [ set_start_page            => sub { $c->set_start_page(title => $_[0], sub {}) } ],
        [ folder_invite_link        => sub { $c->folder_invite_link(3, name => $_[0], sub {}) } ],
        [ answer_pre_checkout_query => sub { $c->answer_pre_checkout_query('7', error => $_[0], sub {}) } ],
    ) {
        my ($name, $code) = @$t;
        @sent = ();
        my $e = do { local $@; eval { $code->($ft) }; $@ };
        like $e, qr/must be a string/, "$name refuses a formattedText";
        is scalar(@sent), 0, "and $name sends nothing";
        $code->(bless {}, 'StringyName');
        like last_json(), qr/"Stringy"/, "$name takes an object that stringifies";
    }

    # a folder name is a formattedText in the TL, so one passes through there
    $c->create_folder({ name => $ft }, sub {});
    is_deeply last_req()->{folder}{name}{text}, $ft, 'a folder name may be a formattedText';
    $c->create_folder({ name => bless({}, 'StringyName') }, sub {});
    is last_req()->{folder}{name}{text}{text}, 'Stringy', 'or an object that stringifies';
    my $e = do { local $@; eval { $c->create_folder({ name => 'Work', include_group => 1 }, sub {}) }; $@ };
    like $e, qr/unknown folder field\(s\): include_group/,
        'a misspelt folder flag croaks rather than turning the flag off';

    # the bot setters clear on '' but croak with the value left out, as
    # set_bio does
    for my $m (qw(set_bot_name set_bot_description set_bot_short_description)) {
        @sent = ();
        $e = do { local $@; eval { $c->$m(sub {}) }; $@ };
        like $e, qr/needs a/, "$m with the value left out croaks";
        is scalar(@sent), 0, "and $m sends nothing";
    }
}

# --- a press on a message sent for a connected business account reached
# neither the router nor on_callback_query
{
    my $c = new_client();
    my (@routed, @handled);
    $c->on_callback_data(again => sub { push @routed, $_[0] });
    $c->on_callback_query(sub { push @handled, $_[0] });
    $c->inject_raw(q({"@type":"updateNewBusinessCallbackQuery","id":"78","sender_user_id":5,)
                 . q("connection_id":"conn1","chat_instance":"1",)
                 . q("message":{"@type":"businessMessage","message":{"@type":"message",)
                 . q("id":1048576,"chat_id":55}},)
                 . q("payload":{"@type":"callbackQueryPayloadData","data":"YWdhaW4="}}));
    is scalar(@routed), 1, 'a business press reaches the router';
    is_deeply [ @{ $routed[0] }{qw(chat_id message_id connection_id)} ], [55, 1048576, 'conn1'],
        'with its chat, its message and the connection it came through';
    is scalar(@handled), 1, 'and on_callback_query';

    # an inline query with no chat type used to plant chat_type => {} in the
    # update that on_update then received
    my $seen;
    $c->on_update(sub { $seen = $_[0] if ($_[0]{'@type'} // '') eq 'updateNewInlineQuery' });
    $c->on_inline_query(sub {});
    $c->inject_raw(q({"@type":"updateNewInlineQuery","id":"9","sender_user_id":5,"query":"x","offset":""}));
    ok !exists $seen->{chat_type}, 'reading the chat type does not create one in the update';
}

# --- the id and cursor forms round 16 left without a test
{
    my $c = new_client();
    @sent = ();
    $c->invite_link_members(-100, 'https://t.me/+x',
        offset_member => { '@type' => 'chatInviteLinkMember', user_id => 5 }, sub {});
    is last_req()->{offset_member}{user_id}, 5, 'invite_link_members pages with offset_member';
    $c->add_paid_reaction(-100, 7, 1, type => " -1001\n", sub {});
    is last_req()->{type}{chat_id}, -1001, 'a paid reaction chat id may be padded, like any id';
    $c->load_chats(10, list => " 3\n", sub {});
    is last_req()->{chat_list}{chat_folder_id}, 3, 'and so may a folder id';
    $c->send_inline_result(-100, '5', 'r1', schedule => 1700000000, sub {});
    is last_req()->{options}{scheduling_state}{send_date}, 1700000000,
        'send_inline_result schedules too';

    # each failed login() gets its own copy of the error
    my $l = new_client(bot_token => '1:x');
    my @errs;
    $l->login(sub { push @errs, $_[1] });
    $l->login(sub { push @errs, $_[1] });
    $l->inject_raw(qq({"\@type":"updateAuthorizationState","authorization_state":{"\@type":"authorizationStateWaitTdlibParameters"}}));
    @sent = ();
    $l->inject_raw(qq({"\@type":"updateAuthorizationState","authorization_state":{"\@type":"authorizationStateWaitPhoneNumber"}}));
    my $x = last_extra();
    $l->inject_raw(qq({"\@type":"error","code":400,"message":"ACCESS_TOKEN_INVALID","\@extra":"$x"}));
    is scalar(@errs), 2, 'both waiting logins fail';
    $errs[0]{message} = 'changed';
    like $errs[1]{message}, qr/ACCESS_TOKEN_INVALID/, 'and one changing its error leaves the other alone';
}

# --- senders that call back on acceptance accepted wait => 'sent' and still
# called back on acceptance, with temporary ids
{
    my $c = new_client();
    for my $t (
        [ forward_messages   => sub { $c->forward_messages(-100, -200, [1], wait => $_[0], sub {}) } ],
        [ send_inline_result => sub { $c->send_inline_result(-100, '5', 'r1', wait => $_[0], sub {}) } ],
        [ send_quick_reply   => sub { $c->send_quick_reply(-100, 7, wait => $_[0], sub {}) } ],
    ) {
        my ($name, $code) = @$t;
        my $e = do { local $@; eval { $code->('sent') }; $@ };
        like $e, qr/cannot wait for delivery/, "$name refuses wait => 'sent'";
        ok eval { $code->('accepted'); 1 }, "and takes wait => 'accepted', which is what it does"
            or diag $@;
    }
}

# --- Carp trusts along @ISA, which a mixin lacks, so a croak raised in one
# mixin's method on behalf of another named a line inside the module
{
    my $file = __FILE__;
    for my $t (['send_gift',  sub { $td->send_gift('g1', 42, text => [1], sub {}) }],
               ['post_story', sub { $td->post_story(-100, 'p.jpg', caption => [1], sub {}) }]) {
        my ($name, $code) = @$t;
        my $e = do { local $@; eval { $code->() }; $@ };
        like $e, qr/ at \Q$file\E line \d+/, "$name: the croak names the caller's line";
    }
}

# --- username and sticker slots refuse references instead of stringifying them
{
    my $e = do { local $@; eval { $td->chat_by_username([]) }; $@ };
    like $e, qr/a username must be a string/, 'chat_by_username refuses a ref';

    $e = do { local $@; eval { $td->user_by_username([]) }; $@ };
    like $e, qr/a username must be a string/, 'user_by_username refuses a ref';

    $e = do { local $@; eval { $td->custom_emoji_stickers([{}]) }; $@ };
    like $e, qr/each of custom_emoji_ids must be a string/, 'sticker_id_list refuses ref elements';

    $e = do { local $@; eval { $td->create_sticker_set(1, 't', 'n', [{ file => 'f', emojis => 'e', keywords => [{}] }]) }; $@ };
    like $e, qr/each of keywords must be a string/, 'new_sticker refuses ref elements in keywords';

    $e = do { local $@; eval { $td->create_sticker_set(1, 't', 'n', [{ file => 'f', emojis => 'e', keywords => 'cat' }]) }; $@ };
    like $e, qr/keywords must be an arrayref at \Q${\__FILE__}\E/,
        'and a keywords string croaks at the call site rather than dying inside';

    # bytes slots: a defined ref passed every presence check and went out as
    # the base64 of "HASH(0x...)"
    $e = do { local $@; eval { $td->press(-100, 5, [], sub {}) }; $@ };
    like $e, qr/callback data must be a string/, 'press refuses a ref as data';

    $e = do { local $@; eval { EV::Telegram::TDLib->inline_keyboard(
        [ [ { text => 'x', data => {} } ] ]) }; $@ };
    like $e, qr/callback button data must be a string/,
        'a keyboard button refuses a ref as data';
}

# --- asynchronous request methods must never leak callback return values on format errors
{
    my $cb = sub { return 42 };
    is $td->post_story(-100, 'p.jpg', caption => '*bold', parse_mode => 'markdown', $cb),
        undef, 'post_story returns undef on format error';
    is $td->edit_story(-100, 1, caption => '*bold', parse_mode => 'markdown', $cb),
        undef, 'edit_story returns undef on format error';
    is $td->set_draft(-100, '*bold', parse_mode => 'markdown', $cb),
        undef, 'set_draft returns undef on format error';
    is $td->edit_message_caption(-100, 1, '*bold', parse_mode => 'markdown', $cb),
        undef, 'edit_message_caption returns undef on format error';
    is $td->send_gift('gift1', 1, text => '*bold', parse_mode => 'markdown', $cb),
        undef, 'send_gift returns undef on format error';
    is $td->edit_inline_caption('inline1', '*bold', parse_mode => 'markdown', $cb),
        undef, 'edit_inline_caption returns undef on format error';
}

done_testing;
