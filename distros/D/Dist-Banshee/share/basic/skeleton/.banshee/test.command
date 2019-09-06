#! perl
use strict;
use warnings;

use Dist::Banshee::Core qw/source dist_test/;

dist_test(source('gather-files'));

0;
