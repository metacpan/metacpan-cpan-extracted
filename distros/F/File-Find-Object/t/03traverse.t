#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 46;

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
        'name' => "traverse--traverse-1/",
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
                        'name' => "yet/",
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
            $t->get_path("./t/sample-data/traverse--traverse-1")
        );
    my @results;
    for my $i (1 .. 6)
    {
        push @results, $ff->next();
    }
    # TEST
    is_deeply(
        \@results,
        [(map { $t->get_path("t/sample-data/traverse--traverse-1/$_") }
            ("", qw(
                a
                b.doc
                foo
                foo/yet
            ))),
         undef
        ],
        "Checking for regular, lexicographically sorted order",
    );

    rmtree($t->get_path("./t/sample-data/traverse--traverse-1"));
}

{
    my $test_id = "traverse--traverse-dirs-and-files";
    my $test_dir = "t/sample-data/$test_id";
    my $tree =
    {
        'name' => "$test_id/",
        'subs' =>
        [
            {
                'name' => "a/",
                subs =>
                [
                    {
                        'name' => "b.doc",
                        'contents' => "This file was spotted in the wild.",
                    },
                ],
            },
            {
                'name' => "foo/",
                'subs' =>
                [
                    {
                        'name' => "t.door.txt",
                        'contents' => "A T Door",
                    },
                    {
                        'name' => "yet/",
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
            $t->get_path("./$test_dir/a/b.doc"),
            $t->get_path("./$test_dir/foo"),
        );
    my @results;
    for my $i (1 .. 5)
    {
        push @results, $ff->next();
    }
    # TEST
    is_deeply(
        \@results,
        [(map { $t->get_path("$test_dir/$_") }
            (qw(
                a/b.doc
                foo
                foo/t.door.txt
                foo/yet
            ))),
         undef
        ],
        "Checking that one can traverse regular files.",
    );

    rmtree($t->get_path("./$test_dir"))
}

{
    my $test_id = "traverse--dont-traverse-non-existing-files";
    my $test_dir = "t/sample-data/$test_id";
    my $tree =
    {
        'name' => "$test_id/",
        'subs' =>
        [
            {
                'name' => "a/",
                subs =>
                [
                    {
                        'name' => "b.doc",
                        'contents' => "This file was spotted in the wild.",
                    },
                ],
            },
            {
                'name' => "c/",
                subs =>
                [
                    {
                        'name' => "d.doc",
                        'contents' => "This file was spotted in the wild.",
                    },
                ],
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
            {
                'name' => "bar/",
                'subs' =>
                [
                    {
                        name => "myfile.txt",
                        content => "Hello World",
                    },
                    {
                        'name' => "zamda/",
                    },
                ],
            },
            {
                'name' => "daps/",
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree("./t/sample-data/", $tree);
    my $ff =
        File::Find::Object->new(
            {},
            $t->get_path("./$test_dir/foo"),
            $t->get_path("./$test_dir/a/non-exist"),
            $t->get_path("./$test_dir/bar"),
            $t->get_path("./$test_dir/b/non-exist"),
            $t->get_path("./$test_dir/daps"),
        );
    my @results;
    for my $i (1 .. 7)
    {
        push @results, $ff->next();
    }
    # TEST
    is_deeply(
        \@results,
        [(map { $t->get_path("$test_dir/$_") }
            (qw(
                foo
                foo/yet
                bar
                bar/myfile.txt
                bar/zamda
                daps
            ))),
         undef
        ],
        "Checking that we skip non-existent paths",
    );

    rmtree($t->get_path("./$test_dir"))
}

{
    my $test_id = "traverse--handle-non-accessible-dirs-gracefully";
    my $test_dir = "t/sample-data/$test_id";
    my $tree =
    {
        'name' => "$test_id/",
        'subs' =>
        [
            {
                'name' => "a/",
                subs =>
                [
                    {
                        'name' => "b.doc",
                        'contents' => "This file was spotted in the wild.",
                    },
                ],
            },
            {
                'name' => "c/",
                subs =>
                [
                    {
                        'name' => "d.doc",
                        'contents' => "This file was spotted in the wild.",
                    },
                ],
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
            {
                'name' => "bar/",
                'subs' =>
                [
                    {
                        name => "myfile.txt",
                        content => "Hello World",
                    },
                    {
                        'name' => "zamda/",
                    },
                ],
            },
            {
                'name' => "daps/",
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree("./t/sample-data/", $tree);
    chmod (0000, $t->get_path("$test_dir/bar"));
    eval
    {
        my $ff = File::Find::Object->new({}, $t->get_path("$test_dir"));

        my @results;
        while (defined(my $result = $ff->next()))
        {
            push @results, $result;
        }
        # TEST
        ok (scalar(grep { $_ eq $t->get_path("$test_dir/a")} @results),
            "Found /a",
        );
    };
    # TEST
    is ($@, "", "Handle non-accessible directories gracefully");

    chmod (0755, $t->get_path("$test_dir/bar"));
    rmtree($t->get_path("./$test_dir"))
}

{
    my $tree =
    {
        'name' => "traverse--traverse-1/",
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
                        'name' => "file.txt",
                        'contents' => "A file that should come before yet/",
                    },
                    {
                        'name' => "yet/",
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
            $t->get_path("./t/sample-data/traverse--traverse-1")
        );

    {
        my $r = $ff->next_obj();

        # TEST
        is ($r->path(), $t->get_path("t/sample-data/traverse--traverse-1/"), "Path");

        # TEST
        is ($r->base(), $t->get_path("./t/sample-data/traverse--traverse-1"), "Base");

        # TEST
        is_deeply ($r->dir_components(), [], "Dir_Components are empty");

        # TEST
        ok ($r->is_dir(), "Is a directory");

        # TEST
        ok (!$r->is_link(), "Not a link");

        # TEST
        is_deeply ($r->full_components(), [], "Full components are empty");
    }

    {
        my $r = $ff->next_obj();

        # TEST
        is ($r->path(), $t->get_path("t/sample-data/traverse--traverse-1/a"), "Path");

        # TEST
        is ($r->base(), $t->get_path("./t/sample-data/traverse--traverse-1"), "Base");

        # TEST
        is_deeply ($r->dir_components(), [qw(a)], "Dir_Components are 'a'");

        # TEST
        ok ($r->is_dir(), "Is a directory");

        # TEST
        is_deeply ($r->full_components(), [qw(a)], "Full components are 'a'");
    }

    {
        my $r = $ff->next_obj();

        # TEST
        is ($r->path(), $t->get_path("t/sample-data/traverse--traverse-1/b.doc"), "Path");

        # TEST
        is ($r->base(), $t->get_path("./t/sample-data/traverse--traverse-1"), "Base");

        # TEST
        is_deeply ($r->dir_components(), [], "Dir_Components are empty");

        # TEST
        ok (!$r->is_dir(), "Not a directory");

        # TEST
        ok (!$r->is_link(), "Not a link");

        # TEST
        is_deeply ($r->full_components(), [qw(b.doc)],
            "Full components are 'b.doc'"
        );

        # TEST
        is ($r->basename(), "b.doc", "Basename is 'b.doc'");
    }

    {
        my $r = $ff->next_obj();

        # TEST
        is ($r->path(), $t->get_path("t/sample-data/traverse--traverse-1/foo"), "Path");

        # TEST
        is ($r->base(), $t->get_path("./t/sample-data/traverse--traverse-1"), "Base");

        # TEST
        is_deeply ($r->dir_components(), [qw(foo)],
            "Dir_Components are 'foo'"
        );

        # TEST
        ok ($r->is_dir(), "Is a directory");

        # TEST
        is_deeply ($r->full_components(), [qw(foo)],
            "Full components are 'foo'"
        );
    }

    {
        my $r = $ff->next_obj();

        # TEST
        is ($r->path(), $t->get_path("t/sample-data/traverse--traverse-1/foo/file.txt"),
            "Path",
        );

        # TEST
        is ($r->base(), $t->get_path("./t/sample-data/traverse--traverse-1"),
            "Base"
        );

        # TEST
        is_deeply ($r->dir_components(), [qw(foo)],
            "Dir_Components are 'foo'"
        );

        # TEST
        ok (!$r->is_dir(), "Not a directory");

        # TEST
        is_deeply ($r->full_components(), [qw(foo file.txt)],
            "Full components are 'foo/file.txt'"
        );

        # TEST
        is ($r->basename(), "file.txt", "Basename is 'file.txt'");
    }

    {
        my $r = $ff->next_obj();

        # TEST
        is ($r->path(), $t->get_path("t/sample-data/traverse--traverse-1/foo/yet"),
            "Path",
        );

        # TEST
        is ($r->base(), $t->get_path("./t/sample-data/traverse--traverse-1"), "Base");

        # TEST
        is_deeply ($r->dir_components(), [qw(foo yet)],
            "Dir_Components are 'foo/yet'"
        );

        # TEST
        ok ($r->is_dir(), "Is a directory");

        # TEST
        is_deeply ($r->full_components(), [qw(foo yet)],
            "Full components are 'foo/yet'"
        );
    }

    {
        my $r = $ff->next_obj();

        # TEST
        ok (!defined($r), "Last result is undef");
    }

    undef ($ff);

    rmtree($t->get_path("./t/sample-data/traverse--traverse-1"))
}

{
    my $tree =
    {
        'name' => "traverse--traverse-1/",
        'subs' =>
        [
            {
                'name' => "0/",
            },
            {
                'name' => "foo/",
                'subs' =>
                [
                    {
                        'name' => "0",
                        'contents' => "Zero file",
                    },
                    {
                        'name' => "1",
                        'contents' => "One file",
                    },
                    {
                        'name' => "2",
                        'contents' => "Two file",
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
            $t->get_path("./t/sample-data/traverse--traverse-1")
        );

    my @results;
    for my $i (1 .. 7)
    {
        push @results, $ff->next();
    }

    # TEST
    is_deeply(
        \@results,
        [(map { $t->get_path("t/sample-data/traverse--traverse-1/$_") }
            sort {$a cmp $b }
            ("", qw(
                0
                foo
                foo/0
                foo/1
                foo/2
            ))),
         undef
        ],
        "Checking that files named '0' are correctly scanned",
    );

    rmtree($t->get_path("./t/sample-data/traverse--traverse-1"));
}

{
    my $tree =
    {
        'name' => "traverse--traverse-1/",
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
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree("./t/sample-data/", $tree);

    my $ff;
    my $callback = sub {
        my $path = shift;

        my $path_obj = $ff->item_obj();

        # TEST
        ok ($path_obj, "Path object is defined.");

        # TEST
        is_deeply($path_obj->full_components(),
            [],
            "Path empty."
        );

        # TEST
        ok ($path_obj->is_dir(), "Path object is a directory");
    };

    $ff =
        File::Find::Object->new(
            {callback => $callback},
            $t->get_path("./t/sample-data/traverse--traverse-1")
        );

    my @results;

    # Call $ff->next() and do the tests in $callback .
    push @results, $ff->next();

    rmtree($t->get_path("./t/sample-data/traverse--traverse-1"));
}

{
    my $tree =
    {
        'name' => "traverse--traverse-1/",
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
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree("./t/sample-data/", $tree);
    my $ff =
        File::Find::Object->new(
            {nocrossfs => 1,},
            $t->get_path("./t/sample-data/traverse--traverse-1")
        );
    my @results;
    for my $i (1 .. 6)
    {
        push @results, $ff->next();
    }
    # TEST
    is_deeply(
        \@results,
        [(map { $t->get_path("t/sample-data/traverse--traverse-1/$_") }
            ("", qw(
                a
                b.doc
                foo
                foo/yet
            ))),
         undef
        ],
        "Testing nocrossfs",
    );

    rmtree($t->get_path("./t/sample-data/traverse--traverse-1"));
}

{
    my $tree =
    {
        'name' => "traverse--traverse-1/",
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
                        'name' => "file.txt",
                        'contents' => "A file that should come before yet/",
                    },
                    {
                        'name' => "yet/",
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
            $t->get_path("./t/sample-data/traverse--traverse-1")
        );

    my @results;

    while (my $r = $ff->next_obj())
    {
        if ($r->is_file())
        {
            push @results, $r->path();
        }
    }

    # TEST
    is_deeply(
        \@results,
        [
            map { $t->get_path("t/sample-data/traverse--traverse-1/$_") }
            (qw(b.doc foo/file.txt))
        ],
        "Checking for regular, lexicographically sorted order",
    );

    rmtree($t->get_path("./t/sample-data/traverse--traverse-1"))
}
