package Encode::ISO2022JP2;

use strict;
use warnings;
use base qw(Encode::ISO2022);
our $VERSION = '0.02';

use Encode::ISOIRSingle;
use Encode::JISLegacy;
use Encode::CN;
use Encode::KR;

__PACKAGE__->Define(
    Alias => qr/\biso-?2022-?jp-?2$/i,
    Name  => 'iso-2022-jp-2',
    CCS   => [
	{   cl       => 1,
	    encoding => 'ascii',
	    g_init   => 'g0',
	    g_seq    => "\e\x28\x42",
	},
	# Japanese
	{   encoding => 'iso-646-jp',
	    g        => 'g0',
	    g_seq    => "\e\x28\x4A",
	    #ss       => '', # encodes runs as short as possible.
	},
	{   bytes    => 2,
	    encoding => 'jis0208-raw',
	    g        => 'g0',
	    g_seq    => "\e\x24\x42",
	    range    => '\x21-\x7E',
	},
	{   bytes    => 2,
	    dec_only => 1,
	    encoding => 'jis-x-0208-1978',
	    g        => 'g0',
	    g_seq    => "\e\x24\x40",
	    range    => '\x21-\x7E',
	},
	{   bytes    => 2,
	    encoding => 'jis-x-0212-ascii',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x44",
	    range    => '\x21-\x7E',
	},
	# European
	{   encoding => 'iso-8859-1-right',
	    g        => 'g2',
	    g_seq    => "\e\x2E\x41",
	    ss       => "\e\x4E",
	},
	{   encoding => 'iso-8859-7-right',
	    g        => 'g2',
	    g_seq    => "\e\x2E\x46",
	    ss       => "\e\x4E",
	},
	# Chinese
	{   bytes    => 2,
	    encoding => 'gb2312-raw',
	    g        => 'g0',
	    g_seq    => "\e\x24\x41",
	    range    => '\x21-\x7E',
	},
	# Korean
	{   bytes    => 2,
	    encoding => 'ksc5601-raw',
	    g        => 'g0',
	    g_seq    => "\e\x24\x28\x43",
	    range    => '\x21-\x7E',
	},
	# Nonstandard
	{   encoding => 'jis-x-0201-right',
	    g        => 'g0',
	    g_seq    => "\e\x28\x49",
	},
    ],
    LineInit => 1,
    SubChar  => "\x{3013}",
);

sub needs_lines { 1 }

1;
__END__

=head1 NAME

Encode::ISO2022JP2 - iso-2022-jp-2 - Extended iso-2022-jp character set

=head1 SYNOPSIS

    use Encode::ISO2022JP2;
    use Encode qw/encode decode/;
    $byte = encode("iso-2022-jp-2", $utf8);
    $utf8 = decode("iso-2022-jp-2", $byte);

=head1 ABSTRACT

This module provides iso2022-jp-2 encoding.

  Canonical       Alias                           Description
  --------------------------------------------------------------
  iso-2022-jp-2   qr/\biso-?2022-?jp-?2$/i        RFC 1554
  --------------------------------------------------------------

=head1 DESCRIPTION

To find out how to use this module in detail, see L<Encode>.

=head2 Note on Implementation

Though RFC 1554 allows designation of JIS X 0201 Latin set at end of the
lines, it also states that such use of non-ASCII is "discouraged".
So by this module, ASCII is always assumed at end of encoded lines.

=head1 SEE ALSO

RFC 1554
I<ISO-2022-JP-2: Multilingual Extension of ISO-2022-JP>.

L<Encode>, L<Encode::JP>, L<Encode::JISX0213>.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji <hatuka(at)nezumi.nu>

=head1 COPYRIGHT

Copyright (C) 2013 Hatuka*nezumi - IKEDA Soji.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

