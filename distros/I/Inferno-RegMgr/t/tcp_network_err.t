# TODO иногда приходит "лишний" event/IN с текстом 000001 (обычно первый
# приходящий это 000002)
# http://code.google.com/p/inferno-os/issues/detail?id=179
use t::share;

use Inferno::RegMgr::TCP;


plan tests => 3;

my $reg = Inferno::RegMgr::TCP->new({ host => '127.0.0.172' });

$reg->open_event({ cb => \&cb_event });


my $t = EV::timer 5, 0, sub { die "timeout\n" };
EV::loop;


sub cb_event {
    my ($e, $err) = @_;
    is($err, 'Connection refused', 'cb_event: network error');
    $reg->open_find({ cb => \&cb_find });
    return;
}

sub cb_find {
    my ($srv, $err) = @_;
    is($err, 'Connection refused', 'cb_find: network error');
    $reg->open_new({ cb => \&cb_new, name => 'test' });
    return;
}

sub cb_new {
    my ($err) = @_;
    is($err, 'Connection refused', 'cb_new: network error');
    EV::unloop;
    return;
}


