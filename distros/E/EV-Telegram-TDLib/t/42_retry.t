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

# Run the loop for a bounded slice: a plain EV::run would block forever when
# the feature under test has not armed a timer, hanging instead of failing.
sub pump {
    my $t = EV::timer 0.05, 0, sub { EV::break };
    EV::run;
}

sub new_client {
    return EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-retry', @_);
}

sub flood {
    my ($extra, $seconds) = @_;
    return qq({"\@type":"error","code":429,)
         . qq("message":"Too Many Requests: retry after $seconds","\@extra":"$extra"});
}

# margin => 0 keeps the tests fast; the real default adds a second of its own
my %FAST = (attempts => 3, margin => 0);

# --- without retry the 429 reaches the caller untouched, as it does today
{
    @sent = ();
    my $td = new_client();
    my ($res, $err);
    $td->send({ '@type' => 'getMe' }, sub { ($res, $err) = @_ });
    $td->inject_raw(flood(last_extra(), 5));
    is $err->{code}, 429, 'without retry a 429 is delivered to the caller';
    is scalar(@sent), 1, 'and nothing is re-sent';
}

# --- retry re-sends, with a fresh @extra
{
    @sent = ();
    my $td = new_client();
    my ($res, $err);
    $td->send({ '@type' => 'getMe' }, sub { ($res, $err) = @_ }, retry => \%FAST);
    my $first = last_extra();
    $td->inject_raw(flood($first, 0));
    pump();
    is scalar(@sent), 2, 'a 429 with a delay is retried';
    isnt last_extra(), $first, 'the retry carries a new @extra';
    ok !defined $err, 'and the caller has not been told yet';

    $td->inject_raw(qq({"\@type":"user","id":7,"\@extra":"@{[last_extra()]}"}));
    is $res->{id}, 7, 'the eventual success reaches the original callback';
}

# --- a 429 with no parseable delay is not retried
{
    @sent = ();
    my $td = new_client();
    my $err;
    $td->send({ '@type' => 'getMe' }, sub { $err = $_[1] }, retry => \%FAST);
    $td->inject_raw(
        qq({"\@type":"error","code":429,"message":"slow down","\@extra":"@{[last_extra()]}"}));
    pump();
    is scalar(@sent), 1, 'a 429 without a stated delay is not retried';
    is $err->{code}, 429, 'and is returned to the caller';
}

# --- other error codes are never retried
{
    @sent = ();
    my $td = new_client();
    my $err;
    $td->send({ '@type' => 'getMe' }, sub { $err = $_[1] }, retry => \%FAST);
    $td->inject_raw(
        qq({"\@type":"error","code":400,"message":"retry after 1","\@extra":"@{[last_extra()]}"}));
    pump();
    is scalar(@sent), 1, 'a non-429 is never retried even if it says retry after';
    is $err->{code}, 400, 'and is returned unchanged';
}

# --- max_wait is a give-up threshold, not a clamp
{
    @sent = ();
    my $td = new_client();
    my $err;
    $td->send({ '@type' => 'getMe' }, sub { $err = $_[1] },
              retry => { attempts => 3, max_wait => 10, margin => 0 });
    $td->inject_raw(flood(last_extra(), 300));
    pump();
    is scalar(@sent), 1,
        'a delay longer than max_wait is not retried sooner: it is not retried at all';
    is $err->{code}, 429, 'the 429 is returned unchanged';
    like $err->{message}, qr/retry after 300/, 'with the server message intact';
}

# --- the chain gives up after attempts and returns the last error
{
    @sent = ();
    my $td = new_client();
    my $err;
    $td->send({ '@type' => 'getMe' }, sub { $err = $_[1] },
              retry => { attempts => 2, margin => 0 });
    for my $i (1 .. 3) {
        $td->inject_raw(flood(last_extra(), 0));
        pump();
    }
    is scalar(@sent), 3, 'attempts => 2 means the first send plus two retries';
    is $err->{code}, 429, 'and the last error is returned';
}

# --- close() must fail a request that is waiting out a backoff
{
    @sent = ();
    my $td = new_client();
    my $err;
    $td->send({ '@type' => 'getMe' }, sub { $err = $_[1] },
              retry => { attempts => 3, margin => 30 });
    $td->inject_raw(flood(last_extra(), 30));   # still waiting when we close
    ok !defined $err, 'the request is waiting out the backoff';
    $td->closed;
    is $err->{message}, 'client closed',
        'close fails a backing-off request rather than losing it';
}

# --- call() accepts the same option tail
{
    @sent = ();
    my $td = new_client();
    $td->call('getMe', {}, sub {}, retry => \%FAST);
    $td->inject_raw(flood(last_extra(), 0));
    pump();
    is scalar(@sent), 2, 'call() honours retry rather than dropping the option';
}

# --- a constructor default applies to every request
{
    @sent = ();
    my $td = new_client(retry => \%FAST);
    $td->send({ '@type' => 'getMe' }, sub {});
    $td->inject_raw(flood(last_extra(), 0));
    pump();
    is scalar(@sent), 2, 'a constructor retry default is honoured';
}

# --- the documented defaults must be the actual defaults
{
    @sent = ();
    my $td = new_client();
    my $err;
    # only the margin is overridden, so this pins the default attempts of 3
    $td->send({ '@type' => 'getMe' }, sub { $err = $_[1] }, retry => { margin => 0 });
    for (1 .. 4) {
        $td->inject_raw(flood(last_extra(), 0));
        pump();
    }
    is scalar(@sent), 4, 'the default attempts of 3 means four requests in all';
    is $err->{code}, 429, 'and the last error reaches the caller';
}

{
    # the default margin is 1s, so a 0-second flood still waits about a second
    @sent = ();
    my $td = new_client();
    $td->send({ '@type' => 'getMe' }, sub {}, retry => 1);
    $td->inject_raw(flood(last_extra(), 0));
    pump();
    is scalar(@sent), 1,
        'the default margin delays the retry past a 50ms pump';
    # the retry is still armed a second out; left alone it fires inside some
    # later block's loop and lands in that block's @sent
    $td->closed;
}

{
    # factor lengthens the margin on repeated 429s
    @sent = ();
    my $td = new_client();
    $td->send({ '@type' => 'getMe' }, sub {},
              retry => { attempts => 3, margin => 0.02, factor => 100 });
    $td->inject_raw(flood(last_extra(), 0));
    pump();
    is scalar(@sent), 2, 'the first retry fires within the pump';
    $td->inject_raw(flood(last_extra(), 0));
    pump();
    is scalar(@sent), 2,
        'the second waits longer, so factor is applied rather than ignored';
    $td->closed;
}

# --- retry is a send()/call() option; a named method has its own %opt
# namespace and does not forward it. The client-wide default does reach them,
# which is the documented way to cover everything.
{
    @sent = ();
    my $td = new_client();
    $td->send_message(-100, 'hi', retry => \%FAST, sub {});
    $td->inject_raw(flood(last_extra(), 0));
    pump();
    is scalar(@sent), 1, 'a named method ignores a per-call retry';

    @sent = ();
    my $wide = new_client(retry => \%FAST);
    $wide->send_message(-100, 'hi', sub {});
    $wide->inject_raw(flood(last_extra(), 0));
    pump();
    is scalar(@sent), 2, 'but a client-wide retry covers it';
}

# --- a retrying send must not leak its captures. A self-referential closure
# would hold the request, the callback and the client itself forever.
{
    my $freed = 0;
    {
        package RetryProbe;
        sub new { bless {}, shift }
        sub DESTROY { $freed++ }
    }

    my $run = sub {
        my (%opt) = @_;
        $freed = 0;
        @sent = ();
        {
            my $td = new_client();
            for (1 .. 3) {
                my $probe = RetryProbe->new;
                $td->send({ '@type' => 'getMe' }, sub { my $keep = $probe }, %opt);
                $td->inject_raw(
                    qq({"\@type":"user","id":7,"\@extra":"@{[last_extra()]}"}));
            }
        }
        return $freed;
    };

    is $run->(), 3, 'a plain send frees everything it captured';
    is $run->(retry => \%FAST), 3,
        'and so does a send that opted into retry';
}

# --- the backoff waits what the server asked for. Retrying sooner than the
# server demanded is what gets accounts limited, so the delay is measured
# rather than sampled: a loaded machine runs a sampling timer late, after the
# retry, and calls a correct delay a failure.
{
    @sent = ();
    my $td = new_client();
    # a request of its own type: earlier blocks leave backing-off timers armed
    # on the shared loop, and their getMe retries land in @sent while we wait
    $td->send({ '@type' => 'getCountries' }, sub {},
              retry => { attempts => 3, margin => 0, factor => 1 });
    my $ours = sub { scalar grep { /getCountries/ } @sent };
    # taken before the 429 arms the retry, so a stall between the two is not
    # subtracted from the delay being measured
    my $t0 = EV::time();
    $td->inject_raw(flood(last_extra(), 1));
    is $ours->(), 1, 'the 429 reply consumed the first attempt';

    # measured, not sampled at a fixed moment: a loaded machine can run the
    # sampling timer late, after the retry, and call a correct delay a failure
    my $at;
    my $w = EV::timer 0, 0.02, sub {
        $at = EV::time() if !$at && $ours->() > 1;
        EV::break if $at || EV::time() - $t0 > 5;
    };
    EV::run;
    is $ours->(), 2, 'the request is re-sent';
    cmp_ok $at - $t0, '>=', 0.9,
        'and not before the second the server asked for, with margin 0';
}

# --- a backing-off request is tracked so close() can fail it, and untracked
# again once it has retried. Left tracked, a client that retries often grows
# the table for the life of the process: the entry is only otherwise removed
# by close.
{
    # counted by its own type, as the block above is: a retry some earlier
    # block left armed would otherwise fire in this pump and count as ours
    @sent = ();
    my $td = new_client();
    my $ours = sub { scalar grep { /getApplicationConfig/ } @sent };
    $td->send({ '@type' => 'getApplicationConfig' }, sub {},
              retry => { attempts => 3, margin => 0, factor => 1 });
    $td->inject_raw(flood(last_extra(), 0));
    is scalar keys %{ $td->{retry_waiters} || {} }, 1,
        'a request waiting to retry is tracked';
    pump();
    is $ours->(), 2, 'it retried';
    is scalar keys %{ $td->{retry_waiters} || {} }, 0,
        'and is untracked once it has';
}

# --- the backoff is measured from now, not from a stale ev_now. ev_now only
# advances while the loop runs, so a process that blocked outside it would
# otherwise compute a deadline already in the past and retry at once --
# exactly the too-soon retry the delay exists to prevent.
{
    pump() for 1 .. 3;
    @sent = ();
    my $td = new_client();
    EV::now_update();
    select undef, undef, undef, 1.0;
    $td->send({ '@type' => 'getMe' }, sub {},
              retry => { attempts => 3, margin => 0, factor => 1 });
    $td->inject_raw(flood(last_extra(), 1));
    my $w = EV::timer 0.2, 0, sub { EV::break };
    EV::run;
    # asserted on our own waiter, not on @sent: timers armed by earlier
    # blocks come due during the select above and fire on this same pump
    is scalar keys %{ $td->{retry_waiters} || {} }, 1,
        'a second of backoff is still a second after blocking outside the loop';
}

# --- the documented defaults. attempts and margin were pinned by the tests
# above; max_wait and factor were only ever passed explicitly, so changing
# either left the suite green.
{
    my $td = new_client();
    my $p = $td->retry_policy({ retry => 1 });
    is $p->{attempts}, 3,   'attempts defaults to the documented 3';
    is $p->{margin},   1,   'margin defaults to the documented 1 second';
    is $p->{max_wait}, 300, 'max_wait defaults to the documented 300';
    is $p->{factor},   2,   'factor defaults to the documented 2';
    is $td->retry_policy({}), undef, 'and no retry option means no retrying';
}

# --- retry_after reads a delay, and only a delay. An unanchored digit run
# would match the empty string in "retry after " and return 0, which retries
# at once -- the opposite of what the message asks for.
{
    # through a helper: "is Class->method(...)" parses as "Class->is(...)"
    my $ra = sub { EV::Telegram::TDLib->retry_after($_[0]) };
    my $e  = sub { { '@type' => 'error', code => 429, message => $_[0] } };
    is $ra->($e->('Too Many Requests: retry after 7')), 7,
        'a stated delay is read';
    is $ra->($e->('retry after ')), undef,
        'a truncated message yields no delay rather than zero';
    is $ra->($e->('slow down')), undef,
        'a 429 with no stated delay yields none';
    is $ra->({ '@type' => 'error', code => 400, message => 'retry after 7' }),
        undef, 'and a non-429 is never a retry, whatever it says';
}

done_testing;
