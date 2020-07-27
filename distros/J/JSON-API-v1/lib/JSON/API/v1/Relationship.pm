use utf8;

package JSON::API::v1::Relationship;
our $VERSION = '0.002';
use Moose;
use namespace::autoclean;
use Carp qw(croak);
use List::Util qw(any);

our @CARP_NOT;

# ABSTRACT: A JSON API Relationship object according to jsonapi v1 specification

has data => (
    is        => 'ro',
    isa       => 'Defined',
    predicate => 'has_data',
);

sub TO_JSON {
    my $self = shift;

    if (!$self->has_data && !$self->has_links && !$self->has_meta_object) {
        croak("Unable to continue, you don't have data, links or meta set");
    }

    return {
        $self->has_links       ? (links => $self->links)       : (),
        $self->has_data        ? (data  => $self->data)        : (),
        $self->has_meta_object ? (meta  => $self->meta_object) : (),
    };
}

with qw(
    JSON::API::v1::Roles::TO_JSON
    JSON::API::v1::Roles::Links
    JSON::API::v1::Roles::MetaObject
);


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::API::v1::Relationship - A JSON API Relationship object according to jsonapi v1 specification

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 DESCRIPTION

This module attempts to make a Moose object behave like a JSON API object as
defined by L<jsonapi.org>. This object adheres to the v1 specification

=head1 ATTRIBUTES

=head1 METHODS

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
