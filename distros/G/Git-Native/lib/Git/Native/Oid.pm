# ABSTRACT: A libgit2 OID (20-byte SHA-1)

package Git::Native::Oid;
use Moo;
use Carp ();
use Git::Libgit2 qw( oid_from_hex oid_to_hex );
use FFI::Platypus::Buffer qw( scalar_to_buffer );

# Holds the raw 20-byte SHA. All other forms (hex, short, pointer) are
# derived. The scalar lives as long as the Oid object - that's the
# anchor libgit2 dereferences via the pointer we hand it.
has raw => (
  is       => 'ro',
  required => 1,
);

sub from_hex {
  my ( $class, $hex ) = @_;
  return $class->new( raw => oid_from_hex($hex) );
}

sub from_raw {
  my ( $class, $raw ) = @_;
  Carp::croak "raw OID must be 20 bytes" unless length($raw) == 20;
  return $class->new( raw => $raw );
}

# Construct from a pointer libgit2 returned (e.g. git_reference_target).
# We copy the 20 bytes out so the resulting Oid owns its memory and
# doesn't dangle when the source handle is freed.
sub from_ptr {
  my ( $class, $ptr ) = @_;
  Carp::croak "from_ptr: null pointer" unless $ptr;
  require FFI::Platypus;
  my $ffi = FFI::Platypus->new( api => 2 );
  my $copy = $ffi->cast( 'opaque', 'string(20)', $ptr );
  return $class->new( raw => $copy );
}

sub hex {
  my $self = shift;
  my ($ptr) = scalar_to_buffer( $self->{raw} );
  return oid_to_hex($ptr);
}

sub short {
  my ( $self, $n ) = @_;
  $n //= 7;
  return substr( $self->hex, 0, $n );
}

sub ptr {
  my $self = shift;
  my ($p) = scalar_to_buffer( $self->{raw} );
  return $p;
}

use overload
  '""'     => sub { $_[0]->hex },
  'eq'     => sub { $_[0]->raw eq (ref $_[1] ? $_[1]->raw : $_[1]) },
  fallback => 1;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Oid - A libgit2 OID (20-byte SHA-1)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $oid = Git::Native::Oid->from_hex('abcd...');
  say $oid;          # full hex
  say $oid->short;   # 7 chars
  $oid->ptr;         # C pointer for libgit2

=head1 DESCRIPTION

A SHA-1 OID. Holds the raw 20 bytes; everything else is derived.
The raw scalar is the anchor for any pointer libgit2 reads it through -
keep the Oid alive as long as the pointer is in use.

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
