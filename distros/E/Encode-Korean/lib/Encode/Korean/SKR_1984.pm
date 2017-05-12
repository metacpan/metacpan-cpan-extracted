# Encoding of Korean: South Korean Romanization 1984 

# $Id: SKR_1984.pm,v 1.4 2007/11/29 14:25:31 you Exp $

package Encode::Korean::SKR_1984;

our $VERSION = do { q$Revision: 1.4 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };

use 5.008008;

use strict;
use warnings;

use Encode::Encoding;
use base qw(Encode::Encoding);

__PACKAGE__->Define(qw/skr-1984 skr1984 skr/); 

sub import {
	require Encode;
	Encode->export_to_level(1,@_);
}


# == RULES ==
use Encode::Korean::TransliteratorGenerator;
my $skr = Encode::Korean::TransliteratorGenerator->new();

$skr->consonants(qw(k kk n t tt r m p pp s ss ng ch tch ch' k' t' p' h));
$skr->vowels(
	"a",
	"ae",
	"ya",
	"yae",
	"\x{014F}", # \x{014F} latin small letter o with breve (ŏ)
	"e",
	"y\x{014F}",
	"ye",
	"o",
	"wa",
	"wae",
	"oe",
	"yo",
	"u",
	"wo",
	"we",
	"wi",
	"yu",
	"\x{016D}", # \x{016D} latin small letter u with breve (ŭ)
	"\x{016D}y",
	"i"
	);
$skr->el('l');
$skr->ell('ll');
$skr->naught('-');
$skr->sep('-');
$skr->make();


# == MODES ==
$skr->enmode('greedy');
$skr->demode('greedy');
my $encode_enc = 'utf8';
my $decode_enc = 'utf8';

sub enmode {
	my $class = shift;
	my $mode = shift;
	my $enc = shift;
	unless(defined Encode::find_encoding($enc)) {
		require Carp;
		Carp::croak("Unknown encoding '$enc'");
	}

	$skr->enmode($mode);
	$encode_enc = $enc;
}

sub demode {
	my $class = shift;
	my($mode, $enc) = @_;
	$skr->demode($mode);
	$decode_enc = $enc;
}


# == METHODS ==
# === encode ===
# * encode($string [,$check])
# * Encodes unicode hangul syllables (Perl internal string) 
#   into transliterated (romanized) string
sub encode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $tr = Encode::encode $encode_enc, $skr->encode($str, $chk);
    $_[1] = '' if $chk;
    return $tr;
}

#
# === decode ===
# * decode($octets [,$check])
# * Decodes transliteration into unicode hangul syllables (Perl internal string)
sub decode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $han = $skr->decode(Encode::decode($decode_enc, $str), $chk);
    $_[1] = '' if $chk;
    return $han;
}

# === cat_decode ===
# * Needs to work with encoding pragma
# * cat_decode($destination, $octets, $offset, $terminator [,$check])


1;
__END__
=head1 NAME

Encode::Korean::SKR_1984 - Perl extension for Encoding of Korean: South Korean
Romanization 1984.

=head1 SYNOPSIS

  use Encode::Korean::SKR_1984;

  $string = decode 'skr-1984', $octets;
  $octets = encode 'skr-1984', $string;

  while($line = <>) {
    print encode 'utf8', decode 'skr-1984', $line;
  }

=head1 DESCRIPTION

L<Encode::Korean::SKR_1984|Encode::Korean::SKR_1984> implements an encoding system
of Korean based on the transliteration method of South Korean romanization system,
officially released on January 1, 1984 by South Korean Ministry of Education.

This module use Encode implementation base class L<Encode::Encoding|Encode::Encoding>.
The conversion is carried by a transliterator object of 
L<Encode::Korean::TransliteratorGenerator|Encode::Korean::TransliteratorGenerator>.


=head2 RULES
RR of Korean is basically similar to McCune-Reischaur, but uses only low ascii
characters. In case of ambiguity, orthographic syllable boundaries may be 
indicated with a hyphen.

	Unicode name		Transliteration

	kiyeok			k (g)
	ssangkieok		kk
	nieun			n
	tikeut			t (d)
	ssangtikeut		tt
	rieul			r
	mieum			m
	pieup			p (b)
	ssangpieup		pp
	sios			s (sh)
	ssangsios		ss
	ieung			ng
	cieuc			ch (j)
	ssangcieuc		tch
	chieuch			ch'
	khieukh			k'
	thieuth			t'
	phieuph			p'
	hieuh			h

	a			a
	ae			ae
	ya			ya
	yae			yae
	eo			\x{014F}		(o with breve)
	e			e
	yeo			y\x{014F}
	ye			ye
	o			o
	wa			wa
	wae			wae
	oe			oe
	yo			yo
	u			u
	weo			wo
	we			we
	wi			wi
	yu			yu
	eu			\x{016D}		(u with breve)
	yi			\x{016D}i
	i			i


=head1 SEE ALSO

Visit 
L<http://en.wikipedia.org/wiki/Revised_Romanization_of_Korean>, 
if you need information on Revised Romanization of Korean.
Keep in mind that this module uses the transliteration method,
not the transcription method. 

Visit
L<http://www.alanwood.net/unicode/hangul_jamo.html>,
if you want a list of Hangul Jamo in Unicode.

See
L<Encode|Encode>, 
L<Encode::Encoding|Encode::Encoding>, 
L<Encode::Korean|Encode::Korean>, 
L<Encode::Korean::TransliteratorGenerator|Encode::Korean::TransliteratorGenerator>, 
if you want to know more about relevant modules.

See 
L<Encode::KR|Encode::KR>, 
L<Lingua::KO::MacKorean|Lingua::KO::MacKorean>, 
if you need common encodings.

See
L<Lingua::KO::Romanize::Hangul|Lingua::KO::Romanize::Hangul>, 
if you need a common romanization (transcription method used in public).

=head1 AUTHOR

You Hyun Jo, E<lt>you at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by You Hyun Jo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
