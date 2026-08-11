# ABSTRACT: A Git author/committer signature

package Git::Native::Signature;
use Moo;
use Carp ();
use Git::Libgit2::FFI ();
use Git::Native::Error qw( check_rc );

has name  => ( is => 'ro', required => 1 );
has email => ( is => 'ro', required => 1 );
has when  => ( is => 'ro' );                # epoch seconds; default = now
has offset => ( is => 'ro', default => 0 ); # minutes

# git_signature layout on a 64-bit host:
#   typedef struct { char *name; char *email; git_time when; } git_signature;
#   typedef struct { git_time_t time; int offset; char sign; } git_time;
# giving  0 = char *name, 8 = char *email, 16 = int64 time, 24 = int offset.
# Stable since libgit2 1.0; re-verified empirically against 1.5.1.
use constant SIG_HEADER_SIZE => 28;   # through git_time.offset; .sign unused

# Underlying git_signature*; allocated lazily, freed in DESTROY.
has _handle => (
  is      => 'lazy',
  builder => '_build_handle',
  clearer => '_clear_handle',
);

sub _build_handle {
  my $self = shift;
  my $sig;
  if ( defined $self->when ) {
    check_rc Git::Libgit2::FFI::git_signature_new(
      \$sig, $self->name, $self->email, $self->when, $self->offset,
    );
  }
  else {
    check_rc Git::Libgit2::FFI::git_signature_now(
      \$sig, $self->name, $self->email,
    );
  }
  return $sig;
}

# Wrap a git_signature* libgit2 allocated for us (e.g. git_signature_default).
# Takes ownership of the handle - DEMOLISH frees it. name/email are COPIED out
# of the struct into Perl scalars, so they don't dangle once the C handle is
# freed (same contract as Git::Native::Oid::from_ptr).
sub from_handle {
  my ( $class, $ptr ) = @_;
  Carp::croak 'from_handle: null pointer' unless $ptr;
  my $ffi = Git::Libgit2::FFI::ffi();
  my ( $name_ptr, $email_ptr, $when, $offset )
    = unpack 'Q Q q l', $ffi->cast( 'opaque', 'string(' . SIG_HEADER_SIZE . ')', $ptr );
  return $class->new(
    name    => $ffi->cast( 'opaque', 'string', $name_ptr ),
    email   => $ffi->cast( 'opaque', 'string', $email_ptr ),
    when    => $when,
    offset  => $offset,
    _handle => $ptr,
  );
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_signature_free( $self->{_handle} )
    if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Signature - A Git author/committer signature

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $sig = Git::Native::Signature->new(
    name  => 'Test',
    email => 'test@example.invalid',
    when  => time,
    offset => 0,
  );

=head1 DESCRIPTION

A Git signature (name + email + timestamp). Wraps C<git_signature*>;
freed automatically when the object goes out of scope.

Pass one as C<author> or C<committer> to
L<Git::Native::Repository/commit_create>, or let that method fall back to
L<Git::Native::Repository/signature_default>, which reads C<user.name> and
C<user.email> from the repository config.

=head2 name

The human name, e.g. C<'Ada Lovelace'>. Required.

=head2 email

The email address, without angle brackets. Required.

=head2 when

Timestamp in Unix epoch seconds. Leave it unset and the signature is
stamped with the current time when its libgit2 handle is first built.

=head2 offset

Timezone offset in B<minutes> east of UTC (C<120> for C<+0200>), default
C<0>. Recorded for display only — C<when> is an absolute epoch either way.

=head2 from_handle

  my $sig = Git::Native::Signature->from_handle($ptr);

Wraps a C<git_signature*> that libgit2 allocated (as
L<Git::Native::Repository/signature_default> does) and takes ownership of
it. C<name>, C<email>, C<when> and C<offset> are read out of the C struct
and copied into Perl, so they stay valid after the handle is freed.

=head1 SEE ALSO

L<Git::Native::Repository>, L<Git::Native::Commit>

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
