package Git::Gitalist::Object::HasTree;

use Moose::Role;

use Method::Signatures;

has tree => (
  isa        => 'ArrayRef[Git::Gitalist::Object]',
  required   => 0,
  is         => 'ro',
  lazy_build => 1,
);


method _build_tree {
    my $output = $self->_run_cmd(qw/ls-tree -z/, $self->sha1);
    return unless defined $output;

    my @ret;
    for my $line (split /\0/, $output) {
        my ($mode, $type, $object, $file) = split /\s+/, $line, 4;
        # Ignore commits, these represent submodules
        next if $type eq 'commit';
        my $class = 'Git::Gitalist::Object::' . ucfirst($type);
        push @ret, $class->new( mode => oct $mode,
                                type => $type,
                                sha1 => $object,
                                file => $file,
                                repository => $self->repository,
                              );
    }
    return \@ret;
}

method entries {
    return $self->{_gpp_obj}->{directory_entries};
}

1;

__END__

=head1 NAME

Git::Gitalist::Object::HasTree - Git::Object::HasTree module forGit::Gitalist

=head1 SYNOPSIS

    my $tree = Repository->get_object($tree_sha1);

=head1 DESCRIPTION

Role for objects which have a tree - C<Commit> and C<Tree> objects.


=head1 ATTRIBUTES

=head2 tree


=head1 METHODS


=head1 AUTHORS

See L<Git::Gitalist> for authors.

=head1 LICENSE

See L<Git::Gitalist> for the license.

=cut
