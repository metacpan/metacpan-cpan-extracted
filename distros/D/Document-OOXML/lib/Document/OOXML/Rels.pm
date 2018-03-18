use utf8;
package Document::OOXML::Rels;
use Moose;
use namespace::autoclean;

# ABSTRACT: Class representing ".rels" (relationships) files in OOXML


has xml => (
    is => 'ro',
    isa => 'XML::LibXML::Document',
    required => 1,
);

has xpc => (
    is       => 'ro',
    isa      => 'XML::LibXML::XPathContext',
    required => 1,
);

has basedir => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);


my $RELATIONSHIPS_NS = 'http://schemas.openxmlformats.org/package/2006/relationships';

sub new_from_xml {
    my $class = shift;
    my $xml_data = shift;
    my $basedir = shift;

    my $xml = XML::LibXML->load_xml( string => $xml_data );
    my $xpc = XML::LibXML::XPathContext->new();
    $xpc->registerNs('r' => $RELATIONSHIPS_NS);

    return $class->new(
        xml     => $xml,
        xpc     => $xpc,
        basedir => $basedir,
    );
}


sub get_part_relation_by_type {
    my $self = shift;
    my $part_type = shift;

    my ($part_relation) = $self->xpc->findnodes(
        "/r:Relationships/r:Relationship[\@Type='$part_type']",
        $self->xml->documentElement,
    );

    return $self->_extract_relation_data($part_relation);
}


sub get_part_relation_by_id {
    my $self = shift;
    my $part_id = shift;

    my ($part_relation) = $self->xpc->findnodes(
        "/r:Relationships/r:Relationship[\@Id='$part_id']",
        $self->xml->documentElement,
    );

    return $self->_extract_relation_data($part_relation);
}

sub _extract_relation_data {
    my $self = shift;
    my $part_relation = shift;
    return unless $part_relation;

    my $id        = $self->xpc->findvalue('@Id', $part_relation);
    my $type      = $self->xpc->findvalue('@Type', $part_relation);
    my $part_name = $self->xpc->findvalue('@Target', $part_relation);

    return {
        id        => $id,
        type      => $type,
        part_name => $self->basedir
            ? join('/', $self->basedir, $part_name)
            : $part_name,
    };
}

__PACKAGE__->meta->make_immutable();

__END__

=pod

=encoding UTF-8

=head1 NAME

Document::OOXML::Rels - Class representing ".rels" (relationships) files in OOXML

=head1 VERSION

version 0.180750

=head1 SYNOPSIS

    my $rels = Document::OOXML::Rels->new_from_xml($rels_xml);

    my $rel1 = $rels->get_part_relation_by_type('http://purl.oclc.org/ooxml/officeDocument/relationships/officeDocument');
    my $rel2 = $rels->get_part_relation_by_id('someId1');

=head1 DESCRIPTION

Class representing a C<.rels> file in an OOXML file. These files specify where
to find related document parts in the package.

They can be referenced from the document by type (this is called an "implicit
reference", footnotes in WordprocessingML work like this), or by id (called an
"explicit reference", headings and footers in WordprocessingML work like this).

=head1 METHODS

=head2 new_from_xml($xml_data)

Parse the "rels" (relationships) XML file data, so it can be queried.

Returns a new instance of C<Document::OOXML::Rels>.

=head2 get_part_relation_by_type($type)

Retrieves the properties (id, type, part name) of a related part, searching
for the C<Type>.

Returns a hash reference with the following keys if the relation is found:

=over

=item * id

=item * type

=item * part_name

=back

=head2 get_part_relation_by_id($type)

Retrieves the properties (id, type, part name) of a related part, searching
for the C<Id>.

Returns a hash reference with the following keys if the relation is found:

=over

=item * id

=item * type

=item * part_name

=back

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
