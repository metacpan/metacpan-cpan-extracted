use utf8;
package Document::OOXML::PartParser;
use Moose;

# ABSTRACT: OOXML document part parser

use Carp;
use Document::OOXML::Part::WordprocessingML;


my %PART_TYPES = (
    # Defined in ISO/IEC 29500-1, § 11.3
    WordprocessingML => qr{
        application/vnd\.openxmlformats-officedocument\.wordprocessingml\.
            (?:
                comments|
                settings|
                endnotes|
                fontTable|
                footer|
                footnotes|
                glossary|
                header|
                document\.main|
                document\.template|
                numbering|
                styles|
                webSettings
            )\+xml
    }x
);


sub parse_part {
    my $class = shift;
    my %args =  @_;

    if ($args{content_type} =~ $PART_TYPES{WordprocessingML}) {
        return Document::OOXML::Part::WordprocessingML->new_from_xml(
            $args{part_name},
            $args{contents},
            $args{is_strict} ? 1 : 0,
        );
    }

    croak("Unknown part of type '$args{content_type}'");
}

__PACKAGE__->meta->make_immutable();

__END__

=pod

=encoding UTF-8

=head1 NAME

Document::OOXML::PartParser - OOXML document part parser

=head1 VERSION

version 0.172650

=head1 SYNOPSIS

    my $doc = Document::OOXML::PartParser->parse_part(
        part_name    => '/word/footer1.xml',
        content_type => 'application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml',
        content      => '<?xml version="1.0"?> ...',
        is_strict    => 1,
    );

=head1 DESCRIPTION

This module provides one method that creates a new L<Document::OOXML::Part> of
the right kind (WordprocessingML, etc.), given a content-type and file
contents.

=head1 METHODS

=head2 parse_part

Parse a part of an OOXML document, and return a L<Document::OOXML::Part>
for it.

=over

=item * part_name

The name of the part (in the zip file that is the "package")

=item * content_type

Content-type of this part. Used to determine the class to use to
represent it.

=item * contents

Contents of the part.

=item * is_strict

True if the file looks like it's using the "strict" namespaces/types.

=back

=head1 SEE ALSO

=over

=item * L<Document::OOXML>

=back

=head1 AUTHOR

Martijn van de Streek <martijn@vandestreek.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Martijn van de Streek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
