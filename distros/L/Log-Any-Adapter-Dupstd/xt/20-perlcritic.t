#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

if ( !$ENV{RELEASE_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ($@) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

Test::Perl::Critic->import();

all_critic_ok();
