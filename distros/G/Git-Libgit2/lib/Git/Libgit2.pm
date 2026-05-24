# ABSTRACT: Low-level FFI bindings to libgit2

package Git::Libgit2;
our $VERSION = '0.001';
use strict;
use warnings;
use Carp ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );
use Git::Libgit2::FFI ();
use Git::Libgit2::Error ();
use Exporter 'import';

our @EXPORT_OK = qw(
  init_lib
  shutdown_lib
  version
  check_rc
  oid_from_hex
  oid_to_hex

  GIT_OBJECT_ANY
  GIT_OBJECT_INVALID
  GIT_OBJECT_COMMIT
  GIT_OBJECT_TREE
  GIT_OBJECT_BLOB
  GIT_OBJECT_TAG

  GIT_REPOSITORY_INIT_BARE
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use constant {
  GIT_OBJECT_ANY        => -2,
  GIT_OBJECT_INVALID    => -1,
  GIT_OBJECT_COMMIT     =>  1,
  GIT_OBJECT_TREE       =>  2,
  GIT_OBJECT_BLOB       =>  3,
  GIT_OBJECT_TAG        =>  4,

  GIT_REPOSITORY_INIT_BARE => 1 << 0,

  GIT_OID_RAWSZ   => 20,
  GIT_OID_HEXSZ   => 40,
};

my $initialised = 0;

sub init_lib {
  Git::Libgit2::FFI::ffi();
  my $rc = Git::Libgit2::FFI::git_libgit2_init();
  Carp::croak "git_libgit2_init failed (rc=$rc)" if $rc < 1;
  $initialised = $rc;
  return $rc;
}

sub shutdown_lib {
  return 0 unless $initialised;
  my $rc = Git::Libgit2::FFI::git_libgit2_shutdown();
  $initialised = $rc;
  return $rc;
}

sub version {
  Git::Libgit2::FFI::ffi();
  my ( $maj, $min, $rev );
  Git::Libgit2::FFI::git_libgit2_version( \$maj, \$min, \$rev );
  return wantarray ? ( $maj, $min, $rev ) : "$maj.$min.$rev";
}

sub check_rc {
  my ($rc) = @_;
  return $rc if $rc >= 0;
  die Git::Libgit2::Error->last($rc);
}

# oid_from_hex returns a Perl scalar holding the raw 20 bytes.
# Callers must keep the scalar alive for as long as the OID pointer
# is needed by libgit2 — the C side just gets a pointer into the PV.
sub oid_from_hex {
  my ($hex) = @_;
  Carp::croak "oid_from_hex: expected 40-char hex, got '$hex'"
    unless defined $hex && length($hex) == GIT_OID_HEXSZ && $hex =~ /\A[0-9a-fA-F]{40}\z/;
  my $raw = "\0" x GIT_OID_RAWSZ;
  my ($ptr) = scalar_to_buffer($raw);
  check_rc Git::Libgit2::FFI::git_oid_fromstr( $ptr, $hex );
  return $raw;
}

sub oid_to_hex {
  my ($oid_ptr) = @_;
  my $buf = "\0" x ( GIT_OID_HEXSZ + 1 );
  my ($bufp) = scalar_to_buffer($buf);
  Git::Libgit2::FFI::git_oid_tostr( $bufp, GIT_OID_HEXSZ + 1, $oid_ptr );
  $buf =~ s/\0.*//s;
  return $buf;
}

# Get a raw pointer to a Perl scalar's bytes (for passing as 'opaque').
sub _scalar_ptr {
  my ($p) = scalar_to_buffer($_[0]);
  return $p;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Libgit2 - Low-level FFI bindings to libgit2

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Git::Libgit2 qw( init_lib version check_rc );

  init_lib();
  printf "libgit2 %s\n", version();

  # Direct FFI calls live in Git::Libgit2::FFI
  use Git::Libgit2::FFI;
  my $rc = Git::Libgit2::FFI::git_repository_open(\my $repo, '/path/to/.git');
  check_rc $rc;

=head1 DESCRIPTION

Low-level L<FFI::Platypus> bindings to the C<libgit2> C library, via
L<Alien::Libgit2>.

This module is intentionally close to the C surface. Use L<Git::Native>
for an idiomatic Moo wrapper with RAII handle management.

=head1 EXPORTS

C<init_lib>, C<shutdown_lib>, C<version>, C<check_rc>, C<oid_from_hex>,
C<oid_to_hex>, plus object-type and repository-init constants.

=head1 SEE ALSO

L<Alien::Libgit2>, L<Git::Native>, L<FFI::Platypus>, L<libgit2|https://libgit2.org/>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-git-libgit2/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
