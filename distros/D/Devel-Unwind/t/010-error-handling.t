use warnings;
use strict;

use Devel::Unwind;
use Test::More;
use File::Spec;

my $pid=fork();
die "Can't fork" unless defined $pid;

if ($pid == 0) {
    open STDERR, '>', File::Spec->devnull();
    mark FOO { unwind BAR; };
    exit(0);
}
waitpid $pid,0;
isnt($?, 0, "Unwinding to a non-existing label should exit with a failure.");
done_testing();
