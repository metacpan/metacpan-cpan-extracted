#!/usr/bin/perl
use warnings;
use strict;

use Time::HiRes qw(time gettimeofday tv_interval);
use Scalar::Util qw{looks_like_number};
use File::Basename qw(fileparse);
use Getopt::Long;
use GRID::Cluster;
use IO::Select;
use Pod::Usage;

my $config = 'MachineConfig.pm';
my $np;

my $A  = "data/A100x100.dat";
my $B  = "data/B100x100.dat";
my $resultfile = '';
my $clean = 0; # clean the matrix dir in the remote machines

GetOptions (
  'config=s' => \$config, # Module containing the definition of %machine and %map_id_machine
  'np=i'     => \$np,
  'a=s'      => \$A,
  'b=s'      => \$B,
  'clean'    => \$clean,
  'result=s' => \$resultfile,
  'help'     => sub { pod2usage( -exitval => 0, -verbose => 2, ) },
) or pod2usage(-msg => "Bad usage\n", -exitval => 1, -verbose => 1,);

die "Cant find matrix file $A\n" unless -r $A;
die "Cant find matrix file $B\n" unless -r $B;

# Reads the dimensions of the matrix
open DAT, $A or die "The file $A can't be opened to read\n";
my $line = <DAT>;
my ($A_rows, $A_cols) = split(/\s+/, $line);
close DAT;

open DAT, $B or die "The file $B can't be opened to read\n";
$line = <DAT>;
my ($B_rows, $B_cols) = split(/\s+/, $line);
close DAT;

# Checks the dimensions of the matrix
die "Dimensions error. Matrix A: $A_rows x $A_cols, Matrix B: $B_rows x $B_cols.\n" if ($A_cols != $B_rows);

my $c = GRID::Cluster->new(config => $config)
  || die "No machines has been initialized in the cluster";

my $nummachines = $c->get_num_machines();
$np ||= $nummachines; # number of processes

# Checks that the number of processes doesn't exceed
# the number of rows of the matrix A
die "Too many processes. $np processes for $A_rows rows\n" if ($np > $A_rows);

my ($filename_A, $path_A) = fileparse($A);
my ($filename_B, $path_B) = fileparse($B);

$c->copyandmake(
  dir => 'matrix',
  makeargs => 'matrix',
  files => ['matrix.c', 'Makefile', $A, $B ],
  cleanfiles => $clean,
  cleandirs => $clean,
  keepdir => 1
);

$c->chdir("matrix/") || die "Can't change to matrix/\n";

my @commands = map { "./matrix $_ $np $filename_A $filename_B" } 0..$np-1;

my $t0 = [gettimeofday];

my $result = $c->qx(@commands);

# Place result rows in their final location
my @r = map { @{eval($_)} } @$result;

my $elapsed = tv_interval($t0);
print "Elapsed Time: $elapsed seconds\n";

if ($resultfile) { 
  print "sending result to $resultfile\n";
  open my $f, "> $resultfile";
  print $f "@$_\n" for @r;
  close($f);
}
elsif (@r < 11) { # Send to STDOUT
  print "@$_\n" for @r;
}

__END__

=head1 NAME

matrix_grid.pl -- A simple example of parallel distributed computing

=head1 SYNOPSIS

  ./matrix_grid.pl [options]

  --config  configuration_file

  --np number_of_processes

  --a file name of matrix A

  --b file name of matrix B

  --result file name of the result matrix

  --clean
       flag: clean files after execution

=head1 DESCRIPTION

This example uses the method open to create unidirectional pipes
for communications among different processes.
