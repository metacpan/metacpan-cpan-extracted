#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $m = GRID::Machine->new( host => shift());

$m->put([ $0, 'put.pl'], '/tmp/newname.pl');
$m->run("uname -a; ls -l /tmp/newname.pl");
