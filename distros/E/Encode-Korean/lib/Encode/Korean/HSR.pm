# Encoding of Korean: Hangeul Society Romanization 1984

# $Id: HSR.pm,v 1.7 2007/11/29 14:25:31 you Exp $

package Encode::Korean::HSR;

our $VERSION = do { q$Revision: 1.7 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };

use 5.008008;

use strict;
use warnings;

use Encode::Encoding;
use base qw(Encode::Encoding);

__PACKAGE__->Define(qw/hsr-1984 hsr1984 hsr/); 

sub import {
	require Encode;
	Encode->export_to_level(1,@_);
}


# == RULES ==
use Encode::Korean::TransliteratorGenerator;
my $hsr = Encode::Korean::TransliteratorGenerator->new();

$hsr->consonants(qw(g gg n d dd l m b bb s ss ng j jj ch k t p h));
$hsr->vowels(qw(a ae ya yae eo e yeo ye o wa wae oe yo u weo we wi yu eu eui i));
$hsr->el('l');
$hsr->ell('ll');
$hsr->naught('.');
$hsr->sep('.');
$hsr->make();


# == MODES ==
$hsr->enmode('greedy');
$hsr->demode('greedy');
sub enmode {
	my $class = shift;
	my($mode) = @_;
	$hsr->enmode($mode);
}

sub demode {
	my $class = shift;
	my($mode) = @_;
	$hsr->demode($mode);
}


# == METHODS ==
# === encode ===
# * encode($string [,$check])
# * Encodes unicode hangul syllables (Perl internal string) 
#   into transliterated (romanized) string
sub encode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $tr = $hsr->encode($str, $chk);
    $_[1] = '' if $chk;
    return $tr;
}

#
# === decode ===
# * decode($octets [,$check])
# * Decodes transliteration into unicode hangul syllables (Perl internal string)
sub decode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $han = $hsr->decode($str, $chk);
    $_[1] = '' if $chk;
    return $han;
}

# === cat_decode ===
# * Needs to work with encoding pragma
# * cat_decode($destination, $octets, $offset, $terminator [,$check])


1;
__END__
=head1 NAME

Encode::Korean::HSR - Perl extension for Encoding of Korean: Hangeul Society
Romanization 1984

=head1 SYNOPSIS

  use Encode::Korean::HSR;

  $string = decode 'hsr', $octets;
  $octets = encode 'hsr', $string;

  while($line = <>) {
    print encode 'utf8', decode 'hsr', $line;
  }

=head1 DESCRIPTION

L<Encode::Korean::HSR|Encode::Korean::HSR> implements an encoding system
of Korean based on the transliteration method of Hangeul Society Romanization,
released in 1984.

This module use Encode implementation base class L<Encode::Encoding|Encode::Encoding>.
The conversion is carried by a transliterator object of 
L<Encode::Korean::TransliteratorGenerator|Encode::Korean::TransliteratorGenerator>.


=head2 RULES

	Unicode name		Transliteration

	kiyeok			g
	ssangkieok		gg
	nieun			n
	tikeut			d
	ssangtikeut		dd
	rieul			r
	mieum			m
	pieup			b
	ssangpieup		bb
	sios			s
	ssangsios		ss
	ieung			ng
	cieuc			j
	ssangcieuc		jj
	chieuch			ch
	khieukh			k
	thieuth			t
	phieuph			p
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
	yi			eui
	i			i


=head1 SEE ALSO

Visit 
L<http://www.hangeul.or.kr> (only in Korean), 
if you are interested in Hangeul Society.

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
