use strict;
use warnings;

use Test::More tests => 2;

my $dir = "t/var/";
my $file = "test.db";

if(-e $dir . $file) {
    ok(unlink($dir . $file), "Removing test database.");
    ok(rmdir($dir), "Removing test directory.");
}

else {
    fail("Can't find the test database.");
}

