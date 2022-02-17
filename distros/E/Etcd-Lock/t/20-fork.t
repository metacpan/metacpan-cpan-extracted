use Test::More;
use Test::Fork;
use Etcd::Lock;
use boolean;

plan skip_all => 'set TEST_ETCD to enable this test' unless $ENV{TEST_ETCD};

my $lu = new Etcd::Lock( host => $ENV{TEST_ETCD}, key => 'test' . time );

fork_ok(
    2,
    sub {
        # forked process
        is( $lu->lock, true, "Lock acquired in forked process" );
        sleep 1;
        is( $lu->unlock, true, "Unlock in forked process" );
    }
);

sleep 1;
is( $lu->lock, false, "Lock not acquired in main process" );
sleep 1;
is( $lu->lock, true, "Lock acquired in main process" );

done_testing();
