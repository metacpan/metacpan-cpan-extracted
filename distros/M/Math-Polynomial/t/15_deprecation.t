# Copyright (c) 2017-2019 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Checking final state of Math::Polynomial::Generic after deprecation.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/15_deprecation.t'

#########################

use strict;
use warnings;
use Test;
BEGIN {
    plan tests => 3;
}

#########################

my $loaded = eval { require Math::Polynomial::Generic };
my $imported;
my $version;

skip(!$loaded,
    not $imported = eval { Math::Polynomial::Generic->import(), 1 }
);

skip(!$loaded,
    !$imported && $@ =~ /Math::Polynomial::Generic is no longer available/
);

skip(!$loaded,
    eval { Math::Polynomial::Generic->VERSION('1.014') }
);

__END__
