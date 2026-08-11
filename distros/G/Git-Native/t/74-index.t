use Test2::V0;
use lib 't/lib';
use TestRepo;
use Path::Tiny;
use Git::Native;
use Git::Libgit2 qw( GIT_STATUS_CURRENT GIT_STATUS_WT_DELETED );

# Git::Native::Index - karr ticket #24.
#
# The index answers "does git track this path". The working tree cannot answer
# it: a clean tracked file does not show up in ->status at all, ->status_for_path
# refuses a directory outright, and a file deleted without `git rm` is still
# tracked while the working tree says it is gone. The first two subtests are
# that argument, not a demonstration that the methods run.
#
# Two traps the ticket named, both load-bearing below:
#
#   * git_index_find_prefix matches a STRING prefix, not a path - 'tasks' also
#     matches 'tasksfoo.txt'. The fixture tracks BOTH tasks/1.md and
#     tasksfoo.txt on purpose: with only one of the two present, has_prefix and
#     is_tracked_under would agree on every input and the file would measure
#     nothing.
#
#   * libgit2 caches one git_index* inside the git_repository and hands the
#     same object to every git_repository_index call, so a wrapper built over
#     it answers from whatever that object last read. Repository->index calls
#     git_index_read for exactly that reason, and 'a foreign write' below is
#     what goes red if that line is removed.

# The index is the one thing this distribution cannot write: Git::Native::Index
# is read-only and there is no add/write anywhere else. A clone is how the
# suite gets a populated index natively - checkout writes one - so the fixture
# is a source repo pushed into a bare repo, cloned per subtest that mutates.
my $src_dir  = Path::Tiny->tempdir;
my $bare_dir = Path::Tiny->tempdir;

my $src = Git::Native->init( "$src_dir", initial_branch => 'main' );

my $sub_tb = $src->tree_builder;
$sub_tb->insert(
  name => '1.md',
  oid  => $src->blob_create_frombuffer("one\n"),
  mode => 0100644,
);

my $root_tb = $src->tree_builder;
$root_tb->insert( name => 'tasks', oid => $sub_tb->write, mode => 040000 );
$root_tb->insert(
  name => 'tasksfoo.txt',
  oid  => $src->blob_create_frombuffer("foo\n"),
  mode => 0100644,
);
$root_tb->insert(
  name => 'README.md',
  oid  => $src->blob_create_frombuffer("readme\n"),
  mode => 0100644,
);

my $commit = $src->commit_create(
  tree => $root_tb->write, parents => [], message => 'init',
);
$src->reference_create( 'refs/heads/main', $commit, force => 1 );

my $bare = Git::Native->init( "$bare_dir", bare => 1, initial_branch => 'main' );
$src->remote_create( 'origin', "file://$bare_dir" )
  ->push( refspecs => ['+refs/heads/main:refs/heads/main'] );
$bare->set_head('refs/heads/main');

# The three paths every assertion below counts on.
my @TRACKED = ( 'README.md', 'tasks/1.md', 'tasksfoo.txt' );

# A Path::Tiny tempdir is removed when its guard object goes out of scope, and
# the repositories handed out here outlive the subtest that made them.
my @KEEP;

sub fresh_clone {
  my $dir = Path::Tiny->tempdir;
  push @KEEP, $dir;
  return ( Git::Native->clone( "file://$bare_dir", "$dir" ), $dir );
}

# Read-only subtests share one clone; every subtest that touches the working
# tree or the index file takes its own, so subtest order cannot matter.
my ( $repo, $repo_dir ) = fresh_clone();
my $index = $repo->index;

# The staleness subtests need a write to the index file from OUTSIDE libgit2,
# and Git::Native::Index is read-only, so the git CLI is the only way to make
# one. Its config is already isolated - TestRepo points GIT_CONFIG_GLOBAL and
# GIT_CONFIG_SYSTEM at /dev/null for exactly this. Missing git skips those two
# subtests loudly rather than passing quietly.
my $HAVE_GIT = do {
  my $v = `git --version 2>/dev/null`;
  defined $v && $v =~ /^git version/;
};
diag 'git is not on PATH: the two index-staleness subtests will be skipped, '
  . 'so the git_index_read in Repository->index is NOT covered by this run'
  unless $HAVE_GIT;

# ---------------------------------------------------------------------------
# Why this API exists at all.
# ---------------------------------------------------------------------------
subtest 'the working tree cannot answer the tracked-path question' => sub {
  # Nothing has been touched in this clone, so status is empty - and all three
  # paths are still tracked. Anything built on ->status would read that empty
  # hash as "no files here".
  is $repo->status, {}, 'a clean checkout has an empty status hash';
  is $index->entrycount, scalar @TRACKED,
    'while the index holds all three tracked paths';
  is $repo->status_for_path('tasks/1.md'), GIT_STATUS_CURRENT,
    'status_for_path can only say "unchanged" about a tracked file';
  is $index->has_path('tasks/1.md'), 1, 'the index says it is tracked';

  # And status cannot even be pointed at a directory: libgit2 rejects the
  # whole call. There is no working-tree spelling of is_tracked_under('tasks').
  my $err = dies { $repo->status_for_path('tasks') };
  isa_ok $err, ['Git::Native::Error'], 'status_for_path on a directory throws';
  is $err->is_ambiguous, 1, 'with GIT_EAMBIGUOUS - a directory is not a status path';
  is $index->is_tracked_under('tasks'), 1,
    'the same question against the index is answerable, and true';
};

subtest 'tracked but not on disk' => sub {
  # The case status is structurally unable to answer: the file is gone from
  # the working tree but git still tracks it, because nothing ran `git rm`.
  # A caller asking "does this project own tasks/?" must get yes here - it is
  # the state a half-finished delete leaves behind.
  my ( $r, $dir ) = fresh_clone();
  path($dir)->child('tasks/1.md')->remove;

  my $i = $r->index;
  is $i->entrycount, scalar @TRACKED, 'the index is unchanged by an unlink';
  is $i->has_path('tasks/1.md'), 1, 'the deleted file is still tracked';
  is $i->is_tracked_under('tasks'), 1,
    'and the directory still counts as tracked';

  # The working-tree verdict on the same path, for contrast: gone.
  ok( ( $r->status_for_path('tasks/1.md') & GIT_STATUS_WT_DELETED ),
    'status calls the very same path WT_DELETED' );
};

# ---------------------------------------------------------------------------
# The prefix trap - the reason is_tracked_under is not has_prefix.
# ---------------------------------------------------------------------------
subtest 'a string prefix is not a path prefix' => sub {
  # 'task' matches 'tasks/1.md' as a string. No directory named 'task' is
  # tracked, so the path question is false while the string question is true.
  # This pair is the whole point of the method; if both answered the same the
  # wrapper would be a rename of has_prefix.
  is $index->has_prefix('task'), 1,
    "has_prefix('task') is true - it matched 'tasks/1.md' character by character";
  is $index->is_tracked_under('task'), 0,
    "is_tracked_under('task') is false - nothing is tracked at or below 'task'";

  # Same shape one directory over, and this time the string match comes from
  # the file the ticket named: 'tasksfoo' is a prefix of 'tasksfoo.txt'.
  is $index->has_prefix('tasksfoo'), 1, "has_prefix('tasksfoo') is true";
  is $index->is_tracked_under('tasksfoo'), 0,
    "is_tracked_under('tasksfoo') is false - 'tasksfoo' is not a directory";

  # And the case where both are true, so the method above is not simply
  # answering no to everything that is not an exact path.
  is $index->has_prefix('tasks'),        1, "has_prefix('tasks') is true";
  is $index->is_tracked_under('tasks'),  1,
    "is_tracked_under('tasks') is true - tasks/1.md really is below it";
};

subtest 'an exact path answers for itself' => sub {
  is $index->is_tracked_under('tasks/1.md'), 1,
    'a tracked file is tracked under itself';
  is $index->is_tracked_under('tasksfoo.txt'), 1,
    'including the one that only looks like a directory prefix';
  is $index->is_tracked_under('README.md'), 1, 'and a top-level file';

  # There is no index entry for a directory - git tracks files. So the exact
  # question and the "under" question genuinely differ for 'tasks'.
  is $index->has_path('tasks'), 0, 'has_path is false for the directory itself';
  is $index->has_path('tasks/1.md'), 1, 'and true for the file inside it';

  is $index->is_tracked_under('nope.txt'),  0, 'an untracked file is false';
  is $index->is_tracked_under('nope/deep'), 0, 'so is an untracked directory';
};

subtest 'trailing slashes are stripped' => sub {
  is $index->is_tracked_under('tasks/'), $index->is_tracked_under('tasks'),
    "'tasks/' answers exactly as 'tasks'";
  is $index->is_tracked_under('tasks/'),  1, 'and that answer is true';
  is $index->is_tracked_under('tasks//'), 1, 'more than one slash is stripped too';

  # The strip must not make the trap case true: 'task/' has no more tracked
  # content under it than 'task' does.
  is $index->is_tracked_under('task/'), 0, "'task/' stays false";

  # The strip lives in is_tracked_under alone - the raw string methods have no
  # path semantics to strip with, which is why 'tasks//' misses there.
  is $index->has_prefix('tasks//'), 0,
    'has_prefix takes the slashes literally and finds nothing';
};

# ---------------------------------------------------------------------------
# find / find_prefix / entrycount.
# ---------------------------------------------------------------------------
subtest 'find and find_prefix report positions, undef on a miss' => sub {
  is $index->entrycount, 3, 'entrycount is the number of paths committed';

  my $pos = $index->find('tasks/1.md');
  like $pos, qr/\A\d+\z/, 'find returns a plain non-negative number';
  ok $pos < $index->entrycount, 'inside the entry list';

  # libgit2 keeps entries sorted, so the first entry starting with 'task' is
  # 'tasks/1.md' - pinning that find_prefix reports the FIRST match rather
  # than an arbitrary one.
  is $index->find_prefix('task'), $pos,
    'find_prefix lands on the first entry with that prefix';

  # A miss is undef, not a throw: "not tracked" is an answer, not an error.
  is $index->find('nope.txt'), undef, 'find returns undef for an unknown path';
  is $index->find('tasks'), undef,
    'and for a directory, which has no entry of its own';
  is $index->find_prefix('nope'), undef,
    'find_prefix returns undef when nothing starts with the prefix';

  # The booleans are documented as 1 / 0, not merely truthy.
  is $index->has_path('README.md'), 1, 'has_path returns 1 on a hit';
  is $index->has_path('nope.txt'),  0, 'and 0 on a miss';
  is $index->has_prefix('READ'),    1, 'has_prefix returns 1 on a hit';
  is $index->has_prefix('zzz'),     0, 'and 0 on a miss';
};

# ---------------------------------------------------------------------------
# Staleness: the git_index_read in Repository->index.
# ---------------------------------------------------------------------------
subtest 'a foreign write is invisible to a held Index, visible to a fresh one' => sub {
  skip_all 'git is not on PATH - no way to write the index from outside libgit2'
    unless $HAVE_GIT;

  my ( $r, $dir ) = fresh_clone();
  my $held = $r->index;
  is $held->is_tracked_under('later.txt'), 0,
    'control: the new path is not tracked before the write';

  path($dir)->child('later.txt')->spew("later\n");
  is system( 'git', '-C', "$dir", 'add', '--', 'later.txt' ), 0,
    'git add stages it behind libgit2\'s back';

  # ORDER MATTERS. libgit2 caches one git_index* per git_repository and hands
  # it to every git_repository_index call, so $held and the fresh accessor
  # below share the underlying object - once the accessor re-reads, $held
  # reports the new state too. Ask the stale one first or this measures
  # nothing.
  is $held->is_tracked_under('later.txt'), 0,
    'the Index held across the write has not noticed it';

  # This is the assertion that goes red if the git_index_read call is removed
  # from Repository->index: without it the "fresh" accessor hands back the
  # same cached, unrefreshed object and answers 0 - a file git just staged
  # reported as untracked, the failure mode karr #24 named.
  is $r->index->is_tracked_under('later.txt'), 1,
    'a freshly fetched $repo->index sees the staged file';
  is $r->index->entrycount, scalar(@TRACKED) + 1,
    'and counts it';
};

subtest 'reload picks up a foreign write on the object you are holding' => sub {
  skip_all 'git is not on PATH - no way to write the index from outside libgit2'
    unless $HAVE_GIT;

  my ( $r, $dir ) = fresh_clone();
  my $held = $r->index;

  path($dir)->child('reloaded.txt')->spew("reloaded\n");
  is system( 'git', '-C', "$dir", 'add', '--', 'reloaded.txt' ), 0, 'git add stages it';
  is $held->is_tracked_under('reloaded.txt'), 0, 'the held Index is stale';

  is $held->reload, exact_ref($held), 'reload returns the same Index object';
  is $held->is_tracked_under('reloaded.txt'), 1, 'and it now sees the write';
  is $held->entrycount, scalar(@TRACKED) + 1, 'with the entry counted';

  # force => 1 skips libgit2's stat check. Same answer, no crash - the
  # argument is passed through as a flag, not as a path.
  is $held->reload( force => 1 ), exact_ref($held), 'reload(force => 1) works too';
  is $held->is_tracked_under('reloaded.txt'), 1, 'and the answer is unchanged';
};

# ---------------------------------------------------------------------------
# Argument guards. Same contract as t/70 and t/73: a check that never reaches
# libgit2 croaks, so there is no invented ->code, and the message names the
# method and the argument.
# ---------------------------------------------------------------------------
subtest 'every method rejects an undef or empty argument' => sub {
  my %arg_name = (
    find             => 'path',
    find_prefix      => 'prefix',
    has_path         => 'path',
    has_prefix       => 'prefix',
    is_tracked_under => 'path',
  );

  for my $method ( sort keys %arg_name ) {
    my $arg = $arg_name{$method};
    for my $case ( [ 'undef', undef, 'undef' ], [ 'the empty string', '', "''" ] ) {
      my ( $label, $value, $shown ) = @$case;
      subtest "$method with $label" => sub {
        my $err = dies { $index->$method($value) };
        ok defined $err, 'the call dies';
        # A Git::Native::Error would mean a ->code libgit2 never produced:
        # an empty prefix matches entry 0 of any non-empty index, so this
        # never reaches the FFI at all.
        ok !ref $err, 'the failure is a croak, not a Git::Native::Error';
        # Named per method, not delegated - has_path must not report itself
        # as find, or the caller is sent to read the wrong method's docs.
        like "$err", qr/\QGit::Native::Index->$method\E requires a non-empty \Q$arg\E/,
          'the message names the method and the argument';
        like "$err", qr/got \Q$shown\E/, 'and what it was given';
        like "$err", qr{at \S*74-index\.t line \d+},
          'croak blames the caller, not Index.pm';
      };
    }
  }
};

subtest 'is_tracked_under rejects a path that is only slashes' => sub {
  # '/' survives the definedness check and is emptied by the trailing-slash
  # strip. Left alone it would ask has_prefix('/'), i.e. "is anything tracked",
  # which is not the question the caller asked.
  for my $path ( '/', '//', '///' ) {
    my $err = dies { $index->is_tracked_under($path) };
    ok !ref $err, "'$path' croaks rather than throwing a Git::Native::Error";
    like "$err", qr/\QGit::Native::Index->is_tracked_under\E requires a non-empty path/,
      "'$path' is told what is_tracked_under wanted";
    like "$err", qr/got '\Q$path\E'/, "'$path' is echoed back as given, before the strip";
  }

  # The guard is about emptiness, not about slashes: the raw string methods
  # have no path semantics and take '/' as an ordinary prefix that matches
  # nothing here.
  is $index->find_prefix('/'), undef, "find_prefix('/') is a plain miss, not a croak";
  is $index->has_path('/'),    0,     "has_path('/') is a plain miss too";
};

# ---------------------------------------------------------------------------
# Bare repositories.
# ---------------------------------------------------------------------------
subtest 'a bare repository has an index, and it is empty' => sub {
  # Measured, and worth pinning because it is not what the neighbouring
  # working-tree API does: status refuses a bare repo outright, the index
  # accessor does not. A caller that wraps ->index in an is_bare check would
  # be guarding against a failure that never happens.
  my $bare_index;
  ok lives { $bare_index = $bare->index }, '->index on a bare repo does not throw';
  isa_ok $bare_index, ['Git::Native::Index'], 'it returns an Index';
  is $bare_index->entrycount, 0, 'with no entries - a bare repo stages nothing';
  is $bare_index->is_tracked_under('tasks'), 0,
    'so nothing is tracked under any path, even one the bare repo has commits for';
  is $bare_index->find('README.md'), undef, 'and find misses rather than throwing';

  # The control group: same repository, the working-tree API, which does
  # refuse. Without this the subtest above could be passing on a repo that
  # merely is not bare.
  is $bare->is_bare, 1, 'the repository really is bare';
  my $err = dies { $bare->status };
  isa_ok $err, ['Git::Native::Error'], 'status on the same repo throws';
  is $err->is_bare_repo, 1, 'with GIT_EBAREREPO - the refusal ->index does not make';
};

# ---------------------------------------------------------------------------
# Memory ownership.
# ---------------------------------------------------------------------------
subtest 'an Index outlives the Repository variable it came from' => sub {
  # Repository->index passes _owner => $self, so the Index holds a strong ref
  # to the Repository and git_repository_free cannot run while the Index is
  # alive. Drop the only other reference and keep reading: if _owner were ever
  # dropped, the git_index* below would be reading through a freed repository.
  my $orphan;
  {
    my $r = Git::Native->open("$repo_dir");
    $orphan = $r->index;
  }   # $r out of scope - git_repository_free must NOT have run

  is $orphan->entrycount, scalar @TRACKED,
    'the Index still reads after its Repository variable is gone';
  is $orphan->is_tracked_under('tasks'), 1, 'and still answers the path question';
  is $orphan->find('tasks/1.md'), $index->find('tasks/1.md'),
    'with the same positions as an Index whose Repository is still held';
};

done_testing;
