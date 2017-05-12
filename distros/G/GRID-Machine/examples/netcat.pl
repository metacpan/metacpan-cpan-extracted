#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = GRID::Machine->new(
   command => q{ssh nereida 'PERLDB_OPTS="RemotePort=nereida:12345" perl -d'},
);

print $machine->eval(q{ 
  system('ls');
  print %ENV,"\n";
});

__END__
