#-*- perl -*-
#-*- coding: us-ascii -*-

package Encode::ShiftJIS2004;

use strict;
use warnings;
use base qw(Encode::Encoding);
our $VERSION = '0.03';

use Carp qw(carp croak);
use Encode::JISX0213::CCS;

my $err_encode_nomap = '"\x{%*v04X}" does not map to %s';
my $err_decode_nomap = '%s "\x%*v02X" does not map to Unicode';

my $DIE_ON_ERR = Encode::DIE_ON_ERR();
my $FB_QUIET = Encode::FB_QUIET();
my $HTMLCREF = Encode::HTMLCREF();
my $LEAVE_SRC = Encode::LEAVE_SRC();
my $PERLQQ = Encode::PERLQQ();
my $RETURN_ON_ERR = Encode::RETURN_ON_ERR();
my $WARN_ON_ERR = Encode::WARN_ON_ERR();
my $XMLCREF = Encode::XMLCREF();

my $name = 'shift_jis-2004';
Encode::define_alias(qr/\bshift.*jis.*2004$/, "\"$name\"");
$Encode::Encoding{$name} = bless {
    Name => $name,
    encoding => $Encode::Encoding{'jis-x-0213-annex1'},
} => __PACKAGE__;

# Workaround for encengine.c which cannot correctly map Unicode sequence
# with multiple characters.
my %composed = (
    "\x{304B}\x{309A}" => "\x82\xF5",
    "\x{304D}\x{309A}" => "\x82\xF6",
    "\x{304F}\x{309A}" => "\x82\xF7",
    "\x{3051}\x{309A}" => "\x82\xF8",
    "\x{3053}\x{309A}" => "\x82\xF9",
    "\x{30AB}\x{309A}" => "\x83\x97",
    "\x{30AD}\x{309A}" => "\x83\x98",
    "\x{30AF}\x{309A}" => "\x83\x99",
    "\x{30B1}\x{309A}" => "\x83\x9A",
    "\x{30B3}\x{309A}" => "\x83\x9B",
    "\x{30BB}\x{309A}" => "\x83\x9C",
    "\x{30C4}\x{309A}" => "\x83\x9D",
    "\x{30C8}\x{309A}" => "\x83\x9E",
    "\x{31F7}\x{309A}" => "\x83\xF6",
    "\x{00E6}\x{0300}" => "\x86\x63",
    "\x{0254}\x{0300}" => "\x86\x67",
    "\x{0254}\x{0301}" => "\x86\x68",
    "\x{028C}\x{0300}" => "\x86\x69",
    "\x{028C}\x{0301}" => "\x86\x6A",
    "\x{0259}\x{0300}" => "\x86\x6B",
    "\x{0259}\x{0301}" => "\x86\x6C",
    "\x{025A}\x{0300}" => "\x86\x6D",
    "\x{025A}\x{0301}" => "\x86\x6E",
    "\x{0301}"         => "\x86\x79",
    "\x{0300}"         => "\x86\x7B",
    "\x{02E5}"         => "\x86\x80",
    "\x{02E9}"         => "\x86\x84",
    "\x{02E9}\x{02E5}" => "\x86\x85",
    "\x{02E5}\x{02E9}" => "\x86\x86",
);
my $composed_re = join '|', reverse sort keys %composed;
my $regexp = qr{\A (.*?) ($composed_re | \z)}osx;

# substitution cacharcter for multibyte.
my $subChar = "\x81\xAC"; # GETA MARK

sub encode {
    my ($self, $utf8, $chk) = @_;
    $chk ||= 0;

    my $chk_sub;
    if (ref $chk eq 'CODE') {
	$chk_sub = $chk;
	$chk = $PERLQQ | $LEAVE_SRC;
    }

    my $str = '';

  CHUNKS:
    while ($utf8 =~ /./os) {
	while ($utf8 =~ s/$regexp//) {
	    my ($chunk, $mc) = ($1, $2);
	    last CHUNKS unless $chunk =~ /./os or $mc =~ /./os;

	    if ($chunk =~ /./os) {
		$str .= $self->{encoding}->encode($chunk, $FB_QUIET);
	    }
	    if ($chunk =~ /./os) {
		$utf8 = $chunk . $mc . $utf8;
		last;
	    }

	    if ($mc =~ /./os) {
		$str .= $composed{$mc};
	    }
	}

	my $errChar = substr($utf8, 0, 1);
	if ($chk & $DIE_ON_ERR) {
	    croak sprintf $err_encode_nomap, '}\x{', $errChar, $self->{Name};
	}
	if ($chk & $WARN_ON_ERR) {
	    carp sprintf $err_encode_nomap, '}\x{', $errChar, $self->{Name};
	}
	if ($chk & $RETURN_ON_ERR) {
	    last;
	}
	# PERLQQ won't be suported to avoid ambiguity of "\x5C".
	if ($chk_sub) {
	    $str .= $chk_sub->(ord $errChar);
	} elsif ($chk & $XMLCREF) {
	    $str .= sprintf '&#x%04X;', ord $errChar;
	} elsif ($chk & $HTMLCREF) {
	    $str .= sprintf '&#%d;', ord $errChar;
	} else {
	    $str .= $subChar;
	}
	substr($utf8, 0, 1) = '';
    } # CHUNKS

    $_[1] = $utf8 unless $chk & $LEAVE_SRC;
    return $str;
}

sub decode {
    my ($self, $str, $chk) = @_;

    my $chk_sub;
    if (ref $chk eq 'CODE') {
	$chk_sub = $chk;
	$chk = $PERLQQ | $LEAVE_SRC;
    }

    my $utf8 = '';

    while (length $str) {
	$utf8 .= $self->{encoding}->decode($str, $FB_QUIET);
	last unless length $str;

	my $errChar;
	if ($str =~ /^([\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC])/) {
	    $errChar = $1;
	} else {
	    $errChar = substr($str, 0, 1);
	}
	if ($chk & $DIE_ON_ERR) {
	    croak sprintf $err_decode_nomap, $self->{Name}, '\x', $errChar;
	}
	if ($chk & $WARN_ON_ERR) {
	    carp sprintf $err_decode_nomap, $self->{Name}, '\x', $errChar;
	}
	if ($chk & $RETURN_ON_ERR) {
	    last;
	}
	substr($str, 0, length $errChar) = '';

	if ($chk_sub) {
	    $utf8 .= join '', map { $chk_sub->(ord $_) } split //, $errChar;
	} elsif ($chk & $PERLQQ) {
	    $utf8 .= sprintf '\x%*v02X', '\x', $errChar;
	} else {
	    $utf8 .= '\x{FFFD}';
	}
    }
    $_[1] = $str unless $chk & $LEAVE_SRC;
    return $utf8;
}

sub mime_name { uc(shift->{Name}) }

1;
__END__

=head1 NAME

Encode::ShiftJIS2004 - shift_jis-2004 - JIS X 0213 Annex 1 encoding

=head1 SYNOPSIS

  use Encode::ShiftJIS2004;
  use Encode qw/encode decode/;
  $bytes = encode("shift_jis-2004", $utf8);
  $utf8 = decode("shift_jis-2004", $bytes);

=head1 ABSTRACT

This module provides followng encoding for JIS X 0213:2004 Annex 1.

  Canonical         Alias                         Description
  --------------------------------------------------------------
  shift_jis-2004    qr/\bshift.*jis.*2004$/i      shift encoding
  --------------------------------------------------------------

=head1 DESCRIPTION

To find out how to use this module in detail,
see L<Encode>.

=head2 Note

This encoding does not keep forward compatibility to C<ascii>
but keeps conformance to the standard,
C<"\x5C"> and C<"\x7E"> are mapped from/to YEN SIGN and OVERLINE;
REVERSE SOLIDUS and TILDE are mapped to/from multibyte sequences.

=head1 SEE ALSO

L<Encode>, L<Encode::JISX0213>.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji <hatuka(at)nezumi.nu>

=head1 COPYRIGHT

Copyright (C) 2013 Hatuka*nezumi - IKEDA Soji.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
