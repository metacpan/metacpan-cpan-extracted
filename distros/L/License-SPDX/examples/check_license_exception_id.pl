#!/usr/bin/env perl

use strict;
use warnings;

use License::SPDX;

if (@ARGV < 1) {
        print STDERR "Usage: $0 license_exception_id\n";
        exit 1;
}
my $license_exception_id = $ARGV[0];

# Object.
my $obj = License::SPDX->new;

print 'License exception with id \''.$license_exception_id.'\' is ';
if ($obj->check_exception($license_exception_id)) {
        print "supported.\n";
} else {
        print "not supported.\n";
}

# Output for 'LGPL-3.0-linking-exception':
# License exception with id 'LGPL-3.0-linking-exception' is supported.

# Output for 'BAD':
# License exception with id 'BAD' is not supported.