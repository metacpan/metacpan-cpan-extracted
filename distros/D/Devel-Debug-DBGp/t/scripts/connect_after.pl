print "\n"; flush STDOUT; # for synchronization

my $i = 0;

$i = 1;

# some time so the debugger can listen again
readline; # for synchronization

DB::connectOrReconnect();

$i = 2;

DB::enable();

$i = 3;

$i++; # just to avoid the program exiting
