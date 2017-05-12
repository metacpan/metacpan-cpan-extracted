#!/usr/bin/perl
use warnings;
use strict;

use Scalar::Util qw{looks_like_number};
use IO::Select;
use GRID::Cluster;
use Parallel::ForkManager;
use Getopt::Long;
use Data::Dumper;
use Pod::Usage;

my $A  = "matrix_open2/data/A10x10.dat";
my $B  = "matrix_open2/data/B10x10.dat";
my $clean = 0; # clean the matrix dir in the remote machines
my $resultfile = '';

GetOptions(
  'a=s'      => \$A,
  'b=s'      => \$B,
  'clean'    => \$clean,
  'result=s' => \$resultfile,
  'help'     => sub { pod2usage( -exitval => 0, -verbose => 2, ) },
) or pod2usage(-msg => "Bad usage\n", -exitval => 1, -verbose => 1,);

die "Cant find matrix file $A\n" unless -r $A;
die "Cant find matrix file $B\n" unless -r $B;

# Reads the matrix files
open DAT, $A or die "The file $A can't be opened to read\n";
my @A_lines = <DAT>;
my ($A_rows, $A_cols) = split(/\s+/, $A_lines[0]);
close DAT;
chomp @A_lines;

open DAT, $B or die "The file $B can't be opened to read\n";
my @B_lines = <DAT>;
my ($B_rows, $B_cols) = split(/\s+/, $B_lines[0]);
close DAT;
chomp @B_lines;

# Checks the dimensions of the matrix
die "Dimensions error. Matrix A: $A_rows x $A_cols, Matrix B: $B_rows x $B_cols.\n" if ($A_cols != $B_rows);

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

sub send_message {
  my $d = shift;

  my $b = syswrite($d->{handle},
           join(" ", 
                  $d->{chunksize}, 
                  $d->{A_cols}, 
                  @A_lines[$d->{start}.. $d->{end}], 
                  @B_lines,
                  "\cN"
               ),
  );
}

$c->copyandmake(
  dir        => 'matrix_open2',
  makeargs   => 'matrix',
  files      => [ 'matrix_open2/matrix.c', 'matrix_open2/Makefile' ],
  cleanfiles => $clean,
  cleandirs  => $clean, # remove the whole directory at the end
  keepdir    => 1,
);

$c->chdir("matrix_open2/");

my @commands = map { "./matrix" } 0..$np-1;

my $handles_info = $c->open2(@commands);

# Calculates the start, the end and the size of the chunk that
# is going to be processed
my ($chunksize, $start, $end);
my $div = int($A_rows / $np);
my $rest = $A_rows % $np;
my @str_handles;

for (my $counter = 0; $counter < $np; $counter++) {
  if ($counter < $rest) {
    $chunksize = $div + 1;
    $start = $counter * $chunksize + 1;
  }
  else {
    $chunksize = $div;
    $start = $counter * $chunksize + $rest + 1;
  }
  $end = $start + $chunksize;

  # Builds the string which has to be written into the pipe
  # This string contains the chunk of the matrix A and fully
  # the matrix B
  $str_handles[$counter] = {
     chunksize => $chunksize,
     A_cols => $A_cols,
     start => $start,
     end => ($end - 1),
     handle => ${$handles_info->{wproc}}[$counter],
     rhandle => ${$handles_info->{rproc}}[$counter],
     host => ${$handles_info->{map_id_machine}}{$counter}
  };
}

# Parallelise the writing into the pipes
my $pm = Parallel::ForkManager->new($np / 2);
foreach (@str_handles) {
  my $pid = $pm->start;
  next if ($pid);
  send_message($_);
  $pm->finish;
}
$pm->wait_all_children;

my $result = $c->close2($handles_info);

# Place result rows in their final location
my @r = map { @{eval($_)} } @$result;

if ($resultfile) { 
  print "Sending result to $resultfile\n";
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

This example uses the method open2 to create bidirectional pipes for
communications among different processes.
