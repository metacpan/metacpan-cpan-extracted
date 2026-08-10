use Test2::V0;
use Git::Libgit2 qw(
  init_lib
  GIT_OK GIT_ERROR GIT_ENOTFOUND GIT_EEXISTS GIT_EAUTH GIT_ECERTIFICATE
  GIT_ENONFASTFORWARD GIT_EINVALIDSPEC GIT_TIMEOUT
);
use Git::Libgit2::FFI ();

# git_error_code constants carry their canonical libgit2 values.
is GIT_OK,              0,   'GIT_OK';
is GIT_ERROR,          -1,  'GIT_ERROR';
is GIT_ENOTFOUND,      -3,  'GIT_ENOTFOUND';
is GIT_EEXISTS,        -4,  'GIT_EEXISTS';
is GIT_ENONFASTFORWARD,-11, 'GIT_ENONFASTFORWARD';
is GIT_EINVALIDSPEC,   -12, 'GIT_EINVALIDSPEC';
is GIT_EAUTH,          -16, 'GIT_EAUTH';
is GIT_ECERTIFICATE,   -17, 'GIT_ECERTIFICATE';
is GIT_TIMEOUT,        -37, 'GIT_TIMEOUT';

# Git::Libgit2::Error->last decodes a real error's klass (no longer hardwired
# to 0). Opening a non-existent repo yields GIT_ENOTFOUND with a non-zero
# class (GIT_ERROR_OS).
init_lib();
my $rc = Git::Libgit2::FFI::git_repository_open( \my $repo, '/nonexistent/xyz/.git' );
my $err = Git::Libgit2::Error->last($rc);
is $err->code, GIT_ENOTFOUND, 'open of a missing repo reports GIT_ENOTFOUND';
ok $err->klass != 0, 'klass is decoded to a non-zero category (got ' . $err->klass . ')';
ok length $err->message, 'message is populated';

done_testing;
