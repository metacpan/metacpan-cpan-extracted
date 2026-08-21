#!/usr/bin/env perl
# t/changes.t -- Validate Changes file format per CPAN::Changes::Spec.
# Gated on AUTHOR_TESTING so it only runs for the maintainer.

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::CPAN::Changes';

Test::CPAN::Changes::changes_ok();

done_testing();
