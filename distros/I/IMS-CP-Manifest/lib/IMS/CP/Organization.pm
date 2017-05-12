use strict;
use warnings;

package IMS::CP::Organization;
{
  $IMS::CP::Organization::VERSION = '0.0.3';
}
use Moose;
with 'XML::Rabbit::Node';

# ABSTRACT: A way to organize content in the package


has 'title' => (
    isa         => 'Str',
    traits      => [qw/XPathValue/],
    xpath_query => './cp:title',
);


has 'items' => (
    isa         => 'ArrayRef[IMS::CP::Organization::Item]',
    traits      => [qw/XPathObjectList/],
    xpath_query => './cp:item',
);

no Moose;
__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

IMS::CP::Organization - A way to organize content in the package

=head1 VERSION

version 0.0.3

=head1 ATTRIBUTES

=head2 title

The title of this organization of items.

=head2 items

The items in this particular organization.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
