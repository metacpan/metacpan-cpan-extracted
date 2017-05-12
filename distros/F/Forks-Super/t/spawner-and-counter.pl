#! perl
# t/spawner-and-counter.pl  pid-file  spawn  counter
# spawns a new instance of spawn-and-counter.pl (after decrementing
# the spawn count)
#
# this program is used to test whether child and grandchild processes
# can be killed successfully. See t/40g-timeout.t

use strict;
use warnings;
my ($pid_file, $spawn_count, $counter_count) = @ARGV;

open(F, ">>", $pid_file);
flock F, 2;
seek F, 0, 2;
print F "$$,t/out/spawn-counter.$$\n";
close F;

if ($spawn_count > 0 && fork() == 0) {
    $spawn_count--;
    exec($^X, $0, $pid_file, $spawn_count, $counter_count);
    exit 1;
}

open(OUT, ">". "t/out/spawn-counter.$$");
select OUT;
$| = 1;

while ($counter_count >= 0) {
    print "$counter_count\n";
    $counter_count--;
    sleep 1;
    # give heavily loaded systems a better chance to pass
    # sleep 1 if $counter_count < 7; 
}
close OUT;
