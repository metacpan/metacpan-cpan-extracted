use strict;
use warnings;

package IMS::LOM::LangString;
{
  $IMS::LOM::LangString::VERSION = '0.0.3';
}
use Moose;
with 'XML::Rabbit::Node';

# ABSTRACT: A string of text in the specified language


has 'language' => (
    isa         => 'Str',
    traits      => [qw/XPathValue/],
    xpath_query => './lom:langstring/@xml:lang',
);


has 'text' => (
    isa         => 'Str',
    traits      => [qw/XPathValue/],
    xpath_query => './lom:langstring',
);

no Moose;
__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

IMS::LOM::LangString - A string of text in the specified language

=head1 VERSION

version 0.0.3

=head1 ATTRIBUTES

=head2 language

The language identifier for the text. Specified in W3C xml:lang syntax.

=head2 text

The actual string of text.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
