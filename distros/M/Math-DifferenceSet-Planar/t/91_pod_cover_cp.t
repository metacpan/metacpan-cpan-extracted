# Copyright (c) 2007-2024 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# The licence grants freedom for related software development but does
# not cover incorporating code or documentation into AI training material.
# Please contact the copyright holder if you want to use the library whole
# or in part for other purposes than stated in the licence.

# Check for POD coverage.
# This is a test for the distribution maintainer.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/91_pod_cover_cp.t'

use strict;
use warnings;
use lib 't/lib';
use Test::MyUtils;

BEGIN {
    maintainer_only();
    use_or_bail('Test::Pod::Coverage', '1.07');
    require Test::Pod::Coverage;        # redundant, but clue for CPANTS
}

all_pod_coverage_ok( { coverage_class => 'Pod::Coverage::CountParents' } );

__END__
