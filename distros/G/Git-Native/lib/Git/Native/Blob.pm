# ABSTRACT: A libgit2 blob object

package Git::Native::Blob;
use Moo;
use Git::Libgit2::FFI ();
use Git::Native::Oid ();

has _handle => ( is => 'ro', required => 1 );
has _owner  => ( is => 'ro', required => 1 );   # Repository - keeps repo alive

has oid => ( is => 'lazy' );
sub _build_oid {
  my $self = shift;
  Git::Native::Oid->from_ptr(
    Git::Libgit2::FFI::git_object_id( $self->_handle )
  );
}

sub size {
  my $self = shift;
  return Git::Libgit2::FFI::git_blob_rawsize( $self->_handle );
}

sub content {
  my $self = shift;
  my $ptr  = Git::Libgit2::FFI::git_blob_rawcontent( $self->_handle );
  my $size = $self->size;
  return '' unless $ptr && $size > 0;
  return Git::Libgit2::FFI::ffi()->cast( 'opaque', "string($size)", $ptr );
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_blob_free( $self->{_handle} ) if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Blob - A libgit2 blob object

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $blob = $repo->blob($oid);
  say $blob->size;
  say $blob->content;

=head1 DESCRIPTION

A libgit2 blob, exposing C<oid>, C<size>, C<content>. Freed when the
object goes out of scope. Obtained from
L<Git::Native::Repository/blob> or L<Git::Native::Repository/object>; the
blob keeps its repository alive for as long as it is itself in scope.

Blobs are created from a Perl scalar with
L<Git::Native::Repository/blob_create_frombuffer>, which returns the OID
rather than a Blob.

=head2 oid

  say $blob->oid;   # full hex

The blob's L<Git::Native::Oid>. Computed on first use from the object
handle.

=head2 size

  say $blob->size;   # 6

Size of the blob content in bytes.

=head2 content

  my $bytes = $blob->content;

The raw blob content as a byte string, copied out of libgit2's buffer, so
it stays valid after the Blob goes away. Binary-safe: NUL bytes and
non-UTF-8 data survive unchanged, and nothing is decoded — a text file
comes back as bytes, not characters. An empty blob yields the empty
string.

=head1 SEE ALSO

L<Git::Native::Repository>, L<Git::Native::Tree>, L<Git::Native::Oid>

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
