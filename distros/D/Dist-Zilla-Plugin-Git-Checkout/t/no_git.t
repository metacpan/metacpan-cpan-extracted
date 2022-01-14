#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use Git::Background 0.003;
use Path::Tiny;
use Test::DZil;
use Test::Fatal;
use Test::More 0.88;

use lib path(__FILE__)->absolute->parent->child('lib')->stringify;

use Local::Test::TempDir qw(tempdir);

main();

sub main {
    note('no git in PATH');
  SKIP:
    {
        local $ENV{PATH} = path( tempdir() )->absolute->stringify;

        skip q{Cannot remove 'git' from PATH}, 1 if defined Git::Background->version;

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
                                    repo => path(__FILE__)->absolute->parent(2)->child('corpus/test.bundle')->stringify,
                                },
                            ],
                        ),
                    },
                },
            );
        };

        like( $exception, qr{ \Q[Git::Checkout] No 'git' in PATH\E }xsm, q{throws an exception if there is no 'git' in PATH} );
    }

    done_testing;

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
