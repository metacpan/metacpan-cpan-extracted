#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $m = GRID::Machine->new( host => shift(), startdir => 'tutu',);

$m->put([ glob('nes*.pl') ]);
$m->run('uname -a; pwd; ls -l n*.pl');

print "*******************************\n";

my $progs = $m->glob('nes*.pl')->results;
$m->get($progs, '/tmp/');
system('uname -a; cd /tmp; pwd; ls -l n*.pl');
