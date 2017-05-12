# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as erl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaBrea::NetIO qw(:DEFAULT
	fetch
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

my @response;
my $command;

print $_, "\nnot "
	unless ($_ = fetch('crap',\@response,$command));
&ok;

## test 3
my $hash = { qw( d_host some-random-host) };
print $_, "\nnot "
	unless ($_ = fetch($hash,\@response,$command));
&ok;

## test 4
print  $_, "\nnot "
	if ($_ = fetch($stuff,\@response,$command));
&ok;

## test 5
my ($err,$r);
foreach (@lines) {
  next if $_ eq (my $r = shift @response);
  print "error FILE:\n|$_|\nne LINE:\n|$r|\n";  
  $err = 1;  
}  
print "\nnot " if $err;
&ok;
