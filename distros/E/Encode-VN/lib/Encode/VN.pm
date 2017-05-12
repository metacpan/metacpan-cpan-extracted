package Encode::VN;
use 5.007003;
our $VERSION = '0.06';
use Encode;
use XSLoader;
XSLoader::load(__PACKAGE__,$VERSION);

Encode::define_alias( qr/\bVNI(-ANSI)?$/i          => '"x-viet-vni"' );
Encode::define_alias( qr/\bVNI-ASCII$/i            => '"x-viet-vni-ascii"' );
Encode::define_alias( qr/\bVNI-Mac$/i              => '"x-viet-vni-mac"' );
Encode::define_alias( qr/\bVNI-Email$/i            => '"x-viet-vni-email"' );
Encode::define_alias( qr/\bVPS$/i                  => '"x-viet-vps"' );

1;
__END__

=head1 NAME
 
Encode::VN - Extra sets of Vietnamese encodings

=head1 VERSION

This document describes version 0.06 of Encode::VN, released September 15, 2013.

=head1 SYNOPSIS

    use Encode;
    use Encode::VN;

    # VNI (ANSI)
    $vni  = encode("x-viet-vni", $utf8);
    $utf8 = decode("x-viet-vni", $vni );

=head1 DESCRIPTION

Perl 5.7.3 and later ship with an adequate set of Vietnamese encodings,
including the commonly used C<VISCII> and C<CP1258> (also known as
C<MacVietnamese>) encodings.

However, there are additional Vietnamese encodings that are used and may be
encountered; hence, this CPAN module tries to provide the rest of them.

=head1 ENCODINGS

This version includes the following encoding tables:

  Canonical        Alias                       Description
  -----------------------------------------------------------------------------
  x-viet-vni       /\bVNI(-ANSI)?$/i           VNI ANSI (Win/Unix)
  x-viet-vni-ascii /\bVNI-ASCII$/i             VNI ASCII (DOS)
  x-viet-vni-mac   /\bVNI-Mac$/i               VNI Mac
  x-viet-vni-email /\bVNI-Email$/i             VNI Internet Mail (Win/Unix/Mac)
  x-viet-vps       /\bVPS$/i                   Vietnamese Professionals Society

=head1 SEE ALSO

Vietnamese Unicode SourceForge project: L<http://vietunicode.sourceforge.net/>

VNI Wikipedia page: L<http://en.wikipedia.org/wiki/VNI>

Mozilla VPS mappings: L<http://lxr.mozilla.org/seamonkey/source/intl/uconv/ucvlatin/vps.uf>,
                      L<http://lxr.mozilla.org/seamonkey/source/intl/uconv/ucvlatin/vps.ut>

L<Encode>

=head1 ACKNOWLEDGEMENTS

Maps for C<VNI> are generated from the F<vnichar.htm> file,
courtesy of the VNI Sofware Comany, L<http://vnisoft.com/english/vnichar.htm>.

Map for C<VPS> is generated from the "Unicode & Vietnamese Legacy Character
Encodings" page courtesy of the Vietnamese Unicode project on SourceForge,
L<http://vietunicode.sourceforge.net/charset/>.

=head1 AUTHORS

John Wang E<lt>johncwang@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013 by John Wang E<lt>johncwang@gmail.comE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut