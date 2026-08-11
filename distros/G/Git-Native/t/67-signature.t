use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Native::Signature;
use Git::Libgit2::FFI ();

# Repository->signature_default used to hand back the literal placeholder
# string '<from-config>' for both name and email: the real values only ever
# lived in the C handle and were never read out. commit_create was unaffected
# (it passes the handle straight to libgit2), so nothing caught it - which is
# exactly why the two public attributes have to be asserted here.
#
# The configured identity is set at REPOSITORY level, not globally: libgit2
# 1.5 ignores GIT_CONFIG_GLOBAL, so a developer's real ~/.gitconfig can leak
# into the test. Repo-local config wins over global, so this stays
# deterministic regardless of what TestRepo's isolation manages to pin.

my ( $repo, $tmp ) = TestRepo::new_repo();

my $NAME  = 'Sig Tester';
my $EMAIL = 'sig-tester@example.invalid';

$repo->config->set_string( 'user.name',  $NAME );
$repo->config->set_string( 'user.email', $EMAIL );

subtest 'signature_default reports the configured identity' => sub {
  my $sig = $repo->signature_default;
  isa_ok $sig, ['Git::Native::Signature'], 'signature_default returns a Signature';

  is $sig->name,  $NAME,  'name is the configured user.name';
  is $sig->email, $EMAIL, 'email is the configured user.email';

  # The regression guard: the old code returned this literal for both fields.
  unlike $sig->name,  qr/from-config/, 'name is not a placeholder';
  unlike $sig->email, qr/from-config/, 'email is not a placeholder';
};

subtest 'the timestamp comes out of the struct too' => sub {
  my $before = time;
  my $sig    = $repo->signature_default;
  my $after  = time;

  like $sig->when, qr/\A[0-9]+\z/, 'when is a plain epoch integer';
  ok $sig->when >= $before && $sig->when <= $after,
    'when is "now" as libgit2 saw it, not a default or a placeholder';
  like $sig->offset, qr/\A-?[0-9]+\z/, 'offset is a signed minute count';
  ok abs( $sig->offset ) <= 14 * 60, 'offset is inside the real UTC range';
};

subtest 'a follow-up config change is picked up' => sub {
  # Proves the values are read per call from the freshly built C signature
  # rather than memoised from whatever the first call happened to see.
  $repo->config->set_string( 'user.name', 'Renamed Tester' );
  is $repo->signature_default->name, 'Renamed Tester',
    'signature_default re-reads the config';
  $repo->config->set_string( 'user.name', $NAME );
};

subtest 'the signature outlives the repository it came from' => sub {
  # Memory ownership: the strings are copied into Perl scalars, so they must
  # stay readable after the git_signature* (and the repo behind it) are gone.
  # If from_handle kept the C pointers instead, this is where it would dangle.
  my ( $short_lived, $short_tmp ) = TestRepo::new_repo();
  $short_lived->config->set_string( 'user.name',  'Doomed Repo' );
  $short_lived->config->set_string( 'user.email', 'doomed@example.invalid' );

  my $sig = $short_lived->signature_default;
  undef $short_lived;    # git_repository_free runs here

  is $sig->name,  'Doomed Repo',            'name survives its repository';
  is $sig->email, 'doomed@example.invalid', 'email survives its repository';

  # Churn libgit2's allocator: a dangling char* would very likely read back
  # as something other than the string we copied.
  Git::Native::Signature->new( name => 'X' x 64, email => 'y' x 64 . '@z.invalid' )
    ->_handle for 1 .. 200;

  is $sig->name,  'Doomed Repo',            'name still intact after allocator churn';
  is $sig->email, 'doomed@example.invalid', 'email still intact after allocator churn';
};

subtest 'the default signature is what commit_create writes' => sub {
  # End-to-end: the handle we adopted is still a valid git_signature*, so a
  # commit made without an explicit author records the configured identity.
  my $blob = $repo->blob_create_frombuffer("hello\n");
  my $tb   = $repo->tree_builder;
  $tb->insert( name => 'README', oid => $blob, mode => 0100644 );
  my $tree = $tb->write;

  my $oid = $repo->commit_create(
    update_ref => 'HEAD',
    tree       => $tree,
    parents    => [],
    message    => "initial\n",
  );

  my $commit = $repo->commit($oid);

  # Read the stored author straight off the commit. git_commit_author hands
  # back a BORROWED pointer owned by the commit - it must not be adopted by
  # from_handle (that would free it), so the fields are peeked here instead.
  my $author = Git::Libgit2::FFI::git_commit_author( $commit->_handle );
  ok $author, 'the commit has an author signature';
  my ( $name_ptr, $email_ptr )
    = unpack 'Q Q', Git::Libgit2::FFI::ffi->cast( 'opaque', 'string(16)', $author );
  my $ffi = Git::Libgit2::FFI::ffi();

  is $ffi->cast( 'opaque', 'string', $name_ptr ), $NAME,
    'the commit author name is the configured one';
  is $ffi->cast( 'opaque', 'string', $email_ptr ), $EMAIL,
    'the commit author email is the configured one';
};

subtest 'from_handle rejects a null pointer' => sub {
  like dies { Git::Native::Signature->from_handle(0) },
    qr/null pointer/, 'from_handle croaks rather than reading address 0';
  like dies { Git::Native::Signature->from_handle(undef) },
    qr/null pointer/, 'undef is refused the same way';
};

done_testing;
