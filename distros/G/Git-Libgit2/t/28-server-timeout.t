#!/usr/bin/env perl
use Test2::V0;
use Path::Tiny;
use POSIX ();
use Time::HiRes ();
use IO::Socket::INET;
use Git::Libgit2 qw(
  init_lib shutdown_lib check_rc version
  GIT_OPT_SET_SERVER_CONNECT_TIMEOUT
  GIT_OPT_SET_SERVER_TIMEOUT
  GIT_DIRECTION_FETCH
);
use Git::Libgit2::FFI ();

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

skip_all 'needs fork to bound a call that may never return'
  if $^O eq 'MSWin32';

my ( $maj, $min ) = version();
skip_all "libgit2 $maj.$min has no server timeout options (need 1.8)"
  if $maj < 1 || ( $maj == 1 && $min < 8 );

init_lib();

# git_libgit2_opts_int exists because git_libgit2_opts is variadic and the
# (int, string) binding cannot carry an int value. A wrong option number or a
# wrong vararg shape does not come back as an error code -- libgit2 va_arg's
# whatever is on the stack -- so a test that only checks the return code
# proves nothing. This one makes the option do its job: a peer that completes
# the TCP handshake and then says nothing has to end the read.

my $TIMEOUT_MS = 1_500;
my $DEADLINE   = 20;      # seconds the child gets before it is declared hung

# The silent peer. Listening but never accepting is enough: the kernel
# completes the handshake from the backlog, so the client connects and then
# waits for a ref advertisement that never comes.
my $server = IO::Socket::INET->new(
  LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 50, ReuseAddr => 1,
) or skip_all "cannot listen on 127.0.0.1: $!";
my $port = $server->sockport;

is Git::Libgit2::FFI::git_libgit2_opts_int(
  GIT_OPT_SET_SERVER_CONNECT_TIMEOUT, $TIMEOUT_MS ), 0,
  'git_libgit2_opts_int(SET_SERVER_CONNECT_TIMEOUT, ms) returns 0';

is Git::Libgit2::FFI::git_libgit2_opts_int(
  GIT_OPT_SET_SERVER_TIMEOUT, $TIMEOUT_MS ), 0,
  'git_libgit2_opts_int(SET_SERVER_TIMEOUT, ms) returns 0';

my $tmp = Path::Tiny->tempdir;
my $repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$repo, "$tmp/local", 0 );

# git:// -- libgit2's own socket transport, always compiled in, no ssh keys or
# HTTP server needed.
my $remote;
check_rc Git::Libgit2::FFI::git_remote_create_anonymous(
  \$remote, $repo, "git://127.0.0.1:$port/silent.git" );

# In a child, because a connect that ignores the timeout never returns and no
# Perl-level alarm can break into a blocking C call.
my $started = Time::HiRes::time();
my $pid     = fork;
die "fork: $!" unless defined $pid;
unless ($pid) {
  my $rc = Git::Libgit2::FFI::git_remote_connect(
    $remote, GIT_DIRECTION_FETCH, undef, undef, undef );
  POSIX::_exit( $rc < 0 ? 0 : 1 );   # 0 = connect refused to hang
}

my ( $reaped, $status );
while ( ( Time::HiRes::time() - $started ) < $DEADLINE ) {
  $reaped = waitpid $pid, POSIX::WNOHANG();
  if ( $reaped == $pid ) { $status = $?; last }
  Time::HiRes::sleep(0.05);
}
my $elapsed = Time::HiRes::time() - $started;

unless ( defined $status ) {
  kill 'KILL', $pid;
  waitpid $pid, 0;
}

ok defined $status,
  "the connect ended on its own within ${DEADLINE}s (timeout took effect)";

SKIP: {
  skip 'connect never returned', 2 unless defined $status;
  is $status >> 8, 0,
    'git_remote_connect failed instead of blocking on the silent peer';
  ok $elapsed >= $TIMEOUT_MS / 1000 * 0.5,
    sprintf( 'and it waited for the timeout first (%.2fs), '
      . 'so it was the timeout that ended it, not an instant error', $elapsed );
}

# Back to libgit2's default (no limit) -- this is process-global state and the
# harness may run more tests in this process.
Git::Libgit2::FFI::git_libgit2_opts_int( GIT_OPT_SET_SERVER_CONNECT_TIMEOUT, 0 );
Git::Libgit2::FFI::git_libgit2_opts_int( GIT_OPT_SET_SERVER_TIMEOUT,         0 );

Git::Libgit2::FFI::git_remote_free($remote);
Git::Libgit2::FFI::git_repository_free($repo);
$server->close;

shutdown_lib();
done_testing;
