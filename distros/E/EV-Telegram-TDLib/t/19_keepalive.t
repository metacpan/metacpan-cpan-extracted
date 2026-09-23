use strict;
use warnings;
use Test::More;
use EV;
use EV::Telegram::TDLib;

sub closed_update {
    q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}})
}

# These clients are never materialised: new(), keepalive() and inject_raw
# all send nothing, and tdjson only creates a client when its first request
# arrives. So injecting the closed update leaves nothing behind for TDLib to
# hold, and closing these ids at exit would only materialise dead clients in
# order to close them.
sub new_client {
    my ($dir) = @_;
    EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', auto_auth => 0,
        database_directory => $dir,
    );
}

sub refcnt { EV::Telegram::TDLib::_pump_refcnt() }

my $a = new_client('t/tmp-ka-a');
is $a->keepalive(1), 1, 'keepalive(1) on a fresh client returns 1';
is refcnt, 1, 'one client holds one pump ref';

my $b = new_client('t/tmp-ka-b');
is refcnt, 2, 'two clients hold two pump refs';
is $b->keepalive(0), 0, 'keepalive(0) releases the ref';
is refcnt, 1, 'one ref left';
is $b->keepalive(0), 0, 'a repeated keepalive(0) spends nothing more';
is refcnt, 1, 'still one ref left';

my $cid_b = $b->{client_id};
$b->inject_raw(closed_update());
ok !EV::Telegram::TDLib::is_registered($cid_b), 'B left the registry';
is refcnt, 1, 'close after keepalive(0) does not unref a second time';

is $b->keepalive(), 0, 'a closed client reports keepalive off';
is $b->keepalive(1), 0, 'keepalive(1) on a closed client is refused';
is refcnt, 1, 'no phantom ref from a closed client';

my $c = new_client('t/tmp-ka-c');
is refcnt, 2, 'a third client takes its ref';
$c->keepalive(0);
is refcnt, 1, 'keepalive(0) spends it';
$c->inject_raw(closed_update());
is refcnt, 1, 'closing a keepalive(0) client spends nothing';

$a->inject_raw(closed_update());
is refcnt, 0, 'the last close releases the loop';

my $d = new_client('t/tmp-ka-d');
is refcnt, 1, 'a fresh client re-takes the ref';
$d->inject_raw(closed_update());
is refcnt, 0, 'and closing it releases it again';

# a truthy value that is not exactly 1 must not take a second loop reference:
# the extra one is never released and EV::run then never returns. One client
# for the whole matrix, and it is closed for real at the end -- faking the
# closed update would leave TDLib holding a client it was never told to drop,
# which aborts the process during its teardown.
{
    my $odd = new_client('t/tmp-ka-odd');
    my $base = refcnt;
    for my $truthy (2, 'yes', -1) {
        $odd->keepalive($truthy);
        is refcnt, $base, "keepalive($truthy) takes no extra reference";
        $odd->keepalive(0);
        is refcnt, $base - 1, "keepalive(0) after $truthy releases the reference";
        $odd->keepalive(1);
    }
    my $shut = 0;
    $odd->close(sub { $shut = 1; EV::break });
    my $late = 0;
    my $w = EV::timer 15, 0, sub { $late = 1; EV::break };
    EV::run(EV::RUN_ONCE) while !$shut && !$late;
    $w->stop;
    ok $shut, 'the keepalive client closed for real';
}

done_testing;
