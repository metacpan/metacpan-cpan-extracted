#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::TempDir;

use ok 'File::Chunk::Writer';
use ok 'File::Chunk::Format::IntBare';

my $root = temp_root();

for my $limit ( 1, 10 ) {
    my $dir    = $root->subdir($limit);
    my $writer = File::Chunk::Writer->new(
        chunk_dir             => $dir,
        chunk_line_limit      => $limit,
        format                => File::Chunk::Format::IntBare->new,
    );

    $writer->chunk_dir->mkpath;

    $writer->print("fo");
    $writer->print("o");
    $writer->print(" bar\n");
    $writer->print("$_\n") for 1 .. 100;
}

is("foo bar\n", scalar $root->subdir(1)->file(0)->slurp);
is("100\n", scalar $root->subdir(1)->file(100)->slurp);

is("foo bar\n" . join("\n", 1..9) . "\n", $root->subdir(10)->file(0)->slurp);

done_testing;
