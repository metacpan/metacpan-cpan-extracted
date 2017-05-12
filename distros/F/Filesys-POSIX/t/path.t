# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX::Path ();

use Test::More ( 'tests' => 67 );
use Test::Exception;
use Test::NoWarnings;
use Test::Filesys::POSIX::Error;

my %TEST_DATA = (
    '/' => {
        'full'     => '/',
        'dirname'  => '/',
        'basename' => '/',
        'parts'    => ['/']
    },

    '.' => {
        'full'     => '.',
        'dirname'  => '.',
        'basename' => '.',
        'parts'    => ['.']
    },

    '..' => {
        'full'     => '..',
        'dirname'  => '.',
        'basename' => '..',
        'parts'    => ['..']
    },

    'meow' => {
        'full'     => 'meow',
        'dirname'  => '.',
        'basename' => 'meow',
        'parts'    => ['meow']
    },

    '/foo/bar/baz' => {
        'full'     => '/foo/bar/baz',
        'dirname'  => '/foo/bar',
        'basename' => 'baz',
        'parts'    => [ '', qw(foo bar baz) ]
    },

    'foo/bar/baz' => {
        'full'     => 'foo/bar/baz',
        'dirname'  => 'foo/bar',
        'basename' => 'baz',
        'parts'    => [qw(foo bar baz)]
    },

    '../foo/bar' => {
        'full'     => '../foo/bar',
        'dirname'  => '../foo',
        'basename' => 'bar',
        'parts'    => [qw(.. foo bar)]
    },

    '///borked' => {
        'full'     => '/borked',
        'dirname'  => '/',
        'basename' => 'borked',
        'parts'    => [ '', 'borked' ]
    },

    './././cats' => {
        'full'     => './cats',
        'dirname'  => '.',
        'basename' => 'cats',
        'parts'    => [ '.', 'cats' ]
    },

    'foo/../bar' => {
        'full'     => 'foo/../bar',
        'basename' => 'bar',
        'dirname'  => 'foo/..',
        'parts'    => [qw(foo .. bar)]
    },

    './foo/../bar' => {
        'full'     => './foo/../bar',
        'basename' => 'bar',
        'dirname'  => './foo/..',
        'parts'    => [qw(. foo .. bar)]
    },
);

foreach my $input ( keys %TEST_DATA ) {
    my $item = $TEST_DATA{$input};
    my $path = Filesys::POSIX::Path->new($input);

    ok(
        $path->full eq $item->{'full'},
        "Full name of '$input' should be $item->{'full'}"
    );
    ok(
        $path->basename eq $item->{'basename'},
        "Base name of '$input' should be $item->{'basename'}"
    );
    ok(
        $path->dirname eq $item->{'dirname'},
        "Directory name of '$input' should be $item->{'dirname'}"
    );
    ok(
        $path->count == scalar @{ $item->{'parts'} },
        "Parsed the correct number of items for '$input'"
    );

    my $left = $path->count;
    while ( $path->count ) {
        $left-- if $path->pop eq pop @{ $item->{'parts'} };
    }

    ok(
        $left == 0,
        "Each component of '$input' held internally parsed as expected"
    );
}

{
    my $path = Filesys::POSIX::Path->new('///foo');
    $path->push('///bar');

    ok(
        $path->full eq '/foo/bar',
        "Filesys::POSIX::Path->push() chops useless items out like new()"
    );
}

{
    my $path    = Filesys::POSIX::Path->new('/foo');
    my $newpath = $path->concat('bar/./baz///boo');

    ok(
        $path->full eq '/foo',
        "Filesys::POSIX::Path->concat() does not mangle original path"
    );
    ok(
        $newpath->full eq 'bar/baz/boo/foo',
        "Filesys::POSIX::Path->concat() provides expected result with string"
    );
}

{
    my $path1   = Filesys::POSIX::Path->new('/foo');
    my $path2   = Filesys::POSIX::Path->new('bar/baz/boo');
    my $newpath = $path1->concat($path2);

    ok(
        $newpath->full eq 'bar/baz/boo/foo',
        "Filesys::POSIX::Path->concat() works with other instances of class"
    );
}

{
    my $path    = Filesys::POSIX::Path->new('///foo');
    my $newpath = $path->append('bar/./baz///boo');

    ok( $path eq $newpath, "Filesys::POSIX::Path->append() returns self" );
    ok(
        $path->full eq '/foo/bar/baz/boo',
        "Filesys::POSIX::Path->append() works expectedly when passed a string"
    );
}

{
    my $path1 = Filesys::POSIX::Path->new('///foo');
    my $path2 = Filesys::POSIX::Path->new('bar/./baz///boo');

    $path1->append($path2);

    ok(
        $path1->full eq '/foo/bar/baz/boo',
        "Filesys::POSIX::Path->append() works when passed instance"
    );
}

ok(
    Filesys::POSIX::Path->basename( '/foo/bar.txt', '.txt' ) eq 'bar',
    "Filesys::POSIX::Path->basename() works with an extension"
);

throws_errno_ok {
    Filesys::POSIX::Path->new('');
}
&Errno::EINVAL, "Filesys::POSIX::Path->new() fails when an empty path is specified";

{
    my $path = Filesys::POSIX::Path->new('.');
    ok(
        scalar(@$path) == 1 && $path->[0] eq '.',
        "Filesys::POSIX::Path handles '.' appropriately"
    );
}

{
    my $path = Filesys::POSIX::Path->new('foo/0');
    is(
        $path->pop, '0',
        'Filesys::POSIX::Path->new() does not treat string "0" in paths as empty'
    );
}
