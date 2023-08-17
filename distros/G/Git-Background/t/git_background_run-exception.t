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

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::Exception qw(exception);

use Git::Background 0.003;

my $bindir = File::Spec->catdir( File::Basename::dirname( File::Basename::dirname( Cwd::abs_path __FILE__ ) ), 'corpus', 'bin' );

my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $obj, 'Git::Background' );

#
note('fatal - 128');
my $f = $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
isa_ok( $f, 'Git::Background::Future' );
my $e = exception { $f->get };
isa_ok( $e, 'Future::Exception' );
ok( !$f->is_done,  '!is_done' );
ok( $f->is_ready,  'is_ready' );
ok( $f->is_failed, 'is_failed' );

my ( $message, $category, $stdout, $stderr, $rc ) = $f->failure;
is( $message,  "error 3\nerror 3 line 2", 'error contains correct message' );
is( $category, 'git',                     'error contains correct category' );
is_deeply( $stdout, [ 'stdout 3', 'stdout 3 line 2' ], 'error contains correct stdout' );
is_deeply( $stderr, [ 'error 3',  'error 3 line 2' ],  'error contains correct stderr' );
is( $rc, 128, 'error contains correct exit code' );

#
note('usage - 129');
$f = $obj->run( '-x129', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
isa_ok( $f, 'Git::Background::Future' );
$e = exception { $f->get };
isa_ok( $e, 'Future::Exception' );
ok( !$f->is_done,  '!is_done' );
ok( $f->is_ready,  'is_ready' );
ok( $f->is_failed, 'is_failed' );

( $message, $category, $stdout, $stderr, $rc ) = $f->failure;
is( $message,  "error 3\nerror 3 line 2", 'error contains correct message' );
is( $category, 'git',                     'error contains correct category' );
is_deeply( $stdout, [ 'stdout 3', 'stdout 3 line 2' ], 'error contains correct stdout' );
is_deeply( $stderr, [ 'error 3',  'error 3 line 2' ],  'error contains correct stderr' );
is( $rc, 129, 'error contains correct exit code' );

#
note('usage - 1');
$f = $obj->run( '-x1', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2' );
isa_ok( $f, 'Git::Background::Future' );
$e = exception { $f->get };
isa_ok( $e, 'Future::Exception' );
ok( !$f->is_done,  '!is_done' );
ok( $f->is_ready,  'is_ready' );
ok( $f->is_failed, 'is_failed' );

( $message, $category, $stdout, $stderr, $rc ) = $f->failure;
is( $message,  "error 3\nerror 3 line 2", 'error contains correct message' );
is( $category, 'git',                     'error contains correct category' );
is_deeply( $stdout, [ 'stdout 3', 'stdout 3 line 2' ], 'error contains correct stdout' );
is_deeply( $stderr, [ 'error 3',  'error 3 line 2' ],  'error contains correct stderr' );
is( $rc, 1, 'error contains correct exit code' );

#
note('usage - 7 / no stderr');
$f = $obj->run( '-x7', '-ostdout 3', '-ostdout 3 line 2' );
isa_ok( $f, 'Git::Background::Future' );
$e = exception { $f->get };
isa_ok( $e, 'Future::Exception' );
ok( !$f->is_done,  '!is_done' );
ok( $f->is_ready,  'is_ready' );
ok( $f->is_failed, 'is_failed' );

( $message, $category, $stdout, $stderr, $rc ) = $f->failure;
is( $message,  'git exited with fatal exit code 7 but had no output to stderr', 'error contains correct message' );
is( $category, 'git',                                                           'error contains correct category' );
is_deeply( $stdout, [ 'stdout 3', 'stdout 3 line 2' ], 'error contains correct stdout' );
is_deeply( $stderr, [],                                'error contains no stderr' );
is( $rc, 7, 'error contains correct exit code' );

#
note('version(ARRAY)');
$e = exception { Git::Background->version( [qw(1 2 3)] ) };
like( $e, qr{ \A \Qusage: Git::Background->version([ARGS])\E }xsm, 'error contains correct message' );

note('version(STRING)');
$e = exception { Git::Background->version('hello world') };
like( $e, qr{ \A \Qusage: Git::Background->version([ARGS])\E }xsm, 'error contains correct message' );

#
done_testing();

exit 0;
