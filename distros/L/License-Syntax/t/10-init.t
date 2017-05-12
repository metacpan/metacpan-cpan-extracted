#!perl -T

use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;
use License::Syntax;
my $o = new License::Syntax {foo => 'bar'};

#1
ok(defined($o), "basic new");
#2
isa_ok($o, 'License::Syntax'); undef $o;

#3
$o = new License::Syntax licensemap => 'license_map.csv';
isa_ok($o, 'License::Syntax'); undef $o;
