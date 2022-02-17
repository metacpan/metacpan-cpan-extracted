use Test::More;
use Etcd::Lock;
use boolean;

plan skip_all => 'set TEST_ETCD to enable this test' unless $ENV{TEST_ETCD};

my $lu = new Etcd::Lock( host => $ENV{TEST_ETCD}, key => 'test' . time );

is ($lu->lock, true, "Lock acquired");
is ($lu->unlock, true, "Unlock acquired");

done_testing();
