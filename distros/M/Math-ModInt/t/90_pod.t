# Copyright (c) 2007-2010 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 90_pod.t 2 2010-09-25 21:31:14Z demetri $

# Check whether POD parses without errors or warnings.
# This is a test for the distribution maintainer.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/90_pod.t'

use strict;
use warnings;
use lib 't/lib';
use Test::MyUtils;

BEGIN {
    maintainer_only();
    use_or_bail('Test::Pod', '1.00');
    require Test::Pod;                  # redundant, but clue for CPANTS
}

all_pod_files_ok();

__END__
