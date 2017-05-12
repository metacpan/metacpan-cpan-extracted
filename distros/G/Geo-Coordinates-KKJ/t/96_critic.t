use strict;
use warnings;

use Test::More;

plan skip_all => 'Test::Perl::Critic test is for author only'
    unless -e 't/AUTHOR_BUILD';

eval "use Test::Perl::Critic ( -severity => 1, -format => '%m in %f, line %l.' );";
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok();
