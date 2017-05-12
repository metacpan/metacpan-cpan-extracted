#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Filesys::Btrfs') || BAIL_OUT("Cannot load Filesys::Btrfs" );
}

diag("Testing Filesys::Btrfs $Filesys::Btrfs::VERSION, Perl $], $^X");
