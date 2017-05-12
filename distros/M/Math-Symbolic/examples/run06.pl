#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Data::Dumper;

use Math::Symbolic qw/:all/;

my $var = Math::Symbolic::Variable->new();
my $a   = $var->new( 'x' => 2 );

print "Vars: x=" . $a->value() . " (Value is optional)\n\n";

my $op  = Math::Symbolic::Operator->new();
my $div = $op->new( '/', $a, $a );
my $mul = $op->new( '*', $a, $a );
my $sum = $op->new( '+', $a, $a );
my $dif = $op->new( '-', $a, $a );

print "Expressions: x/x, x*x, x+x, x-x\n\n";

print "prefix notation and evaluation:\n";
print $div->to_string('prefix') . "\n\n";
print $mul->to_string('prefix') . "\n\n";
print $sum->to_string('prefix') . "\n\n";
print $dif->to_string('prefix') . "\n\n";

print "Finally, we simplify the derived terms as much as possible:\n";

my $simplified = $div->simplify();
print "$simplified\n\n";
$simplified = $mul->simplify();
print "$simplified\n\n";
$simplified = $sum->simplify();
print "$simplified\n\n";
$simplified = $dif->simplify();
print "$simplified\n\n";

