#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 62;

use POSIX qw(mktime strftime);
use File::Path;
use English qw( -no_match_vars );

use Devel::CheckOS qw(:booleans);

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");
use File::Temp qw/ tempdir /;

use File::Find::Object::TreeCreate;

use File::Dir::Dumper::Scanner;

use Digest::MD5;
use Digest::SHA;


{
    my $tree =
    {
        'name' => "traverse-1/",
        'subs' =>
        [
            {
                'name' => "a.doc",
                'contents' => "This file was spotted in the wild.",
            },
            {
                'name' => "b/",
            },
            {
                'name' => "foo/",
                'subs' =>
                [
                    {
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree("./t/sample-data/", $tree);

    my $test_dir = "t/sample-data/traverse-1";

    my $a_doc_time = mktime(1, 2, 3, 4, 5, 106);
    utime($a_doc_time, $a_doc_time, $t->get_path("$test_dir/a.doc"));

    my $scanner = File::Dir::Dumper::Scanner->new(
        {
            dir => $t->get_path($test_dir),
        }
    );

    my $token;

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "header", "Token is of type header");

    # TEST
    is ($token->{dir_to_dump}, $t->get_path($test_dir),
        "dir_to_dump is OK."
    );

    # TEST
    is ($token->{stream_type}, "Directory Dump",
        "stream_type is OK."
    );

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "dir", "type is dir");

    # TEST
    is ($token->{depth}, 0, "depth is 0");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "file", "Type is file");

    # TEST
    is ($token->{filename}, "a.doc", "Filename is OK.");

    # TEST
    is ($token->{mtime},
        strftime("%Y-%m-%dT%H:%M:%S", localtime($a_doc_time)),
        "mtime is OK.",
    );

    # TEST
    is ($token->{size},
        length("This file was spotted in the wild."),
        "size is OK.",
    );

    # TEST
    is ($token->{perms},
        sprintf("%04o", ((stat($t->get_path("$test_dir/a.doc")))[2]&07777)),
        "perms are OK."
    );

    # TEST
    is ($token->{user},
        File::Dir::Dumper::Scanner::_my_getpwuid($UID),
        "user is OK."
    );

    # TEST
    is ($token->{group},
        (
            os_is('Unix')
            ? scalar(getgrgid((stat($t->get_path("$test_dir/a.doc")))[5]))
            : "unknown"
        ),
        "group is OK."
    );

    # TEST
    is ($token->{depth}, 1, "Token depth is 1");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "dir", "Token is dir");

    # TEST
    is ($token->{depth}, 1, "Token depth is 1");

    # TEST
    is ($token->{filename}, "b", "dir name is 'b'");

    # TEST
    is ($token->{perms},
        sprintf("%04o", ((stat($t->get_path("$test_dir/b/")))[2]&07777)),
        "perms are OK."
    );

    # TEST
    is ($token->{user},
        File::Dir::Dumper::Scanner::_my_getpwuid($UID),
        "user is OK."
    );

    # TEST
    is ($token->{group},
        (
            os_is('Unix')
            ? scalar(getgrgid((stat($t->get_path("$test_dir/b/")))[5]))
            : "unknown"
        ),
        "group is OK."
    );

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "updir", "Token is updir");

    # TEST
    is ($token->{depth}, 1, "updir token (from 'b') has depth 1");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "dir", "Token is dir");

    # TEST
    is ($token->{filename}, "foo", "dir name is 'foo'");

    # TEST
    is ($token->{depth}, 1, "Token depth is 1");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "dir", "Token is dir");

    # TEST
    is ($token->{filename}, "yet", "dir name is 'yet'");

    # TEST
    is ($token->{depth}, 2, "Token depth is 2");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "updir", "Token is updir");

    # TEST
    is ($token->{depth}, 2, "Token depth is 2");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "updir", "Token is updir");

    # TEST
    is ($token->{depth}, 1, "Token depth is 1");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "updir", "Token is updir");

    # TEST
    is ($token->{depth}, 0, "Token depth is 0");

    $token = $scanner->fetch();

    # TEST
    is ($token->{type}, "footer", "Token is footer");

    $token = $scanner->fetch();

    # TEST
    ok (!defined($token), "Token is undefined - reached end.");

    $token = $scanner->fetch();

    # TEST
    ok (!defined($token), "Token is undefined - make sure we don't restart");

    rmtree($t->get_path($test_dir))
}

# TEST:$digests=2;
foreach my $is_cache (0, 1)
{
    my $tree =
    {
        'name' => "traverse-1/",
        'subs' =>
        [
            {
                'name' => "a.doc",
                'contents' => "This file was spotted in the wild.",
            },
            {
                'name' => "cat.txt",
                'contents' => "Meow Meow",
            },
            {
                'name' => "foo/",
                'subs' =>
                [
                    {
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree("./t/sample-data/", $tree);

    my $test_dir = "t/sample-data/traverse-1";

    my $a_doc_time = mktime(1, 2, 3, 4, 5, 106);
    utime($a_doc_time, $a_doc_time, $t->get_path("$test_dir/a.doc"));

    my $tempdir = tempdir( CLEANUP => 1);
    my $scanner = File::Dir::Dumper::Scanner->new(
        {
            dir => $t->get_path($test_dir),
            digests => [qw(SHA-512 MD5)],
            ($is_cache
                ? (digest_cache => 'FS', digest_cache_params => {
                    path => $tempdir,
                })
                : ()
            ),
        }
    );

    my $token;

    $token = $scanner->fetch();

    # TEST*$digests
    is ($token->{type}, "header", "Token is of type header");

    # TEST*$digests
    is ($token->{dir_to_dump}, $t->get_path($test_dir),
        "dir_to_dump is OK."
    );

    # TEST*$digests
    is ($token->{stream_type}, "Directory Dump",
        "stream_type is OK."
    );

    $token = $scanner->fetch();

    # TEST*$digests
    is ($token->{type}, "dir", "type is dir");

    # TEST*$digests
    is ($token->{depth}, 0, "depth is 0");

    $token = $scanner->fetch();

    # TEST*$digests
    is ($token->{type}, "file", "Type is file");

    # TEST*$digests
    is ($token->{filename}, "a.doc", "Filename is OK.");

    # TEST*$digests
    is_deeply (
        $token->{digests},
        +{
            MD5 => '85878a491ed9a0e0164c5ee398a6ac74',
            'SHA-512' => 'de8e52b8e38dbd7072e1e73b8340bf357d5af4058fd0110132cb45a532e9506f366f0df4b221a889717304830954d6d53cded53020d465044da7547a87ed02ce',
        },
        "a.doc digests."
    );

    # TEST*$digests
    is ($token->{depth}, 1, "Token depth is 1");

    $token = $scanner->fetch();

    # TEST*$digests
    is ($token->{type}, "file", "Type is file");

    # TEST*$digests
    is ($token->{filename}, "cat.txt", "Filename is OK.");

    # TEST*$digests
    is_deeply (
        $token->{digests},
        +{
            MD5 => '02e86f5c3569cf659e6d39644b681fd9',
            'SHA-512' => '5e8d0710ab13e35f252306006db7dda8e1d244ecbdf0ecacccf41c396bb9f547427890c0ec32c04f59ca079dc4d9e6ad57782804aea1282a926356a03cafaa00',
        },
        "cat.txt digests."
    );

    # TEST*$digests
    is ($token->{depth}, 1, "Token depth is 1");

    rmtree($t->get_path($test_dir))
}
