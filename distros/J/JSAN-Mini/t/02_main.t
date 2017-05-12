#!/usr/bin/perl

# Test what little we can of JSAN::Mini

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use File::Spec::Functions ':ALL';
use JSAN::Mini ();

my $mini = JSAN::Mini->new;
isa_ok( $mini, 'JSAN::Mini' );

# Get the release list
my @releases = $mini->_releases;
ok( scalar(@releases), 'Got release update list' );
