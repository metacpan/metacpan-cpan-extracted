#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = shift || $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new( 
      host => $host,
      cleanup => 1,
      sendstdout => 1,
      startdir => '/tmp/perl5lib',
      prefix => '/tmp/perl5lib/',
   );

my $dir = $machine->getcwd->result;
print "$dir\n";

$machine->modput('Parse::Eyapp::') or die "can't send module\n";

print $machine->system('tree');
my $r =  $machine->system('doesnotexist');
print Dumper $r;
