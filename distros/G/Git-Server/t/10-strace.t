# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;
use Test::More;
# strace is Linux-specific but can help with some more granular git hooks if iotrace is not available
plan skip_all => "strace can work on Linux but not found here [$^O]" unless -x "/usr/bin/strace";

plan tests => 1;
my $try = `strace --help`;
ok (!$?, "strace installed");
