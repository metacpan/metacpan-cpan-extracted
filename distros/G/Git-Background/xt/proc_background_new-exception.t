#!perl

use 5.006;
use strict;
use warnings;

use Test::MockModule 0.14;
use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), qw(lib) );

use Local::FalseThing;

use Git::Background 0.003;

## no critic (ErrorHandling::RequireCarping)

my $bindir = File::Spec->catdir( File::Basename::dirname( File::Basename::dirname( Cwd::abs_path __FILE__ ) ), 'corpus', 'bin' );
my $mock   = Test::MockModule->new('Proc::Background');

my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $obj, 'Git::Background', 'new returned object' );

note('new dies');
{
    $mock->redefine( 'new', sub { die "tEsT eRrOr 47\n" } );

    my $f = $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
    isa_ok( $f, 'Future', 'run() returns a (failed) Future' );
    ok( !$f->is_done,  '!is_done' );
    ok( $f->is_ready,  'is_ready' );
    ok( $f->is_failed, 'is_failed' );
    is_deeply( [ $f->failure ], [ "tEsT eRrOr 47\n", 'Proc::Background' ], 'The Future contains the expected failure' );

    $mock->unmock('new');
}

note('new dies with a non-true exception');
{
    $mock->redefine( 'new', sub { die Local::FalseThing->new(q{}); } );

    my $f = $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
    isa_ok( $f, 'Future', 'run() returns a (failed) Future' );
    ok( !$f->is_done,  '!is_done' );
    ok( $f->is_ready,  'is_ready' );
    ok( $f->is_failed, 'is_failed' );
    is_deeply( [ $f->failure ], [ 'Failed to run Git with Proc::Background', 'Proc::Background' ], 'The Future contains the expected failure' );

    $mock->unmock('new');
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
