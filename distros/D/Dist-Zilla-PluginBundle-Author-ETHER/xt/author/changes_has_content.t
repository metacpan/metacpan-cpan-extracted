use strict;
use warnings;

use Test::More;
plan skip_all => 'xt/release/changes_has_content.t is missing' if not -e 'xt/release/changes_has_content.t';

my $branch_name = $ENV{TRAVIS_BRANCH};
chomp($branch_name = `git rev-parse --abbrev-ref HEAD`) if not $branch_name;
$TODO = 'Changes need not have content for this release yet if this is only the master branch'
    if ($branch_name || '') eq 'master';

do './xt/release/changes_has_content.t';
die $@ if $@;
