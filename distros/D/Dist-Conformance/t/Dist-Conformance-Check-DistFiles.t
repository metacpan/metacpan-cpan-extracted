#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::DistFiles();
use Dist::Conformance::Snapshot::Directory();

my %CONFIG = ( marker => 'dist.ini', files => { 'Changes' => 'templates/Changes', 'prereqs.yml' => 'templates/prereqs.yml' } );

sub dist     (%config)          { return Fixture::make_check( Dist::Conformance::Check::DistFiles::, { %CONFIG, %config }, DIST => 'Foo-Bar', VERSION => '0.001', DATE => '2026-01-01', CPAN_ID => 'TESTER' ) }
sub check_of ( $root, %config ) { return [ dist(%config)->check( Dist::Conformance::Snapshot::Directory->new( root => $root ) ) ] }

subtest check => sub {
    is( check_of( Fixture::checkout() ),                                                     [ 'info', 'no dist.ini' ],                   'without the marker it is only worth knowing' );
    is( check_of( Fixture::checkout(), absent => 'fail' ),                                   [ 'fail', 'no dist.ini' ],                   'unless the flavor says otherwise' );
    is( check_of( Fixture::checkout( 'dist.ini' => q{} ) ),                                  [ 'fail', 'missing: Changes, prereqs.yml' ], 'with it, the missing files fail' );
    is( check_of( Fixture::checkout( map { $_ => q{} } qw{dist.ini Changes prereqs.yml} ) ), [ 'pass', 'all present' ],                   'and all present passes' );
    like( dies { Fixture::make_check( Dist::Conformance::Check::DistFiles::, { files => {} } ) }, qr/\/marker:\ Missing\ property/, 'the marker is required' );
};

subtest update => sub {
    my $plain  = Fixture::checkout();
    my $before = Fixture::tree_of($plain);
    is( Fixture::run_update( dist(), $plain )->changes, [],      'without the marker nothing is written' );
    is( Fixture::tree_of($plain),                       $before, 'at all' );

    my $root   = Fixture::checkout( 'dist.ini' => q{} );
    my $update = Fixture::run_update( dist(), $root );
    is( $update->changes,               [ { action => 'create', path => 'Changes' } ],                                                                                    'a template whose variables are all set is written' );
    is( $root->child('Changes')->slurp, "Revision history for Foo-Bar\n\n0.001 2026-01-01 TESTER\n    - Initial Release\n",                                               'with them filled in' );
    is( $update->manual,                ['Write prereqs.yml from templates/prereqs.yml by hand, or set the variables PERL_FLOOR in .conformance.yml: nothing sets them'], 'one that lacks a variable is left to a person' );
};

subtest 'update: a dry run' => sub {
    my $root   = Fixture::checkout( 'dist.ini' => q{} );
    my $before = Fixture::tree_of($root);
    is( Fixture::run_update( dist(), $root, 1 )->changes, [ { action => 'create', path => 'Changes' } ], 'says what it would write' );
    is( Fixture::tree_of($root),                          $before,                                       'and changes nothing on disk' );
};

done_testing;
