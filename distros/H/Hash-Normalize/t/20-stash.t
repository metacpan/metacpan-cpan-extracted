#!perl -T

use strict;
use warnings;

use Test::More tests => 5;

use Hash::Normalize qw<normalize get_normalization>;

my $cafe_nfc = "caf\x{e9}";
my $cafe_nfd = "cafe\x{301}";

eval <<"CODE";
package Hash::Normalize::TestPkg;

BEGIN { Hash::Normalize::normalize(%Hash::Normalize::TestPkg::) }

sub $cafe_nfd { return 123 }

sub get_coffee_nfc { $cafe_nfc() + 1 }

sub get_coffee_nfd { $cafe_nfd() + 2 }

package Hash::Normalize::TestPkg2;

our \@ISA;
BEGIN {
 \@ISA = 'Hash::Normalize::TestPkg';
}

1;
CODE

is $@, '', 'test package compiled properly';

SKIP: {
 skip 'eval suffers from The Unicode Bug before perl 5.16' => 4
                                                           unless "$]" >= 5.016;

 is Hash::Normalize::TestPkg::get_coffee_nfc(), 124, 'nfc func call';
 is Hash::Normalize::TestPkg::get_coffee_nfd(), 125, 'nfd func call';
 is Hash::Normalize::TestPkg2->get_coffee_nfc(), 124, 'nfc meth call';
 is Hash::Normalize::TestPkg2->get_coffee_nfd(), 125, 'nfd meth call';
}
