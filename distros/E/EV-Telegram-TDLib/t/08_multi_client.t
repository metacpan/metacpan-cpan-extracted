use strict;
use warnings;
use Config;
use Test::More;
use EV;
use EV::Telegram::TDLib;

my $a = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', auto_auth => 0,
    database_directory => 't/tmp-multi-a',
);
my $b = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', auto_auth => 0,
    database_directory => 't/tmp-multi-b',
);
my ($cid_a, $cid_b) = ($a->{client_id}, $b->{client_id});

isnt $cid_a, $cid_b, 'distinct client ids';

my (@a, @b, %upd_a, %upd_b);
$a->on_update(sub { $upd_a{ $_[0]{'@type'} // '' }++ });
$b->on_update(sub { $upd_b{ $_[0]{'@type'} // '' }++ });

my $both = sub { EV::break if @a && @b };
$a->send({ '@type' => 'getMe' }, sub { push @a, ($_[1] // $_[0]); $both->() });
$b->send({ '@type' => 'getMe' }, sub { push @b, ($_[1] // $_[0]); $both->() });

# the loop has not run yet, so ev_now is still the time EV was loaded
EV::now_update();
my $watchdog = EV::timer 15, 0, sub { fail('replies never arrived'); EV::break };
EV::run;
$watchdog->stop;

# seq is per client, so a misrouted reply still matches a pending slot on
# the wrong object: anything but 1/1 here means cross-delivery
is scalar @a, 1, 'client A got exactly one reply';
is scalar @b, 1, 'client B got exactly one reply';
ok $a[0]{'@type'}, 'reply to A is a TDLib response';
ok $b[0]{'@type'}, 'reply to B is a TDLib response';

ok $upd_a{updateAuthorizationState}, 'client A saw its own authorization state';
ok $upd_b{updateAuthorizationState}, 'client B saw its own authorization state';
is $a->auth_state, 'authorizationStateWaitTdlibParameters',
    'FSM of A tracked its own updates';
is $b->auth_state, 'authorizationStateWaitTdlibParameters',
    'FSM of B tracked its own updates';

my $closed = 0;
my $done = sub { EV::break if ++$closed == 2 };
$a->close($done);
$b->close($done);

my $watchdog2 = EV::timer 15, 0, sub { fail('close never completed'); EV::break };
EV::run;
$watchdog2->stop;

is $closed, 2, 'both clients closed';
ok !EV::Telegram::TDLib::is_registered($cid_a), 'client A left the registry';
ok !EV::Telegram::TDLib::is_registered($cid_b), 'client B left the registry';

# a referenced watchdog would itself hold the loop, so the probe runs in a
# forked child with no watchers at all: EV::run returns there only if the
# pump dropped its keepalive; the parent's watchdog bounds a hang
SKIP: {
    skip 'no fork on this platform', 1 unless $Config::Config{d_fork};
    pipe my $rd, my $wr or die "pipe: $!";
    my $pid = fork;
    defined $pid or die "fork: $!";
    if (!$pid) {
        close $rd;
        $wr->autoflush(1);
        EV::run;
        print {$wr} "ok\n";
        exit 0;
    }
    close $wr;
    my $got = '';
    my $probe = EV::timer 3, 0, sub { EV::break };
    my $io = EV::io($rd, EV::READ, sub { $got = <$rd> // ''; EV::break });
    EV::run;
    kill 9, $pid unless $got;
    waitpid $pid, 0;
    is $got, "ok\n", 'pump releases the loop once the last client is gone';
}

done_testing;
