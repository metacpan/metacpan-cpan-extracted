package JSONAPI::Document::Role::Attributes;
$JSONAPI::Document::Role::Attributes::VERSION = '2.4';
=head1 NAME

JSONAPI::Document::Role::Attributes - Consumable role to build resource attributes

=head1 VERSION

version 2.4

=head1 DESCRIPTION

This role allows you to customize the fetching of a rows attributes.

Simply add this to the row object and implement the C<attributes> method and it'll
be called instead of C<JSONAPI::Document> doing the building of attributes.

The method is passed a single argument, an C<ArrayRef> of requested fields,
which should be honoured in the returned C<HashRef>.

=head2 attributes(ArrayRef $fields?) : HashRef

Returns a hashref of columns/attributes for the consuming classes row.

=cut

use Moo::Role;

requires 'attributes';

1;
