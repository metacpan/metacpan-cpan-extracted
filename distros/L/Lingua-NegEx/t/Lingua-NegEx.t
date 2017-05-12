# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-NegEx.t'

#########################

use Test::More tests => 2;
BEGIN { use_ok('Lingua::NegEx qw( negation_scope );') };

#########################

ok( negation_scope( 'there is no foo' ), 'something wrong with negation scope' );
