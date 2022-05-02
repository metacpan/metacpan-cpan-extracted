package File::KDBX::XS;
# ABSTRACT: Speed up File::KDBX

use warnings;
use strict;

use XSLoader;

our $VERSION = '0.900'; # VERSION

XSLoader::load(__PACKAGE__, $VERSION);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::XS - Speed up File::KDBX

=head1 VERSION

version 0.900

=head1 DESCRIPTION

This module provides some speed improvement for L<File::KDBX>.

There is no public interface.

This distribution contains code from L<CryptX> and L<LibTomCrypt|https://www.libtom.net/LibTomCrypt/>,
bundled according to their own licensing terms (which are also permissive).

=head1 FUNCTIONS

=head2 CowREFCNT

Get the copy-on-write (COW) reference count of a scalar, or C<undef> if the perl does not support scalar COW
or if the scalar is not COW.

See also L<B::COW/"cowrefcnt( PV )">.

=for markdown [![Linux](https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/linux.yml/badge.svg)](https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/linux.yml)
[![macOS](https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/macos.yml/badge.svg)](https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/macos.yml)
[![Windows](https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/windows.yml/badge.svg)](https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/windows.yml)

=for HTML <a title="Linux" href="https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/linux.yml"><img src="https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/linux.yml/badge.svg"></a>
<a title="macOS" href="https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/macos.yml"><img src="https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/macos.yml/badge.svg"></a>
<a title="Windows" href="https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/windows.yml"><img src="https://github.com/chazmcgarvey/File-KDBX-XS/actions/workflows/windows.yml/badge.svg"></a>

=for Pod::Coverage kdf_aes_transform_half

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX-XS/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Karel Miko

Karel Miko <mic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
