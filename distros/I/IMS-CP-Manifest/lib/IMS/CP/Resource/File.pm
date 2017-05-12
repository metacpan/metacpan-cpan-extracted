use strict;
use warnings;

package IMS::CP::Resource::File;
{
  $IMS::CP::Resource::File::VERSION = '0.0.3';
}
use Moose;
with 'XML::Rabbit::Node';

# ABSTRACT: One file inside a resource


has 'href' => (
    isa         => 'Str',
    traits      => [qw/XPathValue/],
    xpath_query => './@href',
);


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

no Moose;
__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

IMS::CP::Resource::File - One file inside a resource

=head1 VERSION

version 0.0.3

=head1 ATTRIBUTES

=head2 href

The URI associated with the file.

=head2 id

The identifier for the file.

=head2 title

The title of the file.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
