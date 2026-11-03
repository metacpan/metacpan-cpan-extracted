use strict;
use warnings;
use Test::More;
use POSIX ();
use Spike;

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    my $r = Spike::More::exit_only(1);
    POSIX::_exit($r == 201 ? 0 : 1);
}
waitpid $pid, 0;
is($? >> 8, 0, 'the child ran exit_only and left by _exit');
done_testing;
