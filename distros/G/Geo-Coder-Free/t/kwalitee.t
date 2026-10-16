#!/usr/bin/env perl

# CPANTS Kwalitee checks (author test).  META.yml only exists in a built
# distribution, so that check is skipped when running from a checkout.

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::Kwalitee';

Test::Kwalitee::kwalitee_ok(-e 'META.yml' ? () : '-has_meta_yml');

done_testing();
