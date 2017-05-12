#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use File::Dir::Dumper::DigestCache::Dummy;

{
    my $obj = File::Dir::Dumper::DigestCache::Dummy->new(
        {
            params =>
            {
                path => "./foo",
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
                        return +{
                            md5 => '2' x 16,
                            sha1 => 'd00d' x 12,
                        },
                    },
                }
            )
        ),
        +{
            md5 => '2' x 16,
            sha1 => 'd00d' x 12,
        },
        '->get_digests() returns a different result for same input on 2nd call',
    );
}
