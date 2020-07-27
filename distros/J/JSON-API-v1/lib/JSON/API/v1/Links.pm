use utf8;

package JSON::API::v1::Links;
our $VERSION = '0.002';
use Moose;
use namespace::autoclean;
use Carp qw(croak);
use MooseX::Types::URI qw(Uri);

# ABSTRACT: A JSON API Links object

has uri => (
    is        => 'ro',
    isa       => Uri,
    predicate => 'has_uri',
    coerce    => 1,
);

has related => (
    is        => 'ro',
    isa       => 'JSON::API::v1::Links',
    predicate => 'has_related',
);

sub TO_JSON {
    my $self = shift;

    if (!$self->has_uri && !$self->has_related) {
        croak(
                  "Unable to represent a link data object, both related"
                . "and uri are missing",
        );
    }
    if ($self->has_meta_object) {
        return {
            meta => $self->meta_object,
            href => $self->uri,
            $self->has_related
                ? (related => $self->related)
                : (),
        };
    }
    return {
        $self->has_uri ? (self => $self->uri) : (),
        $self->has_related
            ? (related => $self->related)
            : (),
    };
}

# Make sure we stringify the URI
around uri => sub {
    my ($orig, $self) = @_;
    return $self->$orig . "";
};

with qw(
    JSON::API::v1::Roles::TO_JSON
    JSON::API::v1::Roles::MetaObject
);


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::API::v1::Links - A JSON API Links object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use JSON::API::v1::Resource;
    my $object = JSON::API::v1::Resource->new(
        # If omitted, this becomes a "NULL" object
        id   => 1,
        type => 'example',

        # optional
        attributes => {
            'title' => 'Some example you are',
        },
    );

    $object->TO_JSON_API_V1;

=head1 DESCRIPTION

This module attempts to make a Moose object behave like a JSON API object as
defined by L<jsonapi.org>. This object adheres to the v1 specification.

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=over

=item * L<https://jsonapi.org/format/#document-resource-objects>

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
