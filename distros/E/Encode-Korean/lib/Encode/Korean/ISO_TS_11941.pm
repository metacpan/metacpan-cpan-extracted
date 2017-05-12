# Encoding of Korean: ISO TS 11941 (formerly, ISO TR 11941)

# $Id: ISO_TS_11941.pm,v 1.6 2007/11/29 14:25:31 you Exp $

package Encode::Korean::ISO_TS_11941;

our $VERSION = do { q$Revision: 1.6 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };

use 5.008008;

use strict;
use warnings;

use Encode::Encoding;
use base qw(Encode::Encoding);

__PACKAGE__->Define(qw/iso-ts-11941 iso-tr-11941/); 

sub import {
	require Encode;
	Encode->export_to_level(1,@_);
}


# == RULES ==
use Encode::Korean::TransliteratorGenerator;
my $iso = Encode::Korean::TransliteratorGenerator->new();

$iso->consonants(qw(k kk n t tt r m p pp s ss ng c cc ch kh th ph h));
$iso->vowels(qw(a ae ya yae eo e yeo ye o wa wae oe yo u weo we wi yu eu yi i));
$iso->el('l');
$iso->ell('ll');
$iso->naught("'");
$iso->sep("'");
$iso->make();


# == MODES ==
$iso->enmode('greedy');
$iso->demode('greedy');
sub enmode {
	my $class = shift;
	my($mode) = @_;
	$iso->enmode($mode);
}

sub demode {
	my $class = shift;
	my($mode) = @_;
	$iso->demode($mode);
}


# == METHODS ==
# === encode ===
# * encode($string [,$check])
# * Encodes unicode hangul syllables (Perl internal string) 
#   into transliterated (romanized) string
sub encode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $tr = $iso->encode($str, $chk);
    $_[1] = '' if $chk;
    return $tr;
}

#
# === decode ===
# * decode($octets [,$check])
# * Decodes transliteration into unicode hangul syllables (Perl internal string)
sub decode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $han = $iso->decode($str, $chk);
    $_[1] = '' if $chk;
    return $han;
}

# === cat_decode ===
# * Needs to work with encoding pragma
# * cat_decode($destination, $octets, $offset, $terminator [,$check])


1;
__END__
=head1 NAME

Encode::Korean::ISO_TS_11941 - Perl extension for Encoding of Korean: ISO TS 11941
(formely, ISO TR 11941)

=head1 SYNOPSIS

  use Encode::Korean::ISO_TS_11941;

  $string = decode 'iso-ts-11941', $octets;
  $octets = encode 'iso-ts-11941', $string;

  while($line = <>) {
		print encode 'utf8', decode 'iso-ts-11941', $line;
  }

=head1 DESCRIPTION

L<Encode::Korean::ISO_TS_11941|Encode::Korean::ISO_TS_11941> implements 
an encoding system of Korean based on the transliteration method of 
ISO TS 11941: 1996, Technical Specification, First Edition 1996-12-01,
Information Documentation -- Transliteration of Korean script into Latin 
Characters.

This module use Encode implementation base class L<Encode::Encoding|Encode::Encoding>.
The conversion is carried by a transliterator object of 
L<Encode::Korean::TransliteratorGenerator|Encode::Korean::TransliteratorGenerator>.


=head2 RULES

	Unicode name		Transliteration

	kiyeok			k
	ssangkieok		kk
	nieun			n
	tikeut			t
	ssangtikeut		tt
	rieul			r
	mieum			m
	pieup			p
	ssangpieup		pp
	sios			s
	ssangsios		ss
	ieung			ng
	cieuc			c
	ssangcieuc		cc
	chieuch			ch
	khieukh			kh
	thieuth			th
	phieuph			ph
	hieuh			h

	a			a
	ae			ae
	ya			ya
	yae			yae
	eo			eo
	e			e
	yeo			yeo
	ye			ye
	o			o
	wa			wa
	wae			wae
	oe			oe
	yo			yo
	u			u
	weo			weo
	we			we
	wi			wi
	yu			yu
	eu			eu
	yi			yi
	i			i


=head1 SEE ALSO

Visit 
L<http://asadal.cs.pusan.ac.kr/hangeul/rom/ts11941/index.html>,
if you need information on ISO TS 11941:1996.

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
