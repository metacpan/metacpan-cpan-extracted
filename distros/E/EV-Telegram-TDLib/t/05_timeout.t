use strict;
use warnings;
use Test::More;

# This file stubs _send, so the END-block shutdown cannot deliver its close
# requests and would idle out the whole budget at exit. Nothing was ever sent
# to TDLib here, so there is nothing to wait for.
BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;

# a real getMe is answered by TDLib with an error within milliseconds
# (no parameters set), which would beat the 0.2s timeout to the callback
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { };
}

my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', auto_auth => 0,
    database_directory => 't/tmp-timeout',
);

my @got;
my $extra = $td->send({ '@type' => 'getMe' }, sub { push @got, [@_] }, timeout => 0.2);

my $watchdog = EV::timer 5, 0, sub { fail('watchdog'); EV::break };
my $stop = EV::timer 0.5, 0, sub { EV::break };
EV::run;
# left armed, it fired inside the stale-clock block below on a slow runner
$watchdog->stop;

is scalar @got, 1, 'the callback fired once';
is $got[0][0], undef, 'no result';
is $got[0][1]{message}, 'timeout', 'timeout error delivered';
is $got[0][1]{code}, -1, 'timeout uses code -1';
ok !exists $td->{pending}{$extra}, 'no longer pending';

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };
$td->inject_raw(qq({"\@type":"user","id":1,"\@extra":"$extra"}));
is scalar @got, 1, 'the late reply did not reach the callback again';
like $warnings[0], qr/late reply/, 'the late reply warned';

# the abandoned id is consumed by the reply it was recorded for: a second
# arrival is an unknown id, not a second late reply, and leaving it recorded
# would keep one entry per timed-out request for the life of the client
ok !exists $td->{abandoned}{$extra}, 'the late reply cleared the abandoned id';
@warnings = ();
$td->inject_raw(qq({"\@type":"user","id":1,"\@extra":"$extra"}));
like $warnings[0], qr/unknown request/,
    'and a further arrival is an unknown reply, not a late one';

# the record is capped, so a long-lived client that times out often does not
# accumulate one entry per request forever
{
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-abandon');
    $c->abandon($_) for 1 .. 1200;
    cmp_ok scalar(keys %{ $c->{abandoned} }), '<=', 1001,
        'the abandoned record is bounded';
    ok !exists $c->{abandoned}{1}, 'and it drops the oldest id first';
    ok exists $c->{abandoned}{1200}, 'keeping the newest';
}

# --- a timeout scheduled after blocking outside the loop must be
# measured from now, not from the stale ev_now: without now_update it
# fires immediately, a spurious timeout TDLib might have answered
EV::now_update();
my $t0 = EV::now;
select(undef, undef, undef, 1.0);
my (@got2, $fired_at);
$td->send({ '@type' => 'getMe' }, sub {
    @got2 = @_;
    $fired_at = EV::now;
    EV::break;
}, timeout => 0.4);
my $bound = EV::timer 5, 0, sub { fail('the timeout never fired'); EV::break };
EV::run;
$bound->stop;
is $got2[1]{message}, 'timeout', 'the timeout still fires';
cmp_ok $fired_at - $t0, '>', 1.2, 'the full timeout elapsed despite the stale ev_now';

done_testing;
