#!/usr/bin/perl
use warnings;
use strict;
use GRID::Cluster;
use Getopt::Long;
use List::Util qw(sum);
use Pod::Usage;

my $N = 1000;
my $clean = 1;

GetOptions(
  'N=i'      => \$N,
  'clean'    => \$clean,
  'help'     => sub { pod2usage( -exitval => 0, -verbose => 2,) },
) or pod2usage(-msg => "Bad usage\n", -exitval => 1, -verbose => 1,);

my @machine = split(/:/, $ENV{GRID_REMOTE_MACHINES});
my ($debug, $max_num_np);

for (@machine) {
  $debug->{$_} = 0;
  $max_num_np->{$_} = 1;
}

my $c = GRID::Cluster->new(host_names => \@machine, debug => $debug, max_num_np => $max_num_np)
   || die "No machines has been initialized in the cluster";

my $np = $c->get_max_np();

$c->copyandmake(
      dir => 'pi',
      makeargs => 'pi',
      files => [ qw{pi_qx/pi.c pi_qx/Makefile} ],
      cleanfiles => $clean,
      cleandirs => $clean, # remove the whole directory at the end
      keepdir => 0,
    );

$c->chdir("pi/");

my @commands = map { "./pi $_ $N $np" } 0..$np-1;
my $results = $c->qx(@commands);
my $pi = sum @{$results};
STDOUT->autoflush(1);
print "Pi Value: $pi\n";

__END__

=head1 NAME

pi_grid.pl -- A simple example of parallel distributed computing

=head1 SYNOPSIS

  ./pi_grid.pl [options]

  --N  number_of_intervals 

  --clean    
       flag: clean files after execution
