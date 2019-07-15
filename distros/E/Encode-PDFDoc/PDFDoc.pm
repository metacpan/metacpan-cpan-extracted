package Encode::PDFDoc;
# ABSTRACT: PDFDocEncoding support
$Encode::PDFDoc::VERSION = '0.03';
use Encode;
use XSLoader;
XSLoader::load(__PACKAGE__,$VERSION);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Encode::PDFDoc - PDFDocEncoding support

=head1 VERSION

version 0.03

=head1 SYNOPSIS

       use Encode qw(encode decode)
       use Encode::PDFDoc;

       $characters = decode('PDFDoc', $octets);
       $octets     = encode('PDFDoc', $characters);

=head1 DESCRIPTION

This module contains support for PDFDocEncoding used for text strings
in PDF documents outside of the document's content streams.
This encoding is described in the PDF 1.7 specification, Annex D.

=head1 SEE ALSO

L<Encode>

=head1 AUTHOR

Ievgenii Meshcheriakov <eugen@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ievgenii Meshcheriakov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
