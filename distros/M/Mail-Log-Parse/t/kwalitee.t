#!perl

use Test::More;
plan skip_all => 'Author tests.' unless ( $ENV{RELEASE_TESTING} );
eval { require Test::Kwalitee };
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
Test::Kwalitee->import();
