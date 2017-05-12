# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as erl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaBrea::NetIO qw(:DEFAULT
	TARPIT_PORT
	daemon_handler
);
$loaded = 1;
print "ok 1\n";

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

my $stuff = 'README';

open (F,$stuff);
my @lines = (<F>);
close F;

open (TST,$stuff);

my ($f,$r);
my $err;

print "TARPIT_PORT\t", &TARPIT_PORT, "should be\t8686\nnot "
	unless TARPIT_PORT == 8686;
&ok;

my $subref;
print "failed to open daemon_handler\nnot "
	unless $subref = daemon_handler(*TST,$stuff);
&ok;

foreach(@lines) {
  next if ($r = &$subref) && $_ eq $r;
  print "error FILE:\n|$_|\nne LINE:\n|$r|\n";  
  $err = 1;  
}  
close TST;   
print "\nnot " if $err;
&ok;

print "failed to open daemon_handler\nnot "
	unless $subref = daemon_handler(*TST,{ 'file' => $stuff });
&ok;
foreach(@lines) {
  next if ($r = &$subref) && $_ eq $r;
  print "error FILE:\n|$_|\nne LINE:\n|$r|\n";
  $err = 1;  
}  
close TST;
print "\nnot " if $err;
&ok;
