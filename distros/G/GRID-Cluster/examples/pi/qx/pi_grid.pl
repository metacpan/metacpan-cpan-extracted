#!/usr/bin/perl
use warnings;
use strict;
use GRID::Cluster;
use Time::HiRes qw(time gettimeofday tv_interval);
use Getopt::Long;
use List::Util qw(sum);
use Pod::Usage;

my $config = 'MachineConfig.pm';
my $np = 1;
my $N = 100;
my $clean = 0;

GetOptions(
  'config=s' => \$config, # Module containing the definition of %machine and %map_id_machine
  'np=i'     => \$np,
  'N=i'      => \$N,
  'clean'    => \$clean,
  'help'     => sub { pod2usage( -exitval => 0, -verbose => 2,) },
) or pod2usage(-msg => "Bad usage\n", -exitval => 1, -verbose => 1,);

my %cluster_spec = do $config;
my $max_num_np = $cluster_spec{max_num_np};

my @machine = sort { $max_num_np->{$b} <=> $max_num_np->{$a} } keys  %$max_num_np;

my $c = GRID::Cluster->new(host_names => \@machine, %cluster_spec)
   || die "No machines has been initialized in the cluster";

$np ||= $c->get_num_machines();

$c->copyandmake(
      dir => 'pi',
      makeargs => 'pi',
      files => [ qw{pi.c Makefile} ],
      cleanfiles => $clean,
      cleandirs => $clean, # remove the whole directory at the end
      keepdir => 1,
    );

$c->chdir("pi/") || die "Can't change to pi/\n";

my @commands = map {  "./pi $_ $N $np " } 0..$np-1;

my $t0 = [gettimeofday];

my $pi = sum @{$c->qx(@commands)};

my $elapsed = tv_interval($t0);

print "Calculating Pi with $N iterations and $np processes\n";
print "Elapsed Time: $elapsed seconds\n";
print "Pi Value: $pi\n";

__END__


=head1 NAME

pi_grid.pl -- A simple example of parallel distributed computing

=head1 SYNOPSIS

  ./pi_grid.pl [options]

  --config  configuration_file

  --np number_of_processes

  --N  number_of_intervals 

  --clean    
       flag: clean files after execution

=cut

#
#
cat MachineConfig.pm
return ({europa => 0, beowulf => 0, orion => 0}, {europa => 4, beowulf => 1, orion => 1});

pp2@europa:~/LGRID-Cluster-edusegre/examples/pi/open$ ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 1
Calculating Pi with 1000000000 iterations and 1 processes
Elapsed Time: 62.915575 seconds
Pi Value: 3.141593
pp2@europa:~/LGRID-Cluster-edusegre/examples/pi/open$ ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 6
Calculating Pi with 1000000000 iterations and 6 processes
Elapsed Time: 10.586874 seconds
Pi Value: 3.141594
pp2@europa:~/LGRID-Cluster-edusegre/examples/pi/open$ ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 3
Calculating Pi with 1000000000 iterations and 3 processes
Elapsed Time: 20.986131 seconds
Pi Value: 3.141594
pp2@europa:~/LGRID-Cluster-edusegre/examples/pi/open$ !cat
pp2@europa:~/LGRID-Cluster-edusegre/examples/pi/open$ ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 12
Calculating Pi with 1000000000 iterations and 12 processes
Elapsed Time: 10.736294 seconds
Pi Value: 3.141588


*********************************************************
cat MachineConfig.pm
return ({europa => 0, beowulf => 0, orion => 0}, {europa => 1, beowulf => 1, orion => 1});

pp2@europa:~/LGRID-Cluster-edusegre/examples/pi/open$ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 3
Calculating Pi with 1000000000 iterations and 3 processes
Elapsed Time: 20.956588 seconds
Pi Value: 3.141594

real    0m22.549s
user    0m0.296s
sys     0m0.068s
pp2@europa:~/LGRID-Cluster-edusegre/examples/pi/open$ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 6
Calculating Pi with 1000000000 iterations and 6 processes
Elapsed Time: 15.694753 seconds
Pi Value: 3.141594

real    0m17.285s
user    0m0.304s
sys     0m0.104s
# gana porque europa son 4 y beowulf son 2
pp2@europa:~/LGRID-Cluster-edusegre/examples/pi/open$ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 12
Calculating Pi with 1000000000 iterations and 12 processes
Elapsed Time: 13.246352 seconds
Pi Value: 3.141588

real    0m14.798s
user    0m0.328s
sys     0m0.116s
pp2@europa:~/LGRID-Cluster-edusegre/examples/pi/open$ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 15
Calculating Pi with 1000000000 iterations and 15 processes
Elapsed Time: 12.924256 seconds
Pi Value: 3.1416

real    0m14.500s
user    0m0.372s
sys     0m0.108s

pp2@europa:~/LGRID-Cluster-edusegre/examples/pi/open$ time ./pi_grid.pl -co MachineConfig.pm -N 1000000000 -np 18
Calculating Pi with 1000000000 iterations and 18 processes
Elapsed Time: 14.406338 seconds
Pi Value: 3.141594

real    0m16.008s
user    0m0.364s
sys     0m0.120s
