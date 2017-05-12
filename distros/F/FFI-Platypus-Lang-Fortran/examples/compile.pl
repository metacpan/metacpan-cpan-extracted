use strict;
use warnings;
use File::Glob qw( bsd_glob );

foreach my $src_file (bsd_glob("*.{f,for,f90,f95}"))
{
  # this works in Linux with Gnu Fortran
  # , consult your Fortran compiler manual
  # for the appropriate command
  my $so_file = $src_file;
  $so_file =~ s/\..*$//;
  $so_file = "lib$so_file.so";
  
  my $src_time = (stat $src_file)[9];
  my $so_time  = -e $so_file ? (stat $so_file)[9] : 0;
  
  next unless $so_time < $src_time;
  
  my @cmd = ( 'gfortran', '-fPIC', -o => $so_file, '-shared', $src_file);
  print "+ @cmd\n";
  system @cmd;
}
