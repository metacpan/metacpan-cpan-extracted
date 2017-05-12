package Lingua::ZH::MacChinese::Traditional;

require 5.006001;

use strict;

require Exporter;
require DynaLoader;

our $VERSION = '0.20';
our @ISA = qw(Exporter DynaLoader);
our @EXPORT = qw(decodeMacChineseTrad encodeMacChineseTrad);
our @EXPORT_OK = qw(decode encode);

bootstrap Lingua::ZH::MacChinese::Traditional $VERSION;
1;
__END__

=head1 NAME

Lingua::ZH::MacChinese::Traditional - transcoding between Mac OS Chinese
Traditional encoding and Unicode

=head1 SYNOPSIS

(1) using function names exported by default:

    use Lingua::ZH::MacChinese::Traditional;
    $wchar = decodeMacChineseTrad($octet);
    $octet = encodeMacChineseTrad($wchar);

(2) using function names exported on request:

    use Lingua::ZH::MacChinese::Traditional qw(decode encode);
    $wchar = decode($octet);
    $octet = encode($wchar);

(3) using function names fully qualified:

    use Lingua::ZH::MacChinese::Traditional ();
    $wchar = Lingua::ZH::MacChinese::Traditional::decode($octet);
    $octet = Lingua::ZH::MacChinese::Traditional::encode($wchar);

   # $wchar : a string in Perl's Unicode format
   # $octet : a string in Mac OS Chinese Traditional encoding

=head1 DESCRIPTION

This module provides transcoding from/to
Mac OS Chinese Traditional encoding (denoted MacChineseTrad hereafter).

In order to ensure roundtrip mapping, MacChineseTrad encoding
has some characters with mapping from a single MacChineseTrad character
to a sequence of Unicode characters and vice versa.
Such characters include C<0x80> (MacChineseTrad) from/to
C<0x005C+0xF87F> (Unicode) for C<"REVERSE SOLIDUS, alternate">.

This module provides functions to transcode between MacChineseTrad and
Unicode, without information loss for every MacChineseTrad character.

=head2 Functions

=over 4

=item C<$wchar = decode($octet)>

=item C<$wchar = decode($handler, $octet)>

=item C<$wchar = decodeMacChineseTrad($octet)>

=item C<$wchar = decodeMacChineseTrad($handler, $octet)>

Converts MacChineseTrad to Unicode.

C<decodeMacChineseTrad()> is an alias for C<decode()> exported by default.

If the C<$handler> is not specified,
any MacChineseTrad character that is not mapped to Unicode is deleted;
if the C<$handler> is a code reference,
a string returned from that coderef is inserted there.
if the C<$handler> is a scalar reference,
a string (a C<PV>) in that reference (the referent) is inserted there.

The 1st argument for the C<$handler> coderef is
a string of the unmapped MacChineseTrad character (e.g. C<"\xFC\xFE">).

=item C<$octet = encode($wchar)>

=item C<$octet = encode($handler, $wchar)>

=item C<$octet = encodeMacChineseTrad($wchar)>

=item C<$octet = encodeMacChineseTrad($handler, $wchar)>

Converts Unicode to MacChineseTrad.

C<encodeMacChineseTrad()> is an alias for C<encode()> exported by default.

If the C<$handler> is not specified,
any Unicode character that is not mapped to MacChineseTrad is deleted;
if the C<$handler> is a code reference,
a string returned from that coderef is inserted there.
if the C<$handler> is a scalar reference,
a string (a C<PV>) in that reference (the referent) is inserted there.

The 1st argument for the C<$handler> coderef is
the Unicode code point (unsigned integer) of the unmapped character.

E.g.

   sub hexNCR { sprintf("&#x%x;", shift) } # hexadecimal NCR
   sub decNCR { sprintf("&#%d;" , shift) } # decimal NCR

   print encodeMacChineseTrad("ABC\x{100}\x{10000}");
   # "ABC"

   print encodeMacChineseTrad(\"", "ABC\x{100}\x{10000}");
   # "ABC"

   print encodeMacChineseTrad(\"?", "ABC\x{100}\x{10000}");
   # "ABC??"

   print encodeMacChineseTrad(\&hexNCR, "ABC\x{100}\x{10000}");
   # "ABC&#x100;&#x10000;"

   print encodeMacChineseTrad(\&decNCR, "ABC\x{100}\x{10000}");
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

=item Map (external version) from Mac OS Chinese Traditional encoding
to Unicode 2.1 and later (version: c02 2005-Apr-04)

L<http://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/CHINTRAD.TXT>

=item Registry (external version) of Apple use of Unicode corporate-zone
characters (version: c03 2005-Apr-04)

L<http://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/CORPCHAR.TXT>

=back

=cut
