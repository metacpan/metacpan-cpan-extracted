package KiokuDB::Role::ID::Content;
BEGIN {
  $KiokuDB::Role::ID::Content::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::ID::Content::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Content dependent object IDs

use namespace::clean -except => 'meta';

with qw(
    KiokuDB::Role::ID
    KiokuDB::Role::Immutable
);

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::ID::Content - Content dependent object IDs

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package BLOB;
    use Moose;

    use Digest::SHA1;

    with qw(KiokuDB::Role::ID::Content);

    sub kiokudb_object_id {
        my $self = shift;
        sha1_hex($self->data);
    }

    has data => (
        isa => "Str",
        is  => "ro",
        required => 1,
    );

=head1 DESCRIPTION

This is a role for L<KiokuDB::Role::Immutable> objects whose IDs depend on
their content, or in other words content addressable objects.

A canonical example is a string identified by its SHA-1 hash, as is
demonstrated in the L</SYNOPSIS>.

Objects which do this role are never updated in the database just like
L<KiokuDB::Role::Immutable> objects.

Additionally, it is not an error to insert such objects twice since the objects
are assumed to be identical.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
