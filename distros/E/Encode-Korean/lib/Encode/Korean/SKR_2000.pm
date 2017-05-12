# Encoding of Korean: South Korean Romanization 2000 
#                     (aka. Revised Romanization of Korean)

# $Id: SKR_2000.pm,v 1.5 2007/11/29 14:25:31 you Exp $

package Encode::Korean::SKR_2000;

our $VERSION = do { q$Revision: 1.5 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };

use 5.008008;

use strict;
use warnings;

use Encode::Encoding;
use base qw(Encode::Encoding);

__PACKAGE__->Define(qw/skr-2000 skr2000 skr/); 

sub import {
	require Encode;
	Encode->export_to_level(1,@_);
}


# == RULES ==
use Encode::Korean::TransliteratorGenerator;
my $coder = Encode::Korean::TransliteratorGenerator->new();

$coder->consonants(qw(g kk n d tt r m b pp s ss ng j jj ch k t p h));
$coder->vowels(qw(a ae ya yae eo e yeo ye o wa wae oe yo u wo we wi yu eu ui i));
$coder->el('l');
$coder->ell('ll');
$coder->naught('-');
$coder->sep('-');
$coder->make();


# == MODES ==
$coder->enmode('greedy');
$coder->demode('greedy');
sub enmode {
	my $class = shift;
	my($mode) = @_;
	$coder->enmode($mode);
}

sub demode {
	my $class = shift;
	my($mode) = @_;
	$coder->demode($mode);
}


# == METHODS ==
# === encode ===
# * encode($string [,$check])
# * Encodes unicode hangul syllables (Perl internal string) 
#   into transliterated (romanized) string
sub encode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $tr = $coder->encode($str, $chk);
    $_[1] = '' if $chk;
    return $tr;
}

#
# === decode ===
# * decode($octets [,$check])
# * Decodes transliteration into unicode hangul syllables (Perl internal string)
sub decode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $han = $coder->decode($str, $chk);
    $_[1] = '' if $chk;
    return $han;
}

# === cat_decode ===
# * Needs to work with encoding pragma
# * cat_decode($destination, $octets, $offset, $terminator [,$check])


1;
__END__
=head1 NAME

Encode::Korean::SKR_2000 - Perl extension for Encoding of Korean: South Korean
Romanization 2000.

=head1 SYNOPSIS

  use Encode::Korean::SKR_2000;

  $string = decode 'skr-2000', $octets;
  $octets = encode 'skr-2000', $string;

  while($line = <>) {
    print encode 'utf8', decode 'skr-2000', $line;
  }

=head1 DESCRIPTION

L<Encode::Korean::SKR_2000|Encode::Korean::SKR_2000> implements an encoding system
of Korean based on the transliteration method of South Korean romanization system,
officially released on July 7, 2000 by South Korean Ministry of Culture and Tourism 
(aka. Revised Romanization of Korean)

This module use Encode implementation base class L<Encode::Encoding|Encode::Encoding>.
The conversion is carried by a transliterator object of 
L<Encode::Korean::TransliteratorGenerator|Encode::Korean::TransliteratorGenerator>.


=head2 RULES
RR of Korean is basically similar to McCune-Reischaur, but uses only low ascii
characters. In case of ambiguity, orthographic syllable boundaries may be 
indicated with a hyphen.

	Unicode name		Transliteration

	kiyeok			g
	ssangkieok		kk
	nieun			n
	tikeut			d
	ssangtikeut		tt
	rieul			r
	mieum			m
	pieup			b
	ssangpieup		pp
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
	weo			wo
	we			we
	wi			wi
	yu			yu
	eu			eu
	yi			ui
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
