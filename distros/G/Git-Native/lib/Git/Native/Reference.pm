# ABSTRACT: A Git reference (branch, tag, HEAD)

package Git::Native::Reference;
use Moo;
use Git::Libgit2 qw( check_rc );
use Git::Libgit2::FFI ();
use Git::Native::Oid ();

has _handle => ( is => 'ro', required => 1 );
has _owner  => ( is => 'ro', required => 1 );   # Repository

sub name {
  Git::Libgit2::FFI::git_reference_name( $_[0]->_handle );
}

sub target {
  my $self = shift;
  my $p    = Git::Libgit2::FFI::git_reference_target( $self->_handle );
  return undef unless $p;
  return Git::Native::Oid->from_ptr($p);
}

sub is_symbolic {
  Git::Libgit2::FFI::git_reference_type( $_[0]->_handle ) == 2 ? 1 : 0;
}

# Target refname of a symbolic ref (e.g. HEAD -> 'refs/heads/main');
# undef for a direct ref.
sub symbolic_target {
  Git::Libgit2::FFI::git_reference_symbolic_target( $_[0]->_handle );
}

# Human-readable short name: 'refs/heads/main' -> 'main'.
sub shorthand {
  Git::Libgit2::FFI::git_reference_shorthand( $_[0]->_handle );
}

sub is_branch {
  Git::Libgit2::FFI::git_reference_is_branch( $_[0]->_handle ) ? 1 : 0;
}

sub is_remote {
  Git::Libgit2::FFI::git_reference_is_remote( $_[0]->_handle ) ? 1 : 0;
}

sub is_tag {
  Git::Libgit2::FFI::git_reference_is_tag( $_[0]->_handle ) ? 1 : 0;
}

# Follow symbolic refs until a direct one is reached. Returns a fresh
# Reference; the original handle stays valid.
sub resolve {
  my $self = shift;
  check_rc Git::Libgit2::FFI::git_reference_resolve( \my $ref, $self->_handle );
  return Git::Native::Reference->new( _handle => $ref, _owner => $self->_owner );
}

# Point a direct ref at a new OID. Returns the new Reference; fails on a
# symbolic ref (use symbolic_set_target there).
sub set_target {
  my ( $self, $oid, %opts ) = @_;
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;
  check_rc Git::Libgit2::FFI::git_reference_set_target(
    \my $ref, $self->_handle, $oid->ptr, $opts{message} // '',
  );
  return Git::Native::Reference->new( _handle => $ref, _owner => $self->_owner );
}

# Repoint a symbolic ref at a new target refname. Returns the new Reference.
sub symbolic_set_target {
  my ( $self, $target, %opts ) = @_;
  check_rc Git::Libgit2::FFI::git_reference_symbolic_set_target(
    \my $ref, $self->_handle, $target, $opts{message} // '',
  );
  return Git::Native::Reference->new( _handle => $ref, _owner => $self->_owner );
}

sub delete {
  my $self = shift;
  check_rc Git::Libgit2::FFI::git_reference_delete( $self->_handle );
  return $self;
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_reference_free( $self->{_handle} )
    if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Reference - A Git reference (branch, tag, HEAD)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $ref = $repo->reference('refs/heads/main');
  say $ref->name;       # refs/heads/main
  say $ref->shorthand;  # main
  say $ref->target;     # OID
  $ref->delete;

  my $head = $repo->reference('HEAD');
  say $head->symbolic_target;   # refs/heads/main
  say $head->resolve->target;   # OID HEAD points at

=head1 DESCRIPTION

A Git reference. Direct refs carry an C<oid> C<target>; symbolic refs
carry a C<symbolic_target> (a refname) and C<resolve> to a direct ref.

Read accessors: C<name>, C<shorthand>, C<target>, C<symbolic_target>,
C<is_symbolic>, C<is_branch>, C<is_remote>, C<is_tag>.

Mutators return a fresh Reference: C<set_target> (direct refs),
C<symbolic_set_target> (symbolic refs), plus C<delete>.

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
