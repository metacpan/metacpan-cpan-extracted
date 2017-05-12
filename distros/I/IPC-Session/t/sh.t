# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use IPC::Session;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.


# open local sh session
my $session = new IPC::Session("/bin/sh",15);
print "ok 2\n" if $session;

$session->send("echo hello");
chomp(my $hello = $session->stdout());
print "ok 3\n" if $hello eq "hello";

my $uname=`uname`;
print "ok 4\n" if $uname;
$session->send("uname");  
print "ok 5\n" if $uname eq $session->stdout();
print "ok 6\n" unless $session->stderr();

# errno returned in scalar context:
my $errno = $session->send('/bin/sh -c "exit 99"');
print "ok 7\n" if $errno == 99;

# hash returned in array context:
my %ls = $session->send("ls t/sh.t doesnotexist");
print "ok 8\n" if $ls{'stdout'} =~ /t\/sh/;
print "ok 9\n" if $ls{'stderr'} =~ /doesnotexist/;
print "ok 10\n" if $ls{'errno'} != 0;

