# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Tests for Math::Logic::Ternary::Object

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/01_object.t'

#########################

use strict;
use warnings;
use Test::More tests => 3;

#########################

my $r;

package Math::Logic::Ternary::Test::A;

$r = eval {
    use Role::Basic qw(with);
    with qw(Math::Logic::Ternary::Object);
    1
};
Test::More::ok(!defined $r);            # 1
Test::More::like($@, qr/ requires the method /);  # 2

package Math::Logic::Ternary::Test::B;

sub Trit      {}
sub Trits     {}
sub Rtrits    {}
sub Sign      {}
sub as_int    {}
sub as_int_u  {}
sub as_int_v  {}
sub as_string {}
sub is_equal  {}
sub res_mod3  {}

$r = eval {
    use Role::Basic qw(with);
    with qw(Math::Logic::Ternary::Object);
    1
};
print "# $@" if !$r;
Test::More::is($r, 1);                  # 3

__END__
