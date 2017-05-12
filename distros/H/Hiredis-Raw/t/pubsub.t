use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;

use Hiredis::Async;
use IO::Select;
use t::Redis;

test_redis {
    my $port = shift;

    my $redis_sub = Hiredis::Async->new(
        host => "127.0.0.1",
        port => $port,
    );

    my $redis_pub = Hiredis::Async->new(
        host => "127.0.0.1",
        port => $port,
    );

    my $select_sub = IO::Select->new($redis_sub->GetFd);
    my $select_pub = IO::Select->new($redis_pub->GetFd);

    # subscribe to t1
    my @sub1_reply;
    $redis_sub->Command(['SUBSCRIBE', 't1'], sub { @sub1_reply = @_ });
    $select_sub->can_write;
    $redis_sub->HandleWrite;
    $select_sub->can_read;
    $redis_sub->HandleRead;
    is_deeply \@sub1_reply, [['subscribe', 't1', 1], undef], 'subscribe: t1';

    # subscribe to t2
    my @sub2_reply;
    $redis_sub->Command(['SUBSCRIBE', 't2'], sub { @sub2_reply = @_ });
    $select_sub->can_write;
    $redis_sub->HandleWrite;
    $select_sub->can_read;
    $redis_sub->HandleRead;
    is_deeply \@sub2_reply, [['subscribe', 't2', 2], undef], 'subscribe: t2';

    # publish to t1
    my @pub_reply;
    $redis_pub->Command(['PUBLISH', 't1', 'x1'], sub { @pub_reply = @_ });
    $select_pub->can_write;
    $redis_pub->HandleWrite;
    $select_pub->can_read;
    $redis_pub->HandleRead;
    is_deeply \@pub_reply, [1, undef], 'publish: t1';

    # receive from t1
    $select_sub->can_read;
    $redis_sub->HandleRead;
    is_deeply \@sub1_reply, [['message', 't1', 'x1'], undef], 'receive: t1';

    # unsubscribe from all topics
    $redis_sub->Command(['UNSUBSCRIBE'], sub {});
    $select_sub->can_write;
    $redis_sub->HandleWrite;

    $select_sub->can_read;
    $redis_sub->HandleRead;
    cmp_deeply
        \@sub1_reply,
        [['unsubscribe', 't1', ignore()], undef],
        'unsubscribe: t1';

    $redis_sub->HandleRead;
    cmp_deeply
        \@sub2_reply,
        [['unsubscribe', 't2', ignore()], undef],
        'unsubscribe: t2';
};

done_testing;
