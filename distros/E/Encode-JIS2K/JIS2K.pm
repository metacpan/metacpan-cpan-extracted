package Encode::JIS2K;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.03 $ =~ /(\d+)/g;

use Encode;
use XSLoader;
XSLoader::load(__PACKAGE__,$VERSION);

use Encode::JIS2K::2022JP3;

Encode::define_alias(qr/\beuc.*jp[ \-]?(?:2000|2k)$/i => '"euc-jisx0213"');
Encode::define_alias(qr/\bjp.*euc[ \-]?(2000|2k)$/i   => '"euc-jisx0213"');
Encode::define_alias(qr/\bujis[ \-]?(?:2000|2k)$/i    => '"euc-jisx0213"');

Encode::define_alias(qr/\bshift.*jis(?:2000|2k)$/i    => '"shiftjisx0213"');
Encode::define_alias(qr/\bsjisp \-]?(?:2000|2k)$/i    => '"shiftjisx0213"');


1;
__END__

=head1 NAME

Encode::JIS2K - JIS X 0212 (aka JIS 2000) Encodings

=head1 SYNOPSIS

  use Encode::JIS2K;
  use Encode qw/encode decode/;
  $euc_2k = encode("euc-jisx0213", $utf8);
  $utf8   = decode("euc-jisx0213", $euc_jp);

=head1 ABSTRACT

This module implements encodings that covers JIS X 0213 charset (AKA
JIS 2000, hence the module name).  Encodings supported are as follows.

  Canonical     Alias                                      Description
  --------------------------------------------------------------------
  euc-jisx0213  qr/\beuc.*jp[ \-]?(?:2000|2k)$/i          EUC-JISX0213 
                qr/\bjp.*euc[ \-]?(2000|2k)$/i 
                qr/\bujis[ \-]?(?:2000|2k)$/i
  shiftjisx0123 qr/\bshift.*jis(?:2000|2k)$/i           Shift_JISX0213
                qr/\bsjisp \-]?(?:2000|2k)$/i

  iso-2022-jp-3
  jis0213-1-raw                         JIS X 0213 plane 1, raw format
  jis0213-2-raw                         JIS X 0213 plane 2, raw format
  --------------------------------------------------------------------

=head1 DESCRIPTION

To find out how to use this module in detail, see L<Encode>.

=head1 what is JIS X 0213 anyway?

Simply put, JIS X 0213 is a rework and reorganization of JIS X 0208
and JIS X 0212.  They consist of two 94x94 planes which roughly
corrensponds as follows;

  JIS X 0213 Plane 1 = JIS X 0208 + extension
  JIS X 0213 Plane 2 = JIS X 0212 reorganized + extension

And here is the character repertoire there of at a glance.

          # of codepoints     Kuten Ku (rows) used
  --------------------------------------------------------
  JIS X 0208         6,879    1..8,16..83 
  JIS X 0213-1       8,762    1..94 (all!)
  JIS X 0212         6,067    2,6..7,9..11,16..77
  JIS X 0213-2       2,436    1,3..5,8,12..15,78..94
  -------------------------------------------------------
  (JIS X0213 Total) 11,197

JIS X 0213 was designed to extend JIS X 0208 and JIS X 0212 without
being imcompatible to (classic) EUC-JP and Shift_JIS.  The following
characteristics are as a result thereof.

=over 2

=item *

JIS X plane 1 is (almost) a superset of JIS X 0208.  However, with
Unicode 3.2.0 the mappings differ in 3 codepoints.

  Kuten   JIS X 0208 -> Unicode         JIS X 0213 -> Unicode 
  --------------------------------------------------------------
  1-1-17  <UFFE3> # FULLWIDTH MACRON    <U203E> # OVERLINE
  1-1-29  <U2014> # EM DASH             <U2015> # HORIZONTAL BAR
  1-1-79  <UFFE5> # FULLWIDTH YEN SIGN  <U00A5> # YEN SIGN          

=item *

By the same token, JIS X 0213 plane 2 contains JIS Dai-4 Suijun Kanji
(JIS Kanji Repertoire Level 4).  This allows EUC-JP's G3 to contain
both JIS X 0212 and JIS 0213 plane 2.

However, JIS X 0212:1990 already contains many of Dai-4 Suijun Kanji
so EUC's G3 is subject to containing duplicate mappings. 

=item *

Because of Halfwidth Katakana, Shift_JIS mapping has been tricky and
it is even trickier.  Here is a regex that matches Shift_JISX0213
sequence (note: you have to "use bytes" to make it work!)

  $re_valid_shifjisx0213 = 
    qr/^(?:
         [\x00-\x7f] |                            # ASCII or
	 [\xa1-\xdf] |                            # JIS X 0201 KANA or
         [\x81-\x9f\xe0-\xfc][\x40-\x7e\x80-\xfc] # JIS X 0213
         )+$/xo;

=back

=head2 Note on EUC-JISX0213 (vs. EUC-JP)

As of Encode-1.64, 'euc-jp' does support euc-jisx0213 for decoding.
However, 'euc-jp' in Encode and 'euc-jisx0213' differ as follows;

                    euc-jp                   euc-jisx0213
  --------------------------------------------------------------
  Decodes....       (0201-K|0208|0212|0213)  ditto
  Round-Trip  (|0)  (020-K|0208|0212)        JIS X (0201-K|0213)
  Decode Only (|3)  those only found in 0213   
                                        those only found in 0212
  --------------------------------------------------------------

=head1 AUTHORS

Dan Kogai E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT

Copyright 2002 by Dan Kogai E<lt>dankogai@dan.co.jpE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

L<Encode>, L<Encode::JP>

Japanese Graphic Character Set for Information Interchange -- Plane 1 
L<http://www.itscj.ipsj.or.jp/ISO-IR/228.pdf>

Japanese Graphic Character Set for Information Interchange -- Plane 2
L<http://www.itscj.ipsj.or.jp/ISO-IR/229.pdf>

=cut
