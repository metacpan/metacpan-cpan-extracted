#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $machine = shift || 'orion.pcg.ull.es';
my $m = GRID::Machine->new( host => $machine, cleanup => 0 );

my $f = $m->open('> tutu.txt');
$m->print($f, "Hola Mundo!\n");
$m->print($f, "Hello World!\n");

# See the flush working
$m->flush($f);
print "\n*****************flush*****************\n";
print $m->eval(q{`cat tutu.txt`;})->Results;
print "\n*****************end flush*****************\n";

$m->printf($f, "%s %d %4d\n","Bona Sera Signorina", 44, 77);
$m->close($f);

$f = $m->open('tutu.txt');
my $x;
{
  $x = $m->getc($f)->result;
  last unless defined($x); 
  print $x;
  redo;
} 
$f->close();

# See autoflush working
$f = $m->open('> tutu.txt');
$m->autoflush($f);
$m->print($f, "Hola Mundo!\n");
$m->print($f, "Hello World!\n");

print "\n*****************autoflush*****************\n";
print $m->eval(q{`cat tutu.txt`;})->Results;
print "\n*****************end autoflush*****************\n";

$m->printf($f,"%s %d %4d\n","Bona Sera Signorina", 44, 77);
$m->close($f);

$f = $m->open('tutu.txt');
{
  $x = $m->getc($f)->result;
  last unless defined($x); 
  print $x;
  redo;
} 

$m->close($f);
print "\n********** getline *********\n";
$f = $m->open('tutu.txt');
$x = $m->getline($f)->result;
print $x;
$m->close($f);

print "\n********** getlines *********\n";
$f = $m->open('tutu.txt');
my @x = $m->getlines($f)->Results;
print @x;
$m->close($f);

# Read works differently from the others ...
$f = $m->open('tutu.txt');
$x = $m->read($f,14)->result;
print "\n******read********\n$x\n";
$m->close($f);

# sysread works differently from the others ...
$f = $m->open('tutu.txt');
$x = $m->sysread($f, 14)->result;
print "\n******sysread********\n$x\n";
$m->close($f);

# diamond: List context
$f = $m->open('tutu.txt');
@x = $m->diamond($f)->Results;
print "\n******diamond (literal) list context********\n@x\n";
$m->close($f);

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
my @a = $m->stat($f)->Results;
print "************stat***********\n@a\n";
$f->close();

