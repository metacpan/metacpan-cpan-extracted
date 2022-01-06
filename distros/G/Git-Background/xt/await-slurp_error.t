#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::MockModule 0.14;
use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();

use Git::Background;

my $bindir = File::Spec->catdir( File::Basename::dirname( File::Basename::dirname( Cwd::abs_path __FILE__ ) ), 'corpus', 'bin' );
my $mock   = Test::MockModule->new('File::Temp');

note('stdout / seek error');
{
    $mock->redefine( 'seek', 0 );

    my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
    isa_ok( $obj, 'Git::Background', 'new returned object' );

    my $f = $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
    isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );
    my $e = exception { $f->get };
    isa_ok( $e, 'Future::Exception' );
    ok( !$f->is_done,  '!is_done' );
    ok( $f->is_ready,  'is_ready' );
    ok( $f->is_failed, 'is_failed' );

    like( $e, qr{\A\QCannot seek stdout: \E}, '... throws an error if file cannot be seeked' );

    $mock->unmock('seek');
}

note('stdout / read error');
{
    $mock->redefine( 'error', 1 );

    my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
    isa_ok( $obj, 'Git::Background', 'new returned object' );

    my $f = $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
    isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );
    my $e = exception { $f->get };
    isa_ok( $e, 'Future::Exception' );
    ok( !$f->is_done,  '!is_done' );
    ok( $f->is_ready,  'is_ready' );
    ok( $f->is_failed, 'is_failed' );

    like( $e, qr{\A\QCannot read stdout: \E}, '... throws an error if file cannot be read' );

    $mock->unmock('error');
}

note('stderr / seek');
{
    my $c = 0;
    $mock->redefine(
        'seek',
        sub {
            $c++;

            # skip over the first seek call, which is the one for stdout
            return $mock->original('seek')->(@_) if $c == 1;

            return 0;
        },
    );

    my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
    isa_ok( $obj, 'Git::Background', 'new returned object' );

    my $f = $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
    isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );
    my $e = exception { $f->get };
    isa_ok( $e, 'Future::Exception' );
    ok( !$f->is_done,  '!is_done' );
    ok( $f->is_ready,  'is_ready' );
    ok( $f->is_failed, 'is_failed' );

    like( $e, qr{\A\QCannot seek stderr: \E}, '... throws an error if file cannot be seeked' );

    $mock->unmock('seek');
}

note('stderr / read error');
{
    my $c = 0;
    $mock->redefine(
        'error',
        sub {
            $c++;

            # skip over the first error call, which is the one for stdout
            return $mock->original('error')->(@_) if $c == 1;

            return 1;
        },
    );

    my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
    isa_ok( $obj, 'Git::Background', 'new returned object' );

    my $f = $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
    isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );
    my $e = exception { $f->get };
    isa_ok( $e, 'Future::Exception' );
    ok( !$f->is_done,  '!is_done' );
    ok( $f->is_ready,  'is_ready' );
    ok( $f->is_failed, 'is_failed' );

    like( $e, qr{\A\QCannot read stderr: \E}, '... throws an error if file cannot be read' );

    $mock->unmock('error');
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
