# Copyright (c) 2015-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Tests of Math::ModInt handling Math::BigRat objects.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/10_bigrat.t'

#########################

use strict;
use warnings;
use lib 't/lib';
use Test::MyUtils;
BEGIN {
    use_or_bail('Math::BigRat');
}
use Test;
use Math::ModInt qw(qmod);

plan tests => 2;

my $q = Math::BigRat->new('2/3');
my $o = qmod($q, 5);

ok("$o" eq 'mod(4, 5)');
ok($o->isa(Math::ModInt::));

__END__
