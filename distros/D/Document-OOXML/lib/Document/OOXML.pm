use utf8;
package Document::OOXML;
use Moose;
use namespace::autoclean;

# ABSTRACT: Manipulation of Office Open XML files
our $VERSION = '0.180750'; # VERSION

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Carp;
use XML::LibXML;

use Document::OOXML::ContentTypes;
use Document::OOXML::Document::Wordprocessor;
use Document::OOXML::PartParser;
use Document::OOXML::Rels;


my %ROOT_PART_REL_TYPES = (
    transitionalDocument => 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument',
    strictDocument       => 'http://purl.oclc.org/ooxml/officeDocument/relationships/officeDocument',
);


sub read_document {
    my $class = shift;
    my $filename = shift;

    my $zip = Archive::Zip->new();

    my $zip_status = $zip->read($filename);
    croak("Cannot read: $zip_status") unless $zip_status == AZ_OK;

    my $content_types = do {
        my $ct_xml = $zip->contents('[Content_Types].xml')
            or croak("No member named '/[Content_Types].xml'. Is it OOXML?");

        Document::OOXML::ContentTypes->new_from_xml($ct_xml);
    };

    my $base_rels_data = $zip->contents('_rels/.rels')
        or croak("No member named '_rels/.rels' in document. Is it OOXML?");

    my $rels = Document::OOXML::Rels->new_from_xml($base_rels_data, '');

    # The "old"/transitional XML uses schemas.openxmlformats.org
    # "New"/ISO standard/strict XML uses purl.oclc.org/ooxml
    my %document_part_relation = %{
           $rels->get_part_relation_by_type($ROOT_PART_REL_TYPES{transitionalDocument})
        || $rels->get_part_relation_by_type($ROOT_PART_REL_TYPES{strictDocument})
    };

    my $type      = $document_part_relation{type};
    my $part_name = $document_part_relation{part_name};

    my $strict;
    if ($type eq $ROOT_PART_REL_TYPES{strictDocument}) {
        $strict = 1;
    } else {
        $strict = 0;
    }

    my $part_contents = $zip->contents($part_name)
        or croak("No member named '$part_name' in document. Is it OOXML?");

    my $doc_part = Document::OOXML::PartParser->parse_part(
        content_type  => $content_types->get_content_type_for_part($part_name),
        contents      => $part_contents,
        part_name     => $part_name,
        is_strict     => $strict,
    );

    my $document_class;
    if ($doc_part->isa('Document::OOXML::Part::WordprocessingML')) {
        $document_class = 'Document::OOXML::Document::Wordprocessor';
    }
    else {
        croak("Unsupported document type");
    }

    my $ooxml = $document_class->new(
        content_types => $content_types,
        filename      => $filename,
        source        => $zip,
        is_strict     => $strict,
    );

    # Parts have weak references to the document they're in, so they don't
    # create reference loops.
    #
    # They can use this reference to find or add other parts (images,
    # headers, footers, etc.) referenced by the main document.
    $doc_part->document($ooxml);
    $ooxml->set_document_part($doc_part);

    return $ooxml;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Document::OOXML - Manipulation of Office Open XML files

=head1 VERSION

version 0.180750

=head1 SYNOPSIS

    my $doc = Document::OOXML->read_document('some.docx');

    $doc->replace_text('old', 'new');

    $doc->save_to_file('some_other.docx');

=head1 DESCRIPTION

This module provides a way to open, modify and save Office Open XML files
(also known as OOXML or Microsoft Office XML).

=head1 METHODS

=head2 read_document($filename)

Opens the file named C<$filename> and parses it.

If the file doesn't appear to be a valid package, it will croak.

Returns an instance of a subclass of L<Document::OOXML::Document> that can
be used to manipulate the contents of the document:

=over

=item * L<Document::OOXML::Document::Wordprocessor>

=back

=head1 SEE ALSO

The format of Office Open XML files is described in the
L<ISO/IEC 29500|https://www.iso.org/standard/71691.html> and
L<ECMA-376|https://www.ecma-international.org/publications/standards/Ecma-376.htm>
standards.

=head1 AUTHOR

Martijn van de Streek <martijn@vandestreek.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Martijn van de Streek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
