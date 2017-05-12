use Config;
BEGIN {
  unless ($Config{useithreads}) {
    print "1..0 # SKIP your perl does not support ithreads\n";
    exit 0;
  }
}

use threads;
use threads::shared;

use strict;
use warnings;
no warnings 'once';
use Time::HiRes 'sleep';

$|++; # seems to be critical

share $::TEST_COUNT;

# older perls crash if threads are spawned way too quickly, sleep for 100 msecs
my @pool = map { sleep 0.1 and threads->create(\&run_torture) } (1..($ENV{AUTOMATED_TESTING} ? 20 : 5) );

# again - necessary for older perls
sleep 1;

for (@pool) {
  if ($_->join != 42) {
    die ($_->can('error') ? $_->error : "Thread did not finish successfully" );
  }
}

if ($ENV{AUTOMATED_TESTING}) {
  my $vsz;
  if (-f "/proc/$$/stat") {
    my $proc_stat = do { local (@ARGV, $/) = "/proc/$$/stat"; <> };
    ($vsz) = map { $_ / 1024 }
      (split (/\s+/, $proc_stat))[-22];  # go backwards because the %s of the procname can contain anything
  }

  printf STDERR "#\n# VSIZE:%dKiB\n", $vsz
    if $vsz;
}

print "1..$::TEST_COUNT\n";

sub run_torture {
  do 't/03torture.t';
  die $@ if $@ ne '';
  42;
}
