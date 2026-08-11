# ABSTRACT: A libgit2 branch (thin wrapper over git_reference)

package Git::Native::Branch;
use Moo;
use Git::Libgit2 qw( GIT_BRANCH_LOCAL GIT_BRANCH_REMOTE GIT_BRANCH_ALL );
use Git::Libgit2::FFI ();
use Git::Native::Error qw( check_rc );
use Git::Native::Oid ();

has _handle => ( is => 'ro', required => 1 );  # git_reference*
has _owner  => ( is => 'ro', required => 1 );
has type    => ( is => 'ro', default  => sub { GIT_BRANCH_LOCAL } );

sub name {
  my $self = shift;
  check_rc Git::Libgit2::FFI::git_branch_name( \my $n, $self->_handle );
  return $n;
}

sub refname { Git::Libgit2::FFI::git_reference_name( $_[0]->_handle ) }

sub target {
  my $self = shift;
  my $oidp = Git::Libgit2::FFI::git_reference_target( $self->_handle );
  return undef unless $oidp;
  return Git::Native::Oid->from_ptr($oidp);
}

sub is_head { Git::Libgit2::FFI::git_branch_is_head( $_[0]->_handle ) ? 1 : 0 }
sub is_local  { $_[0]->type == GIT_BRANCH_LOCAL  ? 1 : 0 }
sub is_remote { $_[0]->type == GIT_BRANCH_REMOTE ? 1 : 0 }

sub delete {
  my $self = shift;
  check_rc Git::Libgit2::FFI::git_branch_delete( $self->_handle );
  return $self;
}

sub rename {
  my ( $self, $new_name, %opts ) = @_;
  check_rc Git::Libgit2::FFI::git_branch_move(
    \my $new_ref, $self->_handle, $new_name, $opts{force} ? 1 : 0,
  );
  return ref($self)->new( _handle => $new_ref, _owner => $self->_owner, type => $self->type );
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_reference_free( $self->{_handle} ) if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Branch - A libgit2 branch (thin wrapper over git_reference)

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $b = $repo->branch('main');
  say $b->name;          # 'main'
  say $b->refname;       # 'refs/heads/main'
  say $b->target->hex;   # commit OID
  $b->rename('trunk');

=head1 DESCRIPTION

Wraps a libgit2 branch (which is really a C<git_reference> under
C<refs/heads/*> or C<refs/remotes/*>). Constructed by
L<Git::Native::Repository/branch> and L<Git::Native::Repository/branches>.
A Branch keeps its repository alive for as long as it is in scope.

The same ref is reachable as a L<Git::Native::Reference> through
L<Git::Native::Repository/reference>; this class adds the branch-specific
calls (C<name>, C<is_head>, C<rename>) on top.

=head2 type

  my $b = $repo->branch('origin/main', type => Git::Native::Branch::GIT_BRANCH_REMOTE);

Which namespace the branch was looked up in — C<GIT_BRANCH_LOCAL> (1, the
default), C<GIT_BRANCH_REMOTE> (2) or C<GIT_BRANCH_ALL> (3). It selects
the lookup and is what C<is_local> / C<is_remote> report back.

=head2 name

  say $b->name;   # 'main', or 'origin/main' for a remote branch

The branch name with its namespace prefix stripped: C<refs/heads/main>
gives C<main>, C<refs/remotes/origin/main> gives C<origin/main> — the
remote name stays part of it.

=head2 refname

  say $b->refname;   # refs/heads/main

The full reference name behind the branch.

=head2 target

  say $b->target;   # commit OID

The L<Git::Native::Oid> the branch points at, or C<undef> in the (unusual)
case of a symbolic branch ref.

=head2 is_head

  say $b->is_head;   # 1 when HEAD points here

1 when the repository's HEAD resolves to this branch, 0 otherwise. Always
0 while HEAD is detached, since a detached HEAD points at no branch.

=head2 is_local / is_remote

  $repo->branch('main')->is_local;   # 1

1 or 0 from the C<type> the branch was looked up with, not from the
refname — the local/remote distinction is decided when
L<Git::Native::Repository/branch> or L<Git::Native::Repository/branches>
selects the namespace to search.

=head2 delete

  $repo->branch('stale')->delete;

Delete the branch reference and return the invocant. Deleting the branch
HEAD points at is rejected by libgit2 with a L<Git::Native::Error>.

=head2 rename

  my $renamed = $b->rename('trunk');
  my $forced  = $b->rename('trunk', force => 1);

Move the branch to a new name and return the renamed branch as a B<new>
object; the invocant still reports the old refname, having been made from
the pre-rename handle. Throws when the target name already exists unless
C<force> is set.

=head1 SEE ALSO

L<Git::Native::Repository>, L<Git::Native::Reference>

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
