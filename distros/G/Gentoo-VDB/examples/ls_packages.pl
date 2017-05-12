#!perl
use strict;
use warnings;

use Gentoo::VDB;
my $vdb = Gentoo::VDB->new();
warn "$_\n" for sort $vdb->packages;
