#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), qw( .. t lib) );

use Local::Test::TempDir qw(tempdir);

use Git::Background;

use constant CLASS => 'Git::Background';

my $bindir = File::Spec->catdir( File::Basename::dirname( File::Basename::dirname( Cwd::abs_path __FILE__ ) ), 'corpus', 'bin' );

my $obj = CLASS()->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $obj, CLASS(), 'new returned object' );

like( exception { $obj->get },      qr{\QNothing run() yet\E}, 'is_ready throws an exception if nothing is run yet' );
like( exception { $obj->is_ready }, qr{\QNothing run() yet\E}, 'is_ready throws an exception if nothing is run yet' );

note('--version');
is( $obj->run('--version'), $obj, 'run() returns itself' );

$obj->get;
like( exception { $obj->is_ready }, qr{\QNothing run() yet\E}, 'is_ready throws an exception after get() is run' );

#
is( $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } ), $obj, 'run() returns itself' );
my $e = exception { $obj->get };
isa_ok( $e, 'Git::Background::Exception' );
is_deeply( [ $e->stdout ], [ 'stdout 3', 'stdout 3 line 2' ], 'error obj contains correct stdout' );
is_deeply( [ $e->stderr ], [ 'error 3',  'error 3 line 2' ],  'error obj contains correct stderr' );
is( $e->exit_code, 128, 'error obj contains correct exit code' );

#
is( $obj->run( '-x129', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } ), $obj, 'run() returns itself' );
$e = exception { $obj->get };
isa_ok( $e, 'Git::Background::Exception' );
is_deeply( [ $e->stdout ], [ 'stdout 3', 'stdout 3 line 2' ], 'error obj contains correct stdout' );
is_deeply( [ $e->stderr ], [ 'error 3',  'error 3 line 2' ],  'error obj contains correct stderr' );
is( $e->exit_code, 129, 'error obj contains correct exit code' );

#
is( $obj->run( '-x1', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2' ), $obj, 'run() returns itself' );
$e = exception { $obj->get };
isa_ok( $e, 'Git::Background::Exception' );
is_deeply( [ $e->stdout ], [ 'stdout 3', 'stdout 3 line 2' ], 'error obj contains correct stdout' );
is_deeply( [ $e->stderr ], [ 'error 3',  'error 3 line 2' ],  'error obj contains correct stderr' );
is( $e->exit_code, 1, 'error obj contains correct exit code' );

# run twice
is( $obj->run('-ostdout1'), $obj, 'run() returns itself' );
like( exception { $obj->run('-ostdout2') }, qr{\QYou need to get() the result of the last run() first\E}, q{run() croaks if the last run wasn't get()ted} );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
