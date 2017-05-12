#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = 'casiano@beowulf.pcg.ull.es';

my $machine = GRID::Machine->new(
   command => "ssh -X $host perl -d:ptkdb", 
);

print $machine->eval(q{ 
  print "$ENV{DISPLAY}\n";
  system('ls');
  print %ENV,"\n";
});

__END__
