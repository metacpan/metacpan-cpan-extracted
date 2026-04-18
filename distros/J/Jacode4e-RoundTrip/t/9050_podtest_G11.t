######################################################################
#
# 9050_podtest_G11.t
#
# Copyright (c) 2019, 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $pod_checker_version = do {
    eval q{ require Pod::Checker };
    $@ ? 0 : $Pod::Checker::VERSION + 0;
};

if ($pod_checker_version < 1.51) {
    print "1..1\n";
    print "ok 1 - SKIP Pod::Checker $pod_checker_version < 1.51\n";
    exit;
}

eval q{ use Test::Pod 1.48 tests => 1; };
if ($@) {
    print "1..1\n";
    print "ok 1 - SKIP\n";
}
else {
    pod_file_ok('lib/Jacode4e/RoundTrip.pm');
}

__END__
