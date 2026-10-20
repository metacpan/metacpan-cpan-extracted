#!/usr/bin/env perl

# The module must compile on the Perl that Makefile.PL says it needs.  CI
# cannot run that Perl - the newest releases of some dependencies need a
# later one - so the syntax is checked statically instead.  Only lib/ is
# checked: the tests and bin/address_lookup are not installed with it.

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::MinimumVersion';

Test::MinimumVersion->import();
all_minimum_version_from_mymetajson_ok({ paths => ['lib'] });
