# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl File-SharedVar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
our $DEBUG=0;
BEGIN { use_ok('File::SharedVar') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

  diag("This module relies on your filesystem properly supporting file locking (and your selection of a lockfile on that filesystem), which is not the case for Windows Services for Linux (WSL1 and WSL2) nor their lxfs filesystem.\n\nThe following test takes less than 1 minute on working systems and uses the filesystems on \"/tmp\" and \"./\" in testing.\n\nWhen run on a system with broken locking, these tests may take an extended amount of time to fail (many minutes or even hours).\n\nIf you see \"Cannot truncate file: Invalid argument\" below; one of these filesystems under test does not have functional locking.\n");

foreach my $lockfile ('/tmp/test_file_sharedvar.dat','./test_file_sharedvar.dat') {
  
  my $shared_var=File::SharedVar->new(file => $lockfile, create => 1); # create new
  ok(1,"new ok") if($shared_var);
  
  $shared_var->update('caller', "I am $$", 0);
  ok($shared_var->read('caller') eq "I am $$","stored OK on $lockfile");
  
  $shared_var->update('foo', 1, 1);
  ok($shared_var->read('foo') == 1,"inc OK on $lockfile");
  
  $shared_var->update('foo', -1, 1);
  ok(!$shared_var->read('foo') ,"dec OK on $lockfile");
  
  my $nforks=10;
  my $nreps=10;
  my %kids;
  
  
  for (my $i = 0; $i < $nforks; $i++) {
    my $pid = fork();
    diag("$pid is proc #$i") if($DEBUG && $pid);
    die "Cannot fork: $!" unless defined $pid;
  
    if ($pid == 0) { # Child process
      #diag("forked: $pid is proc #$_");
      my $s2=File::SharedVar->new(file => $lockfile);
      &inky($s2,$nreps);
      # diag("$$ over #$_");
      &diag( "$$ ended. foo=",$s2->read('foo') ) if($DEBUG);
      exit(0);
    } else { # Parent process
      $kids{$pid}++;
    }
  
  }
  
  &inky($shared_var,$nreps); # parent does this as well.

  # # Parent process waits for all child processes to exit
  # foreach my $pid (@child_pids) {
  #   diag("$$ waiting on $pid. foo=",$shared_var->read('foo'));
  #   waitpid($pid, 0); # never exits on broken systems...
  # }


if($nforks) {
  &diag( "\e[1mwait..\e[0m" ) if($DEBUG);
  # Parent process waits for all children to terminate
  my $kid;
  while (($kid = wait()) != -1) {
    delete $kids{$kid};
    diag( "Parent: Child with PID $kid terminated. togo=" . join(",",keys(%kids))) if($DEBUG);
  }


}

  

  # Test that the value of 'foo' equals $nforks * $nreps
  my $expected = 0; # $nforks * $nreps;
  my $actual   = $shared_var->read('foo');
  
  ok($actual == $expected, "foo equals $expected after children have incremented using $lockfile");
  diag("Test over\n") if($DEBUG);
  unlink($lockfile);
} # $lockfile



#diag( "\n\nHI\n\n" );

done_testing();


sub inky {
  my($s,$nreps)=@_;
  for (1 .. $nreps) {
    $s->update('foo', 1, 1); # Increment 'foo' by 1
    #diag("$$ inc #$_");
    $s->update('foo', -1, 1); # Decrement 'foo' by 1
  }
}

=for later


my $first = 0;
my $ntest = 4;

# Update variables
$shared_var->update('last', "I am $$", 0);
$shared_var->update("me $$", $shared_var->read('foo'), 0);

for my $i (1..$ntest) {
  my $value = $shared_var->read('foo') // 0;
  $first = 1 if $value == 0;
  $shared_var->update('foo', 1, 1);  # Increment 'foo' by 1
}

for my $i (1..$ntest) {
  $shared_var->update('foo', -1, 1);  # Decrement 'foo' by 1
}

sleep(2);  # Allow other processes to run concurrently

# Print final value of 'foo'
print "$$ Final value of foo: " . ($shared_var->read('foo') // 0) . "\n";

if ($first) {
  sleep(10);
  print "\e[32;1m$$ Last before ending: foo=" . ($shared_var->read('foo') // 0) . "\e[0m\n";
}

=cut
