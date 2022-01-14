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

my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $obj, 'Git::Background', 'new returned object' );

my $f = $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );
delete $f->{_run};
my $e = exception { $f->get };
isa_ok( $e, 'Future::Exception' );
ok( !$f->is_done,  '!is_done' );
ok( $f->is_ready,  'is_ready' );
ok( $f->is_failed, 'is_failed' );

like( $e, qr{\A\Qinternal error: cannot find '_run'\E}, '... await throws an error if _run is missing' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
