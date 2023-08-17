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

use Test::MockModule 0.14;
use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), qw(.. t lib) );

use Carp;
use Scalar::Util ();

use Local::Test::Exception qw(exception);

use Git::Background 0.003;

my $bindir = File::Spec->catdir( File::Basename::dirname( File::Basename::dirname( Cwd::abs_path __FILE__ ) ), 'corpus', 'bin' );
my $mock   = Test::MockModule->new('Path::Tiny');

note('stdout tempfile');
{
    $mock->redefine( 'tempfile', sub { croak '23' } );

    my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
    isa_ok( $obj, 'Git::Background', 'new returned object' );

    my $e = exception { my $x = $obj->run() };    ## no critic (Variables::ProhibitUnusedVarsStricter)
    ok( !blessed $e, 'exception is not blessed' );
    like( $e, qr{ \A \QCannot create temporary file for stdout: 23\E }xsm, '... correct message' );

    $mock->unmock('tempfile');
}

note('stdout filehandle');
{
    $mock->redefine( 'filehandle', sub { croak '31' } );

    my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
    isa_ok( $obj, 'Git::Background', 'new returned object' );

    my $e = exception { my $x = $obj->run() };    ## no critic (Variables::ProhibitUnusedVarsStricter)
    ok( !blessed $e, 'exception is not blessed' );
    like( $e, qr{ \A \QCannot obtain file handle for stdout temp file: 31\E }xsm, '... correct message' );

    $mock->unmock('filehandle');
}

note('stderr tempfile');
{
    my $c = 0;
    $mock->redefine(
        'tempfile',
        sub {
            $c++;

            # skip over the first error call, which is the one for stdout
            return $mock->original('tempfile')->(@_) if $c == 1;

            croak '29';
        },
    );

    my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
    isa_ok( $obj, 'Git::Background', 'new returned object' );

    my $e = exception { my $x = $obj->run() };    ## no critic (Variables::ProhibitUnusedVarsStricter)
    ok( !blessed $e, 'exception is not blessed' );
    like( $e, qr{ \A \QCannot create temporary file for stdout: 29\E }xsm, '... correct message' );

    $mock->unmock('tempfile');
}

note('stderr filehandle');
{
    my $c = 0;
    $mock->redefine(
        'filehandle',
        sub {
            $c++;

            # skip over the first error call, which is the one for stdout
            return $mock->original('filehandle')->(@_) if $c == 1;

            croak '37';
        },
    );

    my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
    isa_ok( $obj, 'Git::Background', 'new returned object' );

    my $e = exception { my $x = $obj->run() };    ## no critic (Variables::ProhibitUnusedVarsStricter)
    ok( !blessed $e, 'exception is not blessed' );
    like( $e, qr{ \A \QCannot obtain file handle for stderr temp file: 37\E }xsm, '... correct message' );

    $mock->unmock('filehandle');
}

#
done_testing();

exit 0;
