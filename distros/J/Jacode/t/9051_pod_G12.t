######################################################################
#
# t/9051_pod_G12.t - Pod::Checker test (for Pod::Checker >= 1.60)
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

# This test targets Pod::Checker >= 1.60.
# For older versions, see t/9050_pod_G11.t.

eval q{ use Pod::Checker 1.60; };
if ($@) {
    print "1..1\n";
    print "ok 1 - SKIP Pod::Checker < 1.60 (version: ",
          (eval q{ $Pod::Checker::VERSION } || 'unknown'), ")\n";
    exit 0;
}

eval q{ use Test::Pod 1.48 tests => 1; };
if ($@) {
    print "1..1\n";
    print "ok 1 - SKIP Test::Pod not available\n";
    exit 0;
}

pod_file_ok('lib/Jacode.pm');

__END__
