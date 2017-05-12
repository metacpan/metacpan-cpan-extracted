use strict;
use warnings;
use Test::More;
use Test::Exception;
use POSIX qw/setlocale/;

use IO::Select;
use Hiredis::Async;
use t::Redis;

setlocale( &POSIX::LC_ALL, 'C' );

{ # Connection failure test

    # Connection problems are often not discovered until the first command is
    # executed. Here we test that they are noticed and reported properly.

    my $redis = Hiredis::Async->new(host => '127.0.0.1', port => 12345);

    cmp_ok my $fd = $redis->GetFd, '>', 0, 'got fd';

    my ($ping_res, $ping_err);
    $redis->Command(['PING'], sub { ($ping_res, $ping_err) = @_ } );

    my $select = IO::Select->new($fd);
    $select->can_write;

    $redis->HandleWrite;

    is $ping_res, undef, 'no PONG from PING';
    like $ping_err, qr/Connection refused/, 'connection error';

    $select->can_read;
    throws_ok { $redis->HandleRead } qr/does not have a struct/, 
        'read after connection failure is invalid';
};

done_testing;
