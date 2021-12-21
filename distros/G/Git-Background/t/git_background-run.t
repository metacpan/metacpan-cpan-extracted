#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Test::TempDir qw(tempdir);

use Git::Background;

use constant CLASS => 'Git::Background';

my $bindir = File::Spec->catdir( File::Basename::dirname( File::Basename::dirname( Cwd::abs_path __FILE__ ) ), 'corpus', 'bin' );

my $obj = CLASS()->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $obj, CLASS(), 'new returned object' );

note('--version');
is( $obj->run('--version'), $obj, 'run() returns itself' );

ok( exists $obj->{_run},         'contains a _run structure' );
ok( $obj->{_run}{_fatal},        '_run has correct _fatal' );
ok( !defined $obj->{_run}{_dir}, '... _dir' );
is_deeply( $obj->{_run}{_git}, $obj->{_git}, '... git' );
isa_ok( $obj->{_run}{_stderr}, 'File::Temp',       '... stderr' );
isa_ok( $obj->{_run}{_stdout}, 'File::Temp',       '... stdout' );
isa_ok( $obj->{_run}{_proc},   'Proc::Background', '... and _proc' );

my ( $stdout, $stderr, $rc ) = $obj->get;
is_deeply( $stdout, ['git version 2.33.1'], 'get() returns correct stdout' );
is_deeply( $stderr, [],                     '... stderr' );
is( $rc, 0, '... and exit code' );
ok( !exists $obj->{_run}, '_run no longer exists' );

#
is( $obj->run('--version'), $obj, 'run() returns itself' );
($stdout) = $obj->get;
is_deeply( $stdout, ['git version 2.33.1'], 'get() returns correct stdout' );

#
note('stdout and stderr');
is( $obj->run( '-ostdout line 1', '-estderr line 1', '-estderr line 2', '-ostdout line 2' ), $obj, 'run() returns itself' );

( $stdout, $stderr, $rc ) = $obj->get;
is_deeply( $stdout, [ 'stdout line 1', 'stdout line 2' ], 'get() returns correct stdout' );
is_deeply( $stderr, [ 'stderr line 1', 'stderr line 2' ], '... stderr' );
is( $rc, 0, '... and exit code' );

#
note('stdout()');
is( $obj->run( '-ostdout line 1', '-estderr line 1', '-estderr line 2', '-ostdout line 2' ), $obj, 'run() returns itself' );
my @stdout = $obj->stdout;
is_deeply( [@stdout], [ 'stdout line 1', 'stdout line 2' ], 'stdout() returns correct stdout (list)' );

#
note('version()');
is( $obj->version, '2.33.1', 'version() returns version' );

is( $obj->version( { git => [ $^X, File::Spec->catdir( $bindir, 'git-version.pl' ) ] } ), '2.33.2', 'version() returns version' );

#
note('Git::Background->version');
is( Git::Background->version( { git => [ $^X, File::Spec->catdir( $bindir, 'git-version.pl' ) ] } ), '2.33.2', 'version() returns version' );
ok( !defined $obj->version( { git => [ $^X, File::Spec->catdir( $bindir, 'git-noversion.pl' ) ] } ), 'version() returns undef on no version' );

#
note('non fatal');
is( $obj->run( '-x77', '-eerror 1', { fatal => 0 } ), $obj, 'run() returns itself' );

ok( exists $obj->{_run},         'contains a _run structure' );
ok( !$obj->{_run}{_fatal},       '_run has correct _fatal' );
ok( !defined $obj->{_run}{_dir}, '... _dir' );
is_deeply( $obj->{_run}{_git}, $obj->{_git}, '... git' );
isa_ok( $obj->{_run}{_stderr}, 'File::Temp',       '... stderr' );
isa_ok( $obj->{_run}{_stdout}, 'File::Temp',       '... stdout' );
isa_ok( $obj->{_run}{_proc},   'Proc::Background', '... and _proc' );

( $stdout, $stderr, $rc ) = $obj->get;

is_deeply( $stdout, [],          'get() returns correct stdout' );
is_deeply( $stderr, ['error 1'], '... stderr' );
is( $rc, 77, '... exit code' );

# dir
my $dir = tempdir();
$obj = CLASS()->new( $dir, { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $obj, CLASS(), 'new returned object' );

ok( $obj->{_fatal}, 'obj has correct _fatal' );
is( $obj->{_dir}, $dir, 'obj has correct _dir' );
is_deeply( $obj->{_git}, $obj->{_git}, 'obj has correct _git' );

is( $obj->run( { dir => undef } ), $obj, 'run returns itself' );
ok( !defined $obj->{_run}{_dir}, '_dir can be overwritten with undef in run' );
is( $obj->{_dir}, $dir, '... but not in obj' );
$obj->get;

my $dir2 = tempdir();
is( $obj->run( { dir => $dir2 } ), $obj,  'run returns itself' );
is( $obj->{_run}{_dir},            $dir2, 'dir can be overwritten with another dir in run' );
is( $obj->{_dir},                  $dir,  '... but not in obj' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
