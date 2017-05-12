use strict;
use warnings;

package IMS::CP::Organization::Item;
{
  $IMS::CP::Organization::Item::VERSION = '0.0.3';
}
use Moose;
with 'XML::Rabbit::Node';

# ABSTRACT: A specific item in an organization of items


has 'id' => (
    isa         => 'Str',
    traits      => [qw/XPathValue/],
    xpath_query => './cp:metadata/lom:lom/lom:general/lom:identifier',
);


has 'title' => (
    isa         => 'IMS::LOM::LangString',
    traits      => [qw/XPathObject/],
    xpath_query => './cp:metadata/lom:lom/lom:general/lom:title',
);


has 'resource' => (
    isa        => 'IMS::CP::Resource',
    traits      => [qw/XPathObject/],
    xpath_query => sub {
        my ($self) = @_;
        return '/cp:manifest/cp:resources/cp:resource[@identifier=' . $self->id . ']';
    },
);

no Moose;
__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

IMS::CP::Organization::Item - A specific item in an organization of items

=head1 VERSION

version 0.0.3

=head1 ATTRIBUTES

=head2 id

The identifier for the item.

=head2 title

The title for the item.

=head2 resource

The associated resource for the item.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
