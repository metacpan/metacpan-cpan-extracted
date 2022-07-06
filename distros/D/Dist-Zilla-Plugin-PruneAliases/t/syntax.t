#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::More;
use Test::Warnings;

plan tests => 1 + 1;

require_ok 'Dist::Zilla::Plugin::PruneAliases';

done_testing;
