#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
    use File::Spec;
    use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");
}

use File::Find::Object;

use File::Path;

{
    my $ff =
        File::Find::Object->new(
            {},
            "t/",
        );

    my @results;
    push @results, $ff->next();

    # TEST
    is_deeply(\@results, ["t"],
        "t has no trailing slash"
    );
}
