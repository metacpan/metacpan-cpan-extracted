# Copyright (c) 2007-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Checking deprecation of interface extension Math::Polynomial::Generic.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/15_deprecation.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 5 };

#########################

my $loaded = eval { require Math::Polynomial::Generic };
ok($loaded);

my $warning = 'none';
$SIG{__WARN__} = sub { $warning = $_[0] };

my $x = Math::Polynomial::Generic::X();
ok(ref($x), 'Math::Polynomial::Generic');
ok($warning =~ /^Math::Polynomial::Generic is deprecated/);

$warning = 'none';
Math::Polynomial::Generic->import(qw(X));
ok($warning =~ /^Math::Polynomial::Generic is deprecated/);

$warning = 'none';
Math::Polynomial::Generic->import(qw(:legacy X));
ok($warning, 'none');

__END__
