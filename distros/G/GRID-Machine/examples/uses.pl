#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use PDL;
use PDL::IO::Dumper;

my $host = shift || $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new(host => $host, uses => [qw(PDL PDL::IO::Dumper)]);

my $r = $machine->sub( mp => q{
    my ($f, $g) = @_;
    
    my $h = (pdl $f) x (pdl $g);

    sdump($h);
  },
);
$r->ok or die $r->errmsg;

my $f = [[1,2],[3,4]];
$r = $machine->mp($f, $f);
die $r->errmsg unless $r->ok;
my $matrix =  eval($r->result);
print "\$matrix is a ".ref($matrix)." object\n";
print "[[1,2],[3,4]] x [[1,2],[3,4]] = $matrix";
