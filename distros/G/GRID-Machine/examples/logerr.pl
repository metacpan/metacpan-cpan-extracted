use strict;
use GRID::Machine;

my $machine = GRID::Machine->new( host => $ENV{GRID_REMOTE_MACHINE}, cleanup => 0, debug => shift()? 1234 : 0);
print $machine->eval(q{ 
  print File::Spec->tmpdir()."\n";
  my @files =  glob(File::Spec->tmpdir().'/rperl/*');
  local $" = "\n";
  print "@files\n";
  SERVER->remotelog("This message will be saved in the report file");
});
