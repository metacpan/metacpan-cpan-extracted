#!/usr/bin/perl

# Basic test for JSAN::Index

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More;
use File::Remove 'remove';
use LWP::Online  'online';

BEGIN { remove( \1, 'temp' ) if -e 'temp'; }
END   { remove( \1, 'temp' ) if -e 'temp'; }

if ( online() ) {
    plan( tests => 8 );
} else {
    plan( skip_all => "Skipping online tests" );
    exit(0);
}

use JSAN::Index;

JSAN::Index->init({
    mirror_local => 'temp',
    prune => 1
});





#####################################################################
# Main tests

# Can we load the release source?
foreach my $params ( [], [ build => 1 ] ) {
    my $Source = JSAN::Index::Release::Source->new( @$params );
    isa_ok( $Source, 'JSAN::Index::Release::Source' );
    ok( $Source->load, 'JSAN::Index::Release::Source loads ok' );
}

# Get an installation Alg:Dep object
my $Install = JSAN::Index->dependency;
isa_ok( $Install, 'Algorithm::Dependency' );
isa_ok( $Install, 'JSAN::Index::Release::Dependency' );

# Test getting a schedule
my $schedule = $Install->schedule( 'Display.Swap' );
ok( scalar(@$schedule), 'Got at least one item in the schedule' );
my @dists = grep { m{^/dist/} } @$schedule;
is( scalar(@dists), scalar(@$schedule), 'All returned values are dist paths' );
