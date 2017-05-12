package Git::Gitalist::Object::Tag;

use Moose;

extends 'Git::Gitalist::Object';

use Method::Signatures;

has '+type' => ( default => 'tag' );

has '+_gpp_obj' => (
  handles => [qw(
    object
    tag
    tagger
    tagged_time
  )],
);

has commit => (
  isa        => 'Git::Gitalist::Object::Commit',
  is         => 'ro',
  lazy_build => 1,
);

method _build_commit {
  return Git::Gitalist::Object::Commit->new(
    repository => $self->repository,
    sha1       => $self->object,
    type       => 'commit',
  );
}

method tree {
  return [$self->repository->get_object($self->commit->tree_sha1)];
}

1;

__END__

=head1 NAME

Git::Gitalist::Object::Tag - Git::Object::Tag module forGit::Gitalist

=head1 SYNOPSIS

    my $tag = Repository->get_object($tag_sha1);

=head1 DESCRIPTION

Represents a tag object in a git repository.
Subclass of C<Git::Gitalist::Object>.


=head1 ATTRIBUTES

=head2 tag

=head2 tagger

=head2 tagged_time

=head2 object


=head1 METHODS


=head1 AUTHORS

See L<Git::Gitalist> for authors.

=head1 LICENSE

See L<Git::Gitalist> for the license.

=cut
