package Lingua::FreeLing3::EAGLES;

use warnings;
use strict;
use utf8;

use parent 'Exporter';
our $VERSION = "0.1";
our @EXPORT = 'eagles';

my $langs = _load_tags();

sub _load_tags {
    my $struct = {};
    my $section = undef;
    my $lang = undef;

    while ( <DATA> ) {
        s/#.*//;
        next if m/^\s*$/;

        ## name
        if (/^\[([^]]+)\]/) {
            $lang = $1;
        }

        ## category
        elsif (/^_/) {
            m/^([^: ]+)\s*:\s*(\S+)\s*=\s*(.*)$/ or die "Not a valid tags file.";
            my ($tag, $cat, $val) = ($1, $2, $3);
            $struct->{$lang}{$section}{$tag} = [$cat, $val];
        }

        ## new category
        else {
            m/^([^: ]+)\s*:\s*(\S+)\s*=\s*(.*)$/ or die "Not a valid tags file.";
            my ($tag, $cat, $val) = ($1, $2, $3);
            $section = $tag;
            $struct->{$lang}{$section}{$section} = [$cat, $val];
        }
    }

    return $struct;
}


sub _hash { $langs }; # for testing purposes ONLY
sub eagles {
    my ($lang, $tag) = @_;
    return undef unless exists $langs->{$lang};

    for my $prefix (keys %{$langs->{$lang}}) {
        return _expand_tag($lang, $tag => $langs->{$lang}{$prefix}) if $tag =~ /^$prefix/i
    }

    warn "$tag not understood for language $lang";
    undef
}

sub _expand_tag {
    my ($l, $tag, $hash) = @_;

    my $otag = $tag;
    my $fs = {};

    for my $key (keys %$hash) {
        my $re = $key;
        $re =~ s/_/./g;
        $re .= ".*";
        if ($tag =~ /^$re/) {
            $fs->{$hash->{$key}[0]} = $hash->{$key}[1];

            my ($offset, $len) = (0, 0);
            $re =~ /^(\.*)/ and $offset = length($1);
            $key =~ /([^_]+)/ and $len = length($1);
            substr $tag, $offset, $len, ('0' x $len);
        }
    }

    warn "$otag not fully understood ($tag) for language $l" unless $tag =~ /^0+$/;

    return $fs;
}






1;



=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::EAGLES - Interface to parse EAGLES tagsets from FL3

=head1 SYNOPSIS

  use Lingua::FreeLing3::EAGLES;

=head1 DESCRIPTION

=head2 NOTE: THIS MODULE IS NOT YET FUNCTIONAL

EAGLES-like tagets are easy to define, and most of them are kind of
easy to read by humans. However, there is not a clear algorithm to
parse all EAGLES tagsets, as the rules are too permissive.

This module defines an interface to easily obtain feature structures
from EAGLES tags.

=head2 Tagset Feature Structure

The homogeneous feature structure includes obligatorily a category
(C<<cat>> key). All other features might or not be present, depending
on the chosen language, and the supplied tag.

=head1 METHODS

This module exports only one method.

=head2 C<eagles>

The method used to extract details from an EAGLES tag.

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alberto Manuel Brandão Simões

=cut


__DATA__

[pt]

I: cat = interjeição

NP: cat = nome próprio

Fs: cat = pontuação

N: cat = nome
_C: subcat = comum
_P: subcat = próprio
__C: gender = m/f
__F: gender = f
__M: gender = m
___N: number = 2
___P: number = plural
___S: number = singular
______D: degree = diminutivo
______A: degree = aumentativo

R: cat = adverb
_G: type = generalista
_N: type = negação

C: cat = conjunction
_C: type = coordenative
_S: type = subordinative

A: cat = adjective
_O: type = numeral
_Q: type = qualificativo
__S: degree = superlativo
__A: degree = aumentativo # ???
__C: degree = diminutivo # ???
__S: degree = superlativo # ???
___F: gender = f
___M: gender = m
___C: gender = m/f
____S: number = singular
____P: number = plural
____N: number = neuter

D: cat = determinante
_A: subcat = artigo definido
_D: subcat = demonstrativo
_I: subcat = indefinido
_P: subcat = possessivo
__1: pessoa = primeira
__2: pessoa = segunda
__3: pessoa = terceira
___F: gender = f
___M: gender = m
___C: gender = m/f
____S: number = singular
____P: number = plural
____N: number = neuter
_____P: possuidor = varios # ***
_____S: possuidor = um     # ***

P: cat = pronoun
_D: subcat = demonstrativo
_E: subcat = interrogativo
_X: subcat = possessivo
_R: subcat = relativo
_T: subcat = interrogativo/relativo  # ???
_P: subcat = pessoal
__1: pessoa = primeira
__2: pessoa = segunda
__3: pessoa = terceira
___F: gender = f
___M: gender = m
___C: gender = m/f
___N: gender = neutro
____S: number = singular
____P: number = plural
____N: number = neuter
_____O: caso = obliquo
_____N: caso = nominativo
_____D: caso = dativo
_____A: caso = acusativo
______P: possuidor = varios
______S: possuidor = um

SPS: cat = preposition

VM: cat = verb
__G: modo = gerundio
__P: modo = participio
__N: modo = infinitivo
__M: modo = imperativo
__I: modo = indicativo
__S: modo = conjuntivo
___C: tempo = condicional
___I: tempo = pretérito imperfeito
___M: tempo = pretérito mais que perfeito
___S: tempo = pretérito perfeito
____1: pessoa = primeira
____2: pessoa = segunda
____3: pessoa = terceira
_____P: number = plural
_____S: number = singular
______M: genre = m
______F: genre = f

[es]

A: cat = adjetivo
_O: type = ordinal
_Q: type = calificativo
__S: degree = superlativo
___F: gender = f
___M: gender = m
___C: gender = m/f
____S: number = singular
____P: number = plural
____N: number = neutro

D: cat = determinante
_A: subcat = artículo definido
_D: subcat = demonstrativo
_E: subcat = exclamativo
_I: subcat = artículo indefinido
_P: subcat = posesivo
__1: pessoa = primera
__2: pessoa = segunda
__3: pessoa = tercera
___F: gender = f
___M: gender = m
___C: gender = m/f
___N: gender = neutro
____S: number = singular
____P: number = plural
____N: number = neuter
_____P: possuidor = varios
_____S: possuidor = um


N: cat = nome
_C: subcat = comum
_P: subcat = próprio
__C: gender = m/f
__F: gender = f
__M: gender = m
___N: number = neutro
___P: number = plural
___S: number = singular


P: cat = pronombre
_D: subcat = demostrativo
_E: subcat = exclamativo
_I: subcat = indefinido
_X: subcat = posesivo
_R: subcat = relativo
_T: subcat = interrogativo
_P: subcat = personal
__1: pessoa = primeira
__2: pessoa = segunda
__3: pessoa = terceira
___F: gender = f
___M: gender = m
___C: gender = m/f
___N: gender = neutro
____S: number = singular
____P: number = plural
____N: number = neuter
_____O: caso = obliquo
_____N: caso = nominativo
_____D: caso = dativo
_____A: caso = acusativo
______P: possuidor = varios
______S: possuidor = um
______N: possuidor = neutro

SPS: cat = preposition

V: cat = verb
_A: subcat = auxiliar
_S: subcat = ser
_M: subcat = principal
__G: tipo = gerundio
__P: tipo = participio
__N: tipo = infinitivo
__M: modo = imperativo
__I: modo = indicativo
__S: modo = subjuntivo
___C: tempo = condicional
___F: tempo = futuro
___I: tempo = pretérito imperfecto
___P: tempo = presente
___S: tempo = preterito indefinido # pretérito perfecto
____1: pessoa = primeira
____2: pessoa = segunda
____3: pessoa = terceira
_____P: number = plural
_____S: number = singular
______M: genre = m
______F: genre = f

C: cat = conjuncion
_C: subcat = coordinante
_S: subcat = subordinante

I: cat = interjeccion

R: cat = adverbio
_G: subcat = general
_N: subcat = negacion
