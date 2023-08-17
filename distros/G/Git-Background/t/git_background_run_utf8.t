#!perl

# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2021-2023 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.008;
use strict;
use warnings;

use Test::More 0.88;

use Cwd ();
use Encode;
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::TempDir qw(tempdir);

use Git::Background 0.007;

SKIP: {
    for my $output (qw(failure_output todo_output output)) {
        skip "Cannot set test handle $output as UTF-8." if !binmode Test::More->builder->$output, ':encoding(UTF-8)';
    }

    my $bindir = File::Spec->catdir( File::Basename::dirname( File::Basename::dirname( Cwd::abs_path __FILE__ ) ), 'corpus', 'bin' );

    my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
    isa_ok( $obj, 'Git::Background' );

    # Unicode test
    note('usage - 0 / Unicode on stdout / no stderr');
    my $f = $obj->run(
        '-x0',
        "-o\x{4E16}\x{754C}\x{60A8}\x{597D}\n",
        "-e\x{00E4} | \x{4E16}\x{754C}\x{60A8}\x{597D}\n",
        "-o\x{4E16}\x{754C}\x{60A8}\x{597D}\n",
        "-e\x{00F6} | \x{4E16}\x{754C}\x{60A8}\x{597D}\n",
        "-e\x{00FC} | \x{4E16}\x{754C}\x{60A8}\x{597D}\n",
    );

    isa_ok( $f, 'Git::Background::Future' );

    my ( $stdout, $stderr, $rc ) = $f->get;

    is_deeply( $stdout, [ "\x{4E16}\x{754C}\x{60A8}\x{597D}", "\x{4E16}\x{754C}\x{60A8}\x{597D}", ], 'get() returns correct stdout' );
    is_deeply( $stderr, [ "\x{00E4} | \x{4E16}\x{754C}\x{60A8}\x{597D}", "\x{00F6} | \x{4E16}\x{754C}\x{60A8}\x{597D}", "\x{00FC} | \x{4E16}\x{754C}\x{60A8}\x{597D}", ], '... stderr' );
    is( $rc, 0, '... and exit code' );
}

#
done_testing();

exit 0;
