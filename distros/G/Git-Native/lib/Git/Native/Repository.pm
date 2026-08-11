# ABSTRACT: A libgit2 repository handle

package Git::Native::Repository;
use Moo;
use Carp ();
use Git::Libgit2 qw(
  GIT_EMODIFIED GIT_ENOTFOUND GIT_EUNBORNBRANCH GIT_ITEROVER
  GIT_OBJECT_ANY GIT_OBJECT_BLOB GIT_OBJECT_TREE
  GIT_OBJECT_COMMIT GIT_OBJECT_TAG
  GIT_OID_MINPREFIXLEN
);
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );
use Git::Native::Error qw( check_rc );
use Git::Native::Reference ();
use Git::Native::Blob ();
use Git::Native::Tree ();
use Git::Native::TreeBuilder ();
use Git::Native::Commit ();
use Git::Native::Config ();
use Git::Native::Index ();
use Git::Native::Signature ();
use Git::Native::Oid ();
use Git::Native::Remote ();
use Git::Native::Revwalker ();
use Git::Native::Branch ();
use Git::Native::Tag ();
use FFI::Platypus 2.00 ();

has _handle => ( is => 'ro', required => 1 );

sub workdir { Git::Libgit2::FFI::git_repository_workdir( $_[0]->_handle ) }
sub gitdir  { Git::Libgit2::FFI::git_repository_path(    $_[0]->_handle ) }
sub is_bare { Git::Libgit2::FFI::git_repository_is_bare( $_[0]->_handle ) ? 1 : 0 }

# ---------- references ----------

sub reference {
  my ( $self, $name ) = @_;
  check_rc Git::Libgit2::FFI::git_reference_lookup( \my $ref, $self->_handle, $name );
  return Git::Native::Reference->new( _handle => $ref, _owner => $self );
}

sub reference_create {
  my ( $self, $name, $oid, %opts ) = @_;
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;

  my $ref;
  if ( exists $opts{expected_old} ) {
    my $expected = defined $opts{expected_old}
      ? $opts{expected_old}
      : Git::Native::Oid->from_raw( "\0" x 20 );
    $expected = Git::Native::Oid->from_hex($expected) if !ref $expected;
    # expected_old is the overwrite guard, so force must be true: force false
    # returns GIT_EEXISTS before libgit2 can compare the expected OID.
    check_rc Git::Libgit2::FFI::git_reference_create_matching(
      \$ref, $self->_handle, $name, $oid->ptr,
      1,
      $expected->ptr,
      $opts{message} // '',
    );
  }
  else {
    check_rc Git::Libgit2::FFI::git_reference_create(
      \$ref, $self->_handle, $name, $oid->ptr,
      $opts{force} ? 1 : 0,
      $opts{message} // '',
    );
  }
  return Git::Native::Reference->new( _handle => $ref, _owner => $self );
}

sub reference_set_target {
  my ( $self, $name, $oid, %opts ) = @_;
  Carp::croak 'reference_set_target requires expected_old'
    unless exists $opts{expected_old} && defined $opts{expected_old};
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;
  my $expected = $opts{expected_old};
  $expected = Git::Native::Oid->from_hex($expected) if !ref $expected;

  my $current = $self->reference($name);
  my $actual  = $current->target;
  Carp::croak "reference_set_target requires a direct reference: $name"
    unless $actual;
  if ( $actual->hex ne $expected->hex ) {
    Git::Native::Error->throw(
      code    => GIT_EMODIFIED,
      message => "reference '$name' does not match expected old OID",
    );
  }

  return $current->set_target( $oid, message => $opts{message} // '' );
}

sub reference_delete {
  my ( $self, $name ) = @_;
  check_rc Git::Libgit2::FFI::git_reference_remove( $self->_handle, $name );
  return $self;
}

sub reference_exists {
  my ( $self, $name ) = @_;
  my $rc = Git::Libgit2::FFI::git_reference_lookup( \my $ref, $self->_handle, $name );
  if ( $rc == 0 ) {
    Git::Libgit2::FFI::git_reference_free($ref);
    return 1;
  }
  return 0;
}

# Returns list of full ref names. Optional `glob` filters libgit2-side.
sub reference_names {
  my ( $self, %opts ) = @_;
  my $iter;
  if ( $opts{glob} ) {
    check_rc Git::Libgit2::FFI::git_reference_iterator_glob_new(
      \$iter, $self->_handle, $opts{glob},
    );
  }
  else {
    check_rc Git::Libgit2::FFI::git_reference_iterator_new( \$iter, $self->_handle );
  }
  my @names;
  while (1) {
    my $rc = Git::Libgit2::FFI::git_reference_next_name( \my $name, $iter );
    last if $rc == GIT_ITEROVER;
    check_rc $rc;
    push @names, $name;
  }
  Git::Libgit2::FFI::git_reference_iterator_free($iter);
  return \@names;
}

# Resolved HEAD reference, or undef when HEAD is unborn / missing
# (fresh repo with no commits yet).
sub head {
  my $self = shift;
  my $rc = Git::Libgit2::FFI::git_repository_head( \my $ref, $self->_handle );
  return undef if $rc == GIT_EUNBORNBRANCH || $rc == GIT_ENOTFOUND;
  check_rc $rc;
  return Git::Native::Reference->new( _handle => $ref, _owner => $self );
}

sub head_unborn {
  my $rc = Git::Libgit2::FFI::git_repository_head_unborn( $_[0]->_handle );
  check_rc $rc if $rc < 0;
  return $rc ? 1 : 0;
}

sub head_detached {
  my $rc = Git::Libgit2::FFI::git_repository_head_detached( $_[0]->_handle );
  check_rc $rc if $rc < 0;
  return $rc ? 1 : 0;
}

# Point HEAD at a branch refname (e.g. 'refs/heads/main'). The branch may
# be unborn - this is how you pin 'main' on a freshly init'd repo.
sub set_head {
  my ( $self, $refname ) = @_;
  check_rc Git::Libgit2::FFI::git_repository_set_head( $self->_handle, $refname );
  return $self;
}

sub reference_symbolic_create {
  my ( $self, $name, $target, %opts ) = @_;
  check_rc Git::Libgit2::FFI::git_reference_symbolic_create(
    \my $ref, $self->_handle, $name, $target,
    $opts{force} ? 1 : 0,
    $opts{message} // '',
  );
  return Git::Native::Reference->new( _handle => $ref, _owner => $self );
}

# ---------- blobs / trees / commits ----------

sub blob_create_frombuffer {
  my ( $self, $content ) = @_;
  my $raw = "\0" x 20;
  my ($oid_p)     = scalar_to_buffer($raw);
  my ($content_p) = scalar_to_buffer($content);
  check_rc Git::Libgit2::FFI::git_blob_create_from_buffer(
    $oid_p, $self->_handle, $content_p, length($content),
  );
  return Git::Native::Oid->from_raw($raw);
}

sub blob {
  my ( $self, $oid ) = @_;
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;
  check_rc Git::Libgit2::FFI::git_blob_lookup( \my $b, $self->_handle, $oid->ptr );
  return Git::Native::Blob->new( _handle => $b, _owner => $self );
}

sub tree {
  my ( $self, $oid ) = @_;
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;
  check_rc Git::Libgit2::FFI::git_tree_lookup( \my $t, $self->_handle, $oid->ptr );
  return Git::Native::Tree->new( _handle => $t, _owner => $self );
}

sub tree_builder {
  my $self = shift;
  check_rc Git::Libgit2::FFI::git_treebuilder_new( \my $tb, $self->_handle, undef );
  return Git::Native::TreeBuilder->new( _handle => $tb, _owner => $self );
}

sub commit {
  my ( $self, $oid ) = @_;
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;
  check_rc Git::Libgit2::FFI::git_commit_lookup( \my $c, $self->_handle, $oid->ptr );
  return Git::Native::Commit->new( _handle => $c, _owner => $self );
}

# object($oid): look up an object of unknown kind and return the matching
# typed wrapper (Blob / Tree / Commit / Tag). git_blob_free/git_commit_free/
# git_tree_free/git_tag_free are all thin wrappers that call git_object_free
# (stable across libgit2 1.x), so it's safe to hold the git_object* handle in
# a typed wrapper whose DEMOLISH calls the type-specific free.
my %_OBJECT_WRAPPER = (
  GIT_OBJECT_BLOB()   => 'Git::Native::Blob',
  GIT_OBJECT_TREE()   => 'Git::Native::Tree',
  GIT_OBJECT_COMMIT() => 'Git::Native::Commit',
  GIT_OBJECT_TAG()    => 'Git::Native::Tag',
);

sub object {
  my ( $self, $oid ) = @_;
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;
  check_rc Git::Libgit2::FFI::git_object_lookup(
    \my $obj, $self->_handle, $oid->ptr, GIT_OBJECT_ANY,
  );
  return $self->_wrap_object( $obj, $oid );
}

# object_by_prefix($hex): the `git rev-parse abc1234` lookup - resolve an
# abbreviated OID against this repository's object database.
#
# libgit2 takes the prefix in a full-width git_oid buffer plus a length in hex
# characters (nibbles, NOT bytes), so the prefix is zero-padded out to 40 and
# its original length passed alongside; libgit2 reads only that many nibbles.
#
# The minimum-length check is ours on purpose. libgit2 answers a prefix below
# GIT_OID_MINPREFIXLEN with GIT_EAMBIGUOUS ("ambiguous lookup - OID prefix is
# too short") - the same code a genuinely ambiguous prefix returns, so
# is_ambiguous could not tell "your code is wrong" from "ask the user for more
# characters". Croaking here keeps the two apart, same reasoning as
# commit_create's argument checks.
sub object_by_prefix {
  my ( $self, $prefix ) = @_;
  # An Oid is accepted as well; it stringifies to its full 40-char hex.
  $prefix = "$prefix" if ref $prefix;
  Carp::croak 'object_by_prefix requires a hex OID prefix of at most 40 characters'
    unless defined $prefix && $prefix =~ /\A[0-9a-fA-F]{1,40}\z/;
  Carp::croak sprintf
    'object_by_prefix: prefix %s is shorter than the %d characters libgit2 requires',
    $prefix, GIT_OID_MINPREFIXLEN
    if length($prefix) < GIT_OID_MINPREFIXLEN;

  my $oid = Git::Native::Oid->from_hex(
    $prefix . ( '0' x ( 40 - length $prefix ) ) );
  check_rc Git::Libgit2::FFI::git_object_lookup_prefix(
    \my $obj, $self->_handle, $oid->ptr, length($prefix), GIT_OBJECT_ANY,
  );
  return $self->_wrap_object( $obj, $prefix );
}

# Shared tail of object() and object_by_prefix(): git_object* -> typed wrapper,
# freeing the handle if we have no wrapper for the type ($what is only for the
# message).
sub _wrap_object {
  my ( $self, $obj, $what ) = @_;
  my $type  = Git::Libgit2::FFI::git_object_type($obj);
  my $class = $_OBJECT_WRAPPER{$type};
  unless ($class) {
    Git::Libgit2::FFI::git_object_free($obj);
    Carp::croak "object: unexpected git object type $type for $what";
  }
  return $class->new( _handle => $obj, _owner => $self );
}

# commit_create(%args): tree => Oid|hex, parents => [Oid|hex, ...],
# message => str, update_ref => 'HEAD', author => Signature, committer => Signature
sub commit_create {
  my ( $self, %args ) = @_;

  # Check the required arguments before any FFI call: libgit2 reports a
  # missing message as "invalid argument: 'string'" and a missing tree only
  # surfaces inside Oid->from_hex, neither of which names the caller.
  Carp::croak 'commit_create requires tree'    unless defined $args{tree};
  Carp::croak 'commit_create requires message' unless defined $args{message};
  Carp::croak 'commit_create requires parents to be an arrayref'
    if defined $args{parents} && ref $args{parents} ne 'ARRAY';

  my $tree_oid = $args{tree};
  $tree_oid = Git::Native::Oid->from_hex($tree_oid) if !ref $tree_oid;

  # commit_create takes git_tree*, so we need to look it up.
  check_rc Git::Libgit2::FFI::git_tree_lookup( \my $tree_h, $self->_handle, $tree_oid->ptr );

  my $sig_author    = $args{author}    // $self->signature_default;
  my $sig_committer = $args{committer} // $sig_author;

  # Parents: libgit2 wants an array of git_commit*. We pass undef for 0,
  # otherwise look up each parent into commits and pass an opaque[] array.
  # FFI::Platypus passes Perl arrays of opaque via 'opaque[]'.
  my @parent_oids = @{ $args{parents} // [] };
  my @parent_handles;
  for my $p (@parent_oids) {
    $p = Git::Native::Oid->from_hex($p) if !ref $p;
    check_rc Git::Libgit2::FFI::git_commit_lookup( \my $c, $self->_handle, $p->ptr );
    push @parent_handles, $c;
  }

  my $raw = "\0" x 20;
  my ($oid_p) = scalar_to_buffer($raw);

  # Build a parents-array pointer if non-empty.
  # FFI::Platypus 2: we declared parents as 'opaque' — accepting NULL or a pointer.
  # The non-empty branch packs ALL parent handles into a pointer array, so
  # any parent count works (0 roots, 1 normal, 2+ merge commits — see t/48).
  if ( @parent_handles == 0 ) {
    check_rc Git::Libgit2::FFI::git_commit_create(
      $oid_p, $self->_handle, $args{update_ref},
      $sig_author->_handle, $sig_committer->_handle,
      $args{message_encoding} // 'UTF-8',
      $args{message},
      $tree_h,
      0, undef,
    );
  }
  else {
    # Pack pointer array. Each pointer is a 64-bit value on x86_64.
    my $parents_buf = pack 'J*', @parent_handles;
    my ($parents_p) = scalar_to_buffer($parents_buf);
    check_rc Git::Libgit2::FFI::git_commit_create(
      $oid_p, $self->_handle, $args{update_ref},
      $sig_author->_handle, $sig_committer->_handle,
      $args{message_encoding} // 'UTF-8',
      $args{message},
      $tree_h,
      scalar(@parent_handles), $parents_p,
    );
  }

  Git::Libgit2::FFI::git_commit_free($_) for @parent_handles;
  Git::Libgit2::FFI::git_tree_free($tree_h);

  return Git::Native::Oid->from_raw($raw);
}

# ---------- remotes ----------

sub remote {
  my ( $self, $name ) = @_;
  check_rc Git::Libgit2::FFI::git_remote_lookup( \my $r, $self->_handle, $name );
  return Git::Native::Remote->new( _handle => $r, _owner => $self );
}

sub remote_create {
  my ( $self, $name, $url ) = @_;
  check_rc Git::Libgit2::FFI::git_remote_create( \my $r, $self->_handle, $name, $url );
  return Git::Native::Remote->new( _handle => $r, _owner => $self );
}

sub remote_anonymous {
  my ( $self, $url ) = @_;
  check_rc Git::Libgit2::FFI::git_remote_create_anonymous( \my $r, $self->_handle, $url );
  return Git::Native::Remote->new( _handle => $r, _owner => $self );
}

sub has_remote {
  my ( $self, $name ) = @_;
  my $rc = Git::Libgit2::FFI::git_remote_lookup( \my $r, $self->_handle, $name );
  if ( $rc == 0 ) {
    Git::Libgit2::FFI::git_remote_free($r);
    return 1;
  }
  return 0;
}

# ---------- config ----------

# Live, writable config (use set_string here).
sub config {
  my $self = shift;
  check_rc Git::Libgit2::FFI::git_repository_config( \my $cfg, $self->_handle );
  return Git::Native::Config->new( _handle => $cfg, _owner => $self );
}

# Read-only snapshot - required for reliable git_config_get_string.
sub config_snapshot {
  my $self = shift;
  check_rc Git::Libgit2::FFI::git_repository_config_snapshot( \my $cfg, $self->_handle );
  return Git::Native::Config->new( _handle => $cfg, _owner => $self );
}

# Convenience: read one key off a fresh snapshot. undef when unset.
sub config_string {
  my ( $self, $key ) = @_;
  return $self->config_snapshot->get_string($key);
}

# Convenience: read one key as a git-style boolean off a fresh snapshot.
# undef when unset; Git::Native::Error on a non-boolean value.
sub config_bool {
  my ( $self, $key ) = @_;
  return $self->config_snapshot->get_bool($key);
}

# ---------- revwalk ----------

sub revwalker {
  my $self = shift;
  check_rc Git::Libgit2::FFI::git_revwalk_new( \my $w, $self->_handle );
  return Git::Native::Revwalker->new( _handle => $w, _owner => $self );
}

# ---------- branches ----------

sub branch {
  my ( $self, $name, %opts ) = @_;
  my $type = $opts{type} // Git::Native::Branch::GIT_BRANCH_LOCAL;
  check_rc Git::Libgit2::FFI::git_branch_lookup( \my $ref, $self->_handle, $name, $type );
  return Git::Native::Branch->new( _handle => $ref, _owner => $self, type => $type );
}

sub has_branch {
  my ( $self, $name, %opts ) = @_;
  my $type = $opts{type} // Git::Native::Branch::GIT_BRANCH_LOCAL;
  my $rc = Git::Libgit2::FFI::git_branch_lookup( \my $ref, $self->_handle, $name, $type );
  if ( $rc == 0 ) {
    Git::Libgit2::FFI::git_reference_free($ref);
    return 1;
  }
  return 0;
}

sub branch_create {
  my ( $self, $name, $target, %opts ) = @_;
  my $oid = ref($target) && $target->isa('Git::Native::Oid')
    ? $target : Git::Native::Oid->from_hex($target);
  check_rc Git::Libgit2::FFI::git_commit_lookup( \my $commit_h, $self->_handle, $oid->ptr );
  my $rc = Git::Libgit2::FFI::git_branch_create(
    \my $ref, $self->_handle, $name, $commit_h, $opts{force} ? 1 : 0,
  );
  Git::Libgit2::FFI::git_commit_free($commit_h);
  check_rc $rc;
  return Git::Native::Branch->new(
    _handle => $ref, _owner => $self,
    type    => Git::Native::Branch::GIT_BRANCH_LOCAL,
  );
}

sub branches {
  my ( $self, %opts ) = @_;
  my $type = $opts{type} // Git::Native::Branch::GIT_BRANCH_ALL;
  check_rc Git::Libgit2::FFI::git_branch_iterator_new( \my $iter, $self->_handle, $type );
  my @out;
  while (1) {
    my $rc = Git::Libgit2::FFI::git_branch_next( \my $ref, \my $branch_type, $iter );
    last if $rc == GIT_ITEROVER;
    if ( $rc != 0 ) {
      Git::Libgit2::FFI::git_branch_iterator_free($iter);
      check_rc $rc;
    }
    push @out, Git::Native::Branch->new(
      _handle => $ref, _owner => $self, type => $branch_type,
    );
  }
  Git::Libgit2::FFI::git_branch_iterator_free($iter);
  return \@out;
}

# ---------- tags ----------

sub tag {
  my ( $self, $name ) = @_;
  # Resolve refs/tags/$name -> object id -> git_tag_lookup.
  my $refname = $name =~ m{^refs/tags/} ? $name : "refs/tags/$name";
  check_rc Git::Libgit2::FFI::git_reference_lookup( \my $ref, $self->_handle, $refname );
  my $oidp = Git::Libgit2::FFI::git_reference_target($ref);
  my $oid  = Git::Native::Oid->from_ptr($oidp);
  Git::Libgit2::FFI::git_reference_free($ref);
  my $rc = Git::Libgit2::FFI::git_tag_lookup( \my $tag, $self->_handle, $oid->ptr );
  if ( $rc != 0 ) {
    # Not an annotated tag - lightweight. Return undef; caller should use ->reference.
    return undef;
  }
  return Git::Native::Tag->new( _handle => $tag, _owner => $self );
}

sub tag_create {
  my ( $self, $name, $target, %args ) = @_;
  my $oid = ref($target) && $target->isa('Git::Native::Oid')
    ? $target : Git::Native::Oid->from_hex($target);
  # Look up target object generically (commit / tree / blob).
  check_rc Git::Libgit2::FFI::git_object_lookup(
    \my $obj, $self->_handle, $oid->ptr, GIT_OBJECT_ANY,
  );

  my $raw = "\0" x 20;
  my ($oid_p) = FFI::Platypus::Buffer::scalar_to_buffer($raw);

  if ( defined $args{message} ) {
    my $tagger = $args{tagger} // $self->signature_default;
    my $rc = Git::Libgit2::FFI::git_tag_create(
      $oid_p, $self->_handle, $name, $obj,
      $tagger->_handle, $args{message},
      $args{force} ? 1 : 0,
    );
    Git::Libgit2::FFI::git_object_free($obj);
    check_rc $rc;
  }
  else {
    my $rc = Git::Libgit2::FFI::git_tag_create_lightweight(
      $oid_p, $self->_handle, $name, $obj, $args{force} ? 1 : 0,
    );
    Git::Libgit2::FFI::git_object_free($obj);
    check_rc $rc;
  }
  return Git::Native::Oid->from_raw($raw);
}

sub tag_delete {
  my ( $self, $name ) = @_;
  check_rc Git::Libgit2::FFI::git_tag_delete( $self->_handle, $name );
  return $self;
}

sub tag_names {
  my ( $self, %opts ) = @_;
  # git_strarray on stack: {char **strings; size_t count} = 16 bytes.
  my $buf = "\0" x 16;
  my ($p) = FFI::Platypus::Buffer::scalar_to_buffer($buf);
  if ( $opts{pattern} ) {
    check_rc Git::Libgit2::FFI::git_tag_list_match( $p, $opts{pattern}, $self->_handle );
  }
  else {
    check_rc Git::Libgit2::FFI::git_tag_list( $p, $self->_handle );
  }
  # Unpack strings ptr (at offset 0) and count (at offset 8).
  my ( $strings_ptr, $count ) = unpack 'Q Q', $buf;
  my @names;
  if ( $count > 0 && $strings_ptr ) {
    my $ffi = Git::Libgit2::FFI::ffi();
    for my $i ( 0 .. $count - 1 ) {
      my $sp = $ffi->cast( 'opaque', 'opaque[' . ( $i + 1 ) . ']', $strings_ptr )->[$i];
      my $s  = $ffi->cast( 'opaque', 'string', $sp );
      push @names, $s;
    }
  }
  Git::Libgit2::FFI::git_strarray_free($p);
  return \@names;
}

# ---------- status ----------

# status() returns hashref { path => status_flags, ... }.
# status flags are the GIT_STATUS_* bitfield from libgit2.
sub status {
  my $self = shift;
  my %out;
  my $ffi = Git::Libgit2::FFI::ffi();
  my $cb = $ffi->closure( sub {
    my ( $path, $flags, $payload ) = @_;
    $out{$path} = $flags;
    return 0;
  });
  check_rc Git::Libgit2::FFI::git_status_foreach( $self->_handle, $cb, undef );
  return \%out;
}

sub status_for_path {
  my ( $self, $path ) = @_;
  check_rc Git::Libgit2::FFI::git_status_file( \my $flags, $self->_handle, $path );
  return $flags;
}

# ---------- index ----------

# The index, freshly read from disk.
#
# libgit2 caches the git_index* inside the git_repository: every
# git_repository_index call hands back the SAME object with its refcount
# bumped, so a new Perl wrapper on its own still sees whatever that cached
# object last read - a `git add` by another process would be invisible. The
# git_index_read here is what makes the accessor answer for the current disk
# state; force = 0 leaves it to libgit2's stat check, so repeated calls on an
# unchanged index cost nothing. Deliberately not cached Perl-side either, for
# the same reason.
#
# The wrapper is built before the read so a failing read frees the handle
# through DEMOLISH instead of leaking it.
sub index {
  my $self = shift;
  check_rc Git::Libgit2::FFI::git_repository_index( \my $idx, $self->_handle );
  my $index = Git::Native::Index->new( _handle => $idx, _owner => $self );
  check_rc Git::Libgit2::FFI::git_index_read( $idx, 0 );
  return $index;
}

sub signature_default {
  my $self = shift;
  my $rc = Git::Libgit2::FFI::git_signature_default( \my $sig, $self->_handle );
  # We got an allocated git_signature*; from_handle adopts it and copies
  # name/email/when out of the struct, so the attributes report what the
  # config actually says instead of a placeholder.
  return Git::Native::Signature->from_handle($sig) if $rc == 0;
  # Fallback if no user.name/email configured.
  return Git::Native::Signature->new(
    name  => 'Git::Native',
    email => 'unconfigured@example.invalid',
  );
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_repository_free( $self->{_handle} )
    if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Repository - A libgit2 repository handle

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $repo = Git::Native->open('/path/to/.git');
  my $main = $repo->reference('refs/heads/main');
  say $main->target;

  my $blob_oid = $repo->blob_create_frombuffer("hi\n");
  my $tb       = $repo->tree_builder;
  $tb->insert(name => 'hi.txt', oid => $blob_oid, mode => 0100644);
  my $tree_oid = $tb->write;
  my $commit_oid = $repo->commit_create(
    update_ref => 'HEAD',
    tree       => $tree_oid,
    parents    => [$main->target],
    message    => 'add greeting',
  );

=head1 DESCRIPTION

The main entry point for working with a Git repository through
L<Git::Native>. Wraps C<git_repository*>; freed automatically.

=head2 workdir

  my $dir = $repo->workdir;    # '/path/to/checkout/'

Absolute path of the working directory, with a trailing slash. C<undef> for a
bare repository, so check C<is_bare> before using it as a path.

=head2 gitdir

  my $dir = $repo->gitdir;     # '/path/to/checkout/.git/'

Absolute path of the repository directory — the C<.git> directory, or the
repository itself when bare — with a trailing slash.

=head2 is_bare

Returns 1 for a bare repository, 0 otherwise. A bare repository has no
checkout: C<workdir> is C<undef> and the worktree-only operations C<status> /
C<status_for_path> fail with C<GIT_EBAREREPO>.

=head2 reference

  my $ref = $repo->reference('refs/heads/main');

Look up a reference by its full name. Returns a L<Git::Native::Reference>, or
throws a L<Git::Native::Error> for which C<is_not_found> is true when there is
no such reference. Use C<reference_exists> to test without an exception.

=head2 reference_exists

  if ( $repo->reference_exists('refs/heads/main') ) { ... }

Returns 1 or 0 for the full reference name. Never throws for a missing
reference.

=head2 reference_names

  my $all  = $repo->reference_names;
  my $tags = $repo->reference_names( glob => 'refs/tags/*' );

Arrayref of full reference names. C<glob> filters libgit2-side, which is
cheaper than listing everything and grepping in Perl.

=head2 reference_create

  my $ref = $repo->reference_create(
    'refs/heads/main', $new_oid,
    expected_old => $old_oid,
  );

Create or update a direct reference. C<force> and C<message> retain their
usual meaning for unconditional calls. Supplying C<expected_old> makes the
update compare-and-swap: the write succeeds only while the reference points
to that OID, otherwise it throws a L<Git::Native::Error> for which
C<is_not_matched> is true. An explicit C<expected_old =E<gt> undef> requires
the reference to be absent and creates it atomically.

A correct retry loop has to cover two failure kinds, both normal under
contention and both retryable: C<is_not_matched> (another writer moved the
reference in the meantime) and C<is_locked> (a concurrent writer currently
holds the C<refs/E<lt>nameE<gt>.lock> file). Retrying only on
C<is_not_matched> silently loses updates.

=head2 reference_set_target

  my $ref = $repo->reference_set_target(
    'refs/heads/main', $new_oid,
    expected_old => $old_oid,
  );

Atomically update an existing direct reference by name. C<expected_old> is
required. A stale expected OID throws a L<Git::Native::Error> for which
C<is_not_matched> is true and leaves the reference unchanged.

As with C<reference_create>, a correct retry loop covers C<is_not_matched>
(the reference moved under us) as well as C<is_locked> (a concurrent writer
holds C<refs/E<lt>nameE<gt>.lock>); both are expected under contention and
both are retryable.

libgit2 does not provide a C<git_reference_set_target_matching> function.
This method looks up the reference, checks the caller's expected OID, then
uses C<git_reference_set_target>, which atomically guards its write against
the OID in that looked-up reference.

=head2 reference_symbolic_create

  $repo->reference_symbolic_create('refs/heads/current', 'refs/heads/main');

Create a symbolic reference — one that points at another reference's B<name>
rather than at an OID. C<force> overwrites an existing reference, C<message>
goes into the reflog. Returns the new L<Git::Native::Reference>.

=head2 reference_delete

  $repo->reference_delete('refs/heads/topic');

Delete a reference by full name and return the repository. B<Idempotent>:
deleting a reference that does not exist succeeds, exactly like
C<git update-ref -d>. That is deliberately unlike C<reference> and C<tag>,
which throw C<is_not_found> for something missing — so a successful
C<reference_delete> is no evidence the reference was ever there.

=head2 head

  my $head = $repo->head or say 'no commits yet';

The resolved HEAD reference as a L<Git::Native::Reference>, or C<undef> when
HEAD is unborn (a freshly initialised repository, before its first commit) or
missing altogether. Those two cases do B<not> throw, so no C<eval> is needed;
use C<head_unborn> to tell them apart.

=head2 head_unborn

Returns 1 when HEAD points at a branch that has no commit yet, 0 otherwise.
This is the normal state directly after C<< Git::Native->init >>.

=head2 head_detached

Returns 1 when HEAD points straight at a commit instead of at a branch, 0
otherwise.

=head2 set_head

  $repo->set_head('refs/heads/main');

Point HEAD at C<$refname> and return the repository. The branch may be
unborn — this is how a freshly initialised repository gets its default branch
pinned. A refname outside C<refs/heads/> (a tag, say) leaves HEAD detached at
that reference's target instead. An invalid reference name throws a
L<Git::Native::Error> for which C<is_invalid_spec> is true.

=head2 object

  my $obj = $repo->object($oid);   # Blob / Tree / Commit / Tag

Look up an object of unknown kind and return the wrapper matching its actual
type: L<Git::Native::Blob>, L<Git::Native::Tree>, L<Git::Native::Commit> or
L<Git::Native::Tag>. Croaks for an object type this distribution has no
wrapper for. C<$oid> may be a L<Git::Native::Oid> or a hex string, as
everywhere below.

The OID has to be complete — 40 hex characters. Resolving an abbreviation is a
separate operation, because it can fail in a way an exact lookup cannot: see
C<object_by_prefix>.

=head2 object_by_prefix

  my $obj = $repo->object_by_prefix('c2981a9');   # git rev-parse c2981a9

Resolve an B<abbreviated> OID against this repository's object database and
return the same typed wrapper C<object> would. This is what C<git rev-parse>
does with a short SHA; C<object> deliberately does not accept one, since only
this path can come back ambiguous.

C<$prefix> is 4 to 40 hex characters (a full L<Git::Native::Oid> is accepted
too, and then behaves exactly like C<object>). Three ways it can go wrong:

=over 4

=item *

More than one object matches — a L<Git::Native::Error> with C<is_ambiguous>
true. The fix is more characters, so this is worth catching and reporting
rather than dying on.

=item *

Nothing matches — a L<Git::Native::Error> with C<is_not_found> true, exactly as
for a full OID.

=item *

Fewer than 4 characters, more than 40, or not hex at all — a croak, before
libgit2 is called. libgit2's own answer to a too-short prefix is
C<GIT_EAMBIGUOUS>, indistinguishable from a real ambiguity; a prefix that short
is a bug in the calling code, not a property of the repository, so it is
rejected here instead. Four is libgit2's C<GIT_OID_MINPREFIXLEN>.

=back

L<Git::Native::Oid/from_hex> stays strict about the full 40 characters: an Oid
is a value with no repository behind it, and an abbreviation cannot be expanded
without one.

=head2 blob

  my $blob = $repo->blob($oid);

Look up a blob and return a L<Git::Native::Blob>. Type-asserting: an OID
naming an object of another kind throws a L<Git::Native::Error> ("the
requested type does not match the type in the ODB") rather than quietly
returning something else — use C<object> when the kind is not known up front.

libgit2 reports that mismatch as C<GIT_ENOTFOUND>, so C<is_not_found> is true
on the error even though the object does exist; C<is_not_found> alone cannot
tell "no such object" from "wrong type". The same applies to C<tree> and
C<commit>.

=head2 tree

  my $tree = $repo->tree($oid);

Look up a tree and return a L<Git::Native::Tree>. Type-asserting in the same
way as C<blob>.

=head2 commit

  my $commit = $repo->commit($oid);

Look up a commit and return a L<Git::Native::Commit>. Type-asserting in the
same way as C<blob>.

=head2 blob_create_frombuffer

  my $oid = $repo->blob_create_frombuffer("hello\n");

Write a blob straight from a Perl scalar into the object database and return
its L<Git::Native::Oid>. Index and working directory are untouched.

=head2 tree_builder

  my $tb = $repo->tree_builder;
  $tb->insert( name => 'hi.txt', oid => $blob_oid, mode => 0100644 );
  my $tree_oid = $tb->write;

A fresh, empty L<Git::Native::TreeBuilder> for composing a tree object.

=head2 commit_create

  my $oid = $repo->commit_create(
    update_ref => 'HEAD',
    tree       => $tree_oid,
    parents    => [ $head->target ],
    message    => "add greeting\n",
  );

Write a commit object and return its L<Git::Native::Oid>. C<tree> and
C<message> are required.

C<parents> is an arrayref of OIDs: C<[]> (or omitted) makes a root commit,
one entry the ordinary case, two or more a merge commit. C<update_ref> names
a reference to move to the new commit — usually C<'HEAD'>, which follows the
symbolic HEAD to its branch and creates that branch if it is still unborn.
Omitting C<update_ref> writes the commit without pointing any reference at
it.

C<author> and C<committer> take a L<Git::Native::Signature>; C<author>
defaults to C<signature_default> and C<committer> to C<author>.
C<message_encoding> defaults to C<UTF-8>.

=head2 branch

  my $b = $repo->branch('main');
  my $r = $repo->branch( 'origin/main',
    type => Git::Native::Branch::GIT_BRANCH_REMOTE );

Look up a branch by its B<short> name and return a L<Git::Native::Branch>.
C<type> defaults to C<Git::Native::Branch::GIT_BRANCH_LOCAL>. Throws a
L<Git::Native::Error> for which C<is_not_found> is true when there is no such
branch.

=head2 has_branch

The non-throwing form of C<branch>: returns 1 or 0, and takes the same
C<type> option.

=head2 branch_create

  my $b = $repo->branch_create('topic', $commit_oid);

Create a local branch pointing at C<$target>, which must name a commit.
C<force> moves an existing branch of that name; without it a duplicate throws
C<is_exists>. Returns the new L<Git::Native::Branch>.

=head2 branches

  my $all    = $repo->branches;
  my $locals = $repo->branches( type => Git::Native::Branch::GIT_BRANCH_LOCAL );

Arrayref of L<Git::Native::Branch> objects. C<type> defaults to
C<Git::Native::Branch::GIT_BRANCH_ALL> — local plus remote-tracking.

=head2 tag

  my $tag = $repo->tag('v1.0');

Look up an B<annotated> tag by short or full (C<refs/tags/...>) name and
return a L<Git::Native::Tag>.

Returns C<undef> for a lightweight tag: those are plain references under
C<refs/tags/*> with no tag object behind them, so there is nothing to wrap —
read them through C<reference> instead. A name with no reference at all
throws C<is_not_found>, so C<undef> specifically means "exists, but
lightweight".

=head2 tag_create

  my $oid = $repo->tag_create('v1.0', $commit_oid, message => "release\n");
  my $oid = $repo->tag_create('v1.0-lw', $commit_oid);       # lightweight

Tag any object — commit, tree or blob. With C<message> this creates an
annotated tag and returns the new tag object's OID; without one it creates a
lightweight tag and returns the target's OID. C<tagger> takes a
L<Git::Native::Signature> and defaults to C<signature_default>. C<force>
replaces an existing tag of that name; otherwise a duplicate throws
C<is_exists>.

=head2 tag_delete

  $repo->tag_delete('v1.0');

Delete a tag by short name and return the repository. Unlike
C<reference_delete> this is B<not> idempotent: deleting a tag that does not
exist throws a L<Git::Native::Error> for which C<is_not_found> is true.

=head2 tag_names

  my $names = $repo->tag_names;
  my $v1    = $repo->tag_names( pattern => 'v1.*' );

Arrayref of B<short> tag names (no C<refs/tags/> prefix), annotated and
lightweight alike. C<pattern> is an fnmatch-style glob applied libgit2-side.

=head2 remote

  my $origin = $repo->remote('origin');

Look up a configured remote by name and return a L<Git::Native::Remote>.
Throws a L<Git::Native::Error> for which C<is_not_found> is true when the
remote is not configured.

=head2 has_remote

The non-throwing form of C<remote>: returns 1 or 0.

=head2 remote_create

  my $r = $repo->remote_create('origin', 'https://example.invalid/repo.git');

Create a named remote with the default fetch refspec and persist it to the
repository config. Returns a L<Git::Native::Remote>.

=head2 remote_anonymous

  my $r = $repo->remote_anonymous('file:///srv/git/repo.git');

An in-memory remote for a one-off fetch or ref listing. Nothing is written to
the config, so C<has_remote> stays false afterwards and C<< $r->name >> is
C<undef>.

=head2 config

  $repo->config->set_string('user.name', 'Ada');

The repository's live, writable L<Git::Native::Config>. Writes go here;
B<reads do not> — libgit2 refuses C<get_string> on a live config. Use
C<config_snapshot>, C<config_string> or C<config_bool> to read.

=head2 config_snapshot

  my $snap = $repo->config_snapshot;
  say $snap->get_string('user.email');

A read-only, point-in-time L<Git::Native::Config>. Values written through
C<config> afterwards are not visible in an existing snapshot; take a fresh
one.

=head2 config_string

  my $name = $repo->config_string('user.name');

One string value, read off a freshly taken snapshot. C<undef> when the key is
unset anywhere in the config chain.

=head2 config_bool

  my $bare = $repo->config_bool('core.bare');   # 1 / 0 / undef

One value parsed by git's boolean rules (C<true> / C<yes> / C<on> / non-zero
numbers against C<false> / C<no> / C<off> / C<0>), read off a freshly taken
snapshot. C<undef> when the key is unset; a value that is set but not a
boolean throws a L<Git::Native::Error>.

=head2 revwalker

  my $walk = $repo->revwalker;
  $walk->push_head;
  say $_->hex for @{ $walk->all };

A fresh L<Git::Native::Revwalker> for this repository. It yields nothing
until seeded with one of its C<push_*> methods.

=head2 status

  my $st = $repo->status;
  say "$_ $st->{$_}" for sort keys %$st;

Hashref of C<< path =E<gt> flags >> for every path that is not clean, where
C<flags> is libgit2's C<GIT_STATUS_*> bitmask combining the index-side and
worktree-side bits. Clean paths are absent, so an empty hashref means a clean
tree.

On a bare repository this throws a L<Git::Native::Error> for which
C<is_bare_repo> is true — it does not return an empty result. Code walking a
mixed set of repositories has to handle that explicitly.

=head2 status_for_path

  my $flags = $repo->status_for_path('README.md');

The same C<GIT_STATUS_*> bitmask for a single path, relative to the working
directory. A path git knows nothing about — neither tracked nor present on
disk — throws C<is_not_found>; a bare repository throws C<is_bare_repo>.

=head2 index

  my $index = $repo->index;
  if ( $index->is_tracked_under('tasks') ) { ... }

The repository's index as a L<Git::Native::Index> — the tracked-path list
C<git ls-files> prints, queryable without shelling out.

Every call re-reads the index file from disk, so a fresh
C<< $repo->index >> always reflects what is on disk right now. That is not
free of consequences and is worth knowing in two directions:

An Index object you B<hold on to> does not update itself, which is what
this accessor is for. What it also is not is a snapshot of when you took
it: libgit2 keeps one cached C<git_index*> per repository and every call
here hands back that same object, so the re-read this one does is felt by
Index objects handed out earlier. Neither direction is a guarantee — take
a fresh one from here, or call L<Git::Native::Index/reload>, whenever the
answer has to be current.

And because this re-reads, any in-memory modification of the index would be
discarded by the next call. Nothing in L<Git::Native> can make one today —
L<Git::Native::Index> is read-only — but that is the reason the accessor is
free to re-read rather than a promise it will keep if that changes.

=head2 signature_default

  my $sig = $repo->signature_default;

A L<Git::Native::Signature> built from the repository's effective
C<user.name> / C<user.email> configuration, stamped with the current time.

When neither is configured this falls back to
C<Git::Native E<lt>unconfigured@example.invalidE<gt>> rather than failing, so
C<commit_create> and C<tag_create> still work in an unconfigured environment.
Pass an explicit C<author> / C<tagger> where that placeholder would be wrong.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-git-native/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
