#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;

use File::Path qw( rmtree mkpath );

use File::TreeCreate ();

{
    my $t = File::TreeCreate->new();

    # TEST
    ok( $t, "TreeCreate object was initialized" );

    # TEST
    is( $t->get_path("./t/file.txt"),
        File::Spec->catfile( File::Spec->curdir(), "t", "file.txt" ) );

    # TEST
    is( $t->get_path("./t/mydir/"),
        File::Spec->catdir( File::Spec->curdir(), "t", "mydir" ) );

    # TEST
    is(
        $t->get_path("./t/hello/there/world.jpg"),
        File::Spec->catfile(
            File::Spec->curdir(), "t", "hello", "there", "world.jpg"
        )
    );

    # TEST
    is(
        $t->get_path("./one/two/three/four/"),
        File::Spec->catdir(
            File::Spec->curdir(), "one", "two", "three", "four"
        )
    );
}

{
    my $t = File::TreeCreate->new();

    # TEST
    ok( $t->exist("./MANIFEST"), "Checking the exist() method" );

    # TEST
    ok( !$t->exist("./BKLASDJASFDJODIJASDOJASODJ.wok"),
        "Checking the exist() method" );

    # TEST
    ok( $t->is_file("./MANIFEST"), "Checking the is_file method" );

    # TEST
    ok( !$t->is_file("./t"), "Checking the is_file method - 2" );

    # TEST
    ok( !$t->is_dir("./MANIFEST"), "Checking the is_dir method - false" );

    # TEST
    ok( $t->is_dir("./t"), "Checking the is_dir method - true" );

    # TEST
    is( $t->cat("./t/sample-data/h.txt"), "Hello.", "Checking the cat method" );

    {
        mkdir( $t->get_path("./t/sample-data/tree-create-ls-test") );
        mkdir( $t->get_path("./t/sample-data/tree-create-ls-test/a") );
        {
            open my $out_fh, ">",
                $t->get_path("./t/sample-data/tree-create-ls-test/b.txt");
            print {$out_fh} "Yowza";
            close($out_fh);
        }
        mkdir( $t->get_path("./t/sample-data/tree-create-ls-test/c") );
        {
            open my $out_fh, ">",
                $t->get_path("./t/sample-data/tree-create-ls-test/h.xls");
            print {$out_fh} "FooBardom!\n";
            close($out_fh);
        }

        # TEST
        is_deeply(
            $t->ls("./t/sample-data/tree-create-ls-test"),
            [ "a", "b.txt", "c", "h.xls" ],
            "Testing the ls method",
        );

        # Cleanup
        rmtree( $t->get_path("./t/sample-data/tree-create-ls-test") );
    }

    {
        my $tree = {
            'name' => "tree-create--tree-test-1/",
            'subs' => [
                {
                    'name'     => "b.doc",
                    'contents' => "This file was spotted in the wild.",
                },
                {
                    'name' => "a/",
                },
                {
                    'name' => "foo/",
                    'subs' => [
                        {
                            'name' => "yet/",
                        },
                    ],
                },
            ],
        };

        $t->create_tree( "./t/sample-data/", $tree );

        # TEST
        is_deeply(
            $t->ls("./t/sample-data/tree-create--tree-test-1"),
            [ "a", "b.doc", "foo" ],
            "Testing the contents of the root tree"
        );

        # TEST
        ok( $t->is_dir("./t/sample-data/tree-create--tree-test-1/a"),
            "a is a dir" );

        # TEST
        is_deeply( $t->ls("./t/sample-data/tree-create--tree-test-1/a"),
            [], "Testing the contents of a" );

        # TEST
        is_deeply( $t->ls("./t/sample-data/tree-create--tree-test-1/foo"),
            ["yet"], "Testing the contents of foo" );

        # TEST
        ok( $t->is_dir("./t/sample-data/tree-create--tree-test-1/foo/yet"),
            "Testing that foo/yet is a dir" );

        # TEST
        is_deeply( $t->ls("./t/sample-data/tree-create--tree-test-1/foo/yet"),
            [], "Testing that foo/yet is a dir" );

        # TEST
        ok( $t->is_file("./t/sample-data/tree-create--tree-test-1/b.doc"),
            "Checking that b.doc is a file" );

        # TEST
        is(
            $t->cat("./t/sample-data/tree-create--tree-test-1/b.doc"),
            "This file was spotted in the wild.",
            "Checking for contents of b.doc"
        );

        # Cleanup
        rmtree( $t->get_path("./t/sample-data/tree-create--tree-test-1") );
    }
    {
        # TEST
        is(
            $t->get_path("s/hello"),
            File::Spec->catfile( "s", "hello" ),
            "Bug that eliminated ^[AnyChar]/ instead of ^\\./"
        );
    }
}

