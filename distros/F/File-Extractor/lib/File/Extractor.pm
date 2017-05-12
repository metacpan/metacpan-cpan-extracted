package File::Extractor;

use strict;
use warnings;

our $VERSION = '0.04';
our @ISA;

eval {
    require XSLoader;
    XSLoader::load( __PACKAGE__, $VERSION );
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    __PACKAGE__->bootstrap( $VERSION );
};

=head1 NAME

File::Extractor - Extract meta-data from arbitrary files

=head1 SYNOPSIS

    use File::Extractor;

    my $extractor = File::Extractor->loadDefaultLibraries;
    my %keywords  = $extractor->getKeywords($fh);

=head1 DESCRIPTION

This module provides a perl interface to libextractor.

GNU libextractor provides developers of file-sharing networks, file managers,
and WWW-indexing bots with a universal library to obtain meta-data about
files.

Currently, libextractor supports the following formats: HTML, PDF, PS, OLE2
(DOC, XLS, PPT), OpenOffice (sxw), StarOffice (sdw), DVI, MAN, MP3 (ID3v1 and
ID3v2), OGG, WAV, EXIV2, JPEG, GIF, PNG, TIFF, DEB, RPM, TAR(.GZ), ZIP, ELF,
REAL, RIFF (AVI), MPEG, QT and ASF.

Also, various additional MIME types are detected. It can also be used to
compute hash functions (SHA-1, MD5, ripemd160).

L<http://www.gnunet.org/libextractor/>

=head1 METHODS

=head2 C<getDefaultLibraries>

  my @default_libraries = File::Extractor->getDefaultLibraries;

Return a list of strings which are the names of the default extractor
libraries.

=head2 C<loadDefaultLibraries>

  my $extractor = File::Extractor->loadDefaultLibraries;

Load the default set of libraries. Returns a File::Extractor instance.

=head2 C<loadConfigLibraries>

  my $extractor = File::Extractor->loadConfigLibraries($config);
  my $new_extractor = $extractor->loadConfigLibraries($config);

Load multiple libraries as specified by the user. C<$config> is a
string given by the user that defines which libraries should be loaded.
Has the format
C<"[[-]LIBRARYNAME[(options)][:[-]LIBRARYNAME[(options)]]]*".>. For
example C<libextractor_mp3.so:libextractor_ogg.so> loads the mp3 and
the ogg library. The '-' before the LIBRARYNAME indicates that the
library should be added to the end of the library list
(C<addLibraryLast>).

=head2 C<addLibrary>

  my $extractor = File::Extractor->addLibrary($library);
  my $new_extractor = $extractor->addLibrary($library);

Add a library for keyword extraction. C<$library> is the name of the
library to be loaded.

=head2 C<addLibraryLast>

  my $extractor = File::Extractor->addLibraryLast($library);
  my $new_extractor = $extractor->addLibraryLast($library);

Add a library for keyword extraction at the end of the list.
C<$library> is the name of the library to be loaded.

=head2 C<removeLibrary>

  $extractor->removeLibrary($library);

Remove a library for keyword extraction. C<$library> is the name of the
library to be removed.

=head2 C<getKeywords>

  my %keywords = $extractor->getKeywords($fh);
  my %keywords = $extractor->getKeywords($data);

Extract keywords from an opened filehandle (C<$fh>) or from a buffer in memory
(C<$data>). Returns a hash with all the extracted keywords. The hash keys
represent the keywords type, the hash values are the actual keywords.

=head1 AUTHOR

Florian Ragwitz, C<< <rafl at debian.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-extractor at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Extractor>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Extractor

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Extractor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Extractor>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Extractor>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Extractor>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Florian Ragwitz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of File::Extractor
