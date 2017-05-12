#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $m = GRID::Machine->new( host => shift());

$m->chdir('/tmp');
$m->put([ $0 ]);
$m->run("uname -a; ls -l $0");
