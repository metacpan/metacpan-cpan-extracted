# ABSTRACT: A libgit2 commit object

package Git::Native::Commit;
use Moo;
use Git::Libgit2::FFI ();
use Git::Native::Error qw( check_rc );
use Git::Native::Oid ();
use Git::Native::Tree ();

has _handle => ( is => 'ro', required => 1 );
has _owner  => ( is => 'ro', required => 1 );   # Repository

has oid => ( is => 'lazy' );
sub _build_oid {
  Git::Native::Oid->from_ptr(
    Git::Libgit2::FFI::git_object_id( $_[0]->_handle )
  );
}

sub message {
  Git::Libgit2::FFI::git_commit_message( $_[0]->_handle );
}

# First paragraph of the message, whitespace-collapsed (libgit2-side).
sub summary {
  Git::Libgit2::FFI::git_commit_summary( $_[0]->_handle );
}

# Commit time as a Unix epoch (committer's time).
sub time {
  Git::Libgit2::FFI::git_commit_time( $_[0]->_handle );
}

# Timezone offset of the commit time, in minutes east of UTC.
sub time_offset {
  Git::Libgit2::FFI::git_commit_time_offset( $_[0]->_handle );
}

sub tree {
  my $self = shift;
  check_rc Git::Libgit2::FFI::git_commit_tree( \my $t, $self->_handle );
  return Git::Native::Tree->new( _handle => $t, _owner => $self->_owner );
}

sub tree_oid {
  Git::Native::Oid->from_ptr(
    Git::Libgit2::FFI::git_commit_tree_id( $_[0]->_handle )
  );
}

sub parent_count {
  Git::Libgit2::FFI::git_commit_parentcount( $_[0]->_handle );
}

sub parent_oids {
  my $self = shift;
  my @out;
  my $n = $self->parent_count;
  for my $i ( 0 .. $n - 1 ) {
    push @out, Git::Native::Oid->from_ptr(
      Git::Libgit2::FFI::git_commit_parent_id( $self->_handle, $i )
    );
  }
  return \@out;
}

sub DEMOLISH {
  my $self = shift;
  Git::Libgit2::FFI::git_commit_free( $self->{_handle} ) if $self->{_handle};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native::Commit - A libgit2 commit object

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $commit = $repo->commit($oid);
  say $commit->message;
  say $commit->summary;
  say scalar gmtime $commit->time;
  say $commit->tree_oid;

=head1 DESCRIPTION

A libgit2 commit object exposing C<oid>, C<message>, C<summary>,
C<time> (Unix epoch), C<time_offset> (minutes east of UTC), C<tree>,
C<tree_oid>, C<parent_count>, C<parent_oids>.

Obtained from L<Git::Native::Repository/commit> or
L<Git::Native::Repository/object>; created with
L<Git::Native::Repository/commit_create>, which returns the new OID rather
than a Commit. A Commit keeps its repository alive, and so does the
L<Git::Native::Tree> it hands out — the tree outlives the commit it came
from.

=head2 oid

  say $commit->oid;

The commit's own L<Git::Native::Oid>. Computed on first use.

=head2 message

  print $commit->message;

The full commit message, as stored — including the trailing newline and
any body paragraphs.

=head2 summary

  say $commit->summary;   # 'add greeting'

The first paragraph of the message with whitespace collapsed, the same
thing C<git log --oneline> shows. libgit2 does the extraction.

=head2 time

  say scalar gmtime $commit->time;

The committer timestamp as Unix epoch seconds, in UTC. The author time is
not exposed.

=head2 time_offset

  printf "%+03d%02d\n", $commit->time_offset / 60, $commit->time_offset % 60;

The committer's timezone offset in B<minutes> east of UTC (C<120> for
C<+0200>), which is what C<time> was recorded against. Git stores it for
display only; C<time> is already UTC and needs no correction.

=head2 tree

  my $tree = $commit->tree;

The commit's root L<Git::Native::Tree>, looked up in the repository.

=head2 tree_oid

  say $commit->tree_oid;

The root tree's L<Git::Native::Oid> without loading the tree object.

=head2 parent_count

  say $commit->parent_count;   # 0 root, 1 normal, 2+ merge

Number of parents.

=head2 parent_oids

  for my $p ( @{ $commit->parent_oids } ) { ... }

Arrayref of the parents' L<Git::Native::Oid>s in commit order, so
C<< ->[0] >> is the first parent. Empty for a root commit.

=head1 SEE ALSO

L<Git::Native::Repository>, L<Git::Native::Tree>, L<Git::Native::Revwalker>

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
