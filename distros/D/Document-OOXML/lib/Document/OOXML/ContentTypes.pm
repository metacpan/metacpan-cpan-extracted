use utf8;
package Document::OOXML::ContentTypes;
use Moose;
use namespace::autoclean;

# ABSTRACT: Part to content-type mapping for OOXML

use XML::LibXML;


my $CONTENT_TYPES_NS = 'http://schemas.openxmlformats.org/package/2006/content-types';

has defaults => (
    is => 'ro',
    isa => 'ArrayRef[HashRef]'
);

has overrides => (
    is => 'ro',
    isa => 'ArrayRef[HashRef]'
);


sub new_from_xml {
    my $class = shift;

    my $doc = XML::LibXML->load_xml( string => shift );
    my $xpc = XML::LibXML::XPathContext->new();
    $xpc->registerNs('ct' => $CONTENT_TYPES_NS);

    my @defaults  = map {
        {
            extension    => $xpc->findvalue('@Extension', $_),
            content_type => $xpc->findvalue('@ContentType', $_),
        }
    } $xpc->findnodes('/ct:Types/ct:Default', $doc->documentElement);

    my @overrides = map {
        {
            part_name    => $xpc->findvalue('@PartName', $_),
            content_type => $xpc->findvalue('@ContentType', $_),
        }
    } $xpc->findnodes('/ct:Types/ct:Override', $doc->documentElement);

    return $class->new(
        defaults  => \@defaults,
        overrides => \@overrides,
    );
}


sub get_content_type_for_part {
    my $self = shift;
    my $part_name = shift;

    my ($overridden) = grep { "/$part_name" eq $_->{part_name} } @{ $self->overrides };
    return $overridden->{content_type} if $overridden;

    my ($default) = grep { "/$part_name" =~ /\Q.$_->{extension}\E$/ } @{ $self->defaults };
    return $default->{content_type} if $default;

    return;
}

__PACKAGE__->meta->make_immutable();

__END__

=pod

=encoding UTF-8

=head1 NAME

Document::OOXML::ContentTypes - Part to content-type mapping for OOXML

=head1 VERSION

version 0.181410

=head1 SYNOPSIS

    my $ct = Document::OOXML::ContentTypes->new_from_xml($xml_data);
    say "The content type of /word/document.xml is " . $ct->get_content_type_for_part('/word/document.xml');

=head1 DESCRIPTION

OOXML files contain a file named '[Content_Types].xml' that describes the
content-types of all the other files in the package.

This class implements a way to look up the content-type for a file name,
given the contents of that file.

=head1 METHODS

=head2 new_from_xml($xml_data)

Creates a new L<Document::OOXML::ContentTypes> instance from the contents
of the C</[Content-Types].xml> file from an OOXML file.

=head2 get_content_type_for_part($part_name)

Returns the content-type of the part with the specified name.

=head1 SEE ALSO

=over

=item * L<Document::OOXML>

=back

=head1 AUTHOR

Martijn van de Streek <martijn@vandestreek.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Martijn van de Streek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
