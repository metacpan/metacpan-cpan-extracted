use strict;
use warnings;
use Test::More;
use Test::Exception;

use Hiredis::Async;
use IO::Select;
use t::Redis;

test_redis {
    my $port = shift;

    my $write_watcher_on = 0;
    my $read_watcher_on  = 0;

    my $redis = Hiredis::Async->new(
        host => "127.0.0.1",
        port => $port,

        addRead  => sub { $read_watcher_on  = 1 },
        delRead  => sub { $read_watcher_on  = 0 },
        addWrite => sub { $write_watcher_on = 1 },
        delWrite => sub { $write_watcher_on = 0 },
    );

    cmp_ok my $fd = $redis->GetFd, '>', 0, 'got fd';

    my $select = IO::Select->new($fd);
    ok $write_watcher_on, 'write after connecting';
    ok !$read_watcher_on, 'no results to read yet';

    $select->can_write;
    $redis->HandleWrite;
    ok !$write_watcher_on, 'finished post connect write';
    ok $read_watcher_on,   'read results';

    my $pong;
    my @l_errs;
    my @values;
    my $zrank;
    my $error;
    my $info_str;

    $redis->Command(['PING'],                    sub { $pong = $_[0] });
    $redis->Command(['INFO'],                    sub { $info_str = $_[0] });
    $redis->Command([qw/LPUSH key value/],       sub { push @l_errs, $_[1] })
        for 1..3;
    $redis->Command([qw/LRANGE key 0 2/],        sub { @values = @{$_[0]} });
    $redis->Command([qw/ZRANK zempty not_here/], sub { $zrank = $_[0] });
    $redis->Command([qw/BOGUS/],                 sub { $error = $_[1] });
    ok $write_watcher_on, 'commands are buffered';

    $select->can_write;
    $redis->HandleWrite;
    ok !$write_watcher_on, 'commands written';

    $select->can_read;
    $redis->HandleRead;

    ok $read_watcher_on, 'always be reading';

    is $pong, 'PONG', 'got PONG from PING';
    is $zrank, undef, 'nil zrank';
    is_deeply \@l_errs, [undef, undef, undef], 'no errors from lpush';
    is_deeply \@values, [qw/value value value/], 'got values';
    is $error, q{ERR unknown command 'BOGUS'}, 'got error';

    # parse the info line;
    my $info = { map { split /:/ } grep { /:/ } split /\r\n/, $info_str };
    ok exists $info->{redis_version}, 'got info';

    ok !$write_watcher_on, 'no new commands';

    # variadic zset command
    if ($info->{redis_version} gt '2.4') {

        my ($z_res, $z_err);
        $redis->Command([qw/ZADD zkey 0 v1 0 v2/], sub { ($z_res, $z_err) = @_ });

        $select->can_write;
        $redis->HandleWrite;

        $select->can_read;
        $redis->HandleRead;

        is $z_res, 2, '2 zadds occured';
        is $z_err, undef, 'no error from zadd';
    }
};

done_testing;
