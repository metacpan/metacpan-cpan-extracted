# ABSTRACT: Exception class for Git::Native

package Git::Native::Error;
use Moo;
use Exporter qw( import );
use Git::Libgit2::Error ();
use Git::Libgit2 qw(
  GIT_ENOTFOUND GIT_EEXISTS GIT_EAUTH GIT_ECERTIFICATE
  GIT_ECONFLICT GIT_ENONFASTFORWARD GIT_EUNBORNBRANCH GIT_EINVALIDSPEC
  GIT_EMODIFIED GIT_ELOCKED GIT_EBAREREPO GIT_EAMBIGUOUS GIT_EOWNER
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
sub is_locked           { $_[0]->code == GIT_ELOCKED         ? 1 : 0 }
sub is_bare_repo        { $_[0]->code == GIT_EBAREREPO       ? 1 : 0 }
sub is_ambiguous        { $_[0]->code == GIT_EAMBIGUOUS      ? 1 : 0 }
sub is_owner_mismatch   { $_[0]->code == GIT_EOWNER          ? 1 : 0 }

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

version 0.005

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

Every failure raised by the distribution arrives as one of these — no
low-level L<Git::Libgit2::Error> escapes the wrapper layer. Being a
L<Throwable::Error>, it carries a stack trace and stringifies to the
message followed by that trace, so a bare C<die $err> stays readable.

  use Try::Tiny;
  try { $repo->reference('refs/heads/nope') }
  catch {
    die $_ unless ref $_ && $_->isa('Git::Native::Error') && $_->is_not_found;
    ...
  };

=head2 code

The libgit2 return code, always negative for a real failure — C<-3> for
C<GIT_ENOTFOUND>, C<-1> for the generic C<GIT_ERROR>. This is the
discriminator to branch on, through the C<is_*> predicates below or
against the C<GIT_E*> constants exported by L<Git::Libgit2>.

=head2 klass

The C<git_error_t> category the failure came from (the C<klass> field of
libgit2's C<git_error>), defaulting to 0. A secondary signal: it says
which subsystem complained, not what went wrong. Branch on C<code>.

=head2 message

The error text libgit2 produced, e.g. C<"cannot set OID on symbolic
reference">. Inherited from L<Throwable::Error>.

=head2 check_rc

  use Git::Native::Error qw( check_rc );
  check_rc Git::Libgit2::FFI::some_call(...);

Pass-through for a non-negative return code; on a negative one it reads
libgit2's thread-local error (a low-level L<Git::Libgit2::Error>) and
re-throws it as a C<Git::Native::Error>. Every wrapper in the distribution
routes its FFI int-returns through this so no raw libgit2 error object
escapes the API.

=head2 is_not_found / is_exists / is_auth / is_certificate / is_conflict / is_not_fast_forward / is_unborn_branch / is_invalid_spec / is_not_matched / is_locked / is_bare_repo / is_ambiguous / is_owner_mismatch

  if ( my $err = $@ ) {
    return if $err->is_not_found;   # treat "missing" as empty
    die $err;
  }

Predicates over C<code> for the common failure kinds (C<GIT_ENOTFOUND>,
C<GIT_EEXISTS>, C<GIT_EAUTH>, C<GIT_ECERTIFICATE>, C<GIT_ECONFLICT>,
C<GIT_ENONFASTFORWARD>, C<GIT_EUNBORNBRANCH>, C<GIT_EINVALIDSPEC>,
C<GIT_EMODIFIED>, C<GIT_ELOCKED>, C<GIT_EBAREREPO>, C<GIT_EAMBIGUOUS>,
C<GIT_EOWNER>). Each returns 1 or 0. For other codes compare
C<< $err->code >> against the C<GIT_E*> constants exported by
L<Git::Libgit2>.

C<is_bare_repo> covers the worktree-only operations: a bare repository has no
checkout, so C<status> and C<status_for_path> fail with C<GIT_EBAREREPO> (-8)
rather than returning an empty result. Code that walks a mixed set of
repositories should treat it as "not applicable here", not as a hard error.

C<is_ambiguous> comes from the abbreviated-OID lookup
L<Git::Native::Repository/object_by_prefix>: the prefix matched more than one
object, so the caller has to ask for more characters. It is B<not> raised for a
prefix that is merely too short — libgit2 answers that with C<GIT_EAMBIGUOUS>
as well, but C<object_by_prefix> croaks on it before the lookup precisely so
this predicate keeps meaning "genuinely ambiguous".

C<is_owner_mismatch> is the container and CI case. libgit2 carries git's
CVE-2022-24765 defence: opening a repository whose path belongs to a different
uid fails with C<GIT_EOWNER> (-36) and the message C<repository path '...' is
not owned by current user>, unless that path is listed in the
C<safe.directory> multivar of the system or global config. An image that bakes
a checkout in as root and then builds it as an unprivileged user hits this on
the first C<< Git::Native->open >>. The path libgit2 stats is the repository's
working directory, not each file under it, so a workdir on foreign-owned
storage is enough on its own.

Two measured quirks of libgit2 1.5.1 come with it, both of which make the
failure harder to recognise than the code suggests. With B<no>
C<safe.directory> entry anywhere in the config — the usual state — the
ownership check never reaches its own error: libgit2 asks the config for the
multivar, gets C<GIT_ENOTFOUND> back and returns I<that>, so the open fails
with code -3 and the message C<config value 'safe.directory' was not found>.
That is the shape most affected users actually see, a not-found naming a key
they never set, and C<is_not_found> is what answers for it. As soon as any
C<safe.directory> entry exists, matching or not, the real C<GIT_EOWNER>
arrives. The second quirk: C<safe.directory = *>, the blanket escape hatch git
honours, is B<not> honoured by libgit2 1.5.1 — the path has to be listed
literally.

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
