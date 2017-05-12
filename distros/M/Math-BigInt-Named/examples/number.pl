#!/usr/bin/perl -w

use lib '../lib';
use lib 'lib';

use Math::BigInt::Named;

my $x = Math::BigInt::Named->new( shift );

print $x->name(),"\n";
