use t::share;

use Inferno::RegMgr;
use Inferno::RegMgr::TCP;
use Inferno::RegMgr::Service;
use Inferno::RegMgr::Monitor;
use Inferno::RegMgr::Lookup;

use Scalar::Util qw( weaken );


@CheckPoint = (
    [ 'cb_add', 'srv1', {type=>'old',auth=>'none',role=>'devel'} ], 'cb_add: srv1 type old auth none role devel',
    [ 'cb_add', 'srv2', {type=>'old',auth=>'none',role=>'prod'}  ], 'cb_add: srv2 type old auth none role prod',
);
plan tests => @CheckPoint/2;


registry_start();

my $reg     = Inferno::RegMgr::TCP->new({ host => '127.0.0.172' });
my $regmgr  = Inferno::RegMgr->new( $reg );
my $srv1    = Inferno::RegMgr::Service->new({ name => 'srv1', attr => {
    type => 'old',
    auth => 'none',
    role => 'devel',
} });
my $srv2    = Inferno::RegMgr::Service->new({ name => 'srv2', attr => { 
    type => 'old',
    auth => 'infpk1',
    role => 'prod',
} });
my $srv3    = Inferno::RegMgr::Service->new({ name => 'srv3', attr => { 
    type => 'new',
    auth => 'infpk1',
    role => 'prod',
} });
my $monitor = Inferno::RegMgr::Monitor->new({ cb_add => \&cb_add, attr => { 
    type => 'old',
    auth => 'none',
} });
$regmgr->attach( $srv1 );
$regmgr->attach( $srv2 );
$regmgr->attach( $srv3 );
$regmgr->attach( $monitor );

my $t = EV::timer 5, 0, sub { die "timeout\n" };
EV::loop;
registry_stop();


sub cb_add {
    my ($name, $attr) = @_;
    &checkpoint;
    if ($name eq 'srv1') {
        $srv2->update({ auth => 'none' });
    }
    if ($name eq 'srv2') {
        $regmgr->detach( $srv1 );
        $t = EV::timer 1, 0, sub { EV::unloop };
    }
}

