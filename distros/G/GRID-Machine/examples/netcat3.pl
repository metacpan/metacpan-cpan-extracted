#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $port = shift || 12345;

my $debug = qq{PERLDB_OPTS="RemotePort=beowulf:$port"};

my $machine = GRID::Machine->new(
   command => qq{ssh beowulf '$debug perl -d'},
   #command => q{ssh nereida perl},
);

print $machine->eval(q{ 
  system('ls');
  print %ENV,"\n";
});

__END__
