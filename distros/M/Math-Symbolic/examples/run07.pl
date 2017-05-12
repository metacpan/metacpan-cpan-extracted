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
my $umi = $op->new( { type => U_MINUS, operands => [$a] } );

print "Expression: -x\n\n";

print "prefix notation:\n";
print $umi->to_string('prefix') . "\n\n";

print "infix notation:\n";
print $umi->to_string('infix') . "\n\n";

