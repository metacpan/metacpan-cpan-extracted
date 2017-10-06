# NAME

EBook::EPUB::Check - Perl wrapper for EpubCheck

# SYNOPSIS

    use EBook::EPUB::Check; # exports epubcheck()

    my $result = epubcheck('epub/invalid.epub'); # => isa 'EBook::EPUB::Check::Result'

    unless ($result->is_valid)
    {
        print $result->report;
    }

    epubcheck('epub/valid.epub')->is_valid; # => success

Command Line Interface:

    epubcheck ebook.epub
    epubcheck -out output.xml ebook.epub # Extracting information from an EPUB file

# DESCRIPTION

EBook::EPUB::Check checks whether your EPUB files are valid.

For more Information about EpubCheck, see [https://github.com/IDPF/epubcheck/wiki](https://github.com/IDPF/epubcheck/wiki).

# PREREQUISITES

Java must be installed and set in your PATH.

# FUNCTIONS

## epubcheck( $epub \[, $jar\] )

Returns an [EBook::EPUB::Check::Result](https://metacpan.org/pod/EBook::EPUB::Check::Result) instance.

# LICENSE

- of the Module

    Copyright (C) pawa.

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself.

- of EpubCheck

    New BSD License

# SEE ALSO

[https://github.com/IDPF/epubcheck/wiki](https://github.com/IDPF/epubcheck/wiki)

[EBook::EPUB](https://metacpan.org/pod/EBook::EPUB)

# AUTHOR

pawa <pawa@pawafuru.com>
