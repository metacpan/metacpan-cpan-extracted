#!/usr/bin/env perl
use Test2::V0;
use Test2::Plugin::BailOnFail; # TODO: Can we set per-subtest instead?
use strict;
use warnings;
use v5.10;
use FindBin;


# Simplest test: Confirm that ngt's runtime check succeeds.  This confirms that all dependencies, including git version, are met
my $check = `$FindBin::Bin/../bin/ngt check`;
ok(!$?, "ngt check");

done_testing();

