# ABSTRACT: Wraps git_error_last() into a Perl structure

package Git::Libgit2::Error;
use strict;
use warnings;
use FFI::Platypus 2.00;
use Git::Libgit2::FFI ();

# struct git_error { char *message; int klass; }
# We read the two fields by hand using cast() — keeps us free of
# FFI::Platypus::Record's compile-time layout requirements.
my $_decode_ffi;
sub _decode {
  my ($err_ptr) = @_;
  return ( '<no error>', 0 ) unless $err_ptr;
  $_decode_ffi ||= do {
    my $f = FFI::Platypus->new( api => 2 );
    $f->attach_cast( '_msg_ptr',   'opaque', 'opaque' );  # *(void**)p
    $f->attach_cast( '_msg_to_str','opaque', 'string' );  # null-terminated C string
    $f;
  };
  # The struct starts with `char *message`. Cast the struct-pointer to
  # opaque*: FFI::Platypus reads the pointer at offset 0 for us.
  my $msg_ref  = $_decode_ffi->cast( 'opaque', 'opaque*', $err_ptr );
  my $msg_ptr  = ref $msg_ref ? $$msg_ref : $msg_ref;
  my $msg      = $msg_ptr ? $_decode_ffi->cast( 'opaque', 'string', $msg_ptr ) : '';
  # klass field follows at sizeof(ptr); skipping for MVP — message is all we use.
  return ( $msg, 0 );
}

sub last {
  my ( $class, $rc ) = @_;
  $rc //= -1;
  Git::Libgit2::FFI::ffi();   # ensure FFI is initialised
  my $err_ptr = Git::Libgit2::FFI::git_error_last();
  my ( $msg, $klass ) = _decode($err_ptr);
  return bless {
    code    => $rc,
    klass   => $klass,
    message => $msg || '<no error>',
  }, $class;
}

sub code    { $_[0]->{code} }
sub klass   { $_[0]->{klass} }
sub message { $_[0]->{message} }

sub stringify {
  my $self = shift;
  sprintf 'libgit2 error %d (klass %d): %s',
    $self->{code}, $self->{klass}, $self->{message};
}

use overload
  '""'     => \&stringify,
  fallback => 1;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Libgit2::Error - Wraps git_error_last() into a Perl structure

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $rc = git_repository_open(\my $repo, $path);
  if ($rc < 0) {
    die Git::Libgit2::Error->last($rc);   # stringifies
  }

=head1 DESCRIPTION

Plain object with C<code>, C<klass>, C<message>. Stringifies via overload.
Used by L<Git::Native> to construct typed exceptions.

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
