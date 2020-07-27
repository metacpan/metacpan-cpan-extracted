use utf8;

package JSON::API::v1::JSONAPI;
our $VERSION = '0.002';
use Moose;
use namespace::autoclean;
use Carp qw(croak);

# ABSTRACT: A JSON API jsonapi object

sub TO_JSON {
    my $self = shift;

    return {
        version => "1.0",
        $self->has_meta_object ? (meta => $self->meta_object) : (),
    }
}

with qw(
    JSON::API::v1::Roles::TO_JSON
    JSON::API::v1::Roles::MetaObject
);

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::API::v1::JSONAPI - A JSON API jsonapi object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use JSON::API::v1::JSONAPI;
    my $object = JSON::API::v1::JSONAPI->new(
        meta => JSON::API::v1::MetaObject->new(),
    );

=head1 DESCRIPTION

This module attempts to make a Moose object behave like a JSON API object as
defined by L<jsonapi.org>. This object adheres to the v1 specification.

This object will always return that the highest supported version is C<1.0>

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
