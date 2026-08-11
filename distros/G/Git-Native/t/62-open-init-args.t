use Test2::V0;
use lib 't/lib';
use TestRepo;
use Path::Tiny;
use Git::Native;

# The Git::Native class methods are the front door of the distribution, and
# their argument guards were the least-tested code in it: open_ext had never
# been called at all, and every `Carp::croak ... unless defined $x` guard on
# open / init / clone was unexecuted, as was the "bare clones not supported"
# refusal that the POD promises. A guard nobody calls is a guard nobody knows
# still works.

# ---- open ----
subtest 'open' => sub {
  my ( $repo, $tmp ) = TestRepo::new_repo();

  my $err = dies { Git::Native->open(undef) };
  like $err, qr/Git::Native->open requires a path/, 'open(undef) croaks';
  ok !ref($err), 'the missing-path failure is a croak, not a libgit2 error';

  my $opened = Git::Native->open("$tmp");
  isa_ok $opened, ['Git::Native::Repository'], 'open on a work tree returns a Repository';
  is $opened->gitdir, $repo->gitdir, 'and it is the same repository';

  # open does NOT search upwards - that is what open_ext is for.
  my $sub = path("$tmp")->child('deep/er');
  $sub->mkpath;
  my $miss = dies { Git::Native->open("$sub") };
  isa_ok $miss, ['Git::Native::Error'], 'open on a subdirectory throws';
  is $miss->is_not_found, 1, 'and it is the not-found kind (open does not search up)';
};

# ---- open_ext ----
subtest 'open_ext' => sub {
  my ( $repo, $tmp ) = TestRepo::new_repo();
  my $sub = path("$tmp")->child('deep/er');
  $sub->mkpath;

  my $found = Git::Native->open_ext("$sub");
  isa_ok $found, ['Git::Native::Repository'],
    'open_ext walks up from a subdirectory and finds the repo';
  is $found->gitdir, $repo->gitdir, 'and it found the right one';

  # flags: GIT_REPOSITORY_OPEN_NO_SEARCH (1) turns off the upward walk, so
  # the same path must now fail.
  my $err = dies { Git::Native->open_ext( "$sub", flags => 1 ) };
  isa_ok $err, ['Git::Native::Error'], 'open_ext with NO_SEARCH throws from a subdirectory';
  is $err->is_not_found, 1, 'and it is the not-found kind';

  # ceiling_dirs stops the upward walk before the repository root.
  my $ceiling = dies {
    Git::Native->open_ext( "$sub", ceiling_dirs => path("$tmp")->child('deep') . '' )
  };
  isa_ok $ceiling, ['Git::Native::Error'], 'a ceiling below the repo stops discovery';
  is $ceiling->is_not_found, 1, 'and it is the not-found kind';
};

# ---- init ----
subtest 'init' => sub {
  my $err = dies { Git::Native->init(undef) };
  like $err, qr/Git::Native->init requires a path/, 'init(undef) croaks';

  # No initial_branch: HEAD is left at libgit2's compiled-in default, which
  # differs between distributions - assert only that it is unborn and a
  # branch, not which one.
  my $tmp_plain = Path::Tiny->tempdir;
  my $plain = Git::Native->init("$tmp_plain");
  is $plain->head_unborn, 1, 'a fresh repo has an unborn HEAD';
  like $plain->reference('HEAD')->symbolic_target, qr{^refs/heads/},
    'HEAD is symbolic into refs/heads/ even without initial_branch';

  # initial_branch as a short name gets the refs/heads/ prefix ...
  my $tmp_short = Path::Tiny->tempdir;
  my $short = Git::Native->init( "$tmp_short", initial_branch => 'trunk' );
  is $short->reference('HEAD')->symbolic_target, 'refs/heads/trunk',
    'a short initial_branch is expanded to a full refname';

  # ... and a name that is already a full refname is passed through unchanged.
  my $tmp_full = Path::Tiny->tempdir;
  my $full = Git::Native->init( "$tmp_full", initial_branch => 'refs/heads/trunk' );
  is $full->reference('HEAD')->symbolic_target, 'refs/heads/trunk',
    'a full refname initial_branch is not double-prefixed';

  # bare => 1
  my $tmp_bare = Path::Tiny->tempdir;
  my $bare = Git::Native->init( "$tmp_bare", bare => 1, initial_branch => 'main' );
  is $bare->is_bare, 1, 'bare => 1 makes a bare repo';
  is $bare->workdir, undef, 'a bare repo has no workdir';
  is $bare->reference('HEAD')->symbolic_target, 'refs/heads/main',
    'initial_branch works on a bare repo too';

  my $tmp_nonbare = Path::Tiny->tempdir;
  my $nonbare = Git::Native->init("$tmp_nonbare");
  is $nonbare->is_bare, 0, 'without bare => 1 the repo has a work tree';
  ok defined $nonbare->workdir, 'and a workdir';
};

# ---- clone argument guards ----
# The guards fire before any network or filesystem work, so this subtest is
# network-free even though clone itself is not.
subtest 'clone argument guards' => sub {
  my $no_url = dies { Git::Native->clone( undef, '/tmp/whatever' ) };
  like $no_url, qr/clone requires url and local_path/, 'clone without a url croaks';

  my $no_path = dies { Git::Native->clone( 'file:///nowhere', undef ) };
  like $no_path, qr/clone requires url and local_path/, 'clone without a local_path croaks';

  # bare clones are deliberately not supported (the `bare` field sits past two
  # embedded structs whose size shifts between libgit2 versions). The refusal
  # must be explicit and must point at the supported workaround.
  my $bare = dies {
    Git::Native->clone( 'file:///nowhere', '/tmp/whatever', bare => 1 )
  };
  like $bare, qr/bare clones not yet supported/, 'clone(bare => 1) is refused';
  like $bare, qr/init\(bare=>1\) \+ remote \+ fetch/,
    'and the refusal names the supported alternative';
};

done_testing;
