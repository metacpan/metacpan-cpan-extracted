# Encodings of Korean

# $Id: Korean.pm,v 1.9 2007/11/29 14:29:53 you Exp $

package Encode::Korean;

use 5.008008;

use strict;
use warnings;

our $VERSION = do { q$Revision: 1.9 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };

sub import {
	if ( defined $_[1] and $_[1] eq ':modes') {
		require Exporter;
		our @ISA = qw(Exporter);
		our @EXPORT_OK = qw(enmode demode);
		__PACKAGE__->export_to_level(1, $_[0], 'enmode', 'demode');
		splice @_, 1, 1;
	}

	require Encode;
	Encode->export_to_level(1, @_);
}

# = transliteration-based encodings =

use Encode::Korean::ISO_TS_11941; # ISO TS 11941
use Encode::Korean::SKR_2000; # South Korean Romanization 2000
use Encode::Korean::SKR_1984; # South Korean Romanization 1984
use Encode::Korean::SKR_1959; # South Korean Romanization 1959
use Encode::Korean::NKR_1992; # North Korean Romanization 1992
use Encode::Korean::MRR;	  # McCune-Reischauer
use Encode::Korean::Yale;	  # Yale romanization for Korean
use Encode::Korean::SKATS;    # Standard Korean Alphabet Transliteration System
use Encode::Korean::HSR;	  # Hangeul Society Romanization 1984


# = modes =

sub enmode($@) {
	my $enc = shift;
	my $obj = Encode::find_encoding($enc);

	unless (defined $obj) {
		require Carp;
		Carp::croak("Unknown encoding '$enc'");
	}
	$obj->enmode(@_);
}

sub demode($@) {
	my $enc = shift;
	my $obj = Encode::find_encoding($enc);

	unless (defined $obj) {
		require Carp;
		Carp::croak("Unknown encoding '$enc'");
	}
	$obj->demode(@_);

}

1;
__END__

=head1 NAME

Encode::Korean - Perl extension for Encodings of Korean Language 

=head1 SYNOPSIS

  use Encode::Korean;

  while($line = <>) {
    print encode 'utf8', decode $enc, $line;
  }

=head1 AKNOWLEDGEMENT

Thanks to Otakar Smrz, who wrote Encode::Arabic module, which inspired
me with the 'philosophy' of Encode::Encoding module and the idea of
mode system.

=head1 DESCRIPTION

This module is a wrapper for Korean encoding modules. 

=head2 ENCODINGS BASED ON TRANSLITERATION

=head3 NOTE or WARNING

The provided transliteration is NOT a public romanization nor phonemic 
transcription, BUT a scientific romanization or letter-to-letter 
transliteration. It DOES NOT take into account morphophonemic changes 
nor natural pronunciations, BUT DOES reflect closely the original hangul 
orthography and make the reverse transliteration possible.

If you're looking for a general romanizer (that does 'transcription'), 
this module is not the one you want.

=head3 IMPLEMENTATION

These encodings are implemented by using 
L<Encode::Korean::TransliteratorGenerator> class
which generates transliteration-based encoding objects.
It makes you easily write a new transliteration-based encoding module 
or just convert Korean script into something, for example, 
into Cyrillic, IPA, or Greek. 

=head3 LIST OF ENCODINGS

=over

=item ISO_TS_11941 

L<Encode::Korean::ISO_TS_11941|Encode::Korean::ISO_TS_11941> implements 
an encoding system based on the transliteration method of 
ISO TS 11941: 1996, Technical Specification, First Edition 1996-12-01,
Information Documentation -- Transliteration of Korean script into Latin 
Characters.

=item SKR_2000

L<Encode::Korean::SKR_2000|Encode::Korean::SKR_2000> implements an encoding system
based on South Korean romanization system,
officially released on July 7, 2000 by South Korean Ministry of Culture and Tourism (aka. Revised Romanization of Korean)

=item SKR_1984

L<Encode::Korean::SKR_1984|Encode::Korean::SKR_1984> implements an encoding system
based on South Korean romanization system,
officially released on January 1, 1984 by South Korean Ministry of Education.

It is not ideal for encodings, since it uses non-ASCII characters: 
latin small letter o with breve (\x{014F})
and latin small letter u with breve (\x{016D}).

=item SKR_1959

L<Encode::Korean::SKR_1959|Encode::Korean::SKR_1959> implements an encoding system
based on South Korean romanization system, officially released in 1959 
by South Korean Ministry of Education.

=item NKR_1992

L<Encode::Korean::NKR_1992> implements an encoding system based on North Korean 
Romanizaiton (National system of DPKR), released in 1992 by Chosun Gwahagwon.

It is not ideal for encodings, since it uses non-ASCII characters. 

=item HSR

L<Encode::Korean::HSR|Encode::Korean::HSR> implements an encoding system
based on the transliteration method of Hangeul Society Romanization,
released in 1984.

=item MRR

L<Encode::Korean::MRR> implements an encoding system based on McCune-Reischauer
Romanization, created in 1937 by George M. McCune and Edwin O. Reischauer. It
is the most widely used method outside of Koreas.

It is not ideal for encodings, since it uses non-ASCII characters.

=item Yale

L<Encode::Korean::Yale|Encode::Korean::Yale> implements an encoding system
of Korean based on the transliteration method of Yale Romanization for
Korean Language, developed by S. Martin and his colleagues at Yale University.

=item SKATS

L<Encode::Korean::SKATS|Encode::Korean::SKATS> implements an encoding system
of Korean based on SKATS (Standar Korean Alphabet Transliteration System).
It is not a true romaniztion (transliteration). SKATS maps Hangul Jamos
to Latin alphabet equivalents as Morse code. It doesn't care about linguistic
knowledge but can be perfectly recoverd to original Korean letters.


=back

=head2 EXPORTS & MODES

Mode system is introduced but not implemented yet for real usage. The idea
of modes is taken from L<Encode::Arabic>. Refer to it for instruction.

=head1 SEEALSO

See 
 L<Encode::KR>,
 L<Lingua::KO::MacKorean>, 
 if you are looking for common (two byte) encodings used in South Korea.

See 
 L<Lingua::KO::Romanize::Hangul>,
 if you are looking for common romanization module of Korean.

See
 L<http://en.wikipedia.org/wiki/Korean_romanization>, 
 L<http://www.eki.ee/wgrs/rom2_ko.htm>
 for more information about romanization of Korean.
 
See
 L<http://www.kawa.net/works/ajax/romanize/hangul-e.html>,
 for online romanization.

=head1 AUTHOR

You Hyun Jo, E<lt>you at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by You Hyun Jo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


