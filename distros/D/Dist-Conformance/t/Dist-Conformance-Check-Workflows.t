#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::Workflows();
use Dist::Conformance::Snapshot::Directory();

my $DIR = '.github/workflows';

sub workflows (%required)          { return Fixture::make_check( Dist::Conformance::Check::Workflows::, { directory => $DIR, required => \%required } ) }
sub check_of  ( $root, %required ) { return [ workflows(%required)->check( Dist::Conformance::Snapshot::Directory->new( root => $root ) ) ] }

subtest check => sub {
    is( check_of( Fixture::checkout() ),                                                                         [ 'info', 'none' ],                  'with none required and none present, info' );
    is( check_of( Fixture::checkout( "$DIR/b.yml" => q{}, "$DIR/a.yml" => q{}, "$DIR/sub/c.yml" => q{} ) ),      [ 'info', 'present: a.yml, b.yml' ], 'with none required, the ones present, not deeper ones' );
    is( check_of( Fixture::checkout( "$DIR/a.yml" => q{} ), 'ci.yml' => 'templates/workflows/ci.yml' ),          [ 'fail', "missing: $DIR/ci.yml" ],  'a missing required workflow fails' );
    is( check_of( Fixture::checkout( "$DIR/ci.yml" => q{} ), 'ci.yml' => 'templates/workflows/ci.yml' ),         [ 'pass', 'all present' ],           'and present passes' );
    is( Fixture::make_check( Dist::Conformance::Check::Workflows::, { directory => $DIR } )->config->{required}, {},                                  'none are required by default' );
};

subtest update => sub {
    my $root   = Fixture::checkout();
    my $update = Fixture::run_update( workflows( 'ci.yml' => 'templates/workflows/ci.yml', 'deploy.yml' => undef ), $root );
    is( $update->changes,                                                 [ { action => 'create', path => "$DIR/ci.yml" } ],                      'a missing workflow with a template is written' );
    is( $root->child( split m{/}, "$DIR/ci.yml" )->slurp,                 "name: ci\non: [push]\n",                                               'from the template' );
    is( $update->manual,                                                  ["Write $DIR/deploy.yml by hand: the flavor names no template for it"], 'one without a template is left to a person' );
    is( Fixture::run_update( workflows(), Fixture::checkout() )->changes, [],                                                                     'with none required, nothing' );
};

subtest 'update: a dry run' => sub {
    my $root   = Fixture::checkout();
    my $before = Fixture::tree_of($root);
    is( Fixture::run_update( workflows( 'ci.yml' => 'templates/workflows/ci.yml' ), $root, 1 )->changes, [ { action => 'create', path => "$DIR/ci.yml" } ], 'says what it would write' );
    is( Fixture::tree_of($root),                                                                         $before,                                           'and changes nothing on disk' );
};

done_testing;
