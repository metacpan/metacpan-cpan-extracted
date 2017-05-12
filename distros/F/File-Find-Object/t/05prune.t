#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN
{
    use File::Spec;
    use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");
}

use File::Find::Object::TreeCreate;
use File::Find::Object;

use File::Path;

{
    my $tree =
    {
        'name' => "prune--traverse-2/",
        'subs' =>
        [
            {
                'name' => "b.doc",
                'contents' => "This file was spotted in the wild.",
            },
            {
                'name' => "a/",
            },
            {
                'name' => "foo/",
                'subs' =>
                [
                    {
                        'name' => "please-prune-me/",
                        'subs' =>
                        [
                            {
                                'name' => "a-non-reachable-dir/",
                                'subs' =>
                                [
                                    {
                                        'name' => "dir1/",
                                    },
                                    {
                                        'name' => "dir2/",
                                    },
                                    {
                                        'name' =>
                                            "if-we-get-this-its-wrong.txt",
                                        'content' => "Hi ho!",
                                    },
                                ],
                            },
                            {
                                'name' => "h.rnd",
                                'contents' => "This file is empty.",
                            },
                            {
                                'name' => "lambda.calculus",
                                'contents' => '\f \x (f (f x))'
                            },
                        ],
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree("./t/sample-data/", $tree);
    my $ff =
        File::Find::Object->new(
            {},
            $t->get_path("./t/sample-data/prune--traverse-2")
        );
    my @results;
    for my $i (1 .. 7)
    {
        my $file = $ff->next();
        # We're doing that because get_current_node_files_list() used to
        # call ->_recurse() which caused some subtle bugs.
        my $files_in_node = $ff->get_current_node_files_list();

        if ($file eq
            $t->get_path("t/sample-data/prune--traverse-2/foo/please-prune-me")
           )
        {
            $ff->set_traverse_to(
                [
                    grep { $_ !~ /non-reachable/ }
                    @{$ff->get_current_node_files_list()}
                ]
            );

            # TEST
            is_deeply ($ff->get_traverse_to(), ["h.rnd", "lambda.calculus"],
                "Testing ->get_traverse_to()"
            );
        }
        push @results, $file;
    }
    # TEST
    is_deeply(
        \@results,
        [(map { $t->get_path("t/sample-data/prune--traverse-2/$_") }
            ("",
            qw(
                a
                b.doc
                foo
                foo/please-prune-me
                foo/please-prune-me/h.rnd
                foo/please-prune-me/lambda.calculus
            )))
        ],
        "Checking for regular, lexicographically sorted order",
    );

    rmtree($t->get_path("./t/sample-data/prune--traverse-2"))
}

{
    my $tree =
    {
        'name' => "prune--traverse-2/",
        'subs' =>
        [
            {
                'name' => "b.doc",
                'contents' => "This file was spotted in the wild.",
            },
            {
                'name' => "a/",
            },
            {
                'name' => "foo/",
                'subs' =>
                [
                    {
                        'name' => "please-prune-me/",
                        'subs' =>
                        [
                            {
                                'name' => "a-non-reachable-dir/",
                                'subs' =>
                                [
                                    {
                                        'name' => "dir1/",
                                    },
                                    {
                                        'name' => "dir2/",
                                    },
                                    {
                                        'name' =>
                                            "if-we-get-this-its-wrong.txt",
                                        'content' => "Hi ho!",
                                    },
                                ],
                            },
                            {
                                'name' => "h.rnd",
                                'contents' => "This file is empty.",
                            },
                            {
                                'name' => "lambda.calculus",
                                'contents' => '\f \x (f (f x))'
                            },
                        ],
                    },
                    {
                        'name' => "zardoz/",
                        'subs' =>
                        [
                            {
                                'name' => "p.txt",
                                'contents' => "Intentionally Left Boring.",
                            },
                        ],
                    },
                ],
            },
            {
                'name' => "zardoz/",
                'subs' =>
                [
                    {
                        'name' => "p.txt",
                        'contents' => "Intentionally Left Boring.",
                    },
                ],
            },

        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree("./t/sample-data/", $tree);
    my $ff =
        File::Find::Object->new(
            {},
            $t->get_path("./t/sample-data/prune--traverse-2")
        );
    my @results;
    for my $i (1 .. 9)
    {
        my $file = $ff->next();
        if ($file eq
            $t->get_path("t/sample-data/prune--traverse-2/foo/please-prune-me")
           )
        {
            $ff->prune();
        }
        push @results, $file;
    }

    # TEST
    ok (!defined($ff->next()), "Testing that the scan has completed.");

    # TEST
    is_deeply(
        \@results,
        [(map { $t->get_path("t/sample-data/prune--traverse-2/$_") }
            ("",
            qw(
                a
                b.doc
                foo
                foo/please-prune-me
                foo/zardoz
                foo/zardoz/p.txt
                zardoz
                zardoz/p.txt
            )))
        ],
        "Checking for regular, lexicographically sorted order",
    );

    rmtree($t->get_path("./t/sample-data/prune--traverse-2"))
}
