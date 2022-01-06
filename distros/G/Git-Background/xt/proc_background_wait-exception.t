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
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), qw(lib) );

use Local::FalseThing;

use Git::Background;

## no critic (ErrorHandling::RequireCarping)

my $bindir = File::Spec->catdir( File::Basename::dirname( File::Basename::dirname( Cwd::abs_path __FILE__ ) ), 'corpus', 'bin' );
my $mock   = Test::MockModule->new('Proc::Background');

my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $obj, 'Git::Background', 'new returned object' );

note('wait dies');
{
    $mock->redefine( 'wait', sub { die "tEsT eRrOr 77\n" } );

    my $f = $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
    isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );
    my $e = exception { $f->get };
    isa_ok( $e, 'Future::Exception' );
    ok( !$f->is_done,  '!is_done' );
    ok( $f->is_ready,  'is_ready' );
    ok( $f->is_failed, 'is_failed' );

    like( $e, qr{\A\QtEsT eRrOr 77\E}, '... throws an error if Proc::Background wait throws an error' );

    $mock->unmock('wait');
}

note('wait dies with a non-true exception');
{
    $mock->redefine( 'wait', sub { die Local::FalseThing->new(q{}); } );

    my $f = $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
    isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );
    my $e = exception { $f->get };
    isa_ok( $e, 'Future::Exception' );
    ok( !$f->is_done,  '!is_done' );
    ok( $f->is_ready,  'is_ready' );
    ok( $f->is_failed, 'is_failed' );

    like( $e, qr{\A\QFailed to wait on Git process with Proc::Background\E}, '... throws an error if Proc::Background wait throws a false error' );

    $mock->unmock('wait');
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
