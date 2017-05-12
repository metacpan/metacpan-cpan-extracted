# TODO иногда приходит "лишний" event/IN с текстом 000001 (обычно первый
# приходящий это 000002)
# http://code.google.com/p/inferno-os/issues/detail?id=179
use t::share;

use Inferno::RegMgr::TCP;


@CheckPoint = (
    [ 'cb_event',   CONNECTED,  undef   ], 'cb_event: CONNECTED',
    [ 'cb_event',   IN,         undef   ], 'cb_event: IN',
    [ 'cb_event',   EOF,        undef   ], 'cb_event: EOF',
);
plan tests => @CheckPoint/2;


registry_start();

my $reg = Inferno::RegMgr::TCP->new({ host => '127.0.0.172' });

$reg->open_event({
    cb      => \&cb_event,
});


my $t = EV::timer 5, 0, sub { die "timeout\n" };
EV::loop;
registry_stop();


sub cb_event {
    my ($e, $err) = @_;
    &checkpoint;
    if ($e & CONNECTED) {
        $reg->open_new({
            name    => 'tcp!127.0.0.172!1234',
            attr    => {},
            cb      => \&cb_new,
        });
    }
    if ($e & IN) {
        registry_stop();
    }
    if ($e & EOF) {
        $t = EV::timer 1, 0, sub { EV::unloop }; # wait for more events
    }
    return;
}

sub cb_new {
    my ($err) = @_;
    &checkpoint;
    return;
}

