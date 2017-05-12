# Encoding of Korean: SKATS (Standard Korean Alphabet Transliteration System)

# $Id: SKATS.pm,v 1.7 2007/11/29 14:25:31 you Exp $

package Encode::Korean::SKATS;

our $VERSION = do { q$Revision: 1.7 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };


use 5.008008;

use strict;
use warnings;

use Encode::Encoding;
use base qw(Encode::Encoding);

__PACKAGE__->Define(qw/skats/); 

sub import {
	require Encode;
	Encode->export_to_level(1,@_);
}


# == RULES ==
use Encode::Korean::TransliteratorGenerator;
my $skats = Encode::Korean::TransliteratorGenerator->new();

$skats->consonants(qw(L LL F B BB V M W WW G GG K P PP C X Z O J));
$skats->vowels(qw(E EU I US T TU S SU A AE AEU AU N H HT HTU HU R D DU U));
#$skats->el('l');
#$skats->ell('ll');
$skats->naught('');
$skats->sep(' ');
$skats->make();

$skats->enmode('greedy');
$skats->demode('greedy');


# == MODES ==
sub enmode {
	my $class = shift;
	my($mode) = @_;
	$skats->enmode($mode);
}

sub demode {
	my $class = shift;
	my($mode) = @_;
	$skats->demode($mode);
}


# == METHODS ==
# === encode ===
# * encode($string [,$check])
# * Encodes unicode hangul syllables (Perl internal string) 
#   into transliterated (romanized) string
sub encode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $tr;
	 my @word = split(/([ ]+)/, $str);
	 foreach (@word) {
		if ($_ =~ m/([ ]+)/) { 
			$tr = $tr . $1 . ' '; 
		} else { 
			$tr = $tr . $skats->encode($_, $chk);	
		}
	 }
    $_[1] = '' if $chk;
    return $tr;
}

#
# === decode ===
# * decode($octets [,$check])
# * Decodes transliteration into unicode hangul syllables (Perl internal string)
sub decode ($$;$) {
   my ($obj, $str, $chk) = @_;
	my $han;
	my @word = split(/([ ][ ]+)/, $str);
	foreach (@word) {
		if ($_ =~ m/[ ]([ ]+)/) {
			$han = $han . $1;
		} else {
			$han = $han . $skats->decode($_, $chk);
		}
	}
   $_[1] = '' if $chk;
   return $han;
   
}

# === cat_decode ===
# * Needs to work with encoding pragma
# * cat_decode($destination, $octets, $offset, $terminator [,$check])


1;
__END__
=utf8
=head1 NAME

Encode::Korean::SKATS - Perl extension for Encoding of Korean: SKATS

=head1 SYNOPSIS

  use Encode::Korean::SKATS;

  $string = decode 'skats', $octets;
  $octets = encode 'skats', $string;

  while($line = <>) {
    print encode 'utf8', decode 'skats', $line;
  }

=head1 DESCRIPTION

L<Encode::Korean::SKATS|Encode::Korean::SKATS> implements an encoding system
of Korean based on SKATS (Standar Korean Alphabet Transliteration System).

This module use Encode implementation base class L<Encode::Encoding|Encode::Encoding>.
The conversion is carried by a transliterator object of 
L<Encode::Korean::TransliteratorGenerator|Encode::Korean::TransliteratorGenerator>.


=head2 RULES

	Unicode name		Transliteration

	kiyeok			L
	ssangkieok		LL
	nieun			F
	tikeut			B
	ssangtikeut		BB
	rieul			V
	mieum			M
	pieup			W
	ssangpieup		WW
	sios			G
	ssangsios		GG
	ieung			K
	cieuc			P
	ssangcieuc		PP
	chieuch			C	
	khieukh			X
	thieuth			Z
	phieuph			O
	hieuh			J

	a			E
	ae			EU
	ya			I
	yae			US
	eo			T
	e			TU
	yeo			S	
	ye			SU
	o			A
	wa			AE
	wae			AEU
	oe			AU
	yo			N
	u			H
	weo			HT
	we			HTU
	wi			HU
	yu			R
	eu			D
	yi			DU
	i			D

* Put one space between syllables and two spaces between words.

=head2 EXAMPLES

 SKATS = "PU LH VDV  PU XS VE!"

=head1 SEE ALSO

Visit 
L<http://en.wikipedia.org/wiki/SKATS>,
for more information about SKATS.

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
