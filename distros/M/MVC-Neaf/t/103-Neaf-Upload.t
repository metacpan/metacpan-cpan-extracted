#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::Upload;

my $up = MVC::Neaf::Upload->new( id => "foo"
    , filename => "shmoe.txt", handle => \*DATA );

like $up->content, qr/Foo\nBared/s, "Content loaded";
    # This test is actually bugged because content() rewinds file
    #    and rewinding __DATA__ leads to slurping the script itself
cmp_ok $up->size, ">", 0, "Size positive";
is $up->filename, "shmoe.txt", "File name round trip";

done_testing;

__DATA__
Foo
Bared
