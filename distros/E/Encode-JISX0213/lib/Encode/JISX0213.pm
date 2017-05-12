#-*- perl -*-
#-*- coding: utf-8 -*-

package Encode::JISX0213;

use strict;
use warnings;
use base qw(Encode::ISO2022);
our $VERSION = '0.04';

use Encode::ISOIRSingle;
use Encode::JISLegacy;
use Encode::JISX0213::CCS;

__PACKAGE__->Define(
    Alias => qr/\beuc-?(jis|jp)-?2004$/i,
    Name  => 'euc-jis-2004',
    CCS   => [
	{   cl       => 1,
	    encoding => 'ascii',
	    g_init   => 'g0',
	},
	{encoding => 'c1-ctrl',},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane1-ascii',
	    gr       => 1,
	    g_init   => 'g1',
	    range    => '\xA1-\xFE',
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane2',
	    gr       => 1,
	    g_init   => 'g3',
	    ss       => "\x8F",
	    range    => '\xA1-\xFE',
	},

	# Unrecommended encodings
	{   encoding => 'jis-x-0201-right',
	    gr       => 1,
	    g_init   => 'g2',
	    ss       => "\x8E",
	},

	# Nonstandard
	{   bytes    => 2,
	    encoding => 'jis-x-0212-ascii',
	    gr       => 1,
	    g_init   => 'g3',
	    ss       => "\x8F",
	    range    => '\xA1-\xFE',
	},
    ],
    SubChar => "\x{3013}",
);

Encode::define_alias(qr/\beucjisx0213$/i              => '"euc-jisx0213"');
Encode::define_alias(qr/\beuc.*jp[ \-]?(?:2000|2k)$/i => '"euc-jisx0213"');
Encode::define_alias(qr/\bjp.*euc[ \-]?(2000|2k)$/i   => '"euc-jisx0213"');
Encode::define_alias(qr/\bujis[ \-]?(?:2000|2k)$/i    => '"euc-jisx0213"');
__PACKAGE__->Define(
    Name  => 'euc-jisx0213',
    CCS   => [
	{   cl       => 1,
	    encoding => 'ascii',
	    g_init   => 'g0',
	},
	{encoding => 'c1-ctrl',},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane1-2000-ascii',
	    gr       => 1,
	    g_init   => 'g1',
	    range    => '\xA1-\xFE',
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane2',
	    gr       => 1,
	    g_init   => 'g3',
	    ss       => "\x8F",
	    range    => '\xA1-\xFE',
	},

	# Unrecommended encodings
	{   encoding => 'jis-x-0201-right',
	    gr       => 1,
	    g_init   => 'g2',
	    ss       => "\x8E",
	},

	# Nonstandard
	{   bytes    => 2,
	    encoding => 'jis-x-0212-ascii',
	    gr       => 1,
	    g_init   => 'g3',
	    ss       => "\x8F",
	    range    => '\xA1-\xFE',
	},
    ],
    SubChar => "\x{3013}",
);

__PACKAGE__->Define(
    Alias => qr/\biso-?2022-?jp-?2004$/i,
    Name  => 'iso-2022-jp-2004',
    CCS   => [
	{   cl       => 1,
	    encoding => 'ascii',
	    g_init   => 'g0',
	    g_seq    => "\e\x28\x42",
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane1-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x51",
	    range    => '\x21-\x7E',
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane2',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x50",
	    range    => '\x21-\x7E',
	},

	# Unrecommended encodings.
	{   bytes    => 2,
	    dec_only => 1,
	    encoding => 'jis-x-0213-plane1-2000-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x4F",
	    range    => '\x21-\x7E',
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0208-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x42",
	    ss       => '', # encodes runs as short as possible
	    range    => '\x21-\x7E',
	},

	# Nonstandard
    ],
    SubChar => "\x{3013}",
);

__PACKAGE__->Define(
    Alias => qr/\biso-?2022-?jp-?2004-?strict$/i,
    Name  => 'x-iso2022jp2004-strict',
    CCS   => [
	{   cl       => 1,
	    encoding => 'ascii',
	    g_init   => 'g0',
	    g_seq    => "\e\x28\x42",
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0208-0213-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x42",
	    range    => '\x21-\x7E',
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane1-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x51",
	    ss       => '', # encodes runs as short as possible
	    range    => '\x21-\x7E',
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane2',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x50",
	    range    => '\x21-\x7E',
	},

	# Unrecommended encodings.
	{   bytes    => 2,
	    dec_only => 1,
	    encoding => 'jis-x-0213-plane1-2000-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x4F",
	    range    => '\x21-\x7E',
	},

	# Nonstandard
    ],
    SubChar => "\x{3013}",
);

__PACKAGE__->Define(
    Alias => qr/\biso-?2022-?jp-?2004-?compatible$/i,
    Name  => 'x-iso2022jp2004-compatible',
    CCS   => [
	{   cl       => 1,
	    encoding => 'ascii',
	    g_init   => 'g0',
	    g_seq    => "\e\x28\x42",
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0208-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x42",
	    range    => '\x21-\x7E',
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane1-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x51",
	    ss       => '', # encodes runs as short as possible
	    range    => '\x21-\x7E',
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane2',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x50",
	    range    => '\x21-\x7E',
	},

	# Unrecommended encodings.
	{   bytes    => 2,
	    dec_only => 1,
	    encoding => 'jis-x-0213-plane1-2000-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x4F",
	    range    => '\x21-\x7E',
	},

	# Nonstandard
    ],
    SubChar => "\x{3013}",
);

__PACKAGE__->Define(
    Alias => qr/\biso-?2022-?jp-?3$/i,
    Name  => 'iso-2022-jp-3',
    CCS   => [
	{   cl       => 1,
	    encoding => 'ascii',
	    g_init   => 'g0',
	    g_seq    => "\e\x28\x42",
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane1-2000-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x4F",
	    range    => '\x21-\x7E',
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0213-plane2',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x50",
	    range    => '\x21-\x7E',
	},

	# Unrecommended encoding.
	{   bytes    => 2,
	    encoding => 'jis-x-0208-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x42",
	    ss       => '', # encodes runs as short as possible
	    range    => '\x21-\x7E',
	},

	# Nonstandard
    ],
    SubChar => "\x{3013}",
);

sub needs_lines { 1 }

1;
__END__

=encoding utf-8

=head1 NAME

Encode::JISX0213 - JIS X 0213 encodings

=head1 SYNOPSIS

    use Encode::JISX0213;
    use Encode qw/encode decode/;
    $byte = encode("iso-2022-jp-2004", $utf8);
    $utf8 = decode("iso-2022-jp-2004", $byte);

=head1 ABSTRACT

This module provides following encodings.

  Canonical         Alias                         Description
  --------------------------------------------------------------
  euc-jis-2004      qr/\beuc-?(jis|jp)-?2004$/i   8-bit encoding
  iso-2022-jp-2004  qr/\biso-?2022-?jp-?2004$/i   7-bit encoding
  --------------------------------------------------------------

=over

=item *

About "shift encoding" see L<Encode::ShiftJIS2004>.

=back

Additionally, it provides encodings for older revision, JIS X 0213:2000:

  Canonical         Alias                         Description
  --------------------------------------------------------------
  euc-jisx0213      qr/\beucjisx0213$/i           8-bit encoding
                    qr/\beuc.*jp[ \-]?(?:2000|2k)$/i
                    qr/\bjp.*euc[ \-]?(2000|2k)$/i
                    qr/\bujis[ \-]?(?:2000|2k)$/i
  iso-2022-jp-3     qr/\biso-?2022-?jp-?3$/i      7-bit encoding
  --------------------------------------------------------------

and for transition from legacy standards:

  Canonical         Alias                         Description
  --------------------------------------------------------------
  x-iso2022jp2004-compatible                      See note.
                    qr/\biso-?2022-?jp-?2004-?compatible$/i
  x-iso2022jp2004-strict                          See note.
                    qr/\biso-?2022-?jp-?2004-?strict$/i
  --------------------------------------------------------------

=head1 DESCRIPTION

To find out how to use this module in detail, see L<Encode>.

=head2 Notes on Compatibility

To encode Unicode string to byte string,
C<x-iso2022jp2004-strict> uses JIS X 0208 as much as possible,
strictly conforming to JIS X 0213:2004 Annex 2.
It is compatible to other encodings.

C<x-iso2022jp2004-compatible> uses JIS X 0208 for the bit combinations
co-existing on JIS X 0208 and JIS X 0213 plane 1.
It is I<not> compatible to other encodings;
it had never been registered by any standards bodies.

However, to decode byte string to Unicode string,
encodings in the tables above
accept arbitrary sequences of both JIS X 0208 and JIS X 0213.
Exception is C<x-iso2022jp2004-strict>:
It accepts only allowed JIS X 0208 sequences.

C<euc-jis-2004> and C<euc-jisx0213> contains JIS X 0213 plane 2 along with
JIS X 0212 in G3.
By this non-standard extension, they have forward compatibility with
EUC-JP (AJEC) in case of decoding.

=head2 Comparison with Other Modules

L<Encode::JIS2K> provides C<euc-jisx0213>, C<iso-2022-jp-3> and
C<shift_jisx0213> encodings.
C<euc-jp> in L<Encode::JP> 1.64 or later can decode C<euc-jisx0213>
sequences.
They support earlier revision of standard, and lack function to encode
sequences with multiple Unicode characters such as
katakana with semi-voiced sound mark.

L<ShiftJIS::X0213::MapUTF> provides C<shift_jisx0213> and C<shift_jis-2004>.
It does not provide interface to contemporary L<Encode> module.

=head1 SEE ALSO

JIS X 0213:2000
I<7ビット及び8ビットの2バイト情報交換用符号化拡張漢字集合>
(I<7-bit and 8-bit double byte coded extended KANJI sets for information
interchange>),
and its amendment JIS X 0213:2000/Amd.1:2004.

L<Encode>, L<Encode::JP>, L<Encode::ShiftJIS2004>.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji <hatuka(at)nezumi.nu>

=head1 COPYRIGHT

Copyright (C) 2013, 2015 Hatuka*nezumi - IKEDA Soji.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
