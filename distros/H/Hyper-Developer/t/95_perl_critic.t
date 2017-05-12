#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use Test::More;
use English qw(-no_match_vars);

$ENV{TEST_AUTHOR} or plan(
    skip_all => 'Author test. Set (export) $ENV{TEST_AUTHOR} to a true value to run.'
);

eval 'use Test::Perl::Critic';

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

#my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
#Test::Perl::Critic->import( -profile => $rcfile );
Test::Perl::Critic->import( -severity => 5 );
all_critic_ok( qw{
    t
    t/lib
    lib
    cgi-bin
}  );
