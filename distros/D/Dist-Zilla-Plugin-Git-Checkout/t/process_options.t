#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use Git::Background 0.003;
use Git::Version::Compare qw(ge_git);
use Path::Tiny;
use Test::DZil;
use Test::Fatal;
use Test::MockModule 0.14;
use Test::More 0.88;

use lib path(__FILE__)->absolute->parent->child('lib')->stringify;

use Local::Test::TempDir qw(tempdir);

main();

sub main {
  SKIP:
    {
        {
            my $git_version = Git::Background->version;
            skip 'Cannot find Git in PATH',     1 if !defined $git_version;
            skip 'Git must be at least 1.7.10', 1 if !ge_git( $git_version, '1.7.10' );
        }

        note('create Git test repository');
        my $repo_path = path( tempdir() )->child('my_repo.git')->absolute->stringify;
        {
            my $future = Git::Background->run( 'clone', '--bare', path(__FILE__)->absolute->parent(2)->child('corpus/test.bundle')->stringify(), $repo_path );
            if ( $future->await->is_failed ) {
                my ($error) = $future->failure;
                skip "Cannot setup test repository: $error", 1;
            }
        }

        note('default commitish');
        {
            my $mock = Test::MockModule->new('Dist::Zilla::Plugin::Git::Checkout');
            my $commitish;
            $mock->redefine(
                '_process_options',
                sub {
                    $commitish = $mock->original('_process_options')->(@_);
                    die 'TEST EXIT';
                },
            );

            my $tzil;
            my $exception = exception {
                $tzil = Builder->from_config(
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
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \QTEST EXIT\E }xsm, '_process_options does not throw an exception' );
            is_deeply( $commitish, { type => 'branch', id => undef }, '... returns correct commitish' );

            ok( Dist::Zilla::Plugin::Git::Checkout->_commitish_is_branch($commitish), '_commitish_is_branch returns true' );

            $mock->unmock('_process_options');
        }

        note(q{branch 'branch-103'});
        {
            my $mock = Test::MockModule->new('Dist::Zilla::Plugin::Git::Checkout');
            my $commitish;
            $mock->redefine(
                '_process_options',
                sub {
                    $commitish = $mock->original('_process_options')->(@_);
                    die 'TEST EXIT';
                },
            );

            my $tzil;
            my $exception = exception {
                $tzil = Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    {
                                        repo   => $repo_path,
                                        branch => 'branch-103',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \QTEST EXIT\E }xsm, '_process_options does not throw an exception' );
            is_deeply( $commitish, { type => 'branch', id => 'branch-103' }, '... returns correct commitish' );

            ok( Dist::Zilla::Plugin::Git::Checkout->_commitish_is_branch($commitish), '_commitish_is_branch returns true' );

            $mock->unmock('_process_options');
        }

        note(q{tag 'v107'});
        {
            my $mock = Test::MockModule->new('Dist::Zilla::Plugin::Git::Checkout');
            my $commitish;
            $mock->redefine(
                '_process_options',
                sub {
                    $commitish = $mock->original('_process_options')->(@_);
                    die 'TEST EXIT';
                },
            );

            my $tzil;
            my $exception = exception {
                $tzil = Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    {
                                        repo => $repo_path,
                                        tag  => 'v107',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \QTEST EXIT\E }xsm, '_process_options does not throw an exception' );
            is_deeply( $commitish, { type => 'tag', id => 'v107' }, '... returns correct commitish' );

            ok( !Dist::Zilla::Plugin::Git::Checkout->_commitish_is_branch($commitish), '_commitish_is_branch returns false' );

            $mock->unmock('_process_options');
        }

        note(q{revision 'deadbeaf'});
        {
            my $mock = Test::MockModule->new('Dist::Zilla::Plugin::Git::Checkout');
            my $commitish;
            $mock->redefine(
                '_process_options',
                sub {
                    $commitish = $mock->original('_process_options')->(@_);
                    die 'TEST EXIT';
                },
            );

            my $tzil;
            my $exception = exception {
                $tzil = Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    {
                                        repo     => $repo_path,
                                        revision => 'deadbeaf',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \QTEST EXIT\E }xsm, '_process_options does not throw an exception' );
            is_deeply( $commitish, { type => 'revision', id => 'deadbeaf' }, '... returns correct commitish' );

            ok( !Dist::Zilla::Plugin::Git::Checkout->_commitish_is_branch($commitish), '_commitish_is_branch returns false' );

            $mock->unmock('_process_options');
        }

        note(q{branch 'branch-109', and tag 'v113'});
        {
            my $mock = Test::MockModule->new('Dist::Zilla::Plugin::Git::Checkout');
            $mock->redefine(
                '_process_options',
                sub {
                    $mock->original('_process_options')->(@_);
                    die 'TEST EXIT';
                },
            );

            my $tzil;
            my $exception = exception {
                $tzil = Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    {
                                        repo   => $repo_path,
                                        branch => 'branch-109',
                                        tag    => 'v113',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \Q[Git::Checkout] Only one of branch, revision, or tag can be specified\E }xsm, '_process_options throws an exception' );

            $mock->unmock('_process_options');
        }

        note(q{branch 'branch-127', and revision 'deadbeef131'});
        {
            my $mock = Test::MockModule->new('Dist::Zilla::Plugin::Git::Checkout');
            $mock->redefine(
                '_process_options',
                sub {
                    $mock->original('_process_options')->(@_);
                    die 'TEST EXIT';
                },
            );

            my $tzil;
            my $exception = exception {
                $tzil = Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    {
                                        repo     => $repo_path,
                                        branch   => 'branch-127',
                                        revision => 'deadbeef131',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \Q[Git::Checkout] Only one of branch, revision, or tag can be specified\E }xsm, '_process_options throws an exception' );

            $mock->unmock('_process_options');
        }

        note(q{tag 'v137', and revision 'deadbeef139'});
        {
            my $mock = Test::MockModule->new('Dist::Zilla::Plugin::Git::Checkout');
            $mock->redefine(
                '_process_options',
                sub {
                    $mock->original('_process_options')->(@_);
                    die 'TEST EXIT';
                },
            );

            my $tzil;
            my $exception = exception {
                $tzil = Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    {
                                        repo     => $repo_path,
                                        tag      => 'v137',
                                        revision => 'deadbeef139',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \Q[Git::Checkout] Only one of branch, revision, or tag can be specified\E }xsm, '_process_options throws an exception' );

            $mock->unmock('_process_options');
        }

        note(q{branch 'branch-149', tag 'v151', and revision 'deadbeef157'});
        {
            my $mock = Test::MockModule->new('Dist::Zilla::Plugin::Git::Checkout');
            $mock->redefine(
                '_process_options',
                sub {
                    $mock->original('_process_options')->(@_);
                    die 'TEST EXIT';
                },
            );

            my $tzil;
            my $exception = exception {
                $tzil = Builder->from_config(
                    { dist_root => tempdir() },
                    {
                        add_files => {
                            'source/dist.ini' => simple_ini(
                                [
                                    'Git::Checkout',
                                    {
                                        repo     => $repo_path,
                                        branch   => 'branch-149',
                                        tag      => 'v151',
                                        revision => 'deadbeef157',
                                    },
                                ],
                            ),
                        },
                    },
                );
            };

            like( $exception, qr{ \Q[Git::Checkout] Only one of branch, revision, or tag can be specified\E }xsm, '_process_options throws an exception' );

            $mock->unmock('_process_options');
        }
    }

    done_testing;

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
