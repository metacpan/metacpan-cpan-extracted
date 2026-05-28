# ABSTRACT: A libgit2 repository handle

package Git::Native::Repository;
use Moo;
use Carp ();
use Git::Libgit2 qw( check_rc GIT_OBJECT_BLOB GIT_OBJECT_TREE GIT_OBJECT_COMMIT );
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );
use Git::Native::Reference ();
use Git::Native::Blob ();
use Git::Native::Tree ();
use Git::Native::TreeBuilder ();
use Git::Native::Commit ();
use Git::Native::Config ();
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
  check_rc Git::Libgit2::FFI::git_reference_create(
    \my $ref, $self->_handle, $name, $oid->ptr,
    $opts{force} ? 1 : 0,
    $opts{message} // '',
  );
  return Git::Native::Reference->new( _handle => $ref, _owner => $self );
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
    last if $rc == -31;  # GIT_ITEROVER
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
  return undef if $rc == -9 || $rc == -3;   # GIT_EUNBORNBRANCH / GIT_ENOTFOUND
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

# commit_create(%args): tree => Oid|hex, parents => [Oid|hex, ...],
# message => str, update_ref => 'HEAD', author => Signature, committer => Signature
sub commit_create {
  my ( $self, %args ) = @_;

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
  # To pass an array we need a temporary buffer of pointers. For MVP, support 0..1 parent.
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
    last if $rc == -31;  # GIT_ITEROVER
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
  # Look up target object generically (commit / tree / blob - GIT_OBJECT_ANY = -2).
  check_rc Git::Libgit2::FFI::git_object_lookup( \my $obj, $self->_handle, $oid->ptr, -2 );

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

sub signature_default {
  my $self = shift;
  my $rc = Git::Libgit2::FFI::git_signature_default( \my $sig, $self->_handle );
  if ( $rc == 0 ) {
    # We got an allocated git_signature*; wrap it without going through
    # Signature::_build_handle.
    my $obj = Git::Native::Signature->new(
      name  => '<from-config>',  # placeholder; we own the C handle
      email => '<from-config>',
    );
    $obj->{_handle} = $sig;
    return $obj;
  }
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

version 0.003

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
