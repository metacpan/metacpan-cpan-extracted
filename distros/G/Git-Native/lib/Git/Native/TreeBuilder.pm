# ABSTRACT: Build a libgit2 tree object entry by entry

package Git::Native::TreeBuilder;
use Moo;
use Git::Libgit2 qw( check_rc );
use Git::Libgit2::FFI ();
use Git::Native::Oid ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

has _handle => ( is => 'ro', required => 1 );
has _owner  => ( is => 'ro', required => 1 );   # Repository

sub insert {
  my ( $self, %args ) = @_;
  my $oid = $args{oid};
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;
  check_rc Git::Libgit2::FFI::git_treebuilder_insert(
    \my $entry,
    $self->_handle,
    $args{name},
    $oid->ptr,
    $args{mode} // 0100644,
  );
  return $self;
}

sub remove {
  my ( $self, $name ) = @_;
  check_rc Git::Libgit2::FFI::git_treebuilder_remove( $self->_handle, $name );
  return $self;
}

sub write {
  my $self = shift;
  my $raw  = "\0" x 20;
  my ($p)  = scalar_to_buffer($raw);
  check_rc Git::Libgit2::FFI::git_treebuilder_write( $p, $self->_handle );
  return Git::Native::Oid->from_raw($raw);
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_treebuilder_free( $self->{_handle} )
    if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::TreeBuilder - Build a libgit2 tree object entry by entry

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $tb = $repo->tree_builder;
  $tb->insert(name => 'hello.txt', oid => $blob_oid, mode => 0100644);
  my $tree_oid = $tb->write;

=head1 DESCRIPTION

In-memory tree assembler. C<insert>/C<remove> mutate the builder;
C<write> persists it as a tree object and returns its OID.

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
