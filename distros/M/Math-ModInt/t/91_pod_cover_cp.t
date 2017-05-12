# Copyright (c) 2007-2010 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 91_pod_cover_cp.t 4 2010-09-26 00:31:09Z demetri $

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
