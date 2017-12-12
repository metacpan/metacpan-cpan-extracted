package Git::Database::Role::RefReader;
$Git::Database::Role::RefReader::VERSION = '0.010';
use Moo::Role;

requires
  'refs',
  ;

# basic implementations
sub ref_names {
    my ( $self, $type ) = @_;
    return $type
      ? sort grep m{^refs/\Q$type\E/}, keys %{ $self->refs }
      : sort keys %{ $self->refs };
}

sub ref_digest { $_[0]->refs->{ $_[1] } }

1;

__END__

=pod

=head1 NAME

Git::Database::Role::RefReader - Abstract role for Git backends that read references

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    package MyGitBackend;

    use Moo;
    use namespace::clean;

    with
      'Git::Database::Role::Backend',
      'Git::Database::Role::RefReader';

    # implement the required methods
    sub refs { ... }

=head1 DESCRIPTION

A L<backend|Git::Database::Role::Backend> doing the additional
Git::Database::Role::RefReader role is capable of reading references
from a Git repository and return information about them.

=head1 REQUIRED METHODS

=head2 refs

     my $refs = $backend->refs;

Return a hash reference mapping all the (fully qualified) refnames in
the repository to the corresponding digests (including C<HEAD>).

=head1 METHODS

=head2 ref_names

    my @refs    = $backend->ref_names;
    my @heads   = $backend->ref_names('heads');
    my @remotes = $backend->ref_names('remotes');

Return the list of refnames in the repository.

The optional argument is used to limit the list of returned names to
those having the part after C<refs/> in their name equal to it (up to
the next C</>).

For example, given the following refs:

    HEAD
    refs/heads/master
    refs/remotes/origin/HEAD
    refs/remotes/origin/master
    refs/tags/world

C<ref_names('heads')> will return C<refs/heads/master>,
C<ref_names('head')> will return nothing,
C<ref_names('remotes/origin')> will return C<refs/remotes/origin/HEAD>
and C<refs/remotes/origin/master>.

=head2 ref_digest

    $backend->ref_digest('refs/heads/master');    # some SHA-1

    $backend->ref_digest('master');               # undef

Return the digest of the given reference, or C<undef>.

Note that a fully qualified refname is required. This method does not
perform any disambiguation.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
