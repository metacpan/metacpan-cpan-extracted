#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = shift || 'orion.pcg.ull.es';
my $m = GRID::Machine->new( host => $machine );

my $f = $m->open('> tutu.txt');
$f->print("Hola Mundo!\n");
$f->print("Hello World!\n");
$f->printf("%s %d %4d\n","Bona Sera Signorina", 44, 77);
$f->close();

$f = $m->open('tutu.txt');
my $x;
{
  $x = $f->getc();
  last unless defined($x); 
  print $x;
  redo;
} 
$f->close();

