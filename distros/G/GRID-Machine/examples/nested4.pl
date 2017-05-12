#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $host = shift || 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new(host => $host);

my $r = $machine->sub( 
  rpush => q{
    my $f = shift;
    my $s = shift;

    push @$f, $s;
    return $f;
  },
);
$r->ok or die $r->errmsg;

my $f = [[1..3], { a => [], b => [2..4] } ];
my $s = { x => 1, y => 2};

$r = $machine->rpush($f, $s);
die $r->errmsg unless $r->ok;

$Data::Dumper::Indent = 0;
print Dumper($r->result)."\n";
