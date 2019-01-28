package Git::Database::Object::Tree;
$Git::Database::Object::Tree::VERSION = '0.011';
use Moo;
use namespace::clean;

with 'Git::Database::Role::Object';

use Git::Database::DirectoryEntry;

sub kind {'tree'}

has directory_entries => (
    is        => 'rwp',
    required  => 0,
    predicate => 1,
    lazy      => 1,
    builder   => 1,
);

sub BUILD {
    my ($self) = @_;

    die "One of 'digest' or 'content' or 'directory_entries' is required"
      if !$self->has_digest
      && !$self->has_content
      && !$self->has_directory_entries;

    # sort directory entries
    $self->_set_directory_entries(
        [   sort { $a->filename cmp $b->filename }
                @{ $self->directory_entries }
        ]
    ) if $self->has_directory_entries;
}

sub _build_content {
    my ($self) = @_;

    if ( !$self->has_directory_entries ) {
        my $attr = $self->_get_object_attributes();
        return $attr->{content} if exists $attr->{content};

        if ( exists $attr->{directory_entries} ) {
            $self->_set_directory_entries( $attr->{directory_entries} );
        }
        else {
            die "Can't build content from these attributes: "
              . join( ', ', sort keys %$attr );
        }
    }

    return join '', map $_->as_content, @{ $self->directory_entries };
}

# assumes content is set
sub _build_directory_entries {
    my ($self) = @_;

    if ( !$self->has_content ) {
        my $attr = $self->_get_object_attributes();
        return $attr->{directory_entries} if exists $attr->{directory_entries};

        if ( exists $attr->{content} ) {
            $self->_set_content( $attr->{content} );
        }
        else {
            die "Can't build content from these attributes: "
              . join( ', ', sort keys %$attr );
        }
    }

    my $content = $self->content;
    return [] unless $content;

    my @directory_entries;
    while ($content) {
        my $space_index = index( $content, ' ' );
        my $mode = substr( $content, 0, $space_index );
        $content = substr( $content, $space_index + 1 );
        my $null_index = index( $content, "\0" );
        my $filename = substr( $content, 0, $null_index );
        $content = substr( $content, $null_index + 1 );
        my $digest = unpack( 'H*', substr( $content, 0, 20 ) );
        $content = substr( $content, 20 );
        push @directory_entries,
            Git::Database::DirectoryEntry->new(
            mode     => $mode,
            filename => $filename,
            digest   => $digest,
            );
    }
    return \@directory_entries;
}

sub as_string {
    return join '', map $_->as_string, @{ $_[0]->directory_entries };
}

1;

=pod

=for Pod::Coverage
  BUILD
  has_directory_entries

=head1 NAME

Git::Database::Object::Tree - A tree object in the Git object database

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    my $r    = Git::Database->new();        # current Git repository
    my $tree = $r->get_object('b52168');    # abbreviated digest

    # attributes
    $tree->kind;      # tree
    $tree->digest;    # b52168be5ea341e918a9cbbb76012375170a439f
    ...;              # etc., see below

=head1 DESCRIPTION

Git::Database::Object::Tree represents a C<tree> object
obtained via L<Git::Database> from a Git object database.

=head1 ATTRIBUTES

All attributes have a predicate method.

=head2 kind

The object kind: C<tree>.

=head2 digest

The SHA-1 digest of the tree object.

=head2 content

The object's actual content.

=head2 size

The size (in bytes) of the object content.

=head2 directory_entries

An array reference containing a list of L<Git::Database::DirectoryEntry>
objects representing the content of the tree.

=head1 METHODS

=head2 new()

Create a new Git::Object::Database::Commit object.

One (and only one) of the C<content> or C<directory_entries> arguments
is required.

C<directory_entires> is an array reference containing a list of
L<Git::Database::DirectoryEntry> objects representing the content
of the tree.

=head2 as_string()

The content of the tree object, in the format returned by C<git ls-tree>.

=head1 SEE ALSO

L<Git::Database>,
L<Git::Database::Role::Object>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2013-2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
