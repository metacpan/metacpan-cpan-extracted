#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN
{
    use File::Spec;
    use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");
}

use File::Find::Object::TreeCreate;
use File::Find::Object;

use File::Path;

package MyFFO;

use vars qw(@ISA);

@ISA=(qw(File::Find::Object));

sub DESTROY
{
    my $self = shift;
    $self->{'**DESTROY**'}->();
}

package main;

my $destroy_counter = 0;
sub my_destroy
{
    $destroy_counter++;
}

{
    my $tree =
    {
        'name' => "destroy--traverse-1/",
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
        MyFFO->new(
            {},
            $t->get_path("./t/sample-data/destroy--traverse-1")
        );
    $ff->{'**DESTROY**'} = \&my_destroy;
    my @results;
    for my $i (1 .. 6)
    {
        push @results, $ff->next();
    }
    # TEST
    is_deeply(
        \@results,
        [(map { $t->get_path("t/sample-data/destroy--traverse-1/$_") }
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

    rmtree($t->get_path("./t/sample-data/destroy--traverse-1"))
}
# TEST
is ($destroy_counter, 1,
    "Check that the object was destroyed when it goes out of scope."
);

