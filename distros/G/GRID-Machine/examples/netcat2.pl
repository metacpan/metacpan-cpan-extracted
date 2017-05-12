#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = GRID::Machine->new(
   command => q{ssh localhost 'PERLDB_OPTS="RemotePort=localhost:12345" perl -d'},
   #command => q{ssh nereida perl},
);

print $machine->eval(q{ 
  system('ls');
  print %ENV,"\n";
});

__END__
