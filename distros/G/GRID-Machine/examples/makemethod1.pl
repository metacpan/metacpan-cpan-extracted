#!/usr/bin/perl -w
use strict;
use GRID::Machine;

my $host = shift || $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new(host => $host, uses => [q{List::Util}]);

$machine->makemethod( 'List::Util::reduce' );
my $r = $machine->reduce(sub { $a > $b ? $a : $b }, (7,6,5,12,1,9));
die $r->errmsg unless $r->ok;
print "\$r =  ".$r->result."\n";
