# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Detect::Module qw(:standard);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

Use ('Crap::Nothing::doesnotexist', 'CGI') eq 'CGI'
 or print "(requiring CGI) not ";
print "ok 2\n";

Require ('-', 'CGI') eq 'CGI'
 or print "(requiring CGI) not ";
print "ok 3\n";

defined eval { Use '-' }
 and print "not ";
print "ok 4\n";

my $r = NewRef ('IO::Socket::INET');
ref $r eq "CODE"
 or print "not ";
print "ok 5\n";

my $a = Load ('URI::Escape');
$a->uri_escape (' ') eq '%20'
 or print "(requiring URI::Escape) not ";
print "ok 6\n";
$a->('CODE', 'uri_escape')->(' ') eq '%20'
 or print "not ";
print "ok 7\n";

eval { $a->hello (); 1 } and print "not ";
print "ok 8\n";
