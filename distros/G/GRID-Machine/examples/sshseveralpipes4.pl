#!/usr/local/bin/perl
# File: /home/pp2/src/perl/Event/select/sshseveralpipes.pl
use warnings;
use strict;
use IO::Select;
use GRID::Machine;
use Time::HiRes qw(time gettimeofday tv_interval);

my @machine = qw{orion beowulf nereida};
my $nummachines = @machine;
my %machine; # Hash of GRID::Machine objects
my %debug = ( orion => 0, beowulf => 12345,  nereida => 0);

my $np = shift || $nummachines; # number of processes
my $lp = $np-1;

my $N = shift || 100;

my @pid;  # List of process pids
my @proc; # List of handles
my %id;   # Gives the ID for a given handle

my $cleanup = 0;

my $pi = 0;

my $readset = IO::Select->new(); 

copyandcompile();

my $t0 = [gettimeofday];
for (0..$lp) {
  $pid[$_] = open($proc[$_], "ssh $machine[$_ % $nummachines] 'cd pi; ./pi $_ $N $np' |");
  $readset->add($proc[$_]); 
  my $address = 0+$proc[$_];
  $id{$address} = $_;
}

for (1..$np) {
  while(my @ready = $readset->can_read)
  { 
    foreach my $handle (@ready) { 
       my ($partial);

       my $address = 0+$handle;
       my $me = $id{$address};

       my $numBytesRead = sysread($handle,  $partial, 1024);
       chomp($partial);

       $pi += $partial;
       print "Process $me: machine = $machine[$me % $nummachines] partial = $partial pi = $pi\n";

       $readset->remove($handle) if eof($handle); 
     } 
  }
}

my $elapsed = tv_interval ($t0);
print "Pi = $pi. N = $N Time = $elapsed\n";
cleanup($cleanup);

sub cleanup {
  my $cleanup = shift;
  if ($cleanup) {
    for (@machine){
      my $m = $machine{$_};
      my $r = $m->eval(q{
        unlink qw{pi pi.c Makefile};
        chdir "..";
        rmdir "pi";
      });
      warn $r unless $r->ok;
    }
  }
}

sub copyandcompile {
  my $i = 0;
  for (@machine){
    my $m = GRID::Machine->new(host => $_, debug => $debug{$_});
    $m->mkdir("pi") unless $m->_x("pi")->result;
    $m->chdir("pi");
    unless ($m->_x("pi")->result) {
      $m->put(["pi.c", "Makefile"]);
      $m->system("make");
    }
    die "Can't execute 'pi'\n" unless $m->_x("pi")->result;
    $machine{$_} = $m;
    last unless $i++ < $np;
  }
}

# bugs: $host and script.pl (hard wired name)
sub gridpipe {
  my $machine = shift;
  my $exec = shift;

  my $host = $machine->host;
  my $ssh = $machine->ssh;

  my $script = q{
     my $exec = shift;

     my $dir = getcwd;
     open my $file, "> script.pl";
     print $file <<"EOF";
chdir $dir;
\%ENV = "qw{%ENV}";
exec($exec) or die "Can't execute $exec\n";
EOF
     close($file);
  };

  my $r = $machine->eval($script, $exec);
  die $r unless $r->ok;

  my $proc;
  my $pid = open($proc, "$ssh $host perl script.pl |");
  return ($pid, $proc);
}

