#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Test::TempDir;
use IO::String;

use ok 'File::Chunk::Reader';
use ok 'File::Chunk::Format::IntBare';

my $root   = temp_root();

$root->subdir('1')->mkpath;
$root->subdir('1')->file("1")->openw->print("foo\n");
$root->subdir('1')->file("2")->openw->print("bar\n");
$root->subdir('1')->file("3")->openw->print("baz\n");

$root->subdir('2')->mkpath;
$root->subdir('2')->file("1")->openw->print("1\n");
$root->subdir('2')->file("2")->openw->print("2\n");
$root->subdir('2')->file("3")->openw->print("3\n");

my $str = IO::String->new;
$str->print("foo\nbar\nbaz\n1\n2\n3\n");

OBJECT_READER: {
    my $reader = File::Chunk::Reader->new(
        file_dir              => $root,
        format                => File::Chunk::Format::IntBare->new,
    );
    $str->seek(0);

    while (my $line = $reader->getline) {
        my $expect = $str->getline;
        is($str->eof, $reader->eof);
        is($expect, $line);
    }
    is($str->eof, $reader->eof);
}

FH_READER: {
    my $reader = File::Chunk::Reader->new(
        file_dir              => $root,
        format                => File::Chunk::Format::IntBare->new,
    );
    $str->seek(0);

    while (my $line = <$reader>) {
        my $expect = $str->getline;
        is($str->eof, $reader->eof);
        is($expect, $line);
    }
    is($str->eof, $reader->eof);
}



done_testing;
