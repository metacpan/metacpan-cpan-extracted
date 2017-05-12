BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use IO::AIO;
$loaded = 1;
print "ok 1\n";
IO::AIO::min_parallel(10);
print "ok 2\n";
IO::AIO::max_parallel(0);
print "ok 3\n";

