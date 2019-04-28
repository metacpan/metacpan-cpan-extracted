package Git::Database::Object::Blob;
$Git::Database::Object::Blob::VERSION = '0.012';
use Moo;
use namespace::clean;

with 'Git::Database::Role::Object';

sub kind { 'blob' }

sub BUILD {
    my ($self) = @_;
    die "One of 'digest' or 'content' is required"
      if !$self->has_digest && !$self->has_content;
}

1;

__END__

=pod

=for Pod::Coverage
  BUILD

=head1 NAME

Git::Database::Object::Blob - A blob object in the Git object database

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    my $r    = Git::Database->new();        # current Git repository
    my $blob = $r->get_object('b52168');    # abbreviated digest

    # attributes
    $blob->kind;       # blob
    $blob->digest;     # b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0
    $blob->content;    # hello
    ...;               # etc., see below

=head1 DESCRIPTION

Git::Database::Object::Blob represents a C<blob> object
obtained via L<Git::Database> from a Git object database.

=head1 ATTRIBUTES

=head2 kind

The object kind: C<blob>.

=head2 digest

The SHA-1 digest of the blob object.

=head2 content

The object's actual content.

=head2 size

The size (in bytes) of the object content.

=head1 METHODS

=head2 new()

Create a new Git::Object::Database::Blob object.

The C<content> argument is required.

=head2 as_string()

Same as C<content()>.

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
