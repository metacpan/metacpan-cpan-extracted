# TODO иногда приходит "лишний" event/IN с текстом 000001 (обычно первый
# приходящий это 000002)
# http://code.google.com/p/inferno-os/issues/detail?id=179
use t::share;

use Inferno::RegMgr::TCP;


my $wait_srv = {
    'tcp!127.0.0.172!1234'    => {
        auth    => 'none',
        type    => 'fake\'n service',
    }
};
@CheckPoint = (
    [ 'cb_event',   CONNECTED,  undef   ], 'cb_event: CONNECTED',
    [ 'cb_event',   IN,         undef   ], 'cb_event: IN',
    [ 'cb_find',    {},         undef,  ], 'cb_find: nothing found',
    [ 'cb_event',   IN,         undef   ], 'cb_event: IN',
    [ 'cb_find',    $wait_srv,  undef,  ], 'cb_find: service found!',
);
plan tests => @CheckPoint/2+1;


registry_start();

my $reg = Inferno::RegMgr::TCP->new({ host => '127.0.0.172' });
ok($reg, 'Inferno::RegMgr::TCP object created');

my %io;
$io{event} = $reg->open_event({
    cb      => \&cb_event,
});


my $t = EV::timer 5, 0, sub { die "timeout\n" };
EV::loop;
registry_stop();


sub cb_event {
    my ($e, $err) = @_;
    &checkpoint;
    if ($e & CONNECTED) {
        $io{new} = $reg->open_new({
            name    => 'tcp!127.0.0.172!1234',
            attr  => { auth => 'nane', type => 'fake\'n service' },
            cb      => \&cb_new,
        });
    }
    if ($e & IN) {
        $io{find} = $reg->open_find({
            cb      => \&cb_find,
            attr    => {
                auth    => 'none',
            }
        });
    }
    return;
}

sub cb_new {
    my ($err) = @_;
    &checkpoint;
    return;
}

sub cb_find {
    my ($srv, $err) = @_;
    &checkpoint;
    if (ref $srv && !keys %$srv) {
        $reg->update($io{new}, { auth => 'none' });
    }
    if (ref $srv && keys %$srv) {
        EV::unloop;
    }
    return;
}

