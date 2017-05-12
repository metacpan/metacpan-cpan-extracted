#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Finder;
use Test::More;
use Data::Dumper;

is_deeply(
    [sort map { m{^.*/([^/]+$)}; $1 } @{Fennec::Finder->new->test_files}],
    [
        sort qw{
            CantFindLayer.ft
            Case-Scoping.ft
            FinderTest.pm
            Mock.ft
            RunSpecific.ft
            Todo.ft
            WorkflowTest.pm
            Workflow_Fennec.ft
            hash_warning.ft
            import_skip.ft
            inner_todo.ft
            order.ft
            procs.ft
            },
    ],
    "Found all test files"
) || print STDERR Dumper( Fennec::Finder->new->test_files );

run();

1;
