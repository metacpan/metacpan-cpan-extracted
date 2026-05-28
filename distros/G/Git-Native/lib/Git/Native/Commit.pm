# ABSTRACT: A libgit2 commit object

package Git::Native::Commit;
use Moo;
use Git::Libgit2 qw( check_rc );
use Git::Libgit2::FFI ();
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

version 0.003

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
