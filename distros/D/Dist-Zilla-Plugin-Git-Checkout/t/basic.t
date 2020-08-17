#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use Git::Wrapper;
use Path::Tiny;
use Test::DZil;
use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use lib path(__FILE__)->parent->child('lib')->stringify;

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
        skip 'Cannot find Git in PATH', 1 if !Git::Wrapper->has_git_in_path();

        note('create Git test repository');
        my $repo_path = path( tempdir() )->child('my_repo.git')->absolute;
        mkdir $repo_path or die "Cannot create $repo_path";

        {
            my $git = Git::Wrapper->new( $repo_path->stringify );
            $git->init;
            $git->config( 'user.email', 'test@example.com' );
            $git->config( 'user.name',  'Test' );

            my $file_A = $repo_path->child('A');
            my $file_B = $repo_path->child('B');
            $file_A->spew('5');
            $git->add('A');
            $git->commit( { message => 'initial commit' } );

            $file_A->spew('7');
            $git->add('A');
            $git->commit( { message => 'second commit' } );

            $git->branch('dev');
            $git->checkout('dev');

            $file_A->spew('11');
            $git->add('A');
            $file_B->spew('13');
            $git->add('B');
            $git->commit( { message => 'commit on dev branch' } );

            $git->checkout('master');
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
                                    repo => $repo_path->stringify(),
                                },
                            ],
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path->stringify(),
                                    dir  => 'my_repo2',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'thirdCheckout',
                                {
                                    repo     => $repo_path->stringify(),
                                    dir      => 'my_repo3',
                                    push_url => 'http://example.com/my_repo.git',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'devBranchCheckout',
                                {
                                    repo     => $repo_path->stringify(),
                                    dir      => 'my_repo_dev',
                                    checkout => 'dev',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'devBranchCheckout2',
                                {
                                    repo     => $repo_path->stringify(),
                                    dir      => 'my_repo_dev2',
                                    checkout => 'dev',
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

                my $git    = Git::Wrapper->new( $workdir->stringify );
                my @config = $git->config('-l');
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

                is( ( scalar grep { $_ eq "[Git::Checkout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
                is( ( scalar grep { $_ eq "[Git::Checkout] Checking out master in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
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

                my $git    = Git::Wrapper->new( $workdir->stringify );
                my @config = $git->config('-l');
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

                is( ( scalar grep { $_ eq "[secondCheckout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
                is( ( scalar grep { $_ eq "[secondCheckout] Checking out master in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
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

                my $git    = Git::Wrapper->new( $workdir->stringify );
                my @config = $git->config('-l');
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=http://example.com/my_repo.git\E $ }xsm } @config ), 1, '... correct push url is defined' );

                is( ( scalar grep { $_ eq "[thirdCheckout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
                is( ( scalar grep { $_ eq "[thirdCheckout] Checking out master in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
            }

            note('with dir, and checkout');
            {
                my $workdir = path( $tzil->root )->child('my_repo_dev');
                ok( $workdir->is_dir(),                'workspace is checked out' );
                ok( $workdir->child('.git')->is_dir(), '... with a .git directory' );
                ok( -f $workdir->child('A'),           '... with the correct file (A)' )
                  and is( $workdir->child('A')->slurp, '11', '... with the correct content' );
                ok( -f $workdir->child('B'), '... with the correct file (B)' )
                  and is( $workdir->child('B')->slurp, '13', '... with the correct content' );

                my $git    = Git::Wrapper->new( $workdir->stringify );
                my @config = $git->config('-l');
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

                is( ( scalar grep { $_ eq "[devBranchCheckout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
                is( ( scalar grep { $_ eq "[devBranchCheckout] Checking out dev in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
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

                my $git    = Git::Wrapper->new( $workdir->stringify );
                my @config = $git->config('-l');
                is( scalar grep( { m{ ^ \Qremote.origin.pushurl=http://example.com/my_dev_repo.git\E $ }xsm } @config ), 1, '... correct push url is defined' );

                is( ( scalar grep { $_ eq "[devBranchCheckout2] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
                  or diag 'got log messages: ', explain $tzil->log_messages;
                is( ( scalar grep { $_ eq "[devBranchCheckout2] Checking out dev in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
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
                                        repo => $repo_path->stringify(),
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
            my $repo_path2 = path( tempdir() )->child('my_repo2.git')->absolute;
            mkdir $repo_path2 or die "Cannot create $repo_path2";

            my $git = Git::Wrapper->new( $repo_path2->stringify );
            $git->init;
            $git->config( 'user.email', 'test@example.com' );
            $git->config( 'user.name',  'Test' );

            my $file_C = $repo_path2->child('C');
            $file_C->spew('419');
            $git->add('C');
            $git->commit( { message => 'initial commit' } );

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
                                        repo => $repo_path2->stringify(),
                                        dir  => 'ws',
                                    },
                                ],
                                [
                                    'Git::Checkout',
                                    {
                                        repo => $repo_path->stringify(),
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
                                    repo => $repo_path->stringify(),
                                    dir  => 'ws',
                                },
                            ],
                            '=Local::MakeWorkspaceDirty',
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path->stringify(),
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
                                    repo     => $repo_path->stringify(),
                                    dir      => 'ws',
                                    checkout => 'dev',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path->stringify(),
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
            is( ( scalar grep { $_ eq "[Git::Checkout] Checking out dev in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;

            is( ( scalar grep { $_ eq "[secondCheckout] Fetching $repo_path in $workdir" } @{ $tzil->log_messages() } ), 1, '... fetch message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;
            is( ( scalar grep { $_ eq "[secondCheckout] Checking out master in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
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
                                    repo     => $repo_path->stringify(),
                                    dir      => 'ws',
                                    push_url => 'http://example.com/my_repo.git',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path->stringify(),
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

            my $git    = Git::Wrapper->new( $workdir->stringify );
            my @config = $git->config('-l');
            is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

            is( ( scalar grep { $_ eq "[Git::Checkout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;
            is( ( scalar grep { $_ eq "[Git::Checkout] Checking out master in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;

            is( ( scalar grep { $_ eq "[secondCheckout] Fetching $repo_path in $workdir" } @{ $tzil->log_messages() } ), 1, '... fetch message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;
            is( ( scalar grep { $_ eq "[secondCheckout] Checking out master in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
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
                                    repo => $repo_path->stringify(),
                                    dir  => 'ws',
                                },
                            ],
                            '=Local::MakeWorkspaceDirty',
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path->stringify(),
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

            my $git    = Git::Wrapper->new( $workdir->stringify );
            my @config = $git->config('-l');
            is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

            is( ( scalar grep { $_ eq "[Git::Checkout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;
            is( ( scalar grep { $_ eq "[Git::Checkout] Checking out master in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
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
                                    repo => $repo_path->stringify(),
                                    dir  => 'ws',
                                },
                            ],
                            [
                                'Git::Checkout',
                                'secondCheckout',
                                {
                                    repo => $repo_path->stringify(),
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

            my $git    = Git::Wrapper->new( $workdir->stringify );
            my @config = $git->config('-l');
            is( scalar grep( { m{ ^ \Qremote.origin.pushurl=\E }xsm } @config ), 0, '... no push url is defined' );

            is( ( scalar grep { $_ eq "[Git::Checkout] Cloning $repo_path into $workdir" } @{ $tzil->log_messages() } ), 1, '... clone message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;
            is( ( scalar grep { $_ eq "[Git::Checkout] Checking out master in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;

            is( ( scalar grep { $_ eq "[secondCheckout] Fetching $repo_path in $workdir" } @{ $tzil->log_messages() } ), 1, '... fetch message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;
            is( ( scalar grep { $_ eq "[secondCheckout] Checking out master in $workdir" } @{ $tzil->log_messages() } ), 1, '... checkout message got logged' )
              or diag 'got log messages: ', explain $tzil->log_messages;

            # don't know how to test the prompt_yn stuff
            unlike( exception { $tzil->release }, qr{ \QAborting release\E }xsm, '... release is aborted if dirty' )
              or diag 'got log messages: ', explain $tzil->log_messages;
        }
    }

    done_testing;

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
