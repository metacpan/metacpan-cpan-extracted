#!/usr/bin/perl
use warnings;
use strict;
use IO::Select;
use GRID::Machine;
use Time::HiRes qw(time gettimeofday tv_interval);

#my @machine = qw{europa};
#my @machine = qw{europa beowulf orion};
my @machine = qw{nereida europa};
#my @machine = qw{127.0.0.1 127.0.0.2 127.0.0.3 127.0.0.4};
#my @machine = qw{beo chum};
my $nummachines = @machine;
my %machine; # Hash of GRID::Machine objects
#my %debug = (beowulf => 12345, orion => 0, nereida => 0);
#my %debug = (europa => 12344, beowulf => 0, orion => 0, nereida => 0);
my %debug = (europa => 0, beowulf => 0, orion => 0, nereida => 0);

my $np = shift || $nummachines; # number of processes
my $lp = $np-1;

my $N = shift || 100;

my @pid;  # List of process pids
my @proc; # List of handles
my %id;   # Gives the ID for a given handle

my $cleanup = 0;

my $pi = 0;

my $readset = IO::Select->new(); 

my $i = 0;
for (@machine){
  my $m = GRID::Machine->new(host => $_, debug => $debug{$_}, );

  $m->copyandmake(
    dir => 'pi', 
    makeargs => 'pi', 
    files => [ qw{pi.c Makefile} ], 
    cleanfiles => $cleanup,
    cleandirs => $cleanup, # remove the whole directory at the end
    keepdir => 1,
  );

  $m->chdir("pi/");

  die "Can't execute 'pi'\n" unless $m->_x("pi")->result;

  $machine{$_} = $m;
  last unless ++$i < $np;
}

my $t0 = [gettimeofday];
for (0..$lp) {
  my $hn = $machine[$_ % $nummachines];
  my $m = $machine{$hn};
  ($proc[$_], $pid[$_]) = $m->open("./pi $_ $N $np |");
  $readset->add($proc[$_]); 
  my $address = 0+$proc[$_];
  $id{$address} = $_;
}

my @ready;
my $count = 0;
do {
  push @ready, $readset->can_read unless @ready;
  my $handle = shift @ready;

  my $me = $id{0+$handle};

  my ($partial);
  my $numBytesRead = sysread($handle,  $partial, 1024);
  chomp($partial);

  $pi += $partial;
  print "Process $me: machine = $machine[$me % $nummachines] partial = $partial pi = $pi\n";

  $readset->remove($handle) if eof($handle); 
} until (++$count == $np);

my $elapsed = tv_interval ($t0);
print "Pi = $pi. N = $N Time = $elapsed\n";

__END__
pp2@nereida:~/LGRID_Machine/examples$ time ssh beowulf 'pi/pi 0 1000000000 1'
3.141593

real    0m27.020s
user    0m0.036s
sys     0m0.008s

casiano@beowulf:~$ time ssh orion 'pi/pi 0 1000000000 1'
3.141593

real    0m29.120s
user    0m0.028s
sys     0m0.003s

pp2@nereida:~/LGRID_Machine/examples$ time ssh nereida 'pi/pi 0 1000000000 1'
3.141593

real    0m32.534s
user    0m0.036s
sys     0m0.008s

pp2@nereida:~/LGRID_Machine/examples$ time gridpipes.pl 1 1000000000
Process 0: machine = beowulf partial = 3.141593 pi = 3.141593
Pi = 3.141593. N = 1000000000 Time = 27.058693

real    0m28.917s
user    0m0.584s
sys     0m0.192s

pp2@nereida:~/LGRID_Machine/examples$ time gridpipes.pl 2 1000000000
Process 0: machine = beowulf partial = 1.570796 pi = 1.570796
Process 1: machine = orion partial = 1.570796 pi = 3.141592
Pi = 3.141592. N = 1000000000 Time = 15.094719

real    0m17.684s
user    0m0.904s
sys     0m0.260s


pp2@nereida:~/LGRID_Machine/examples$ time gridpipes.pl 3 1000000000
Process 0: machine = beowulf partial = 1.047198 pi = 1.047198
Process 1: machine = orion partial = 1.047198 pi = 2.094396
Process 2: machine = nereida partial = 1.047198 pi = 3.141594
Pi = 3.141594. N = 1000000000 Time = 10.971036

real    0m13.700s
user    0m0.952s
sys     0m0.240s

# 2 veces nereida
pp2@nereida:~/LGRID_Machine/examples$ time gridpipes.pl 2 1000000000
Process 0: machine = 127.0.0.1 partial = 1.570796 pi = 1.570796
Process 1: machine = 127.0.0.2 partial = 1.570796 pi = 3.141592
Pi = 3.141592. N = 1000000000 Time = 16.38121

real    0m17.849s
user    0m0.504s
sys     0m0.212s

******************************************
con -O 3 en gcc
pp2@nereida:~/LGRID_Machine/examples$ time gridpipes.pl 4 1000000000
Process 3: machine = 127.0.0.4 partial = 0.785398 pi = 0.785398
Process 0: machine = 127.0.0.1 partial = 0.785398 pi = 1.570796
Process 1: machine = 127.0.0.2 partial = 0.785398 pi = 2.356194
Process 2: machine = 127.0.0.3 partial = 0.785398 pi = 3.141592
Pi = 3.141592. N = 1000000000 Time = 18.508143

real    0m21.299s
user    0m0.840s
sys     0m0.360s
pp2@nereida:~/LGRID_Machine/examples$ time gridpipes.pl 2 1000000000
Process 1: machine = 127.0.0.2 partial = 1.570796 pi = 1.570796
Process 0: machine = 127.0.0.1 partial = 1.570796 pi = 3.141592
Pi = 3.141592. N = 1000000000 Time = 16.552487

real    0m18.076s
user    0m0.504s
sys     0m0.188s
pp2@nereida:~/LGRID_Machine/examples$ time gridpipes.pl 3 1000000000
Process 1: machine = 127.0.0.2 partial = 1.047198 pi = 1.047198
Process 0: machine = 127.0.0.1 partial = 1.047198 pi = 2.094396
Process 2: machine = 127.0.0.3 partial = 1.047198 pi = 3.141594
Pi = 3.141594. N = 1000000000 Time = 17.372372

real    0m19.461s
user    0m0.696s
sys     0m0.240s
pp2@nereida:~/LGRID_Machine/examples$ time gridpipes.pl 1 1000000000
Process 0: machine = 127.0.0.1 partial = 3.141593 pi = 3.141593
Pi = 3.141593. N = 1000000000 Time = 32.968117

real    0m33.858s
user    0m0.336s
sys     0m0.128s

