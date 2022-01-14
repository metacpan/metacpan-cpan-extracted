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

use Git::Background 0.003;

my $bindir = File::Spec->catdir( File::Basename::dirname( File::Basename::dirname( Cwd::abs_path __FILE__ ) ), 'corpus', 'bin' );

my $obj = Git::Background->new( { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $obj, 'Git::Background', 'new returned object' );

note('--version');
my $f = $obj->run('--version');
isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );
isa_ok( $f, 'Future',                  '... which is a Future' );

ok( exists $f->{_run},         'contains a _run structure' );
ok( $f->{_run}{_fatal},        '_run has correct _fatal' );
ok( !defined $f->{_run}{_dir}, '... _dir' );
isa_ok( $f->{_run}{_stderr}, 'File::Temp',       '... stderr' );
isa_ok( $f->{_run}{_stdout}, 'File::Temp',       '... stdout' );
isa_ok( $f->{_run}{_proc},   'Proc::Background', '... and _proc' );

ok( !$f->{ready}, 'future is not yet ready' );

# await can be called multiple times
is( $f->await, $f, 'await returns itself' );
is( $f->await, $f, '... and can be called multiple times' );
is( $f->await, $f, '... really' );
my ( $stdout, $stderr, $rc ) = $f->get;

ok( $f->{ready},    'future is ready' );
ok( $f->is_ready,   'is_ready' );
ok( $f->is_done,    'is_done' );
ok( !$f->is_failed, '!is_failed' );
is_deeply( $stdout, ['git version 2.33.1'], 'get() returns correct stdout' );
is_deeply( $stderr, [],                     '... stderr' );
is( $rc, 0, '... and exit code' );
ok( !exists $f->{_run}, '_run no longer exists' );

#
note('stdout and stderr');
$f = $obj->run( '-ostdout line 1', '-estderr line 1', '-estderr line 2', '-ostdout line 2' );
isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );

( $stdout, $stderr, $rc ) = $f->get;

is_deeply( $stdout, [ 'stdout line 1', 'stdout line 2' ], 'get() returns correct stdout' );
is_deeply( $stderr, [ 'stderr line 1', 'stderr line 2' ], '... stderr' );
is( $rc, 0, '... and exit code' );

#
note('stdout()');
$f = $obj->run( '-ostdout line 1', '-estderr line 1', '-estderr line 2', '-ostdout line 2' );
isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );
my @stdout = $f->stdout;
is_deeply( [@stdout], [ 'stdout line 1', 'stdout line 2' ], 'stdout() returns correct stdout' );
my @stderr = $f->stderr;
is_deeply( [@stderr], [ 'stderr line 1', 'stderr line 2' ], 'stderr() returns correct stderr' );
my $exit_code = $f->exit_code;
is( $exit_code, 0, 'exit_code() returns correct exit code' );

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
$f = $obj->run( '-x77', '-eerror 1', { fatal => 0 } );
isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );

ok( exists $f->{_run},   'contains a _run structure' );
ok( !$f->{_run}{_fatal}, '_run has correct _fatal' );
isa_ok( $f->{_run}{_stderr}, 'File::Temp',       '... stderr' );
isa_ok( $f->{_run}{_stdout}, 'File::Temp',       '... stdout' );
isa_ok( $f->{_run}{_proc},   'Proc::Background', '... and _proc' );

( $stdout, $stderr, $rc ) = $f->get;

is_deeply( $stdout, [],          'get() returns correct stdout' );
is_deeply( $stderr, ['error 1'], '... stderr' );
is( $rc, 77, '... exit code' );

# dir
my $dir = tempdir();
$obj = Git::Background->new( $dir, { git => [ $^X, File::Spec->catdir( $bindir, 'my-git.pl' ) ] } );
isa_ok( $obj, 'Git::Background', 'new returned object' );

ok( $obj->{_fatal}, 'obj has correct _fatal' );
is( $obj->{_dir}, $dir, 'obj has correct _dir' );
is_deeply( $obj->{_git}, $obj->{_git}, 'obj has correct _git' );

# Same tests as in xt/git_background-run_error.t but with ->failure instead
# of ->get which doesn't throw an error

#
note('fatal - 128');
$f = $obj->run( '-x128', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );
my ( $message, $category );
( $message, $category, $stdout, $stderr, $rc ) = $f->failure;
ok( !$f->is_done,  '!is_done' );
ok( $f->is_ready,  'is_ready' );
ok( $f->is_failed, 'is_failed' );
is( $message,  "error 3\nerror 3 line 2", 'error contains correct message' );
is( $category, 'git',                     'error contains correct category' );
is_deeply( $stdout, [ 'stdout 3', 'stdout 3 line 2' ], 'error contains correct stdout' );
is_deeply( $stderr, [ 'error 3',  'error 3 line 2' ],  'error contains correct stderr' );
is( $rc, 128, 'error contains correct exit code' );

#
note('usage - 129');
$f = $obj->run( '-x129', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2', { fatal => 0 } );
isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );

( $message, $category, $stdout, $stderr, $rc ) = $f->failure;
ok( !$f->is_done,  '!is_done' );
ok( $f->is_ready,  'is_ready' );
ok( $f->is_failed, 'is_failed' );
is( $message,  "error 3\nerror 3 line 2", 'error contains correct message' );
is( $category, 'git',                     'error contains correct category' );
is_deeply( $stdout, [ 'stdout 3', 'stdout 3 line 2' ], 'error contains correct stdout' );
is_deeply( $stderr, [ 'error 3',  'error 3 line 2' ],  'error contains correct stderr' );
is( $rc, 129, 'error contains correct exit code' );

#
note('usage - 1');
$f = $obj->run( '-x1', '-ostdout 3', '-ostdout 3 line 2', '-eerror 3', '-eerror 3 line 2' );
isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );

( $message, $category, $stdout, $stderr, $rc ) = $f->failure;
ok( !$f->is_done,  '!is_done' );
ok( $f->is_ready,  'is_ready' );
ok( $f->is_failed, 'is_failed' );
is( $message,  "error 3\nerror 3 line 2", 'error contains correct message' );
is( $category, 'git',                     'error contains correct category' );
is_deeply( $stdout, [ 'stdout 3', 'stdout 3 line 2' ], 'error contains correct stdout' );
is_deeply( $stderr, [ 'error 3',  'error 3 line 2' ],  'error contains correct stderr' );
is( $rc, 1, 'error contains correct exit code' );

#
note('usage - 7 / no stderr');
$f = $obj->run( '-x7', '-ostdout 3', '-ostdout 3 line 2' );
isa_ok( $f, 'Git::Background::Future', 'run() returns a Git::Background::Future' );

( $message, $category, $stdout, $stderr, $rc ) = $f->failure;
ok( !$f->is_done,  '!is_done' );
ok( $f->is_ready,  'is_ready' );
ok( $f->is_failed, 'is_failed' );
is( $message,  'git exited with fatal exit code 7 but had no output to stderr', 'error contains correct message' );
is( $category, 'git',                                                           'error contains correct category' );
is_deeply( $stdout, [ 'stdout 3', 'stdout 3 line 2' ], 'error contains correct stdout' );
is_deeply( $stderr, [],                                'error contains no stderr' );
is( $rc, 7, 'error contains correct exit code' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
