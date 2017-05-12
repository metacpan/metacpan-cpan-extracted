#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = shift || $ENV{GRID_REMOTE_MACHINE};
my $m = GRID::Machine->new( host => $machine );

my $f = $m->open('> tutu.txt');
$f->print("Hola Mundo!\n");
$f->print("Hello World!\n");
$f->printf("%s %d %4d\n","Bona Sera Signorina", 44, 77);
$f->close();

$f = $m->open('tutu.txt');
my $x = <$f>;
print "\n******diamond scalar********first line=\n$x\n";
$x = <$f>;
print "\n******diamond scalar********second line=\n$x\n";
$f->close();

$f = $m->open('tutu.txt');
my $old = $m->input_record_separator(undef);
$x = <$f>;
print "\n******diamond scalar context and \$/ = undef********\n$x\n";
$f->close();
$old = $m->input_record_separator($old);

