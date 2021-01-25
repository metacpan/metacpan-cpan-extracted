#!perl

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        print "1..0 # SKIP these tests are for release candidate testing";
        exit;
    }
}

use strict;
use warnings;

use Test::Whitespaces {
    dirs   => [ '.' ],
    ignore => [ qr|/blib/|,
                qr|/Makefile(\.old)?$|,
                qr|/MANIFEST(\.bak)?$|,
                qr|/pm_to_blib$|,
              ],
};
