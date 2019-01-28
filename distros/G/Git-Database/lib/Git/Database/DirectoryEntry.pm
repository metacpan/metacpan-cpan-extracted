package Git::Database::DirectoryEntry;
$Git::Database::DirectoryEntry::VERSION = '0.011';
use Sub::Quote;

use Moo;
use namespace::clean;

# Git only uses the following (octal) modes:
# - 040000 for subdirectory (tree)
# - 100644 for file (blob)
# - 100755 for executable (blob)
# - 120000 for a blob that specifies the path of a symlink
# - 160000 for submodule (commit)
#
# See also: cache.h in git.git
has mode => (
    is       => 'ro',
    required => 1,
);

has filename => (
    is => 'ro',
);

has digest => (
    is  => 'ro',
    isa => quote_sub(
        q{ die "Not a SHA-1 digest" unless $_[0] =~ /^[0-9a-f]{40}/; }),
    required => 1,
);

sub as_content {
    my ($self) = @_;
    return
          $self->mode . ' '
        . $self->filename . "\0"
        . pack( 'H*', $self->digest );
}

sub as_string {
    my ($self) = @_;
    my $mode = oct( '0' . $self->mode );
    return sprintf "%06o %s %s\t%s\n", $mode,
        $mode & 0100000 ? 'blob' : 'tree',
        $self->digest, $self->filename;
}

# some helper methods
sub is_tree       { !( oct( '0' . $_[0]->mode ) & 0100000 ) }
sub is_blob       { !!( oct( '0' . $_[0]->mode ) & 0100000 ) }
sub is_executable { !!( oct( '0' . $_[0]->mode ) & 0100 ) }
sub is_link       { $_[0]->mode eq '120000' }
sub is_submodule  { $_[0]->mode eq '160000' }

1;

__END__

=pod

=head1 NAME

Git::Database::DirectoryEntry - A directory entry in Git

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    my $hello = Git::Database::DirectoryEntry->new(
        mode     => '100644',
        filename => 'hello',
        digest   => 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'
    );

    my $tree = Git::Database::Object::Tree->new( directory_entries => [$hello] );

=head1 DESCRIPTION

Git::Database::DirectoryEntry represents a directory entry in a C<tree>
object obtained via L<Git::Database> from a Git object database.

=head1 ATTRIBUTES

=head2 mode

The mode of the directory entry, as a string (octal representation):

=over 4

=item C<040000>

a subdirectory (tree)

=item C<100644>

a file (blob)

=item C<100755>

an executable file for executable (blob)

=item C<120000>

a symbolic link (the blob contains the path to the target file)

=item C<160000>

a submodule (commit)

=back

=head2 digest

The 40 character digest of the Git object pointed by the directory entry.

=head2 filename

The name of the directory entry.

=head1 METHODS

=head2 as_content

Return a string representing the directory entry in the format used
for the content of tree object.

=head2 as_string

Return a string representing the directory entry in the same format as
C<git ls-tree>.

=head2 is_tree

Return a boolean value indicating whether the directory entry points to a
tree object.

=head2 is_blob

Return a boolean value indicating whether the directory entry points to a
blob object.

=head2 is_executable

Return a boolean value indicating whether the directory entry has the
executable switched.

=head2 is_link

Return a boolean value indicating whether the directory entry points to a
a link. Note: a link is a blob.

=head2 is_submodule

Return a boolean value indicating whether the directory entry points to a
a submodule. Note: a submodule is a blob.

=head1 SEE ALSO

L<Git::Database>,
L<Git::Database::Object::Tree>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2013-2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
