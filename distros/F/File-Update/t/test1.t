#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;
use Path::Tiny qw/ path /;
use File::Update qw/ modify_on_change write_on_change write_on_change_raw /;

{
    my $dir = Path::Tiny->tempdir;
    my $f   = $dir->child("test-write_on_change-1.txt");

    write_on_change( $f, \"first text" );

    # TEST
    is_deeply( [ $f->slurp_utf8 ], ["first text"], "initial text" );

    my $mtime = $f->stat->mtime;

    sleep(1);

    write_on_change( $f, \"first text" );

    # TEST
    is( $f->stat->mtime, $mtime, "mtime did not change" );

    write_on_change( $f, \"second text" );

    # TEST
    is_deeply( [ $f->slurp_utf8 ], ["second text"], "updated text" );

    modify_on_change( $f, sub { return ${ shift() } =~ s/second/third/; } );

    # TEST
    is_deeply( [ $f->slurp_utf8 ], ["third text"], "modify_on_change" );

    $f = $dir->child("test-write_on_change_raw-1.txt");
    write_on_change_raw( $f, \"\0foo" );

    # TEST
    is_deeply( [ $f->slurp_raw ], ["\0foo"], "write_on_change_raw" );
}
