use strict;
use warnings;
use Test::More;
use Spike;

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    my $r = Spike::More::child_only(1);
    exit($r == 101 ? 0 : 1);
}
waitpid $pid, 0;
is($? >> 8, 0, 'the child ran child_only and exited by exit');
done_testing;
