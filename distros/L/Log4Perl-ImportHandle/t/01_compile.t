#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib','t/lib';

use Test::More tests => 2;

my @modules = qw(
  Log4Perl::ImportHandle
  Exporter::AutoClean
);

foreach my $module (@modules) {
    eval " use $module ";
    ok(!$@, "$module compiles");
}

1;
