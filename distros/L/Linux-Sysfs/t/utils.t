#!perl

use strict;
use warnings;
use Test::More tests => 1;
use Linux::Sysfs;

# get_mnt_path
{
    my $path = Linux::Sysfs->get_mnt_path;
    ok( length $path, 'get_mnt_path' );
}
