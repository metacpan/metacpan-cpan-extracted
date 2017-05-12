package Lingua::ZH::MacChinese::Simplified;

require 5.006001;

use strict;

require Exporter;
require DynaLoader;

our $VERSION = '0.20';
our @ISA = qw(Exporter DynaLoader);
our @EXPORT = qw(decodeMacChineseSimp encodeMacChineseSimp);
our @EXPORT_OK = qw(decode encode);

bootstrap Lingua::ZH::MacChinese::Simplified $VERSION;
1;
__END__

=head1 NAME

Lingua::ZH::MacChinese::Simplified - transcoding between Mac OS Chinese
Simplified encoding and Unicode

=head1 SYNOPSIS

(1) using function names exported by default:

    use Lingua::ZH::MacChinese::Simplified;
    $wchar = decodeMacChineseSimp($octet);
    $octet = encodeMacChineseSimp($wchar);

(2) using function names exported on request:

    use Lingua::ZH::MacChinese::Simplified qw(decode encode);
    $wchar = decode($octet);
    $octet = encode($wchar);

(3) using function names fully qualified:

    use Lingua::ZH::MacChinese::Simplified ();
    $wchar = Lingua::ZH::MacChinese::Simplified::decode($octet);
    $octet = Lingua::ZH::MacChinese::Simplified::encode($wchar);

   # $wchar : a string in Perl's Unicode format
   # $octet : a string in Mac OS Chinese Simplified encoding

=head1 DESCRIPTION

This module provides transcoding from/to
Mac OS Chinese Simplified encoding (denoted MacChineseSimp hereafter).

In order to ensure roundtrip mapping, MacChineseSimp encoding
has some characters with mapping from a single MacChineseSimp character
to a sequence of Unicode characters and vice versa.
Such characters include C<0xA6D9> (MacChineseSimp) from/to
C<0xFF0C+0xF87E> (Unicode) for C<"FULLWIDTH COMMA for vertical text">.

This module provides functions to transcode between MacChineseSimp and
Unicode, without information loss for every MacChineseSimp character.

=head2 Functions

=over 4

=item C<$wchar = decode($octet)>

=item C<$wchar = decode($handler, $octet)>

=item C<$wchar = decodeMacChineseSimp($octet)>

=item C<$wchar = decodeMacChineseSimp($handler, $octet)>

Converts MacChineseSimp to Unicode.

C<decodeMacChineseSimp()> is an alias for C<decode()> exported by default.

If the C<$handler> is not specified,
any MacChineseSimp character that is not mapped to Unicode is deleted;
if the C<$handler> is a code reference,
a string returned from that coderef is inserted there.
if the C<$handler> is a scalar reference,
a string (a C<PV>) in that reference (the referent) is inserted there.

The 1st argument for the C<$handler> coderef is
a string of the unmapped MacChineseSimp character (e.g. C<"\xFC\xFE">).

=item C<$octet = encode($wchar)>

=item C<$octet = encode($handler, $wchar)>

=item C<$octet = encodeMacChineseSimp($wchar)>

=item C<$octet = encodeMacChineseSimp($handler, $wchar)>

Converts Unicode to MacChineseSimp.

C<encodeMacChineseSimp()> is an alias for C<encode()> exported by default.

If the C<$handler> is not specified,
any Unicode character that is not mapped to MacChineseSimp is deleted;
if the C<$handler> is a code reference,
a string returned from that coderef is inserted there.
if the C<$handler> is a scalar reference,
a string (a C<PV>) in that reference (the referent) is inserted there.

The 1st argument for the C<$handler> coderef is
the Unicode code point (unsigned integer) of the unmapped character.

E.g.

   sub hexNCR { sprintf("&#x%x;", shift) } # hexadecimal NCR
   sub decNCR { sprintf("&#%d;" , shift) } # decimal NCR

   print encodeMacChineseSimp("ABC\x{100}\x{10000}");
   # "ABC"

   print encodeMacChineseSimp(\"", "ABC\x{100}\x{10000}");
   # "ABC"

   print encodeMacChineseSimp(\"?", "ABC\x{100}\x{10000}");
   # "ABC??"

   print encodeMacChineseSimp(\&hexNCR, "ABC\x{100}\x{10000}");
   # "ABC&#x100;&#x10000;"

   print encodeMacChineseSimp(\&decNCR, "ABC\x{100}\x{10000}");
   # "ABC&#256;&#65536;"

=back

=head1 CAVEAT

Sorry, the author is not working on a Mac OS.
Please let him know if you find something wrong.

=head1 AUTHOR

SADAHIRO Tomoyuki <SADAHIRO@cpan.org>

Copyright(C) 2003-2007, SADAHIRO Tomoyuki. Japan. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item Map (external version) from Mac OS Chinese Simplified encoding
to Unicode 3.0 and later (version: c02 2005-Apr-04)

L<http://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/CHINSIMP.TXT>

=item Registry (external version) of Apple use of Unicode corporate-zone
characters (version: c03 2005-Apr-04)

L<http://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/CORPCHAR.TXT>

=back

=cut
