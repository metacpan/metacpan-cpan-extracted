use strict;
use warnings;

use Test::More;

# Author-only test: not for CPAN smokers (they install the built tarball
# where Dist::Zilla's [PkgVersion] has injected `our $VERSION = ...` before
# `use strict;`, which Perl::Critic flags as severity 5).
plan skip_all => 'set AUTHOR_TESTING or RELEASE_TESTING to run Perl::Critic'
    unless $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};

# Perl::Critic also needs Pod::PlainText at runtime (pulled in by
# Perl::Critic::Utils::POD). If it's missing every policy fails to load and
# Test::Perl::Critic dies at import — we catch that and skip.
# severity and policy exclusions live in .perlcriticrc at the project root
eval { require Test::Perl::Critic; Test::Perl::Critic->import(); 1 }
    or plan skip_all => "Test::Perl::Critic required: $@";

all_critic_ok('lib');
