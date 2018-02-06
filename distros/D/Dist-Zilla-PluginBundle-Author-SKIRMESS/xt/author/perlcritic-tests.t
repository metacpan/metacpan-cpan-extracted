#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.032

use Test::Perl::Critic ( -profile => 'xt/author/perlcriticrc-tests' );

all_critic_ok(qw(t xt));
