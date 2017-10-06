#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.024

use Test::More 0.88;
use Test::Kwalitee 'kwalitee_ok';

# Module::CPANTS::Analyse does not find the LICENSE in scripts that don't end in .pl
kwalitee_ok(qw{-has_license_in_source_file -has_abstract_in_pod});

done_testing();
