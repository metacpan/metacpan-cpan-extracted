use strict;
use warnings;
use Test::More;
use EV;
use EV::Telegram::TDLib;

# _set_dispatch swaps before dropping the old ref: a DESTROY that
# re-enters from the dec must see the new value, not a dangling pointer
my $reentered = 0;
{
    package TDReenter;
    sub DESTROY {
        $reentered++;
        EV::Telegram::TDLib::_set_dispatch(sub { });
    }
}
# the coderef must close over something: a capture-less anon sub is a pad
# constant and its DESTROY would only fire at global destruction
my $keep = 1;
my $cb = bless(sub { $keep }, 'TDReenter');
EV::Telegram::TDLib::_set_dispatch($cb);
undef $cb;
EV::Telegram::TDLib::_set_dispatch(sub { });
is $reentered, 1, 'DESTROY re-entered _set_dispatch during the swap';

# a dying dispatch plus a dying __WARN__ hook must not unwind the drain
# and leak the rest of the queue
my $calls = 0;
my $hook_calls = 0;
EV::Telegram::TDLib::_set_dispatch(sub { $calls++; die "dispatch boom\n" });

my $id = EV::Telegram::TDLib::_create_client_id();
ok $id > 0, 'client created';
EV::Telegram::TDLib::_send($id, '{"@type":"getOption","name":"version"}');
EV::Telegram::TDLib::_send($id, '{"@type":"getOption","name":"version"}');

{
    local $SIG{__WARN__} = sub { $hook_calls++; die "warn hook boom\n" };
    # the loop has not run yet, so ev_now is still the time EV was loaded, and
    # under valgrind loading the module alone eats most of the watchdog
    EV::now_update();
    my $poll = EV::timer 0.05, 0.05, sub { EV::break if $calls >= 2 };
    my $watchdog = EV::timer 10, 0, sub { EV::break };
    EV::run;
}

cmp_ok $calls, '>=', 2,
    'every queued message was dispatched despite dying dispatch and __WARN__';
cmp_ok $hook_calls, '>=', 2,
    'each dispatch failure still reached the warn hook';

# An exception object may overload "" or bool with something that dies. The
# drain inspects $@ outside its own eval, so a dying overload would escape
# from C, skipping the frees for the rest of the detached batch.
for my $kind (qw(stringify boolify)) {
    my $pkg = "TDNasty\u$kind";
    my $body = $kind eq 'stringify'
        ? q{use overload '""' => sub { die "boom\n" }, fallback => 0;}
        : q{use overload 'bool' => sub { die "boom\n" },
                         '""'   => sub { 'nasty' }, fallback => 0;};
    eval "package $pkg; $body sub new { bless {}, shift } 1" or die $@;

    my $n = 0;
    EV::Telegram::TDLib::_set_dispatch(sub { $n++; die $pkg->new });
    # the client above, not a fresh one: an unclosed client would show up in
    # xt/teardown_audit.t as materialised at exit
    EV::Telegram::TDLib::_send($id, '{"@type":"getOption","name":"version"}');
    EV::Telegram::TDLib::_send($id, '{"@type":"getOption","name":"version"}');

    my $escaped = 0;
    {
        local $SIG{__WARN__} = sub { };
        my $poll = EV::timer 0.05, 0.05, sub { EV::break if $n >= 2 };
        my $watchdog = EV::timer 10, 0, sub { EV::break };
        eval { EV::run; 1 } or $escaped = 1;
    }
    ok !$escaped, "a dying $kind overload does not escape the drain";
    cmp_ok $n, '>=', 2, 'and the rest of the batch is still dispatched';
}

EV::Telegram::TDLib::_set_dispatch(\&EV::Telegram::TDLib::dispatch_raw);

# --- drain_error routes a dispatch death to the client's on_error
my @derr;
my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', auto_auth => 0,
    database_directory => 't/tmp-drain',
    on_error => sub { push @derr, $_[0] },
);
EV::Telegram::TDLib::drain_error($td->{client_id}, 'dispatch died: boom');
is scalar @derr, 1, 'a dispatch death reaches on_error';
like $derr[0], qr/dispatch died: boom/, 'on_error carries the drain message';

# an unknown client id falls back to warn
my @dwarn;
{
    local $SIG{__WARN__} = sub { push @dwarn, $_[0] };
    EV::Telegram::TDLib::drain_error(999999, 'dispatch died: stray');
}
is scalar @dwarn, 1, 'a clientless dispatch death warns';
like $dwarn[0], qr/dispatch died: stray/, 'the fallback warning carries the message';

# a dying on_error must not propagate out of the helper
$td->on_error(sub { die "on_error boom\n" });
my @dwarn2;
my $lived = do {
    local $SIG{__WARN__} = sub { push @dwarn2, $_[0] };
    eval { EV::Telegram::TDLib::drain_error($td->{client_id}, 'dispatch died: again'); 1 };
};
ok $lived, 'a dying on_error does not unwind the drain helper';
is scalar @dwarn2, 1, 'a dying on_error falls back to warn';
like $dwarn2[0], qr/dispatch died: again/, 'the fallback warning carries the message';

# a raw client id is not in %CLIENTS, so the END-block shutdown never closes
# it; leaving TDLib a live client at exit aborts while its statics tear down
{
    my $shut_done = 0;
    EV::Telegram::TDLib::_set_dispatch(sub {
        my (undef, $json) = @_;
        $shut_done = 1 if $json =~ /authorizationStateClosed/;
        EV::break if $shut_done;
    });
    EV::Telegram::TDLib::_send($id, '{"@type":"close"}');
    # bound on the flag, not the clock: RUN_ONCE with no events left blocks
    my $shut_late = 0;
    my $shut_w = EV::timer 15, 0, sub { $shut_late = 1; EV::break };
    EV::run(EV::RUN_ONCE) while !$shut_done && !$shut_late;
    $shut_w->stop;
    EV::Telegram::TDLib::_set_dispatch(\&EV::Telegram::TDLib::dispatch_raw);
    ok $shut_done, 'the raw client closed before exit';
}

# TDLib always sends an object, but the decoder allows nonref, so a bare
# scalar or an array must be reported rather than treated as a hash
{
    my @shape;
    my $td2 = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x',
        database_directory => 't/tmp-dispatch-shape',
        on_error => sub { push @shape, $_[0] },
    );
    for my $payload ('[]', '"a string"', '42') {
        my $lived = eval { $td2->inject_raw($payload); 1 };
        ok $lived, "a non-object payload ($payload) does not die";
    }
    is scalar @shape, 3, 'each non-object payload was reported';
    like $shape[0], qr/not an object/, 'the error says what was wrong';
}

# updates that arrive without the id their handler keys on must be ignored,
# not filed under the empty string where a later lookup could collide
{
    my @noise;
    local $SIG{__WARN__} = sub { push @noise, $_[0] };
    my $td3 = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x',
        database_directory => 't/tmp-dispatch-ids',
        on_error => sub { },
    );
    my @idless = (
        '{"@type":"updateFile","file":{}}',
        '{"@type":"updateMessageSendSucceeded"}',
        '{"@type":"updateMessageSendFailed"}',
        '{"@type":"updateChatTitle"}',
        '{"@type":"updateChatPosition"}',
    );
    $td3->inject_raw($_) for @idless;
    diag "  unexpected warning: $_" for @noise;
    is scalar @noise, 0, 'an id-less update warns nothing from inside the module';
    is scalar keys %{ $td3->{cache}{sending} || {} }, 0,
        'no empty-string key was created in the sending table';
}

# how far a dying callback reaches depends on whether the module guards it,
# and the docs described one rule for both: a guarded die must not be a way
# to stop the plain handlers from seeing the same update
{
    my $text = q({"@type":"updateNewMessage","message":{"@type":"message",)
             . q("id":1,"chat_id":-100,"content":{"@type":"messageText",)
             . q("text":{"@type":"formattedText","text":"/hi"}}}});

    my (@order, @errs);
    my $g = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-contain',
        on_error => sub { push @errs, $_[0] },
    );
    $g->on_command(hi => sub { push @order, 'command'; die "boom\n" });
    $g->on_message(sub { push @order, 'on_message' });
    $g->on_update(sub { push @order, 'on_update' });
    $g->inject_raw($text);
    is_deeply \@order, [qw(command on_message on_update)],
        'a die in a guarded callback leaves the rest of the update running';
    like $errs[0], qr/a callback died/, 'and is reported as a callback death';

    my @order2;
    my $p = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-contain',
        on_error => sub { },
    );
    $p->on_message(sub { push @order2, 'on_message'; die "boom\n" });
    $p->on_update(sub { push @order2, 'on_update' });
    my $escaped = do { local $@; eval { $p->inject_raw($text); 1 } ? '' : $@ };
    is_deeply \@order2, ['on_message'],
        'a die in a plain handler skips the rest of that update';
    like $escaped, qr/boom/, 'because it leaves the dispatch, which the drain catches';
}

done_testing;
