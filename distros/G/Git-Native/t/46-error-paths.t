use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Libgit2 qw( GIT_EMODIFIED );
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

# clone(bare=>1) is a deliberate, friendly croak BEFORE libgit2 is touched
# (the offset of the `bare` field isn't stable) - a plain die, not a typed
# libgit2 error. Pin that it stays a clear message.
my $bare_err = dies {
  Git::Native->clone( 'file:///does-not-exist', "$tmp/clone-bare", bare => 1 );
};
like $bare_err, qr/bare/, 'clone(bare=>1) croaks with a bare-specific message';

done_testing;
