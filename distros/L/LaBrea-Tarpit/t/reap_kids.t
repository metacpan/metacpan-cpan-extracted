# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as erl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaBrea::NetIO qw(
	reap_kids
);
$loaded = 1;
print "ok 1\n";

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
	while ( $then >= $now );
  $now;
}

my $time = &next_sec;	# sync to epoch

my $n = 4;
my %kids;
foreach(1..$n) {
  my $pid = fork;
  unless ($pid) {	# CHILD
    while (1) {
      exit unless &next_sec < ($time + $_);
    }
  }
  else {		# PARENT
    $kids{$pid} = $_;
  }
}

my $alive = reap_kids(\%kids);
print "have $alive kids, should have $n\nnot "
	unless $alive == $n;
&ok;

foreach my $job (1..$n) {
  while (($alive = reap_kids(\%kids)) > $n - $job) {
    select(undef,undef,undef,0.1);	# delay
  }
  $now = time;
  print "$alive remaining kids, should have ", ($n - $job), "\nnot "
	unless $alive == $n - $job;
  &ok;
  
  print 'bad reaper timing ', $now - $time, " should be $job\nnot "
	unless $job == $now - $time;
  &ok;
}

while (1) {
  last unless reap_kids(\%kids);	# purge remaining kids
  sleep 1;
}
