# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Log::LogLite;
use Log::NullLogLite;
$loaded = 1;
print "ok 1\n";

# create a log file with default level 5
my $log = new Log::LogLite("test.log");
$log->write("message number 1"); # should be in the log
$log->write("message number 2", 4); # should be in the log
$log->write("message number 3", 5); # should be in the log
$log->write("message number 4", 6); # should not be in the log

$log = undef; # close the log

# read the log file and check it.
open(LOG, "test.log");
my @lines = <LOG>;
close(LOG);

if ($lines[0] =~ /\[[^\]]+\] <\-> message number 1/ &&
    $lines[1] =~ /\[[^\]]+\] <4> message number 2/ &&
    $lines[2] =~ /\[[^\]]+\] <5> message number 3/) {
    print "ok 2\n";
}
else {
    print "not ok 2\n";
}


# remove the log file 
unlink("test.log");

# create a new log with 6 as default level
$log = new Log::LogLite("test.log", 6);
$log->write("message number 5", 6); # should be in the log
$log->write("message number 6", 7); # should not be in the log

$log = undef; # close the log

# read the log file and check it
open(LOG, "test.log");
@lines = <LOG>;
close(LOG);

if ($lines[0] =~ /\[[^\]]+\] <6> message number 5/) {
    print "ok 3\n";
}
else {
    print "not ok 3\n";
}

# remove the log file
unlink("test.log");

# create a new log 
$log = new Log::LogLite("test.log");

# change the default message
$log->default_message("message "); 
$log->write("number 7"); # should be in the log

$log = undef; # close the log

# read the log file and check it
open(LOG, "test.log");
@lines = <LOG>;
close(LOG);

if ($lines[0] =~ /\[[^\]]+\] <\-> message number 7/) {
    print "ok 4\n";
}
else {
    print "not ok 4\n";
}

# remove the log file
unlink("test.log");

# create a new log 
$log = new Log::LogLite("test.log");

# change the template
$log->template("<level>:[<date>]: <default_message><message>\n");
$log->write("message number 8"); # should be in the log

$log = undef; # close the log

# read the log file and check it
open(LOG, "test.log");
@lines = <LOG>;
close(LOG);

if ($lines[0] =~ /\-:\[[^\]]+\]: message number 8/) {
    print "ok 5\n";
}
else {
    print "not ok 5\n";
}

# remove the log file
unlink("test.log");

# create a null log 
$log = new Log::NullLogLite();
$log->write("this message will never be written");
print "ok 6\n"; # if we are here, it must be ok.



