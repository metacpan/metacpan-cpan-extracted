package Git::Database::Role::Object;
$Git::Database::Role::Object::VERSION = '0.011';
use Sub::Quote;

use Moo::Role;

requires qw( kind );

has backend => (
    is      => 'lazy',
    builder => sub {
        require Git::Database::Backend::None;
        return Git::Database::Backend::None->new;
    },
    isa => sub {
        die "$_[0] DOES not Git::Database::Role::Backend"
          if !eval { $_[0]->does('Git::Database::Role::Backend') };
    },
    predicate => 1,
);

has digest => (
    is      => 'lazy',
    builder => sub { $_[0]->backend->hash_object( $_[0] ); },
    coerce  => sub { lc $_[0] },
    isa =>
      quote_sub(q{ die "Not a SHA-1 digest" if $_[0] !~ /^[0-9a-f]{40}/; }),
    predicate => 1,
);

has size => (
    is        => 'lazy',
    builder   => sub { length $_[0]->content },
    predicate => 1,
);

has content => (
    is        => 'rwp',
    builder   => sub { $_[0]->_get_object_attributes->{content} },
    predicate => 1,
    lazy      => 1,
);

sub as_string { $_[0]->content; }

sub _get_object_attributes {
    my ($self) = @_;
    my $backend = $self->backend;
    die sprintf "%s can't get_object_attributes", $backend
      if !$backend->can('get_object_attributes');

    my $attr = $backend->get_object_attributes( $self->digest );
    die sprintf '%s %s not found in %s', $self->kind, $self->digest, $backend
      if !$attr;
    return $attr;
}

1;

__END__

=pod

=for Pod::Coverage
  has_backend
  has_content
  has_digest
  has_size

=head1 NAME

Git::Database::Role::Object - Role for objects from the Git object database

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    package Git::Database::Object::Blob;

    use Moo;

    with 'Git::Database::Role::Object';

    sub kind { 'blob' }

    1;

=head1 DESCRIPTION

Git::Database::Role::Object provides the generic behaviour for all
L<Git::Database> objects obtained from or stored into the Git object
database.

When creating a new object meant to be added to the Git object database
(via L<backend>), only the L</content> attribute is actually required.

New objects are typically created via L<Git::Database::Role::ObjectReader>'s
L<get_object|Git::Database::Role::ObjectReader/get_object> method,
rather than by calling C<new> directly. This is when the object data is
fetched from the Git object database.

=head1 ATTRIBUTES

The L<content>, L<size> and L<digest> attribute are lazy, and can be
computed from the others: L<size> from L<content>, L<content> from
L<digest> (if the object exists in the backend store), and L<digest>
from L<content>. All attributes have a predicate method.

Additional attributes in some classes may add other ways to compute
the content.

Creating a new object with inconsistent C<kind>, C<size>,
C<content> and C<digest> attributes can only end in
tears. This is also true for additional attributes such as
L<directory_entries|Git::Database::Object::Tree/directory_entries>,
L<commit_info|Git::Database::Object::Commit/commit_info>, and
L<tag_info|Git::Database::Object::Tag/tag_info>.

For now, as soon as the L</content> of a Git::Database::Role::Object is
needed, it is fully loaded in memory.

=head2 backend

A L<Git::Database::Role::Backend> from which the object comes from
(or will be stored into). It is typically used by the attribute builders.

If none is provided, a L<Git::Database::Backend::None> is used, which
is only able to compute the L<digest>.

=head2 content

The object's actual content.

=head2 size

The size (in bytes) of the object content.

=head2 digest

The SHA-1 digest of the object, as computed by Git.

If set at creation time, it is internally converted to lowercase.

=head1 METHODS

=head2 as_string

Return a string representation of the content.

By default, this is the same as C<content()>, but some classes may
override it.

=head1 REQUIRED METHODS

=head2 kind

Returns the object "kind".

In Git, this is one of C<blob>, C<tree>, C<commit>, and C<tag>.

=head1 SEE ALSO

L<Git::Database::Object::Blob>,
L<Git::Database::Object::Tree>,
L<Git::Database::Object::Commit>,
L<Git::Database::Object::Tag>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2013-2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
