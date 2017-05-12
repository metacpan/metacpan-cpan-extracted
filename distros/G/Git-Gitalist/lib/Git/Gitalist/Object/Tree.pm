package Git::Gitalist::Object::Tree;

use Moose;

extends 'Git::Gitalist::Object';
with 'Git::Gitalist::Object::HasTree';

has '+type' => ( default => 'tree' );
has '+_gpp_obj' => ( handles => [qw(directory_entries)] );

1;

__END__

=head1 NAME

Git::Gitalist::Object::Tree - Git::Object::Tree module forGit::Gitalist

=head1 SYNOPSIS

    my $tree = Repository->get_object($tree_sha1);

=head1 DESCRIPTION

Represents a tree object in a git repository.
Subclass of C<Git::Gitalist::Object>.


=head1 ATTRIBUTES


=head1 METHODS


=head1 AUTHORS

See L<Git::Gitalist> for authors.

=head1 LICENSE

See L<Git::Gitalist> for the license.

=cut
