use strict;
use warnings;
use Test::More;

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};

# Test::Kwalitee::Extra plans tests on import, so use require + a single
# explicit import call; a use followed by import replans and trips the
# Test::More plan guard.
eval { require Test::Kwalitee::Extra };
plan skip_all => 'Test::Kwalitee::Extra required' if $@;

# META.{json,yml} do not exist in a git checkout until make dist builds
# the tarball, so those indicators would fail for the wrong reason.
# The two prereq_matches indicators query MetaCPAN over the network on every
# run, which sends the client's address and this dist's module list to a third
# party and makes the whole file fail with no connection. An author test that
# phones home is not one anybody should have to opt out of.
Test::Kwalitee::Extra->import(qw(
    !has_meta_yml
    !has_meta_json
    !prereq_matches_use
    !build_prereq_matches_use
));
