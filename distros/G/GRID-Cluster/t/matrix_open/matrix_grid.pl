#!/usr/bin/perl
use warnings;
use strict;

use Scalar::Util qw{looks_like_number};
use File::Basename qw(fileparse);
use Getopt::Long;
use GRID::Cluster;
use IO::Select;
use Pod::Usage;

my $A  = "matrix_open/data/A10x10.dat";
my $B  = "matrix_open/data/B10x10.dat";
my $resultfile = '';
my $clean = 0; # clean the matrix dir in the remote machines

GetOptions (
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
die "Dimensions error. Matrix A: $A_rows x $A_cols, Matrix B: $B_rows x $B_cols\n" if ($A_cols != $B_rows);

my @machine = split(/:/, $ENV{GRID_REMOTE_MACHINES});
my ($debug, $max_num_np);

for (@machine) {
  $debug->{$_} = 0;
  $max_num_np->{$_} = 1;
}

my $c = GRID::Cluster->new(host_names => \@machine, debug => $debug, max_num_np => $max_num_np)
  || die "No machines has been initialized in the cluster";

my $np = $c->get_max_np();

# Checks that the number of processes doesn't exceed
# the number of rows of the matrix A
die "Too many processes. $np processes for $A_rows rows\n" if ($np > $A_rows);

my ($filename_A, $path_A) = fileparse($A);
my ($filename_B, $path_B) = fileparse($B);

$c->copyandmake(
  dir => 'matrix_open',
  makeargs => 'matrix',
  files => ['matrix_open/matrix.c', 'matrix_open/Makefile', $A, $B ],
  cleanfiles => $clean,
  cleandirs => $clean,
  keepdir => 1
);

$c->chdir("matrix_open/");

my @commands = map { "./matrix $_ $np $filename_A $filename_B |" } 0..$np-1;
my $handle_info = $c->open(@commands);
my $result = $c->close($handle_info);

# Place result rows in their final location
my @r = map { @{eval($_)} } @$result;

if ($resultfile) { 
  print "sending result to $resultfile\n";
  open my $f, "> $resultfile";
  print $f "@$_\n" for @r;
  close($f);
}
elsif (@r < 11) { # Send to STDOUT
  STDOUT->autoflush(1);
  print "@$_\n" for @r;
}

__END__

=head1 NAME

matrix_grid.pl -- A simple example of parallel distributed computing

=head1 SYNOPSIS

  ./matrix_grid.pl [options]

  --a file name of matrix A

  --b file name of matrix B

  --result file name of the result matrix

  --clean
       flag: clean files after execution

=head1 DESCRIPTION

This example uses the method open to create unidirectional pipes
for communications among different processes.
