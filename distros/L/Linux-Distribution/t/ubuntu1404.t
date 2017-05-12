use 5.006000;
use strict;
use warnings;

use Test::More tests => 2;
use lib '../lib/';
use Linux::Distribution;

local $Linux::Distribution::release_files_directory='t/ubuntu1404/';
my $linux = Linux::Distribution->new;
my $distro = $linux->distribution_name();
is($distro,'ubuntu');
my $version = $linux->distribution_version();
is ($version,'14.04');
