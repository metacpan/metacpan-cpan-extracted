#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $machine = shift || 'orion.pcg.ull.es';
my $m = GRID::Machine->new( host => $machine );

my $f = $m->open('> tutu.txt');
$f->print("Hola Mundo!\n");
$f->print("Hello World!\n");

# See the flush working
$f->flush;
print "\n*****************flush*****************\n";
print $m->eval(q{`cat tutu.txt`;})->Results;
print "\n*****************end flush*****************\n";

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

# See autoflush working
$f = $m->open('> tutu.txt');
$f->autoflush;
$f->print("Hola Mundo!\n");
$f->print("Hello World!\n");

print "\n*****************autoflush*****************\n";
print $m->eval(q{`cat tutu.txt`;})->Results;
print "\n*****************end autoflush*****************\n";

$f->printf("%s %d %4d\n","Bona Sera Signorina", 44, 77);
$f->close();

$f = $m->open('tutu.txt');
{
  $x = $f->getc();
  last unless defined($x); 
  print $x;
  redo;
} 

$f->close();
print "\n********** getline *********\n";
$f = $m->open('tutu.txt');
$x = $f->getline();
print $x;
$f->close();

print "\n********** getlines *********\n";
$f = $m->open('tutu.txt');
my @x = $f->getlines();
print @x;
$f->close();

# Read works differently from the others ...
$f = $m->open('tutu.txt');
$x = $f->read(14);
print "\n******read********\n$x\n";
$f->close();

# sysread works differently from the others ...
$f = $m->open('tutu.txt');
$x = $f->sysread(14);
print "\n******sysread********\n$x\n";
$f->close();

# diamond: List context
$f = $m->open('tutu.txt');
@x = $f->diamond;
print "\n******diamond list context********\n@x\n";
$f->close();

# diamond: scalar context
$f = $m->open('tutu.txt');
$x = <$f>;
print "\n******diamond scalar********\n$x\n";
$f->close();

# diamond: scalar context and $/ = undef
$f = $m->open('tutu.txt');
$m->input_record_separator(undef);
$x = <$f>;
print "\n******diamond scalar context and \$/ = undef********\n$x\n";
$f->close();
$m->input_record_separator("\n");

# diamond: list context and $/ = undef
$f = $m->open('tutu.txt');
$m->input_record_separator(undef);
@x = <$f>;
print "\n******diamond list context and \$/ = undef********\n@x\n";
print "Length of list ".scalar(@x)."\n";
$f->close();
$m->input_record_separator("\n");

#### stat
$f = $m->open('tutu.txt');
my @a = $f->stat;
print "************stat***********\n@a\n";
$f->close();

