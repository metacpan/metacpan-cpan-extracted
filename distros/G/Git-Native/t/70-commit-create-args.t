use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;

# commit_create used to hand its arguments straight to libgit2, so a missing
# `message` came back as Git::Native::Error code=-1 "invalid argument:
# 'string'" and a missing `tree` died inside Oid->from_hex - neither names the
# method nor the argument the caller got wrong. The required arguments are
# checked Perl-side now; these tests pin the diagnosis, not just the failure.

my ( $repo, $tmp ) = TestRepo::new_repo();

my $blob = $repo->blob_create_frombuffer("commit-create-args\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'f', oid => $blob, mode => 0100644 );
my $tree = $tb->write;
my $root = $repo->commit_create( tree => $tree, parents => [], message => 'root' );

sub croaks_like {
  my ( $name, $re, $code ) = @_;
  subtest $name => sub {
    my $err = dies { $code->() };
    ok defined $err, 'the call dies';
    # A Git::Native::Error here would mean the argument reached libgit2 and
    # came back as the opaque "invalid argument: 'string'".
    ok !ref $err, 'the failure is a croak, not a Git::Native::Error';
    like "$err", $re, 'the message names commit_create and the argument';
    like "$err", qr{at \S*70-commit-create-args\.t line \d+},
      'croak blames the caller, not Repository.pm';
  };
}

croaks_like 'missing tree', qr/commit_create requires tree/,
  sub { $repo->commit_create( message => 'no tree' ) };

croaks_like 'undef tree', qr/commit_create requires tree/,
  sub { $repo->commit_create( tree => undef, message => 'undef tree' ) };

croaks_like 'missing message', qr/commit_create requires message/,
  sub { $repo->commit_create( tree => $tree, parents => [$root] ) };

croaks_like 'undef message', qr/commit_create requires message/,
  sub { $repo->commit_create( tree => $tree, message => undef ) };

croaks_like 'parents as a plain string',
  qr/commit_create requires parents to be an arrayref/,
  sub { $repo->commit_create( tree => $tree, message => 'm', parents => "$root" ) };

croaks_like 'parents as a hashref',
  qr/commit_create requires parents to be an arrayref/,
  sub { $repo->commit_create( tree => $tree, message => 'm', parents => {} ) };

subtest 'valid calls still work' => sub {
  my $oid = $repo->commit_create(
    tree => $tree, parents => [$root], message => "child\n",
  );
  isa_ok $oid, ['Git::Native::Oid'], 'a complete call returns an Oid';
  is $repo->commit($oid)->parent_count, 1, 'the commit has its parent';

  # `parents` is optional: omitted and explicit undef both mean "root commit",
  # so the arrayref check must not fire on either.
  isa_ok $repo->commit_create( tree => $tree, message => 'omitted parents' ),
    ['Git::Native::Oid'], 'omitted parents writes a root commit';
  isa_ok $repo->commit_create( tree => $tree, message => 'undef parents', parents => undef ),
    ['Git::Native::Oid'], 'undef parents writes a root commit';

  # libgit2 accepts an empty commit message, so the check is on definedness -
  # tightening it to truthiness would break this call.
  isa_ok $repo->commit_create( tree => $tree, message => '' ),
    ['Git::Native::Oid'], 'an empty message is still accepted';
};

done_testing;
