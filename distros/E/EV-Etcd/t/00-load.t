use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;

BEGIN {
    eval { require EV };
    if ($@) {
        plan skip_all => 'EV module not available';
        exit;
    }
}

plan tests => 4;

my @load_warnings;
{
    local $SIG{__WARN__} = sub { push @load_warnings, @_ };
    use_ok('EV::Etcd');
}
is_deeply(\@load_warnings, [], 'loads without warnings');

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
isa_ok($client, 'EV::Etcd');

# The etcd tests skip when EV::Etcd cannot reach etcd, so with one known to be
# running a broken new() or status() must fail here instead
SKIP: {
    skip 'set EV_ETCD_TEST_ETCD=1 when an etcd for testing runs on 127.0.0.1:2379', 1
        unless $ENV{EV_ETCD_TEST_ETCD};
    my ($ok, $err);
    $client->status(sub { ($ok, $err) = (!$_[1], $_[1]); EV::break });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    ok($ok, 'EV::Etcd reaches the etcd the environment promises') or diag explain $err;
}
