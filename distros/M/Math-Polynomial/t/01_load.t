# Copyright (c) 2007-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Checking whether Math::Polynomial 1.000 can be loaded at all.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/01_load.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 1 };
use Math::Polynomial 1.000;
ok(1);

#########################

__END__
