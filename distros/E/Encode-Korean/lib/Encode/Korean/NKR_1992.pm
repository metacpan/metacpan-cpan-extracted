# Encoding of Korean: North Korean Romanization 1992

# $Id: NKR_1992.pm,v 1.7 2007/11/29 14:25:31 you Exp $

package Encode::Korean::NKR_1992;

our $VERSION = do { q$Revision: 1.7 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };

use 5.008008;

use strict;
use warnings;

use Encode::Encoding;
use base qw(Encode::Encoding);

__PACKAGE__->Define(qw/nkr-1992 nkr1992 nkr/); 

sub import {
	require Encode;
	Encode->export_to_level(1,@_);
}

# = Encoding =
use Encode::Korean::TransliteratorGenerator;

# == RULES ==
my $nkr = Encode::Korean::TransliteratorGenerator->new();

$nkr->consonants(qw(k kk n t tt r m p pp s ss ng ts tss tsh kh th ph h));
$nkr->vowels(
	"a",
	"ae",
	"ya",
	"yae",
	"\x{014F}", # latin small letter with breve (ŏ)
	"e",
	"y\x{014F}",
	"ye",
	"o",
	"wa",
	"wae",
	"oe",
	"yo",
	"u",
	"w\x{014F}",
	"we",
	"wi",
	"yu",
	"\x{016D}", # latin small letter u with breve (ŭ)
	"\x{016D}y",
	"i"
	);
$nkr->el('l');
$nkr->ell('ll');
$nkr->naught('.');
$nkr->sep('.');
$nkr->make();

# == MODES ==
$nkr->enmode('greedy');
$nkr->demode('greedy');

sub enmode {
	my $class = shift;
	my($mode) = @_;
	$nkr->enmode($mode);
}

sub demode {
	my $class = shift;
	my($mode) = @_;
	$nkr->demode($mode);
}

# == METHODS ==
# === encode ===
# * encode($string [,$check])
# * Encodes 
#   unicode hangul syllables (Perl internal string) 
#   into NKR transliteration (octets)
sub encode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $tr = $nkr->encode($str, $chk);
    $_[1] = '' if $chk;
    return $tr;
}

# === decode ===
# * decode($octets [,$check])
# * Decodes 
#   NKR transliteration (octets)
#   into unicode hangul syllables (Perl internal string)
sub decode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $han = $nkr->decode($str, $chk);
    $_[1] = '' if $chk;
    return $han;
}

# === cat_decode ===
# * Needs to work with encoding pragma
# * cat_decode($destination, $octets, $offset, $terminator [,$check])


1;
__END__
=encoding utf8
=head1 NAME

Encode::Korean::NKR_1992 - Perl extension for Encoding of Korean: North Korean 
Romanizaiton 

=head1 SYNOPSIS

  use Encode::Korean::NKR_1992;
  
  $string = decode 'nkr', decode $enc, $octets;
  $octets = encode $enc, encode 'nkr', $string;
  
  while($line = <>) {
    print encode 'utf8', decode 'nkr', $line;
  }
  
=head1 DESCRIPTION

L<Encode::Korean::NKR_1992> implements an encoding system based on North Korean 
Romanizaiton (National system of DPKR), released in 1992 by Chosun Gwahagwon.

=head2 RULES

 $nkr->consonants(qw(k kk n t tt r m p pp s ss ng ts tss tsh kh th ph h));
 $nkr->vowels(
	"a",
	"ae",
	"ya",
	"yae",
	"\x{014F}", # latin small letter with breve (ŏ)
	"e",
	"y\x{014F}",
	"ye",
	"o",
	"wa",
	"wae",
	"oe",
	"yo",
	"u",
	"w\x{014F}",
	"we",
	"wi",
	"yu",
	"\x{016D}", # latin small letter u with breve (ŭ)
	"\x{016D}y",
	"i"

=head1 SEE ALSO

See
 L<http://en.wikipedia.org/wiki/Korean_romanization>,
 you can find a link to comparsion table of transliteration systems.

=head1 AUTHOR

You Hyun Jo, E<lt>you at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by You Hyun Jo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
