package Git::Gitalist::Object::Blob;

use Moose;

extends 'Git::Gitalist::Object';

has '+type' => ( default => 'blob' );

1;

__END__

=head1 NAME

Git::Gitalist::Object::Blob - Git::Object::Blob module forGit::Gitalist

=head1 SYNOPSIS

    my $blob = Repository->get_object($blob_sha1);

=head1 DESCRIPTION

Represents a blob object in a git repository.
Subclass of C<Git::Gitalist::Object>.


=head1 ATTRIBUTES


=head1 METHODS

=head1 AUTHORS

See L<Git::Gitalist> for authors.

=head1 LICENSE

See L<Git::Gitalist> for the license.

=cut
