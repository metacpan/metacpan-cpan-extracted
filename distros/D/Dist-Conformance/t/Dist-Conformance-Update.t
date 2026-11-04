#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;
use File::Temp();
use Mojo::File();

use Fixture();
use Dist::Conformance::Snapshot::Directory();
use Dist::Conformance::Snapshot::Tree();
use Dist::Conformance::Update();

sub update_of ( $root, $dry_run = 0 ) {
    return Dist::Conformance::Update->new( snapshot => Dist::Conformance::Snapshot::Directory->new( root => $root ), dry_run => $dry_run );
}

subtest new => sub {
    like( dies { Dist::Conformance::Update->new }, qr/needs\ a\ snapshot\ that\ it\ can\ write/, 'a snapshot is required' );
    my $tree = Dist::Conformance::Snapshot::Tree->new( paths => {}, fetch => sub { } );
    like( dies { Dist::Conformance::Update->new( snapshot => $tree ) }, qr/needs\ a\ snapshot\ that\ it\ can\ write/, 'and a tree cannot be updated' );
};

subtest write => sub {
    my $root   = Fixture::checkout( 'same' => 'x', 'old' => 'x' );
    my $update = update_of($root);
    ok( $update->write( 'new',   'n' ), 'a new file is written' );
    ok( $update->write( 'old',   'y' ), 'a changed file is written' );
    ok( !$update->write( 'same', 'x' ), 'a file with the same bytes is not' );
    is( $update->changes,           [ { action => 'create', path => 'new' }, { action => 'replace', path => 'old' } ], 'the changes, in order' );
    is( $root->child('new')->slurp, 'n',                                                                               'with their bytes' );
    is( $root->child('old')->slurp, 'y',                                                                               'over the old ones' );
};

subtest 'write: a dry run' => sub {
    my $root   = Fixture::checkout( 'old' => 'x' );
    my $before = Fixture::tree_of($root);
    my $update = update_of( $root, 1 );
    $update->write( 'new', 'n' );
    $update->write( 'old', 'y' );
    is( $update->changes,        [ { action => 'create', path => 'new' }, { action => 'replace', path => 'old' } ], 'records what it would change' );
    is( Fixture::tree_of($root), $before,                                                                           'and changes nothing on disk' );
};

subtest install_hook => sub {
    my $root   = Fixture::checkout();
    my $update = update_of($root);
    ok( $update->install_hook( 'pre-commit',  'h' ), 'a hook is installed' );
    ok( !$update->install_hook( 'pre-commit', 'h' ), 'and not again with the same bytes' );
    is( $update->changes,                               [ { action => 'install', path => '.git/hooks/pre-commit' } ], 'the install is recorded by the path of the hook' );
    is( $root->child(qw{.git hooks pre-commit})->slurp, 'h',                                                          'with its bytes' );

    my $dry    = Fixture::checkout();
    my $before = Fixture::tree_of($dry);
    my $plan   = update_of( $dry, 1 );
    $plan->install_hook( 'pre-commit', 'h' );
    is( $plan->changes,         [ { action => 'install', path => '.git/hooks/pre-commit' } ], 'a dry run records the install' );
    is( Fixture::tree_of($dry), $before,                                                      'and installs nothing' );

    my $plain = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    my $none  = update_of($plain);
    ok( !$none->install_hook( 'pre-commit', 'h' ), 'nothing is installed outside a checkout' );
    is( $none->manual, [ match(qr/\AInstall\ the\ hook\ pre-commit:\ .+\ is\ not\ a\ git/) ], 'and a person is told' );
};

subtest by_hand => sub {
    my $update = update_of( Fixture::checkout() );
    $update->by_hand( 'one', 'two' );
    $update->by_hand('three');
    is( $update->manual, [qw{one two three}], 'in order' );
};

done_testing;
