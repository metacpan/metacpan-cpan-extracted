# Encoding of Korean: McCune-Reischauer Romanization

# $Id: MRR.pm,v 1.5 2007/11/29 14:25:31 you Exp $

package Encode::Korean::MRR;

our $VERSION = do { q$Revision: 1.5 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };

use 5.008008;

use strict;
use warnings;

use Encode::Encoding;
use base qw(Encode::Encoding);

__PACKAGE__->Define(qw/McCune-Reischauer mrr/); 

sub import {
	require Encode;
	Encode->export_to_level(1,@_);
}

use Encode::Korean::TransliteratorGenerator;

# == RULES ==

my $mrr = Encode::Korean::TransliteratorGenerator->new();

$mrr->consonants(qw(k kk n t tt r m p pp s ss ng ch tch ch' k' t' p' h));
$mrr->vowels(
	"a",
	"ae",
	"ya",
	"yae",
	"\x{014F}", # \x{014F} latin small letter with breve (ŏ)
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
	"\x{016D}", # \x{016D} latin small letter u with breve (ŭ)
	"\x{016D}y",
	"i"
	);
$mrr->el('l');
$mrr->ell('ll');
$mrr->naught('.');
$mrr->sep('.');
$mrr->make();

# == MODES ==
$mrr->enmode('greedy');
$mrr->demode('greedy');

sub enmode {
	my $class = shift;
	my($mode) = @_;
	$mrr->enmode($mode);
}

sub demode {
	my $class = shift;
	my($mode) = @_;
	$mrr->demode($mode);
}



# == METHODS ==
# === encode ===
# * encode($string [,$check])
# * Encodes unicode hangul syllables (Perl internal string) 
#   into transliterated (romanized) string
sub encode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $tr = Encode::encode 'utf8', $mrr->encode($str, $chk);
    $_[1] = '' if $chk;
    return $tr;
}

# === decode ===
# * decode($octets [,$check])
# * Decodes transliteration into unicode hangul syllables (Perl internal string)
sub decode ($$;$) {
    my ($obj, $str, $chk) = @_;
	 my $han = $mrr->decode(Encode::decode('utf8', $str), $chk);
    $_[1] = '' if $chk;
    return $han;
}

# === cat_decode ===
# * Needs to work with encoding pragma
# * cat_decode($destination, $octets, $offset, $terminator [,$check])


1;
__END__

=head1 NAME

Encode::Korean::MRR - Perl extension for Encoding of Korean: McCune-Reishauer Romanization 

=head1 SYNOPSIS

   use Encode::Korean::MRR;

   $string = decode 'mrr', $octets;
   $octets = encode 'mrr', $string;

   while($line = <>) {
     print decode 'mrr', $line;
   }

=head1 DESCRIPTION

L<Encode::Korean::MMR> implements an encoding system based on McCune-Reischauer
Romanization, created in 1937 by George M. McCune and Edwin O. Reischauer. It
is one of the most widely used methods.  

=head1 SEE ALSO

See
 L<http://en.wikipedia.org/wiki/McCune-Reischauer>
 for McCune-Reischauer Romanization 


=head1 AUTHOR

You Hyun Jo, E<lt>you at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by You Hyun Jo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
# vim: set ts=4 sts=4 sw=4 et
