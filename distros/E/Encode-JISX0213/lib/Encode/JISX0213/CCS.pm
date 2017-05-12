#-*- perl -*-
#-*- coding: us-ascii -*-

package Encode::JISX0213::CCS;

use strict;
use warnings;
use base qw(Encode::Encoding);
our $VERSION = '0.03';

use Carp qw(carp croak);
use XSLoader;
XSLoader::load('Encode::JISX0213', $VERSION);

my $err_encode_nomap = '"\x{%*v04X}" does not map to %s';

my $DIE_ON_ERR = Encode::DIE_ON_ERR();
my $FB_QUIET = Encode::FB_QUIET();
my $HTMLCREF = Encode::HTMLCREF();
my $LEAVE_SRC = Encode::LEAVE_SRC();
my $PERLQQ = Encode::PERLQQ();
my $RETURN_ON_ERR = Encode::RETURN_ON_ERR();
my $WARN_ON_ERR = Encode::WARN_ON_ERR();
my $XMLCREF = Encode::XMLCREF();

# Workaround for encengine.c which cannot correctly map Unicode sequence
# with multiple characters.
my %composed = (
    "\x{304B}\x{309A}" => "\x24\x77",
    "\x{304D}\x{309A}" => "\x24\x78",
    "\x{304F}\x{309A}" => "\x24\x79",
    "\x{3051}\x{309A}" => "\x24\x7A",
    "\x{3053}\x{309A}" => "\x24\x7B",
    "\x{30AB}\x{309A}" => "\x25\x77",
    "\x{30AD}\x{309A}" => "\x25\x78",
    "\x{30AF}\x{309A}" => "\x25\x79",
    "\x{30B1}\x{309A}" => "\x25\x7A",
    "\x{30B3}\x{309A}" => "\x25\x7B",
    "\x{30BB}\x{309A}" => "\x25\x7C",
    "\x{30C4}\x{309A}" => "\x25\x7D",
    "\x{30C8}\x{309A}" => "\x25\x7E",
    "\x{31F7}\x{309A}" => "\x26\x78",
    "\x{00E6}\x{0300}" => "\x2B\x44",
    "\x{0254}\x{0300}" => "\x2B\x48",
    "\x{0254}\x{0301}" => "\x2B\x49",
    "\x{028C}\x{0300}" => "\x2B\x4A",
    "\x{028C}\x{0301}" => "\x2B\x4B",
    "\x{0259}\x{0300}" => "\x2B\x4C",
    "\x{0259}\x{0301}" => "\x2B\x4D",
    "\x{025A}\x{0300}" => "\x2B\x4E",
    "\x{025A}\x{0301}" => "\x2B\x4F",
    "\x{0301}"         => "\x2B\x5A",
    "\x{0300}"         => "\x2B\x5C",
    "\x{02E5}"         => "\x2B\x60",
    "\x{02E9}"         => "\x2B\x64",
    "\x{02E9}\x{02E5}" => "\x2B\x65",
    "\x{02E5}\x{02E9}" => "\x2B\x66",
);
my $composed         = join '|', reverse sort keys %composed;
my $composed_legacy  = '[^\x00-\x1F\x7F-\x9F][\x{0300}-\x{036F}\x{309A}]+';
my $prohibited_ascii = '[\x21-\x7E]';
my $prohibited_jis   = '[\x21-\x5B\x{00A5}\x5D-\x7D\x{203E}]';

foreach my $encoding (
    qw/jis-x-0208 jis-x-0208-0213 jis-x-0213-plane1 jis-x-0213-plane1-2000/
) {
    foreach my $alt ('', 'ascii', 'jis') {
	my $name = $encoding . ($alt ? "-$alt" : "");
	my $jisx0213 = ($name =~ /jis-x-0213/) ? 1 : 0;

	my $regexp;
	unless ($jisx0213) {
	    if ($alt eq 'ascii') {
		$regexp = qr{
		    \A (.*?) ($composed_legacy | $prohibited_ascii | \z)
		}osx;
	    } elsif ($alt eq 'jis') {
		$regexp = qr{
		    \A (.*?) ($composed_legacy | $prohibited_jis | \z)
		}osx;
	    } else {
		$regexp = qr{
		    \A (.*?) ($composed_legacy | \z)
		}osx;
	    }
	} else {
	    if ($alt eq 'ascii') {
		$regexp = qr{\A (.*?) ($composed | $prohibited_ascii | \z)}osx;
	    } elsif ($alt eq 'jis') {
		$regexp = qr{\A (.*?) ($composed | $prohibited_jis | \z)}osx;
	    } else {
		$regexp = qr{\A (.*?) ($composed | \z)}osx;
	    }
	}

	$Encode::Encoding{$name} = bless {
	    Name => $name,
	    alt => $alt,
	    encoding => $Encode::Encoding{"$encoding-canonic"},
	    jisx0213 => $jisx0213,
	    regexp => $regexp,
	} => __PACKAGE__;
    }
}

# substitution cacharcter for multibyte.
my $subChar = "\x22\x2E"; # GETA MARK

sub encode {
    my ($self, $utf8, $chk) = @_;

    my $chk_sub;
    if (ref $chk eq 'CODE') {
	$chk_sub = $chk;
	$chk = $LEAVE_SRC;
    }
    my $regexp = $self->{regexp};

    my $str = '';

  CHUNKS:
    while ($utf8 =~ /./os) {
	my $errChar = undef;

	while ($utf8 =~ s/$regexp//) {
	    my ($chunk, $mc) = ($1, $2);
	    last CHUNKS unless $chunk =~ /./os or $mc =~ /./os;

	    if ($chunk =~ /./os) {
		$str .= $self->{encoding}->encode($chunk, $FB_QUIET);
		if ($chunk =~ /./os) {
		    $utf8 = $chunk . $mc . $utf8;
		    last;
		}
	    }

	    unless ($mc =~ /./os) {
		next;
	    } elsif ($self->{jisx0213} and $composed{$mc}) {
		$str .= $composed{$mc};
		next;
	    } else {
		$errChar = $mc;
		$utf8 = $mc . $utf8;
		last;
	    }
	}

	$errChar = substr($utf8, 0, 1) unless defined $errChar;

	if ($chk & $DIE_ON_ERR) {
	    croak sprintf $err_encode_nomap, '}\x{', $errChar, $self->{Name};
	}
	if ($chk & $WARN_ON_ERR) {
	    carp sprintf $err_encode_nomap, '}\x{', $errChar, $self->{Name};
	}
	if ($chk & $RETURN_ON_ERR) {
	    last CHUNKS;
	}

	if ($chk_sub) {
	    $str .= join '', map { $chk_sub->(ord $_) } split //, $errChar;
	} else {
	    $str .= $subChar;
	}
	substr($utf8, 0, length $errChar) = '';
    } # CHUNKS

    $_[1] = $utf8 unless $chk & $LEAVE_SRC;
    return $str;
}

sub decode {
    my ($self, $str, $chk) = @_;

    if ($self->{alt} and not ref $chk) {
	$chk &= ~($PERLQQ | $XMLCREF | $HTMLCREF);
    }
    my $utf8 = $self->{encoding}->decode($str, $chk);
    if ($self->{alt} eq 'ascii') {
	$utf8 =~ s{($prohibited_ascii)}
	    {
		pack 'U', ord($1) + 0xFEE0;
	    }eg;
    } elsif ($self->{alt} eq 'jis') {
	$utf8 =~ s{($prohibited_jis)}
	    {
		my $chr = ord $1;
		if ($chr == 0x00A5) {
		    $chr = 0xFFE5;
		} elsif ($chr == 0x203E) {
		    $chr = 0xFFE3;
		} else {
		    $chr += 0xFEE0;
		}
		pack 'U', $chr;
	    }eg;
    }

    $_[1] = $str unless ref $chk or $chk & $LEAVE_SRC;
    return $utf8;
}

sub perlio_ok { 0 }

1;
__END__

=head1 NAME

Encode::JISX0213::CCS - JIS X 0213 coded character sets

=head1 ABSTRACT

This module provides followng coded character sets.

  reg# Name                    Description
  ----------------------------------------------------------------
   87  jis-x-0208              JIS X 0208-1983, 2nd rev. of JIS X 0208
  168      ditto               JIS X 0208-1990, 3rd rev. of JIS X 0208
       jis-x-0208-ascii
       jis-x-0208-jis
  233  jis-x-0213-plane1       JIS X 0213:2004 level 3 (plane 1)
       jis-x-0213-plane1-ascii
       jis-x-0213-plane1-jis
  228  jis-x-0213-plane1-2000  JIS X 0213:2000 level 3 (plane 1)
       jis-x-0213-plane1-2000-ascii
       jis-x-0213-plane1-2000-jis
  229  jis-x-0213-plane2       JIS X 0213:2000/2004 level 4 (plane 2)

   -   jis-x-0208-0213         Common set of JIS X 0208 and JIS X 0213,
       jis-x-0208-0213-ascii   according to JIS X 0213:2004 Annex 2
       jis-x-0208-0213-jis
  ----------------------------------------------------------------

=head1 DESCRIPTION

To find out how to use this module in detail,
see L<Encode> and L<Encode::ISO2022>.

=head2 Note on Variants

Those suffixed "-ascii" and "-jis" use alternative names for the characters
compatible to ISO/IEC 646 IRV (virtually ASCII) and JIS X 0201 Latin set,
respectively.

=head2 Compatibility

C<jis-x-0208*> include a fallback mapping for HORIZONTAL BAR.
Though it is not normative mapping defined by JIS X 0208,
it is added for compatibility to C<jis0208-raw> encoding in L<Encode::JP>
core module.

However, C<jis-x-0208-0213*> no longer include this mapping.

=head1 SEE ALSO

L<Encode>, L<Encode::ISO2022>, L<Encode::ISO2022::CCS>.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji <hatuka(at)nezumi.nu>

=head1 COPYRIGHT

Copyright (C) 2013, 2015 Hatuka*nezumi - IKEDA Soji.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
