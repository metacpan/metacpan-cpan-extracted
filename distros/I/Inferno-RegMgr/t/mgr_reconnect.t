use t::share;

use Inferno::RegMgr;
use Inferno::RegMgr::TCP;
use Inferno::RegMgr::Service;
use Inferno::RegMgr::Monitor;
use Inferno::RegMgr::Lookup;

use Scalar::Util qw( weaken );


@CheckPoint = (
    [ 'cb_lookup1', { srv => {} } ], 'cb_lookup1: { srv => {} }',
    [ 'cb_lookup2', { srv => {} } ], 'cb_lookup2: { srv => {} }',
);
plan tests => @CheckPoint/2;


registry_start();

my $reg     = Inferno::RegMgr::TCP->new({ host => '127.0.0.172' });
my $regmgr  = Inferno::RegMgr->new( $reg );
my $srv     = Inferno::RegMgr::Service->new({ name => 'srv' });
$regmgr->attach( $srv );
my $tl      = EV::timer 1, 0, sub {
    $regmgr->attach( Inferno::RegMgr::Lookup->new({ cb => \&cb_lookup1 }) );
};

my $t = EV::timer 5, 0, sub { die "timeout\n" };
EV::loop;
registry_stop();


sub cb_lookup1 {
    my ($svc) = @_;
    &checkpoint;
    registry_stop();
    registry_start();
    $tl = EV::timer 1, 0, sub {
        $regmgr->attach( Inferno::RegMgr::Lookup->new({ cb => \&cb_lookup2 }) );
    };
}

sub cb_lookup2 {
    my ($svc) = @_;
    &checkpoint;
    EV::unloop;
}

