#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = $ENV{GRID_REMOTE_MACHINE};
my $debug = @ARGV ? 1234 : 0;

my $m = GRID::Machine->new( host => $machine, debug => $debug );

  $m->compile( "is_dir" => q{
      my $file = shift;
      return -d $file;
    }
  );

my @files = $m->eval(q{ glob('*') })->Results;

for (@files) {
  my $r = $m->eval(q{
    $_ = shift;

    print "$_ is a directory\n" if is_dir($_);

  }, $_);
  print $r;
}
