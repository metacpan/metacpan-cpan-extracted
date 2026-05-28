# ABSTRACT: Walk commits in topological / time order

package Git::Native::Revwalker;
use Moo;
use Carp ();
use Git::Libgit2 qw( check_rc );
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );
use Git::Native::Oid ();

use constant {
  GIT_SORT_NONE        => 0,
  GIT_SORT_TOPOLOGICAL => 1,
  GIT_SORT_TIME        => 2,
  GIT_SORT_REVERSE     => 4,
  GIT_ITEROVER         => -31,
};

has _handle => ( is => 'ro', required => 1 );
has _owner  => ( is => 'ro', required => 1 );

sub push_oid {
  my ( $self, $oid ) = @_;
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;
  check_rc Git::Libgit2::FFI::git_revwalk_push( $self->_handle, $oid->ptr );
  return $self;
}

sub push_head { check_rc Git::Libgit2::FFI::git_revwalk_push_head( $_[0]->_handle ); $_[0] }
sub push_ref  { check_rc Git::Libgit2::FFI::git_revwalk_push_ref(  $_[0]->_handle, $_[1] ); $_[0] }
sub push_glob { check_rc Git::Libgit2::FFI::git_revwalk_push_glob( $_[0]->_handle, $_[1] ); $_[0] }
sub push_range { check_rc Git::Libgit2::FFI::git_revwalk_push_range( $_[0]->_handle, $_[1] ); $_[0] }

sub hide_oid {
  my ( $self, $oid ) = @_;
  $oid = Git::Native::Oid->from_hex($oid) if !ref $oid;
  check_rc Git::Libgit2::FFI::git_revwalk_hide( $self->_handle, $oid->ptr );
  return $self;
}

sub hide_head { check_rc Git::Libgit2::FFI::git_revwalk_hide_head( $_[0]->_handle ); $_[0] }
sub hide_ref  { check_rc Git::Libgit2::FFI::git_revwalk_hide_ref(  $_[0]->_handle, $_[1] ); $_[0] }
sub hide_glob { check_rc Git::Libgit2::FFI::git_revwalk_hide_glob( $_[0]->_handle, $_[1] ); $_[0] }

sub sorting {
  my ( $self, $mode ) = @_;
  check_rc Git::Libgit2::FFI::git_revwalk_sorting( $self->_handle, $mode );
  return $self;
}

sub reset { check_rc Git::Libgit2::FFI::git_revwalk_reset( $_[0]->_handle ); $_[0] }
sub simplify_first_parent {
  check_rc Git::Libgit2::FFI::git_revwalk_simplify_first_parent( $_[0]->_handle );
  $_[0];
}

sub next {
  my $self = shift;
  my $raw = "\0" x 20;
  my ($p) = scalar_to_buffer($raw);
  my $rc  = Git::Libgit2::FFI::git_revwalk_next( $p, $self->_handle );
  return undef if $rc == GIT_ITEROVER;
  check_rc $rc;
  return Git::Native::Oid->from_raw($raw);
}

sub all {
  my $self = shift;
  my @out;
  while ( defined( my $o = $self->next ) ) { push @out, $o }
  return \@out;
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_revwalk_free( $self->{_handle} ) if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Revwalker - Walk commits in topological / time order

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $walker = $repo->revwalker;
  $walker->push_head;
  $walker->sorting( Git::Native::Revwalker::GIT_SORT_TIME );
  while ( my $oid = $walker->next ) {
    say $oid->hex;
  }

=head1 DESCRIPTION

Wraps libgit2's C<git_revwalk*>. Push starting points (commits, refs,
globs), optionally hide commits to exclude, then iterate with C<next>.

=head2 push_oid($oid)

Mark a commit as a starting point. C<$oid> may be a hex string or a
L<Git::Native::Oid>.

=head2 push_head / push_ref($refname) / push_glob($pattern) / push_range("A..B")

Convenience pushers.

=head2 hide_oid / hide_head / hide_ref / hide_glob

Exclude commits and their ancestors from the walk.

=head2 sorting($mode)

Bitfield of C<GIT_SORT_NONE>, C<GIT_SORT_TOPOLOGICAL>, C<GIT_SORT_TIME>,
C<GIT_SORT_REVERSE>.

=head2 next

Returns the next L<Git::Native::Oid>, or C<undef> when exhausted.

=head2 all

Drains the walker into an arrayref of L<Git::Native::Oid>.

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
