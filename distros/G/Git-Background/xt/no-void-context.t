#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();

use Git::Background 0.003;

my $bindir = File::Spec->catdir( File::Basename::dirname( File::Basename::dirname( Cwd::abs_path __FILE__ ) ), 'corpus', 'bin' );

my $e = exception { Git::Background->run( '--version', { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } ); };

like( $e, qr{\A\QCannot use run() in void context. (The git process would immediately get killed.)\E}, 'run throws an error in void context' );

my $future = Git::Background->run( '--version', { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $future, 'Git::Background::Future', '... works in scalar context' );
$future->await;

my @future = Git::Background->run( '--version', { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $future[0], 'Git::Background::Future', '... and list context' );
is( scalar @future, 1, '... (returns only one value)' );
$future->await;

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
