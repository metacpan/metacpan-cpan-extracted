#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use File::Temp qw/ tempdir /;

use File::Dir::Dumper::DigestCache::FS;

{
    my $tempdir = tempdir( CLEANUP => 1);
    my $obj = File::Dir::Dumper::DigestCache::FS->new(
        {
            params =>
            {
                path => $tempdir,
            },
        }
    );

    # TEST
    ok ($obj, 'Object was initialized');

    # TEST
    is_deeply(
        scalar($obj->get_digests(
                {
                    path => ['mydir', 'file.txt'],
                    mtime => 100,
                    digests => [qw(md5 sha1)],
                    calc_cb => sub {
                        return +{
                            md5 => 'a' x 16,
                            sha1 => 'c0de' x 12,
                        },
                    },
                }
            )
        ),
        +{
            md5 => 'a' x 16,
            sha1 => 'c0de' x 12,
        },
        '->get_digests() returns the result of calc_cb',
    );

    # TEST
    is_deeply(
        scalar($obj->get_digests(
                {
                    path => ['mydir', 'file.txt'],
                    mtime => 100,
                    digests => [qw(md5 sha1)],
                    calc_cb => sub {
                        die "Should not happen.";
                    },
                }
            )
        ),
        +{
            md5 => 'a' x 16,
            sha1 => 'c0de' x 12,
        },
        '->get_digests() returns the cached result at the 2nd call.',
    );

    # TEST
    is_deeply(
        scalar($obj->get_digests(
                {
                    path => ['mydir', 'sub-dir', '2ndFile.txt'],
                    mtime => 100,
                    digests => [qw(md5 sha1)],
                    calc_cb => sub {
                        return +{
                            md5 => '24' x 8,
                            sha1 => 'dada' x 12,
                        },
                    },
                }
            )
        ),
        +{
            md5 => '24' x 8,
            sha1 => 'dada' x 12,
        },
        '->get_digests() returns the result on new file',
    );

    # TEST
    is_deeply(
        scalar($obj->get_digests(
                {
                    path => ['mydir', 'file.txt'],
                    mtime => 200,
                    digests => [qw(md5 sha1)],
                    calc_cb => sub {
                        return +{
                            md5 => '7' x 16,
                            sha1 => 'abba' x 12,
                        },
                    },
                }
            )
        ),
        +{
            md5 => '7' x 16,
            sha1 => 'abba' x 12,
        },
        '->get_digests() on new mtime',
    );
}
