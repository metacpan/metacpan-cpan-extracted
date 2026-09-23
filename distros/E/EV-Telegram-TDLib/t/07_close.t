use strict;
use warnings;
use Test::More;
use EV;
use EV::Telegram::TDLib;

my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', auto_auth => 0,
    database_directory => 't/tmp-close',
);
my $cid = $td->{client_id};

my $closed = 0;
$td->close(sub { $closed = 1; EV::break });

# the loop has not run yet, so ev_now is still the time EV was loaded
EV::now_update();
my $watchdog = EV::timer 15, 0, sub { fail('close never completed'); EV::break };
EV::run;
$watchdog->stop;

ok $closed, 'close callback fired';
is $td->auth_state, 'authorizationStateClosed', 'reached the closed state';
ok !EV::Telegram::TDLib::is_registered($cid), 'client left the registry';

my $td2 = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', auto_auth => 0,
    database_directory => 't/tmp-close2',
);
my $cid2 = $td2->{client_id};

my %fired;
$td2->close(sub { $fired{first} = 1 });
$td2->close(sub { $fired{second} = 1; EV::break });

my $watchdog2 = EV::timer 15, 0, sub { fail('double close never completed'); EV::break };
EV::run;
$watchdog2->stop;

ok $fired{first}, 'first close callback not dropped by the second close';
ok $fired{second}, 'second close callback fired';
is $td2->auth_state, 'authorizationStateClosed', 'double close still reached Closed';
ok !EV::Telegram::TDLib::is_registered($cid2), 'second client left the registry';

# --- send() on a closed client fails deferred and sends nothing
my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
my $td3 = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', auto_auth => 0,
    database_directory => 't/tmp-close3',
);
$td3->close;
@sent = ();
$td3->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}));

my (@res, @warn);
my $ret = do {
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    $td3->send({ '@type' => 'getMe' }, sub { @res = @_ });
};
is $ret, undef, 'send on a closed client returns undef';
is scalar @sent, 0, 'nothing reaches TDLib';
is scalar @warn, 0, 'no warnings from a send on a closed client';
ok !@res, 'the callback does not fire synchronously';
ok !keys %{ $td3->{pending} }, 'no pending entry is registered';
EV::run(EV::RUN_NOWAIT);
ok @res, 'the callback fires deferred';
is $res[0], undef, 'no result';
is $res[1]{message}, 'client is closed', 'a clear error is delivered';
is $res[1]{code}, -1, 'synthetic error code';

# --- a repeat close() in the settled state chains, none is dropped
my @late_close;
$td3->close(sub { push @late_close, 'late1' });
$td3->close(sub { push @late_close, 'late2' });
is scalar @late_close, 0, 'settled close callbacks do not fire synchronously';
EV::run(EV::RUN_NOWAIT);
is scalar @late_close, 2, 'both settled close callbacks fired';

# --- a deferred close callback keeps the object alive until it fires
my $pin = 0;
{
    my $td4 = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', auto_auth => 0,
        database_directory => 't/tmp-close4',
    );
    $td4->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}));
    $td4->close(sub { $pin = 1 });
}
EV::run(EV::RUN_NOWAIT);
ok $pin, 'the deferred close fired after the caller dropped the object';

done_testing;
