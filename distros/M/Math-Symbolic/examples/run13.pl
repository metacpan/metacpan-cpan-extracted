#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib/';
use Data::Dumper;
use Math::Symbolic qw/:all/;

my $exp = Math::Symbolic->parse_from_string('partial_derivative(1+2+3+4+a,a)');

print $exp->to_string('prefix') . " = " . $exp->value( a => 2 ) . "\n\n";

print "Is constant.\n"             if $exp->is_constant();
print "Can be written as a sum.\n" if $exp->is_sum();

