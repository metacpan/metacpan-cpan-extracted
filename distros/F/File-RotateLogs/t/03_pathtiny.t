use strict;
use warnings;
use File::RotateLogs;
use Test::More;
use Test::Requires qw/Path::Tiny/;
use Capture::Tiny ':all';

my $log;
my $err = capture_stderr {
    $log = File::RotateLogs->new(
        logfile  => path('/tmp')->child('access_log.%Y%m%d%H%M'),
        linkname => path('/tmp')->child('access_log'),
    );
};

ok($log);
like($err, qr/maxage/);
done_testing();

