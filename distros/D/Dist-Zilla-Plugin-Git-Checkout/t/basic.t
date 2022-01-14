#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use Git::Background 0.003;
use Git::Version::Compare qw(ge_git);
use Path::Tiny;
use Test::DZil;
use Test::Fatal;
use Test::More 0.88;

use lib path(__FILE__)->absolute->parent->child('lib')->stringify;

use Local::Test::TempDir qw(tempdir);

main();

sub main {
    note('no attributes');
    {
        my $exception = exception {
            Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            'Git::Checkout',
                        ),
                    },
                },
            );
        };

        ok( defined $exception, q{throws an exception without a 'repo'} );
    }

  SKIP:
    {
        my $git_version = Git::Background->version;
        skip 'Cannot find Git in PATH',     1 if !defined $git_version;
        skip 'Git must be at least 1.7.10', 1 if !ge_git( $git_version, '1.7.10' );

        note('create Git test repository');
        my $repo_path  = path( tempdir() )->child('my_repo.git')->absolute->stringify;
        my $repo_path2 = path($repo_path)->parent->child('my_repo2.git')->stringify;
        {
            my $error;
            {
                local $@;    ## no critic (Variables::RequireInitializationForLocalVars)
                my $ok = eval {

                    # tag v47,       1 commit,  A ->  5
                    # branch master, 2 commits, A ->  7
                    # branch dev,    3 commits, A -> 11, B -> 13
                    Git::Background->run( 'clone',  '--bare', path(__FILE__)->absolute->parent(2)->child('corpus/test.bundle')->stringify(), $repo_path )->get;
                    Git::Background->run( 'remote', 'remove', 'origin',                                                                      { dir => $repo_path } )->get;

                    # branch master, 1 commit, C -> 419
                    Git::Background->run( 'clone',  '--bare', path(__FILE__)->absolute->parent(2)->child('corpus/test2.bundle')->stringify(), $repo_path2 )->get;
                    Git::Background->run( 'remote', 'remove', 'origin',                                                                       { dir => $repo_path2 } )->get;

                    1;
                };

                if ( !$ok ) {
                    $error = $@;
                }
            }
            skip "Cannot setup test repository: $error", 1 if defined $error;
        }

        note('fresh checkouts');
        {
            my $tzil = Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            [
                                'Git::Checkout',
                                {
                                    repo => $repo_path,
                                },
                            ],
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path,
                                    dir  => 'my_repo2',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'tagCheckout',
                                {
                                    repo => $repo_path,
                                    dir  => 'my_repo_tag',
                                    tag  => 'v47',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'thirdCheckout',
                                {
                                    repo     => $repo_path,
                                    dir      => 'my_repo3',
                                    push_url => 'http://example.com/my_repo.git',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'devBranchCheckout',
                                {
                                    repo   => $repo_path,
                                    dir    => 'my_repo_dev',
                                    branch => 'dev',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'devBranchCheckout2',
                                {
                                    repo     => $repo_path,
                                    dir      => 'my_repo_dev2',
                                    branch   => 'dev',
                                    push_url => 'http://example.com/my_dev_repo.git',
                                },
                            ],
                        ),
                    },
                },
            );

            note('default');
            {
                my $workdir = path( $tzil->root )->child('my_repo');
                ok( $workdir->is_dir(),                'workspace is checked out' );
                ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
                ok( -f $workdir->child('A'),           '... with the correct file ...' );
                ok( !-e $workdir->child('B'),          '... only' );
                is( $workdir->child('A')->slurp, '7', '... with the correct content' );

                my @config = Git::Background->run( 'config', '-l', { dir => $workdir } )->stdout;
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

                is( ( scalar grep { $_ eq "[Git::Checkout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
            }

            note('with dir');
            {
                my $workdir = path( $tzil->root )->child('my_repo2');
                ok( $workdir->is_dir(),                'workspace is checked out' );
                ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
                ok( -f $workdir->child('A'),           '... with the correct file' );
                ok( !-e $workdir->child('B'),          '... only' );
                is( $workdir->child('A')->slurp, '7', '... with the correct content' );

                my @config = Git::Background->run( 'config', '-l', { dir => $workdir } )->stdout;
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

                is( ( scalar grep { $_ eq "[secondCheckout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
            }

            note('with dir and tag');
            {
                my $workdir = path( $tzil->root )->child('my_repo_tag');
                ok( $workdir->is_dir(),                'workspace is checked out' );
                ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
                ok( -f $workdir->child('A'),           '... with the correct file' );
                ok( !-e $workdir->child('B'),          '... only' );
                is( $workdir->child('A')->slurp, '5', '... with the correct content' );

                my @config = Git::Background->run( 'config', '-l', { dir => $workdir } )->stdout;
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

                is( ( scalar grep { $_ eq "[tagCheckout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
                is( ( scalar grep { $_ eq "[tagCheckout] Checking out tag v47 in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
            }

            note('with dir and push_url');
            {
                my $workdir = path( $tzil->root )->child('my_repo3');
                ok( $workdir->is_dir(),                'workspace is checked out' );
                ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
                ok( -f $workdir->child('A'),           '... with the correct file' );
                ok( !-e $workdir->child('B'),          '... only' );
                is( $workdir->child('A')->slurp, '7', '... with the correct content' );

                my @config = Git::Background->run( 'config', '-l', { dir => $workdir } )->stdout;
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=http://example.com/my_repo.git\E $ }xsm } @config ), 1, '... correct push url is defined' );

                is( ( scalar grep { $_ eq "[thirdCheckout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
            }

            note('with dir and branch');
            {
                my $workdir = path( $tzil->root )->child('my_repo_dev');
                ok( $workdir->is_dir(),                'workspace is checked out' );
                ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
                ok( -f $workdir->child('A'),           '... with the correct file (A)' )
                  and is( $workdir->child('A')->slurp, '11', '... with the correct content' );
                ok( -f $workdir->child('B'), '... with the correct file (B)' )
                  and is( $workdir->child('B')->slurp, '13', '... with the correct content' );

                my @config = Git::Background->run( 'config', '-l', { dir => $workdir } )->stdout;
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

                is( ( scalar grep { $_ eq "[devBranchCheckout] Cloning $repo_path into $workdir (branch dev)" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
            }

            note('with dir, checkout, and push_url');
            {
                my $workdir = path( $tzil->root )->child('my_repo_dev2');
                ok( $workdir->is_dir(),                'workspace is checked out' );
                ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
                ok( -f $workdir->child('A'),           '... with the correct file (A)' )
                  and is( $workdir->child('A')->slurp, '11', '... with the correct content' );
                ok( -f $workdir->child('B'), '... with the correct file (B)' )
                  and is( $workdir->child('B')->slurp, '13', '... with the correct content' );

                my @config = Git::Background->run( 'config', '-l', { dir => $workdir } )->stdout;
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=http://example.com/my_dev_repo.git\E $ }xsm } @config ), 1, '... correct push url is defined' );

                is( ( scalar grep { $_ eq "[devBranchCheckout2] Cloning $repo_path into $workdir (branch dev)" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
            }
        }

        note('dir exists already');
        {
            my $exception = exception {
                Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                '=Local::CreateWorkspace',
                                [
                                    'Git::Checkout',
                                    {
                                        repo => $repo_path,
                                        dir  => 'ws',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \Q[Git::Checkout] Directory \E .*\Qws exists but is not a Git repository\E }xsm, 'throws an exception if the workspace directory exists already but is not a Git workspace' );
        }

        note('dir exists already but is not workspace for the correct repository');
        {
            my $exception = exception {
                Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    'wrongRepoCheckout',
                                    {
                                        repo => $repo_path2,
                                        dir  => 'ws',
                                    },
                                ],
                                [
                                    'Git::Checkout',
                                    {
                                        repo => $repo_path,
                                        dir  => 'ws',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \Q[Git::Checkout] Directory \E .*\Qws is not a Git repository for $repo_path\E }xsm, 'throws an exception if the workspace directory exists but is not a Git workspace for the correct repository' );
        }

        note('dir exists already but is not workspace for the correct repository (no origin)');
        {
            my $exception = exception {
                Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    'wrongRepoCheckout',
                                    {
                                        repo => $repo_path,
                                        dir  => 'ws',
                                    },
                                ],
                                '=Local::RemoveOrigin',
                                [
                                    'Git::Checkout',
                                    {
                                        repo => $repo_path,
                                        dir  => 'ws',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            skip "Test setup failed\n$Local::RemoveOrigin::NOK", 1 if defined $Local::RemoveOrigin::NOK;

            like( $exception, qr{ \Q[Git::Checkout] Directory \E .*\Qws is not a Git repository for $repo_path\E }xsm, 'throws an exception if the workspace directory exists but is not a Git workspace for the correct repository' );
        }

        note('dirty dir');
        {
            my $tzil = Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            [
                                'Git::Checkout',
                                {
                                    repo => $repo_path,
                                    dir  => 'ws',
                                },
                            ],
                            '=Local::MakeWorkspaceDirty',
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path,
                                    dir  => 'ws',
                                },
                            ],
                        ),
                    },
                },
            );

            my $workdir = path( $tzil->root )->child('ws');
            ok( $workdir->is_dir(),                'workspace is checked out' );
            ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
            ok( -f $workdir->child('A'),           '... with the correct file (A)' )
              and is( $workdir->child('A')->slurp, '67', '... with the correct (dirty) content' );

            is( ( scalar grep { $_ =~ m{ ^\Q[secondCheckout] \E.*\QGit workspace $workdir is dirty - skipping checkout\E }xsm } @{ $tzil->log_messages() } ), 1, '... correct message is logged (is dirty)' )
              or diag 'got log messages: ', explain $tzil->log_messages;
            is( ( scalar grep { $_ eq "[secondCheckout] Fetching $repo_path in $workdir" } @{ $tzil->log_messages() } ), 0, '... _checkout stops when dirty' )
              or diag 'got log messages: ', explain $tzil->log_messages;
        }

        note('wrong branch');
        {
            my $exception = exception {
                Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    {
                                        repo => $repo_path,
                                        dir  => 'ws',
                                    },
                                ],
                                [
                                    'Git::Checkout',
                                    'secondCheckout',
                                    {
                                        repo   => $repo_path,
                                        dir    => 'ws',
                                        branch => 'dev',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \Q[secondCheckout] Directory \E .*\Qws is not on branch dev}xsm, 'throws an exception if the workspace directory exists but is for a different branch' );

        }

        note('not on branch');
        {
            my $exception = exception {
                Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    {
                                        repo => $repo_path,
                                        dir  => 'ws',
                                        tag  => 'my-tag',
                                    },
                                ],
                                [
                                    'Git::Checkout',
                                    'secondCheckout',
                                    {
                                        repo   => $repo_path,
                                        dir    => 'ws',
                                        branch => 'dev',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \Q[secondCheckout] Directory \E .*\Qws is not on branch dev}xsm, 'throws an exception if the workspace directory exists but is not on a branch' );

        }

        note('wrong branch (!master)');
        {
            my $exception = exception {
                Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    {
                                        repo => $repo_path,
                                        dir  => 'ws',
                                    },
                                ],
                                '=Local::UpdateOriginHEAD',
                                [
                                    'Git::Checkout',
                                    'secondCheckout',
                                    {
                                        repo => $repo_path,
                                        dir  => 'ws',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            skip "Test setup failed\n$Local::UpdateOriginHEAD::NOK", 1 if defined $Local::UpdateOriginHEAD::NOK;

            like( $exception, qr{ \Q[secondCheckout] Directory \E .*\Qws is not on branch dev}xsm, 'throws an exception if the workspace directory exists but is for a different branch' );
        }

        note('fetch');
        {
            my $tzil = Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            [
                                'Git::Checkout',
                                {
                                    repo     => $repo_path,
                                    dir      => 'ws',
                                    checkout => 'dev',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path,
                                    dir  => 'ws',
                                },
                            ],
                        ),
                    },
                },
            );

            my $workdir = path( $tzil->root )->child('ws');
            ok( $workdir->is_dir(),                'workspace is checked out' );
            ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
            ok( -f $workdir->child('A'),           '... with the correct file' )
              and is( $workdir->child('A')->slurp, '7', '... with the correct (dirty) content' );

            is( ( scalar grep { $_ eq "[Git::Checkout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;

            is( ( scalar grep { $_ eq "[secondCheckout] Pulling $repo_path in $workdir" } @{ $tzil->log_messages() } ), 1, '... fetch message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;
        }

        note('push_url gets removed');
        {
            my $tzil = Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            [
                                'Git::Checkout',
                                {
                                    repo     => $repo_path,
                                    dir      => 'ws',
                                    push_url => 'http://example.com/my_repo.git',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path,
                                    dir  => 'ws',
                                },
                            ],
                        ),
                    },
                },
            );

            my $workdir = path( $tzil->root )->child('ws');
            ok( $workdir->is_dir(),                'workspace is checked out' );
            ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
            ok( -f $workdir->child('A'),           '... with the correct file' )
              and is( $workdir->child('A')->slurp, '7', '... with the correct (dirty) content' );

            my @config = Git::Background->run( 'config', '-l', { dir => $workdir } )->stdout;
            is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

            is( ( scalar grep { $_ eq "[Git::Checkout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;

            is( ( scalar grep { $_ eq "[secondCheckout] Pulling $repo_path in $workdir" } @{ $tzil->log_messages() } ), 1, '... fetch message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;
        }

        note('release is aborted if workspace is dirty');
        {
            my $tzil = Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            'FakeRelease',
                            [
                                'Git::Checkout',
                                {
                                    repo => $repo_path,
                                    dir  => 'ws',
                                },
                            ],
                            '=Local::MakeWorkspaceDirty',
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path,
                                    dir  => 'ws',
                                },
                            ],
                        ),
                    },
                },
            );

            my $workdir = path( $tzil->root )->child('ws');
            ok( $workdir->is_dir(),                'workspace is checked out' );
            ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
            ok( -f $workdir->child('A'),           '... with the correct file' )
              and is( $workdir->child('A')->slurp, '67', '... with the correct (dirty) content' );

            my @config = Git::Background->run( 'config', '-l', { dir => $workdir } )->stdout;
            is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

            is( ( scalar grep { $_ eq "[Git::Checkout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;

            is( ( scalar grep { $_ =~ m{ ^\Q[secondCheckout] \E.*\QGit workspace $workdir is dirty - skipping checkout\E }xsm } @{ $tzil->log_messages() } ), 1, '... correct message is logged (is dirty)' )
              or diag 'got log messages: ', explain $tzil->log_messages;

            like( exception { $tzil->release }, qr{ \QAborting release\E }xsm, '... release is aborted if dirty' )
              or diag 'got log messages: ', explain $tzil->log_messages;
        }

        note('release is not aborted if workspace is not dirty');
        {
            my $tzil = Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            'FakeRelease',
                            [
                                'Git::Checkout',
                                {
                                    repo => $repo_path,
                                    dir  => 'ws',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path,
                                    dir  => 'ws',
                                },
                            ],
                        ),
                    },
                },
            );

            my $workdir = path( $tzil->root )->child('ws');
            ok( $workdir->is_dir(),                'workspace is checked out' );
            ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
            ok( -f $workdir->child('A'),           '... with the correct file' )
              and is( $workdir->child('A')->slurp, '7', '... with the correct (dirty) content' );

            my @config = Git::Background->run( 'config', '-l', { dir => $workdir } )->stdout;
            is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

            is( ( scalar grep { $_ eq "[Git::Checkout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;

            is( ( scalar grep { $_ eq "[secondCheckout] Pulling $repo_path in $workdir" } @{ $tzil->log_messages() } ), 1, '... fetch message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;

            # don't know how to test the prompt_yn stuff
            unlike( exception { $tzil->release }, qr{ \QAborting release\E }xsm, '... release is aborted if dirty' )
              or diag 'got log messages: ', explain $tzil->log_messages;
        }

        note('checkout branch and tag');
        {
            my $tzil = Builder->from_config(
                { dist_root => tempdir() },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            [
                                'Git::Checkout',
                                'branchCheckout',
                                {
                                    repo => $repo_path,
                                },
                            ],
                            [
                                'Git::Checkout',
                                'tagCheckout',
                                {
                                    repo => $repo_path,
                                    dir  => 'my_tag',
                                    tag  => 'my-tag',
                                },
                            ],
                            [
                                '=Local::UpdateRemote',
                                {
                                    repo => $repo_path,
                                },
                            ],

                            # branch master, 3 commits, A ->  7
                            # branch dev,    3 commits, A -> 11, B -> 13, C -> 1087
                            [
                                'Git::Checkout',
                                'branchUpdate',
                                {
                                    repo => $repo_path,
                                },
                            ],
                            [
                                'Git::Checkout',
                                'tagUpdate',
                                {
                                    repo => $repo_path,
                                    dir  => 'my_tag',
                                    tag  => 'my-tag',
                                },
                            ],
                        ),
                    },
                },
            );

            skip "Test setup failed\n$Local::UpdateRemote::NOK", 1 if defined $Local::UpdateRemote::NOK;

            note(q{checkout and update branch 'master'});
            {
                my $workdir = path( $tzil->root )->child('my_repo');
                ok( $workdir->is_dir(),                'workspace is checked out' );
                ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
                ok( -f $workdir->child('A'),           '... with the correct file ...' );
                ok( !-e $workdir->child('B'),          '... only' );
                ok( -f $workdir->child('C'),           '... updated file exists' )
                  and is( $workdir->child('C')->slurp, '1087', '... with the correct content' );

                my @config = Git::Background->run( 'config', '-l', { dir => $workdir } )->stdout;
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

                is( ( scalar grep { $_ eq "[branchCheckout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;

                is( ( scalar grep { $_ eq "[branchUpdate] Pulling $repo_path in $workdir" } @{ $tzil->log_messages() } ), 1, '... fetch message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
            }

            note(q{checkout and update tag 'my-tag'});
            {
                my $workdir = path( $tzil->root )->child('my_tag');
                ok( $workdir->is_dir(),                'workspace is checked out' );
                ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
                ok( -f $workdir->child('A'),           '... with the correct file ...' );
                ok( !-e $workdir->child('B'),          '... only' );
                ok( -f $workdir->child('C'),           '... updated file exists' );
                is( $workdir->child('C')->slurp, '1087', '... with the correct content' );

                my @config = Git::Background->run( 'config', '-l', { dir => $workdir } )->stdout;
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

                is( ( scalar grep { $_ eq "[tagCheckout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
                is( ( scalar grep { $_ eq "[tagCheckout] Checking out tag my-tag in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;

                is( ( scalar grep { $_ eq "[tagUpdate] Fetching $repo_path in $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
                is( ( scalar grep { $_ eq "[tagUpdate] Checking out tag my-tag in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
            }
        }
    }

    done_testing;

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
