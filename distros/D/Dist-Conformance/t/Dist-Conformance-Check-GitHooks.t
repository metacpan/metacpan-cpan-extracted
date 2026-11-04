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
use Dist::Conformance::Check::GitHooks();
use Dist::Conformance::Snapshot::Directory();
use Dist::Conformance::Snapshot::Tree();

my $PRE    = "#!/bin/sh\n# The fixture pre-commit hook.\nexit 0\n";
my $POST   = "#!/bin/sh\n# The fixture post-commit hook.\nexit 0\n";
my %CONFIG = ( directory => 'git-hooks', hooks => { 'pre-commit' => 'templates/pre-commit', 'post-commit' => 'templates/post-commit' } );

sub hooks    (%config)          { return Fixture::make_check( Dist::Conformance::Check::GitHooks::, { %CONFIG, %config } ) }
sub check_of ( $root, %config ) { return [ hooks(%config)->check( Dist::Conformance::Snapshot::Directory->new( root => $root ) ) ] }

subtest check => sub {
    is( check_of( Fixture::checkout() ),                                                                                               [ 'fail', 'missing: git-hooks/post-commit, git-hooks/pre-commit' ], 'missing hooks fail' );
    is( check_of( Fixture::checkout( 'git-hooks/pre-commit' => $PRE ) ),                                                               [ 'fail', 'missing: git-hooks/post-commit' ],                       'and each is named' );
    is( check_of( Fixture::checkout( 'git-hooks/pre-commit' => $PRE, 'git-hooks/post-commit' => $POST ) ),                             [ 'pass', 'match the templates' ],                                  'hooks that match pass' );
    is( check_of( Fixture::checkout( 'git-hooks/pre-commit' => "$PRE# mine\n", 'git-hooks/post-commit' => $POST ) ),                   [ 'info', 'customized or outdated: git-hooks/pre-commit' ],         'a hook that differs is info' );
    is( check_of( Fixture::checkout( 'git-hooks/pre-commit' => "$PRE# mine\n", 'git-hooks/post-commit' => $POST ), differ => 'fail' ), [ 'fail', match(qr/customized/) ],                                  'or what the flavor says' );
};

subtest 'check: a remote snapshot' => sub {
    my %fetched;
    my $tree = Dist::Conformance::Snapshot::Tree->new(
        paths => { 'git-hooks/pre-commit' => Dist::Conformance::Snapshot::blob_sha($PRE), 'git-hooks/post-commit' => 'f' x 40 },
        fetch => sub ($path) { $fetched{$path}++; return q{} },
    );
    is( [ hooks()->check($tree) ], [ 'info', 'customized or outdated: git-hooks/post-commit' ], 'the SHAs tell a remote hook from its template' );
    is( \%fetched,                 {},                                                          'without fetching a hook' );
};

subtest update => sub {
    my $root   = Fixture::checkout( 'git-hooks/pre-commit' => "$PRE# mine\n" );
    my $update = Fixture::run_update( hooks(), $root );
    is(
        $update->changes,
        [
            { action => 'create',  path => 'git-hooks/post-commit' },
            { action => 'install', path => '.git/hooks/post-commit' },
            { action => 'install', path => '.git/hooks/pre-commit' },
        ],
        'writes the missing hook, and installs both'
    );
    is( $root->child(qw{git-hooks post-commit})->stat->mode & oct 777, oct 755,        'the hook it writes is executable' );
    is( $root->child(qw{git-hooks pre-commit})->slurp,                 "$PRE# mine\n", 'a customized hook is kept' );
    is( $root->child(qw{.git hooks pre-commit})->slurp,                "$PRE# mine\n", 'and is what gets installed' );
    is( Fixture::run_update( hooks(), $root )->changes,                [],             'a second update has nothing to do' );

    my $replaced = Fixture::run_update( hooks( replace => 1 ), $root );
    is( $replaced->changes,                             [ { action => 'replace', path => 'git-hooks/pre-commit' }, { action => 'install', path => '.git/hooks/pre-commit' } ], 'with replace, a hook that differs is replaced, and installed again' );
    is( $root->child(qw{.git hooks pre-commit})->slurp, $PRE,                                                                                                                  'with the template' );

    my $quiet = Fixture::checkout();
    is( [ map { $_->{action} } @{ Fixture::run_update( hooks( install => 0 ), $quiet )->changes } ], [qw{create create}], 'without install, nothing is installed' );
    ok( !-e $quiet->child(qw{.git hooks pre-commit}), 'at all' );

    my $plain = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    my $not   = Fixture::run_update( hooks(), $plain );
    is( [ map { $_->{action} } @{ $not->changes } ], [qw{create create}], 'outside a checkout the hooks are still written' );
    is( scalar @{ $not->manual },                    2,                   'and a person is told that they cannot be installed' );
};

subtest 'update: a dry run' => sub {
    my $root   = Fixture::checkout( 'git-hooks/pre-commit' => "$PRE# mine\n" );
    my $before = Fixture::tree_of($root);
    my $update = Fixture::run_update( hooks( replace => 1 ), $root, 1 );
    is( [ map { "$_->{action} $_->{path}" } @{ $update->changes } ], [ 'create git-hooks/post-commit', 'install .git/hooks/post-commit', 'replace git-hooks/pre-commit', 'install .git/hooks/pre-commit' ], 'says what it would change' );
    is( Fixture::tree_of($root),                                     $before,                                                                                                                               'and changes nothing on disk, .git included' );
};

done_testing;
