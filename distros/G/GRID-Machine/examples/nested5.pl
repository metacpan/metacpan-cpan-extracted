#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
use PDL;
use PDL::IO::Dumper;

use Data::Dumper;

my $host = shift || 'casiano@beowulf.pcg.ull.es';

my $machine = GRID::Machine->new(host => $host, uses => [qw(PDL)]);

my $r = $machine->sub( 
  rpush => q{
    my $f = shift;

    return $f;
  },
);
$r->ok or die $r->errmsg;

my $f = pdl [[1,2],[3,4]];

$r = $machine->rpush($f );
die $r->errmsg unless $r->ok;

print sdump($r->result)."\n";
