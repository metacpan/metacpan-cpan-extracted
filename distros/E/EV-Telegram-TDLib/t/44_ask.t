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
sub last_req { Cpanel::JSON::XS->new->utf8->decode($sent[-1]) }
sub last_extra { last_req()->{'@extra'} }

sub pump {
    my $t = EV::timer 0.05, 0, sub { EV::break };
    EV::run;
}

sub new_client {
    return EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-ask', @_);
}

# the prompt send must succeed before an ask is installed
sub ok_send { my ($td) = @_;
    $td->inject_raw(qq({"\@type":"message","id":9,"\@extra":"@{[last_extra()]}"})) }

sub msg {
    my ($text, %opt) = @_;
    my $user = $opt{user} // 42;
    my $chat = $opt{chat} // -100;
    my $out  = $opt{outgoing} ? 'true' : 'false';
    my $sender = $opt{from_chat}
        ? qq({"\@type":"messageSenderChat","chat_id":$chat})
        : qq({"\@type":"messageSenderUser","user_id":$user});
    my $entities = '';
    if ($text =~ /\A(\/\S+)/) {
        my $len = length $1;
        $entities = qq(,"entities":[{"\@type":"textEntity","offset":0,)
                  . qq("length":$len,"type":{"\@type":"textEntityTypeBotCommand"}}]);
    }
    return qq({"\@type":"updateNewMessage","message":{"\@type":"message",)
         . qq("id":1,"chat_id":$chat,"is_outgoing":$out,"sender_id":$sender,)
         . qq("content":{"\@type":"messageText","text":{"\@type":"formattedText",)
         . qq("text":"$text"$entities}}}});
}

# --- the happy path
{
    @sent = ();
    my $td = new_client();
    my ($got, $err);
    $td->ask(-100, 42, 'your name?', sub { ($got, $err) = @_ });
    is last_req()->{'@type'}, 'sendMessage', 'ask sends the prompt';
    ok_send($td);
    $td->inject_raw(msg('Ada'));
    is $got->{content}{text}{text}, 'Ada', 'the answer reaches the callback';
    ok !defined $err, 'with no error';
}

# --- only that user, in that chat
{
    @sent = ();
    my $td = new_client();
    my $got;
    $td->ask(-100, 42, 'q', sub { $got = $_[0] });
    ok_send($td);
    $td->inject_raw(msg('nope', user => 43));
    ok !defined $got, 'another user in the same chat does not answer';
    $td->inject_raw(msg('nope', chat => -200));
    ok !defined $got, 'the same user in another chat does not answer';
    $td->inject_raw(msg('yes'));
    ok defined $got, 'the right user in the right chat does';
}

# --- an anonymous or channel sender never matches
{
    @sent = ();
    my $td = new_client();
    my $got;
    $td->ask(-100, 42, 'q', sub { $got = $_[0] });
    ok_send($td);
    $td->inject_raw(msg('anon', from_chat => 1));
    ok !defined $got, 'a messageSenderChat message never satisfies an ask';
}

# --- outgoing messages never match
{
    @sent = ();
    my $td = new_client();
    my $got;
    $td->ask(-100, 42, 'q', sub { $got = $_[0] });
    ok_send($td);
    $td->inject_raw(msg('mine', outgoing => 1));
    ok !defined $got, 'an outgoing message never satisfies an ask';
}

# --- a second ask displaces the first, which is told rather than dropped
{
    @sent = ();
    my $td = new_client();
    my ($err1, $got2);
    $td->ask(-100, 42, 'first', sub { $err1 = $_[1] });
    ok_send($td);
    $td->ask(-100, 42, 'second', sub { $got2 = $_[0] });
    ok_send($td);
    like $err1->{message}, qr/superseded/, 'the displaced ask is failed, not lost';
    $td->inject_raw(msg('answer'));
    ok defined $got2, 'and the newer ask receives the answer';
}

# --- cancel_ask
{
    @sent = ();
    my $td = new_client();
    my $err;
    $td->ask(-100, 42, 'q', sub { $err = $_[1] });
    ok_send($td);
    ok $td->cancel_ask(-100, 42), 'cancel_ask reports that one was pending';
    like $err->{message}, qr/cancelled/, 'and fails it with a cancelled error';
    ok !$td->cancel_ask(-100, 42), 'cancelling nothing reports false';
}

# --- a failed prompt send fails the ask immediately and installs nothing
{
    @sent = ();
    my $td = new_client();
    my ($got, $err);
    $td->ask(-100, 42, 'q', sub { ($got, $err) = @_ });
    $td->inject_raw(
        qq({"\@type":"error","code":400,"message":"CHAT_WRITE_FORBIDDEN",)
      . qq("\@extra":"@{[last_extra()]}"}));
    like $err->{message}, qr/CHAT_WRITE_FORBIDDEN/,
        'a failed prompt fails the ask straight away';
    ok !$td->cancel_ask(-100, 42), 'and no ask was left installed';
}

# --- asking again from inside the answer callback must survive
{
    @sent = ();
    my $td = new_client();
    my @answers;
    my $second;
    $td->ask(-100, 42, 'first', sub {
        push @answers, $_[0]{content}{text}{text};
        $td->ask(-100, 42, 'second', sub { $second = $_[0] });
    });
    ok_send($td);
    $td->inject_raw(msg('one'));
    ok_send($td);
    $td->inject_raw(msg('two'));
    is_deeply \@answers, ['one'], 'the first ask answered once';
    ok defined $second, 'and the ask made from inside its callback still works';
}

# --- the timeout fires and clears
{
    @sent = ();
    my $td = new_client();
    my $err;
    $td->ask(-100, 42, 'q', timeout => 0.05, sub { $err = $_[1] });
    ok_send($td);
    pump();
    like $err->{message}, qr/timed out|timeout/, 'the ask times out';
    ok !$td->cancel_ask(-100, 42), 'and is cleared when it does';
}

# --- asking again from inside the timeout callback must survive too
{
    @sent = ();
    my $td = new_client();
    my $again;
    $td->ask(-100, 42, 'q', timeout => 0.05, sub {
        $td->ask(-100, 42, 'retry', sub { $again = $_[0] });
    });
    ok_send($td);
    pump();
    ok_send($td);
    $td->inject_raw(msg('late'));
    ok defined $again, 'an ask made from inside the timeout callback survives';
}

# --- an answer is not offered to the command router, but on_message still sees it
{
    @sent = ();
    my $td = new_client();
    my ($cmd, $any, $got) = (0, 0);
    $td->on_command(cancel => sub { $cmd++ });
    $td->on_message(sub { $any++ });
    $td->ask(-100, 42, 'q', sub { $got = $_[0] });
    ok_send($td);
    $any = 0;
    $td->inject_raw(msg('/cancel'));
    ok defined $got, 'a slash-leading answer still answers the ask';
    is $cmd, 0, 'and is not also dispatched as a command';
    is $any, 1, 'while on_message still sees it';
}

# --- with no ask pending the same message routes as a command
{
    @sent = ();
    my $td = new_client();
    my $cmd = 0;
    $td->on_command(cancel => sub { $cmd++ });
    $td->inject_raw(msg('/cancel'));
    is $cmd, 1, 'with nothing pending the command routes normally';
}

# --- close() fails a pending ask.
# wait => accepted settles the prompt outright: with the default wait => sent
# the prompt callback stays parked in cache{sending}, and close would fail the
# ask through that path with an identically worded error even if the asks
# drain were deleted entirely.
{
    @sent = ();
    my $td = new_client();
    my $err;
    $td->ask(-100, 42, 'q', wait => 'accepted', sub { $err = $_[1] });
    ok_send($td);
    is scalar(keys %{ $td->{pending} || {} }), 0, 'nothing left pending';
    is scalar(keys %{ $td->{cache}{sending} || {} }), 0, 'and nothing parked in sending';
    $td->closed;
    is $err->{message}, 'client closed', 'close fails a pending ask';
    is scalar(keys %{ $td->{asks} || {} }), 0, 'and forgets it';
}

# --- the documented default timeout of 300s must actually be 300s
{
    @sent = ();
    my $td = new_client();
    $td->ask(-100, 42, 'q', sub {});
    ok_send($td);
    my $entry = $td->{asks}{'-100:42'};
    ok $entry && $entry->{timer}, 'a default ask arms a timer';
    # both ends: "> 250" alone was satisfied by 260 and by 3000 alike, so it
    # pinned nothing like the documented default. A second of slack each way,
    # because remaining() is a clock reading: "<= 300" had none and a CI
    # runner duly came back a hair over
    cmp_ok $entry->{timer}->remaining, '>', 299,
        'whose deadline is the documented 300 seconds, not something shorter';
    cmp_ok $entry->{timer}->remaining, '<', 301, 'and not something longer';
}

# --- a prompt that fails synchronously must not leave an ask installed.
# send_message reports a parse_mode failure before it returns, so the failure
# arrives while ask() is still mid-call, before it would install the entry.
{
    @sent = ();
    my $td = new_client();
    my $calls = 0;
    $td->ask(-100, 42, '*bold', parse_mode => 'markdown', sub { $calls++ });
    is $calls, 1, 'a synchronously failing prompt fails the ask once';
    ok !$td->cancel_ask(-100, 42), 'and leaves no ask installed';
    is $calls, 1, 'so the callback is never invoked a second time';
}

# --- the ask is keyed on the numeric ids, not on how they were spelled
{
    @sent = ();
    my $td = new_client();
    my $got;
    # '007' and '+42' interpolate differently from the integers the update
    # carries, so these fail unless the key is numified; '-100'/'42' would
    # pass either way and prove nothing
    $td->ask('-0100', '0042', 'q', sub { $got = $_[0] });
    ok_send($td);
    $td->inject_raw(msg('answer'));
    ok defined $got, 'ids spelled unusually still match the numeric update';

    @sent = ();
    my $td2 = new_client();
    $td2->ask(-100, 42, 'q', sub {});
    ok_send($td2);
    ok $td2->cancel_ask('+42' - 0 + -142, '0042'),
        'and cancel_ask finds it however the ids are spelled';
}

# --- a prompt that fails at the server (not synchronously) must only touch
# its own ask. Between the send and the reply the entry may have been
# cancelled or replaced, and acting on whatever sits at the key strands a
# callback that is still owed an answer.
sub err_reply { my ($x) = @_;
    qq({"\@type":"error","code":400,"message":"CHAT_WRITE_FORBIDDEN","\@extra":"$x"}) }

{
    @sent = ();
    my $td = new_client();
    my @fires;
    $td->ask(-100, 42, 'q', sub { push @fires, $_[1]{message} // 'ok' });
    my $x = last_extra();
    $td->cancel_ask(-100, 42);
    $td->inject_raw(err_reply($x));
    is scalar(@fires), 1,
        'a cancelled ask is not fired again when its prompt fails late';
    like $fires[0], qr/cancelled/, 'and the one firing is the cancellation';
}

{
    @sent = ();
    my $td = new_client();
    my (@first, @second);
    $td->ask(-100, 42, 'first', sub { push @first, $_[1]{message} // 'ok' });
    my $x1 = last_extra();
    $td->ask(-100, 42, 'second',
             sub { push @second, $_[0] ? 'answered' : ($_[1]{message} // '?') });
    ok_send($td);
    $td->inject_raw(err_reply($x1));    # the displaced ask's prompt fails late

    is scalar(@first), 1, 'the displaced ask fires once, on being superseded';
    $td->inject_raw(msg('hello'));
    is_deeply \@second, ['answered'],
        'and the ask that replaced it still receives its answer';
}

# --- a croak inside ask() must leave nothing armed. send_message croaks on a
# bad parse_mode or wait mode, and an ask installed before that point would
# then answer a call that died, as a success.
{
    @sent = ();
    my $td = new_client();
    my @fires;
    my $died = 0;
    eval { $td->ask(-100, 42, 'q', parse_mode => 'Markdown',
                    sub { push @fires, $_[0] ? 'answered' : 'err' }); 1 }
        or $died = 1;
    ok $died, 'a bad parse_mode croaks out of ask';
    is scalar(@sent), 0, 'and sends nothing';
    ok !$td->cancel_ask(-100, 42), 'and leaves no ask armed';

    $td->inject_raw(msg('hello'));
    is_deeply \@fires, [], 'so a later message answers nothing';
}

# --- an ask issued from inside the supersede callback must not be dropped.
# The outer ask installs after sending, by which time the inner one is
# already at the key: overwriting it stranded its callback and left its
# timer alive to kill whatever came next.
{
    @sent = ();
    my $td = new_client();
    my (@inner, @outer);
    $td->ask(-100, 42, 'first', sub {
        my (undef, $err) = @_;
        return unless $err;
        # re-ask on being superseded, the natural retry shape
        $td->ask(-100, 42, 'inner', sub { push @inner, $_[1] ? 'err' : 'answered' });
    });
    ok_send($td);
    $td->ask(-100, 42, 'outer', sub { push @outer, $_[1] ? 'err' : 'answered' });
    ok_send($td);

    is scalar(@inner), 1, 'the inner ask is told it was displaced';
    $td->inject_raw(msg('hello'));
    is_deeply \@outer, ['answered'], 'and the surviving ask gets the answer';
}

# --- two levels of re-ask. The supersede callback fired while installing may
# itself install, and overwriting that entry would strand its callback and
# leave its timer running to kill whatever came next.
{
    @sent = ();
    my $td = new_client();
    my (@a, @b, @c);
    $td->ask(-100, 42, 'a', sub { push @a, $_[1] ? 'err' : 'answered' });
    ok_send($td);
    $td->ask(-100, 42, 'b', sub {
        my (undef, $err) = @_;
        push @b, $err ? 'err' : 'answered';
        return unless $err;
        $td->ask(-100, 42, 'c', sub { push @c, $_[1] ? 'err' : 'answered' });
    });
    ok_send($td);
    $td->ask(-100, 42, 'd', sub {});     # displaces b, whose callback asks c
    ok_send($td);

    is_deeply \@a, ['err'], 'the first displaced ask was told';
    is_deeply \@b, ['err'], 'the displaced ask was told';
    is_deeply \@c, ['err'], 'the inner re-ask was displaced and told';
}

# --- the sharp version: an entry discarded while installing leaves its timer
# running, and that timer later kills whatever ask occupies the key.
{
    @sent = ();
    my $td = new_client();
    $td->ask(-100, 42, 'first', sub {
        my (undef, $err) = @_;
        return unless $err;
        # a short-lived ask made from the supersede callback; if the outer
        # install discards it without stopping this timer, the timer survives
        $td->ask(-100, 42, 'ghost', timeout => 0.05, sub {});
    });
    ok_send($td);
    $td->ask(-100, 42, 'second', sub {});   # displaces first, which asks ghost
    ok_send($td);

    my $err;
    $td->ask(-100, 42, 'victim', timeout => 30, sub { $err = $_[1] });
    ok_send($td);
    pump();
    pump();
    ok !$err, 'a long-lived ask is not killed by a discarded ask\'s timer';
    ok $td->cancel_ask(-100, 42), 'and it is still pending';
}

# --- and the same at a second level of re-asking, where the displaced ask's
# own supersede callback re-asks while we are still displacing
{
    @sent = ();
    my $td = new_client();
    # deeper than the displacement bound, so the give-up path is exercised
    # too: nobody may be stranded and no timer may outlive its entry
    my @told;
    my $reask;
    $reask = sub {
        my ($depth) = @_;
        # stops just past the bound, so the give-up path runs and nothing
        # re-asks afterwards to mask a stranded entry
        return if $depth > 34;
        $td->ask(-100, 42, "level$depth", timeout => 0.05, sub {
            my (undef, $err) = @_;
            return unless $err;
            push @told, $depth;
            $reask->($depth + 1);
        });
    };
    $reask->(1);
    ok_send($td);

    my $err;
    $td->ask(-100, 42, 'victim', timeout => 30, sub { $err = $_[1] });
    ok_send($td);
    pump();
    pump();

    # an entry dropped at the bound must have had its timer stopped, or it
    # fires later and kills whoever holds the key
    ok !$err, 'an entry dropped at the bound does not kill a later ask';
    ok exists $td->{asks}{'-100:42'}, 'and it is still pending';
    is scalar(@told), scalar(keys %{ { map { $_ => 1 } @told } }),
        'no ask in the chain was told twice';
    # exact, not a lower bound: the chain reaches the bound on its own and
    # tells one more only if the give-up path runs, so >= 33 would pass
    # with the give-up path removed
    is scalar(@told), 34,
        'the entry dropped at the bound was told, not silently discarded';
}

# --- why the give-up answer is deferred rather than made inline. The dropped
# entry's callback may itself ask, and an inline answer would run it before
# this call installs its own entry -- so the assignment below would clobber
# what the callback installed, stranding it with its timer armed to fire on
# whoever holds the key next. Deferring puts the callback after the install,
# where its ask supersedes cleanly.
{
    @sent = ();
    my $td = new_client();
    my @told;
    my ($reask, $done);
    $reask = sub {
        my ($depth) = @_;
        return if $done || $depth > 40;
        $td->ask(-100, 42, "level$depth", timeout => 0.05, sub {
            my (undef, $err) = @_;
            return unless $err;
            push @told, $depth;
            $reask->($depth + 1);
        });
    };
    $reask->(1);
    ok_send($td);

    my $msg;
    $td->ask(-100, 42, 'victim', timeout => 30, sub { $msg = $_[1]{message} });
    ok_send($td);
    pump() for 1 .. 3;

    # answered inline, the re-ask is orphaned and its timer finishes whoever
    # holds the key -- which is this ask, killed by a timeout it never set
    is $msg, 'ask superseded',
        'the ask made inside the give-up callback supersedes rather than strands';
    cmp_ok scalar(@told), '>', 34,
        'and the chain continues past the entry that was dropped';
    # the chain's last ask is still armed; left alone it keeps re-asking inside
    # later blocks' loops and pushing into their @sent
    $done = 1;
    $td->closed;
}

# --- each displaced callback gets its own error object; a shared one lets a
# callback that annotates the error corrupt what the rest of the chain sees
{
    @sent = ();
    my $td = new_client();
    my @seen;
    my $reask;
    $reask = sub {
        my ($depth) = @_;
        return if $depth > 4;
        $td->ask(-100, 42, "level$depth", timeout => 30, sub {
            my (undef, $err) = @_;
            return unless $err;
            push @seen, $err->{message};
            $err->{message} .= "[$depth]";
            $reask->($depth + 1);
        });
    };
    $reask->(1);
    ok_send($td);
    $td->ask(-100, 42, 'last', timeout => 30, sub {});
    ok_send($td);
    is_deeply \@seen, [ ('ask superseded') x 4 ],
        'no displaced callback sees another callback of its own chain';
}

# --- an ask timeout armed after the process blocked outside the loop must be
# measured from now, not from the stale ev_now. ev_now is only refreshed
# inside ev_run, so without the refresh the timer is already expired when it
# is armed and the ask fails instantly, before TDLib could possibly answer.
{
    my $td = new_client();
    EV::now_update();
    my $t0 = EV::now;
    select undef, undef, undef, 1.0;
    my ($err, $fired_at);
    $td->ask(-100, 42, 'still there?', timeout => 0.4, sub {
        $err = $_[1];
        $fired_at = EV::now;
        EV::break;
    });
    EV::run;
    is $err->{message}, 'ask timed out', 'the ask timeout still fires';
    cmp_ok $fired_at - $t0, '>', 1.2,
        'the full timeout elapsed despite the stale ev_now';
}

done_testing;
