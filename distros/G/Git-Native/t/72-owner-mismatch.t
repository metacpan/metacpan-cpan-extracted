use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Libgit2 qw( GIT_EOWNER GIT_ENOTFOUND );
use Path::Tiny qw( path );

# GIT_EOWNER (-36): Git::Native->open on a repository whose path belongs to
# another uid. libgit2's side of git's CVE-2022-24765 defence, and for CI and
# container users the most common open failure that looks like nothing else.
#
# Reproducing it needs a repository path whose st_uid differs from the
# caller's euid, which looks like it needs root or a second user. It does not:
# libgit2 validates the repository's *working directory*, and core.worktree
# can name any directory - including one of the root-owned system directories
# every machine already has. Nothing below is privileged, nothing is written
# outside the throwaway repository, and the foreign-owned directory is only
# ever stat()ed.
#
# The unprivileged user-namespace route that suggests itself does NOT work,
# and is worth not retrying: an unprivileged namespace may install exactly one
# uid mapping and it has to be the caller's own euid, so the caller's own
# files always appear to belong to the caller inside the namespace. Measured
# for `unshare -U`, `unshare -U -r` and `unshare -U --map-user=N` - all three
# report the same id for `id -u` and for a file of ours. `--map-auto` needs
# the newuidmap helper, which is not part of a base install.

skip_all 'running as root: a root-owned path matches euid 0, so no ownership '
  . 'mismatch is reachable this way'
  if $> == 0;

# The first standard system directory that exists and is not ours.
my @candidates = qw( /usr/share /usr/lib /usr /etc /var / );
my ($foreign) = grep { -d $_ && ( stat $_ )[4] != $> } @candidates;
skip_all "no directory owned by another uid among @candidates - an ownership "
  . 'mismatch cannot be built without one'
  unless defined $foreign;

# Every curated predicate other than is_owner_mismatch. A real GIT_EOWNER has
# to leave all of them at 0, the same sweep t/71 runs against a real
# GIT_EAMBIGUOUS and t/51 runs over the synthetic codes.
my @other_predicates = qw(
  is_not_found is_exists is_auth is_certificate is_conflict
  is_not_fast_forward is_unborn_branch is_invalid_spec is_not_matched
  is_locked is_bare_repo is_ambiguous
);

# The global config libgit2 reads is $TestRepo::HOME/.gitconfig - TestRepo
# points the global search path there. safe.directory lives at that level (or
# the system one); a repository-level entry is deliberately ignored by
# libgit2, since the repository is exactly what is not trusted yet.
my $global_config = path($TestRepo::HOME)->child('.gitconfig');
sub set_safe_directory {
  my (@dirs) = @_;
  return $global_config->remove unless @dirs;
  $global_config->spew( "[safe]\n", map { "\tdirectory = $_\n" } @dirs );
}

# A repository of our own whose working directory is the foreign-owned one.
# The repository itself stays in a tempdir we own, so only the workdir is
# foreign - which is the point: it is enough on its own.
my ( $seed, $tmp ) = TestRepo::new_repo();
$seed->config->set_string( 'core.worktree', $foreign );
my $gitdir = $seed->gitdir;

isnt( ( stat $foreign )[4], $>,
  "$foreign is owned by another uid (the mismatch this file needs)" );
is( ( stat "$gitdir" )[4], $>, 'the git directory itself is still ours' );

# ---------------------------------------------------------------------------
# The predicate, against a real GIT_EOWNER.
#
# A non-matching safe.directory entry is planted first, and that is not
# cosmetic - see the "no entry at all" block below for what libgit2 1.5.1 does
# without one.
# ---------------------------------------------------------------------------
subtest 'a foreign-owned working directory refuses to open' => sub {
  set_safe_directory('/nonexistent/some-other-repo');

  my $err = dies { Git::Native->open("$gitdir") };
  isa_ok $err, ['Git::Native::Error'], 'the open throws a Git::Native::Error';
  ok !$err->isa('Git::Libgit2::Error'),
    'the low-level libgit2 error does not leak';
  is $err->code, GIT_EOWNER, 'the code is GIT_EOWNER';
  is $err->code, -36, 'which is -36, as the libgit2 header says';
  is $err->is_owner_mismatch, 1, 'is_owner_mismatch answers for it';
  like $err->message, qr/not owned by current user/,
    'and the message says what is wrong';

  is $err->$_, 0, "$_ is 0 for a real ownership mismatch" for @other_predicates;
};

# ---------------------------------------------------------------------------
# safe.directory is the escape hatch, and it works.
#
# This is the half that proves the block above measured the ownership check
# and not some unrelated failure to open: the same repository, the same uid,
# one config entry different.
# ---------------------------------------------------------------------------
subtest 'safe.directory makes the same repository open' => sub {
  set_safe_directory($foreign);

  my $repo = Git::Native->open("$gitdir");
  isa_ok $repo, ['Git::Native::Repository'], 'the repository opens';
  like $repo->workdir, qr{^\Q$foreign\E/?$},
    'and it really is the foreign-owned working directory';
};

# ---------------------------------------------------------------------------
# No safe.directory entry anywhere - the state nearly every affected user is
# in, and the one where libgit2 1.5.1 does not report GIT_EOWNER at all.
#
# It asks the config for the safe.directory multivar, gets GIT_ENOTFOUND back
# and returns that instead of its own error, so the open fails with -3 and
# "config value 'safe.directory' was not found" - a not-found naming a key the
# user never set. The assertion is deliberately the disjunction: the code is
# whichever of the two this libgit2 produces, and a third answer is a change
# worth hearing about. What must hold on every version is that the repository
# does not silently open.
# ---------------------------------------------------------------------------
subtest 'without any safe.directory entry it still refuses' => sub {
  set_safe_directory();

  my $err = dies { Git::Native->open("$gitdir") };
  isa_ok $err, ['Git::Native::Error'], 'it still throws a Git::Native::Error';
  ok $err->code == GIT_EOWNER || $err->code == GIT_ENOTFOUND,
    'the code is GIT_EOWNER, or GIT_ENOTFOUND via the libgit2 1.5.1 '
    . 'safe.directory lookup (got ' . $err->code . ')';
  note 'no safe.directory entry -> code ' . $err->code . ': ' . $err->message;

  # The one thing that must never happen: the ownership check being skipped.
  ok !eval { Git::Native->open("$gitdir"); 1 },
    'the repository does not open regardless of which code arrives';
};

# ---------------------------------------------------------------------------
# safe.directory = * - git's blanket escape hatch. Measured as NOT honoured by
# libgit2 1.5.1, which keeps refusing the path. Recorded as a note rather than
# an assertion: a later libgit2 honouring it would be a fix, not a regression,
# and this file should not fail on it.
# ---------------------------------------------------------------------------
{
  set_safe_directory('*');
  my $err = dies { Git::Native->open("$gitdir") };
  note 'safe.directory = * honoured by this libgit2: '
    . ( $err ? 'no, code ' . $err->code : 'yes' );
}

set_safe_directory();

done_testing;
