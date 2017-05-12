#! perl
# $^X external-daemon.pl [options]
#
# We don't know what OS and environment we are testing on.
# The only external program we can be confident about having
# is perl, so when an external program is needed to test
# something, we'll use a perl script.
#
# This is a prototypical daemon program. It receives
# the name of a log file from $ENV{LOG_FILE} and a
# value from $ENV{VALUE}. It logs its process id and
# parent process id. Then it prints out one string
# every second, up to $ENV{VALUE} seconds. Then it
# writes one more departing message to the log file
# and exits.
#
# Since this is a daemon, you should not assume the program
# is being run out of any particular directory, and so
# you should probably use an absolute path to specify
# the log file.
#

use Carp;
use strict;
use warnings;
my $log;
my $logfile = $ENV{LOG_FILE} || $ENV{LOGFILE} ||
    croak "No log file specified in \$ENV{LOG_FILE}.\n";
$0 = $ENV{DAEMON_NAME} || "t/external_daemon.pl";

my $value = $ENV{VALUE} 
|| do {
    warn "No value specified in \$ENV{VALUE}, using 10.";
    10 
};

open $log, '>', $logfile;
close STDERR; 
open STDERR, '>', "$logfile.err";
select $log;
$| = 1;

print "Hello. This is daemon process $$.\n";
print "My parent pid is ";
print(eval { getppid() } || "<unavailable for $^O>");
print ",";
sleep 3;
print(eval { getppid() } || "<unavailable for $^O>");
print "\n";

for my $i (1 .. $value) {
    sleep 1;
    print "$i " x $i, "\n";
}

END {
    print "Good bye after ", time-$^T, " seconds.\n";
    print "Exit status is $?\n";
    close $log if $log;
    close STDERR;
}
