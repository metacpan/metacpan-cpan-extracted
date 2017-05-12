use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_PREREQ} ) {
    my $msg = 'Author test.  Set $ENV{TEST_PREREQ} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Prereq; };

if ( $@) {
   my $msg = 'Test::Prereq required to criticise code';
   plan( skip_all => $msg );
}

Test::Prereq::prereq_ok(undef, 'prereq', ['Test::CheckChanges', 'Test::CheckManifest', 'Test::Differences', 'Test::Perl::Critic', 'Test::Spelling', 'Test::Prereq']);


