#!/usr/bin/perl


use lib '../lib';

use strict;
use warnings;

use Test::More tests => 3;

my @modules = qw(
Clone
Hash::Merge
Hash::Work
);

foreach my $module (@modules) {
    eval " use $module ";
    ok(!$@, "$module compiles");
}

1;
