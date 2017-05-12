use strict;
use warnings;
use Test::More;
use IPC::Open3;

my $REAL_GNUPLOT = $ENV{REAL_GNUPLOT} || "gnuplot";

note("REAL_GNUPLOT = $REAL_GNUPLOT");

my $pid = open3(my $input, ">&2", undef,
                "gnuplot_builder_tempfile_wrapper", $REAL_GNUPLOT, "--persist");
note("wrapper PID: $pid");

print $input <<'INPUT';
set grid
set title "test"
plot sin(x), cos(x)
set print '-'
print '@@@@@@_END_OF_GNUPLOT_BUILDER_@@@@@@'
exit
INPUT

close $input;
undef $input;
note("close input. Start waiting...");
waitpid $pid, 0;
note("wrapper processs $pid finished");

pass("test complete");

done_testing;

