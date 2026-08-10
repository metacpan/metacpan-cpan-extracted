# ABSTRACT: Exception class for Git::Native

package Git::Native::Error;
use Moo;
use Exporter qw( import );
use Git::Libgit2::Error ();
use Git::Libgit2 qw(
  GIT_ENOTFOUND GIT_EEXISTS GIT_EAUTH GIT_ECERTIFICATE
  GIT_ECONFLICT GIT_ENONFASTFORWARD GIT_EUNBORNBRANCH GIT_EINVALIDSPEC
  GIT_EMODIFIED
);
extends 'Throwable::Error';

our @EXPORT_OK = qw( check_rc );

has code    => ( is => 'ro', required => 1 );
has klass   => ( is => 'ro', default  => 0 );

# Predicates over the libgit2 error `code`, for callers that branch on the
# kind of failure (`if ($err->is_not_found) {...}`). Curated to the codes
# that have real consumer use cases; the long tail is reachable via ->code
# compared against the Git::Libgit2 GIT_E* constants.
sub is_not_found        { $_[0]->code == GIT_ENOTFOUND       ? 1 : 0 }
sub is_exists           { $_[0]->code == GIT_EEXISTS         ? 1 : 0 }
sub is_auth             { $_[0]->code == GIT_EAUTH           ? 1 : 0 }
sub is_certificate      { $_[0]->code == GIT_ECERTIFICATE    ? 1 : 0 }
sub is_conflict         { $_[0]->code == GIT_ECONFLICT       ? 1 : 0 }
sub is_not_fast_forward { $_[0]->code == GIT_ENONFASTFORWARD ? 1 : 0 }
sub is_unborn_branch    { $_[0]->code == GIT_EUNBORNBRANCH   ? 1 : 0 }
sub is_invalid_spec     { $_[0]->code == GIT_EINVALIDSPEC    ? 1 : 0 }
sub is_not_matched      { $_[0]->code == GIT_EMODIFIED       ? 1 : 0 }

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my %args = @args == 1 && ref $args[0] ? %{ $args[0] } : @args;
  $args{message} //= '<unknown libgit2 error>';
  return $class->$orig(\%args);
};

# check_rc($rc): pass non-negative rc straight through; on a negative rc,
# pull libgit2's thread-local error (a low-level Git::Libgit2::Error) and
# re-throw it as a Throwable Git::Native::Error so no raw libgit2 error
# object leaks above this layer. Every FFI int-return goes through here, so
# callers in Git::Native import check_rc from THIS module, not Git::Libgit2.
sub check_rc {
  my ($rc) = @_;
  return $rc if !defined $rc || $rc >= 0;
  my $low = Git::Libgit2::Error->last($rc);
  __PACKAGE__->throw(
    code    => $low->code,
    klass   => $low->klass,
    message => $low->message,
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Error - Exception class for Git::Native

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Git::Native::Error;
  Git::Native::Error->throw(
    code    => -3,
    klass   => 11,
    message => 'object not found',
  );

=head1 DESCRIPTION

Throwable exception used by L<Git::Native> when libgit2 reports an error.
Attributes mirror the C C<git_error> struct plus the return code.

=head2 check_rc

  use Git::Native::Error qw( check_rc );
  check_rc Git::Libgit2::FFI::some_call(...);

Pass-through for a non-negative return code; on a negative one it reads
libgit2's thread-local error (a low-level L<Git::Libgit2::Error>) and
re-throws it as a C<Git::Native::Error>. Every wrapper in the distribution
routes its FFI int-returns through this so no raw libgit2 error object
escapes the API.

=head2 is_not_found / is_exists / is_auth / is_certificate / is_conflict / is_not_fast_forward / is_unborn_branch / is_invalid_spec / is_not_matched

  if ( my $err = $@ ) {
    return if $err->is_not_found;   # treat "missing" as empty
    die $err;
  }

Predicates over C<code> for the common failure kinds (C<GIT_ENOTFOUND>,
C<GIT_EEXISTS>, C<GIT_EAUTH>, C<GIT_ECERTIFICATE>, C<GIT_ECONFLICT>,
C<GIT_ENONFASTFORWARD>, C<GIT_EUNBORNBRANCH>, C<GIT_EINVALIDSPEC>,
C<GIT_EMODIFIED>). Each returns 1 or 0. For other codes compare
C<< $err->code >> against the C<GIT_E*> constants exported by
L<Git::Libgit2>.

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
