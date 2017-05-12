use t::share;

use Inferno::RegMgr;
use Inferno::RegMgr::TCP;
use Inferno::RegMgr::Service;
use Inferno::RegMgr::Monitor;
use Inferno::RegMgr::Lookup;

use Scalar::Util qw( weaken );


@CheckPoint = (
    [ 'cb_add',     'one',  {}              ], 'cb_add: one',
    [ 'cb_add',     'two',  {}              ], 'cb_add: two',
    [ 'cb_mod',     'two',  {version=>1}    ], 'cb_mod: two version 1',
    [ 'cb_mod',     'two',  {version=>2}    ], 'cb_mod: two version 2',
    [ 'cb_del',     'two',  {version=>2}    ], 'cb_del: two version 2',
    [ 'cb_lookup',  { 'one' => {} }         ], 'cb_lookup: ("one")',
);
plan tests => @CheckPoint/2+1;


registry_start();

my $reg     = Inferno::RegMgr::TCP->new({ host => '127.0.0.172' });
my $regmgr  = Inferno::RegMgr->new( $reg );
my $srv1    = Inferno::RegMgr::Service->new({ name => 'one' });
my $srv2    = Inferno::RegMgr::Service->new({ name => 'two' });
my $monitor = Inferno::RegMgr::Monitor->new({
    cb_add => \&cb_add,
    cb_mod => \&cb_mod,
    cb_del => \&cb_del,
});
my $lookup  = Inferno::RegMgr::Lookup->new({ cb => \&cb_lookup });
$regmgr->attach( $srv1 );
$regmgr->attach( $monitor );

my $t = EV::timer 5, 0, sub { die "timeout\n" };
EV::loop;
registry_stop();

weaken( $regmgr );
is($regmgr, undef, 'Inferno::RegMgr object freed');


sub cb_add {
    my ($name, $attr) = @_;
    &checkpoint;
    if ($name eq 'one') {
        $regmgr->attach( $srv2 );
    }
    if ($name eq 'two') {
        $srv2->update({ version => 1 });
    }
}

sub cb_mod {
    my ($name, $attr) = @_;
    &checkpoint;
    if ($name eq 'two') {
        if ($attr->{version} eq '1') {
            $srv2->update({ version => 2 });
        }
        if ($attr->{version} eq '2') {
            $regmgr->detach( $srv2 );
        }
    }
}

sub cb_del {
    my ($name, $attr) = @_;
    &checkpoint;
    if ($name eq 'two') {
        $regmgr->attach( $lookup );
    }
}

sub cb_lookup {
    my ($svc) = @_;
    &checkpoint;
    EV::unloop;
}

