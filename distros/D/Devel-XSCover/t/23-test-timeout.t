use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover::Test ();

plan skip_all => 'process groups and shell scripts here' if $^O eq 'MSWin32';

my $dir  = File::Temp->newdir;
my $slow = XSCoverTest::fake_script($dir, 'fake-slow', 'sleep 30; exit 0');
my @warn;
my $start = time;
my $status;
{
    local $SIG{__WARN__} = sub { push @warn, @_ };
    $status = Devel::XSCover::Test->new(dir => "$dir", make => $slow, silent => 1, timeout => 1)->run;
}
is($status, 124, 'a run past the timeout returns 124');
cmp_ok(time - $start, '<', 20, 'and does not wait for it');
is(scalar @warn, 1, 'one warning');
like($warn[0], qr/passed 1 seconds, ending process group \d+/, 'naming the timeout and the group');

my $quick = XSCoverTest::fake_script($dir, 'fake-quick', 'exit 0');
is(Devel::XSCover::Test->new(dir => "$dir", make => $quick, silent => 1, timeout => 5)->run, 0, 'a quick run under a timeout is fine');

done_testing;
