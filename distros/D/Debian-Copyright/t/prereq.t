use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_PREREQ} ) {
    my $msg = 'Author test.  Set $ENV{TEST_PREREQ} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Prereq::Build; };

if ( $@) {
   my $msg = 'Test::Prereq required to criticise code';
   plan( skip_all => $msg );
}

Test::Prereq::Build::prereq_ok(undef, 'prereq', ['Test::ConsistentVersion', 'Test::CheckManifest', 'Test::Spelling', 'Test::Prereq', 'Test::Prereq::Build', 'Test::Perl::Critic']);


