use strict;
use warnings;
use Test::More;
use Test::Exception;
use POSIX qw/setlocale/;

use Hiredis::Async;

setlocale( &POSIX::LC_ALL, 'C' );

# Redis automatically frees the redis context causing major problems.  We make
# sure that we can't run any commands after this sort of error.

my $redis = Hiredis::Async->new(host => '127.0.0.1', port => 12345);

my ($ping_res, $ping_err);
$redis->Command(['PING'], sub { ($ping_res, $ping_err) = @_ } );

ok $redis->IsAllocated, 'make sure it got allocated';

$redis->HandleWrite;

is $ping_res, undef, 'no response';
like $ping_err, qr/Connection refused/i, 'connection refused error';

ok !$redis->IsAllocated, 'make sure it got deallocated';

done_testing;
