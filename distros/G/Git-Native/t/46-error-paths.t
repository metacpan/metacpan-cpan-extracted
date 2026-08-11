use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Libgit2 qw( GIT_EMODIFIED GIT_ELOCKED GIT_EBAREREPO );
use Git::Native::Error;

# The contract from the docs: every libgit2 failure surfaces as a Throwable
# Git::Native::Error with a negative `code` and a message - no low-level
# Git::Libgit2::Error leaks above this layer. Until now NO test ever caught a
# real libgit2 error to check its type; the whole error path went unverified.

my ( $repo, $tmp ) = TestRepo::new_repo();

# Lookups of things that don't exist all go through check_rc -> throw.
my @cases = (
  [ 'reference (missing ref)' => sub { $repo->reference('refs/heads/nope') } ],
  [ 'blob (missing oid)'      => sub { $repo->blob( '0' x 40 ) } ],
  [ 'commit (missing oid)'    => sub { $repo->commit( '0' x 40 ) } ],
  [ 'tree (missing oid)'      => sub { $repo->tree( '0' x 40 ) } ],
  [ 'object (missing oid)'    => sub { $repo->object( '0' x 40 ) } ],
);

for my $case (@cases) {
  my ( $name, $code ) = @$case;
  my $err = dies { $code->() };
  isa_ok $err, ['Git::Native::Error'],   "$name -> Git::Native::Error";
  isa_ok $err, ['Throwable::Error'],     "$name -> is Throwable";
  ok !( ref $err && $err->isa('Git::Libgit2::Error') ),
    "$name does not leak a raw Git::Libgit2::Error";
  ok( defined $err->code && $err->code < 0, "$name carries a negative code (got @{[ $err->code // 'undef' ]})" );
  ok length( "" . $err->message ), "$name carries a message";
}

# A symbolic ref cannot take a direct target - the failure is the same typed
# error, proving the contract holds on mutators too, not just lookups.
my $blob = $repo->blob_create_frombuffer("x\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'f', oid => $blob, mode => 0100644 );
my $tree = $tb->write;
my $c1   = $repo->commit_create( tree => $tree, parents => [], message => 'one' );
$repo->reference_create( 'refs/heads/main', $c1, force => 1 );

my $head = $repo->reference('HEAD');
ok $head->is_symbolic, 'HEAD is a symbolic ref';
my $sym_err = dies { $head->set_target($c1) };
isa_ok $sym_err, ['Git::Native::Error'],
  'set_target on a symbolic ref throws Git::Native::Error';

# Predicates classify the error kind off the libgit2 code, and klass is now
# a decoded category (no longer hardwired to 0).
my $nf = dies { $repo->reference('refs/heads/nope') };
ok $nf->is_not_found,     'is_not_found true for a missing ref';
ok !$nf->is_auth,         'is_auth false for a not-found error';
ok !$nf->is_certificate,  'is_certificate false for a not-found error';
ok $nf->klass != 0,       'klass is a decoded non-zero category';

my $modified = Git::Native::Error->new(
  code    => GIT_EMODIFIED,
  message => 'stale expected OID',
);
ok $modified->is_not_matched, 'is_not_matched recognizes GIT_EMODIFIED';
ok !$nf->is_not_matched, 'is_not_matched rejects an unrelated error code';

# A concurrent ref writer holding refs/<name>.lock reports GIT_ELOCKED, not
# GIT_EMODIFIED - a CAS retry loop must recognize both.
my $locked = Git::Native::Error->new(
  code    => GIT_ELOCKED,
  message => 'the reference is locked',
);
ok $locked->is_locked, 'is_locked recognizes GIT_ELOCKED';
ok !$locked->is_not_matched, 'is_not_matched rejects GIT_ELOCKED';
ok !$nf->is_locked, 'is_locked rejects an unrelated error code';

# A bare repo has no worktree, so the worktree-only operations refuse to run
# with GIT_EBAREREPO instead of returning an empty result. Without a predicate
# a consumer walking mixed repos has to compare the bare -8.
my $bare = Git::Native::Error->new(
  code    => GIT_EBAREREPO,
  message => 'cannot status. This operation is not allowed against bare repositories.',
);
ok $bare->is_bare_repo, 'is_bare_repo recognizes GIT_EBAREREPO';
ok !$nf->is_bare_repo,  'is_bare_repo rejects an unrelated error code';

# GIT_EBAREREPO must not be swept up by any of the other predicates - each one
# is a distinct branch a caller may take.
for my $other (
  qw( is_not_found is_exists is_auth is_certificate is_conflict
      is_not_fast_forward is_unborn_branch is_invalid_spec is_not_matched
      is_locked )
) {
  ok !$bare->$other, "$other rejects GIT_EBAREREPO";
}

# ...and the same thing off a REAL libgit2 failure, which is the point of this
# file: init a bare repo and ask it for status.
my $bare_repo = Git::Native->init( "$tmp/bare.git", bare => 1 );
ok $bare_repo->is_bare, 'init(bare=>1) gives a bare repository';

my $status_err = dies { $bare_repo->status };
isa_ok $status_err, ['Git::Native::Error'],
  'status on a bare repo throws Git::Native::Error';
is $status_err->code, GIT_EBAREREPO, 'the real failure carries GIT_EBAREREPO';
ok $status_err->is_bare_repo, 'is_bare_repo true for the real status failure';
ok !$status_err->is_not_found, 'the real failure is not misread as not-found';

my $status_path_err = dies { $bare_repo->status_for_path('x') };
isa_ok $status_path_err, ['Git::Native::Error'],
  'status_for_path on a bare repo throws Git::Native::Error';
ok $status_path_err->is_bare_repo,
  'is_bare_repo true for the real status_for_path failure';

# clone(bare=>1) is a deliberate, friendly croak BEFORE libgit2 is touched
# (the offset of the `bare` field isn't stable) - a plain die, not a typed
# libgit2 error. Pin that it stays a clear message.
my $bare_err = dies {
  Git::Native->clone( 'file:///does-not-exist', "$tmp/clone-bare", bare => 1 );
};
like $bare_err, qr/bare/, 'clone(bare=>1) croaks with a bare-specific message';

done_testing;
