#!perl

use strict;
use warnings;

our $CLASS;

# alias subroutine testing, included by sub_ali.t and mbi_ali.t

my $x = $CLASS->new(123);

is ($x->is_pos(), 1, '123 is positive');
is ($x->is_neg(), 0, '123 is not negative');
is ($x->as_int(), 123, '123 is 123 as int');
is (ref($x->as_int()), $CLASS, "as_int(123) is of class '$CLASS'");
$x->bneg();
is ($x->is_pos(), 0, '-123 is not positive');
is ($x->is_neg(), 1, '-123 is negative');
