# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;

use Test::More;
use Test::More;
plan tests => 2;

# git is required
my $try = `git --help`;
ok (!$?, "git installed");

# strace can be used to help with more granular git hooks
SKIP: {
    # But strace is Linux-specific
    skip "strace works on Linux, but not expected on [$^O]", 1 unless $^O =~ /linux/i;

    $try = `strace --help`;
    ok (!$?, "strace installed");
};
