# ABSTRACT: Driver for the tagset of the Maltese Language Software Services (TnT tagger).
# Copyright © 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

# Part-of-Speech tagger for Maltese (including description of tags)
# http://metanet4u.research.um.edu.mt/POS.jsp
# MLRS (Maltese Language Resource Server) corpus
# http://mlrs.research.um.edu.mt/index.php?page=31

package Lingua::Interset::Tagset::MT::Mlss;
use strict;
use warnings;
our $VERSION = '3.011';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Atom';



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'mt::mlss';
}



#------------------------------------------------------------------------------
# This block will be called before object construction. It will build the
# decoding and encoding maps for this particular tagset.
# Then it will pass all the attributes to the constructor.
#------------------------------------------------------------------------------
around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;
    # Call the default BUILDARGS in Moose::Object. It will take care of distinguishing between a hash reference and a plain hash.
    my $attr = $class->$orig(@_);
    # Construct decode_map in the form expected by Atom.
    # http://metanet4u.research.um.edu.mt/POS.jsp
    my %dm =
    (
        # coordinating conjunction
        # examples: u, jew, iżda, imma, bħal (and, or, but, but, as)
        'CC'    => ['pos' => 'conj', 'conjtype' => 'coor'],
        # complementizer
        # examples: li, illi, ili, imbilli (that)
        'CMP'   => ['pos' => 'conj', 'conjtype' => 'sub', 'other' => {'conjtype' => 'cmp'}],
        # paired coordinating conjunction? only one element of the pair?
        # examples: la, ukoll (either/neither, (both-)and)
        'CR'    => ['pos' => 'conj', 'conjtype' => 'coor', 'other' => {'conjtype' => 'cr'}],
        # subordinating conjunction
        # examples: biex, kemm, għax, billi, jekk (to, either, because, since, if)
        'CS'    => ['pos' => 'conj', 'conjtype' => 'sub'],
        # determiner
        # no occurrences in the corpus
        #'DD'    => ['pos' => 'adj', 'prontype' => 'prn'],
        # definite determiner, clitic
        # examples: l-, il-, it-, is-, t- (the)
        'DDC'   => ['pos' => 'adj', 'prontype' => 'art', 'definiteness' => 'def'],
        # determiner, plural (quantifier)
        # examples: ħafna, ftit, bosta, tant, wisq (many, few, many, so many, too)
        'DP'    => ['pos' => 'adj', 'prontype' => 'ind', 'numtype' => 'card', 'number' => 'plur'],
        # determiner quantifier
        # no occurrence in the corpus
        #'DQ'    => [],
        # specifier, singular
        # examples: xi, kull, nofs, ebda, jimxi (some, every, middle, no, go)
        'DS'    => ['pos' => 'adj', 'prontype' => 'ind', 'number' => 'sing'],
        # existential marker ###!!! Chris Manning suggested a correction for handling of English EX in Interset; should it apply here as well?
        # examples: hemm, hawn, hemmx, ilux, damx (there, here, there, there, here)
        'EX'    => ['pos' => 'adv', 'advtype' => 'ex'],
        # interjection
        # examples: le (no), e, bye
        'II'    => ['pos' => 'int'],
        # modifier, adjective
        # examples: oħra, ieħor, iżjed, aktar, istess (other, other, more, more, same)
        'MJ'    => ['pos' => 'adj'],
        # modifier, adverb
        # examples: skont, kif, meta, bħala, hekk (according, how, where/when, as, so)
        'MV'    => ['pos' => 'adv'],
        # Maltese cardinal numerals have transitive (used with a noun) and intransitive (used without a noun) forms.
        # intransitive: 2 tnejn, 3 tlieta, 4 erbgħa, 5 ħamsa, 6 sitta, 7 sebgħa, 8 tmienja, 9 disgħa, 10 għaxra, 11 ħdax, 12 tnax, 13 tlettax, 14 erbatax, 15 ħmistax, 16 sittax, 17 sbatax, 18 tmintax, 19 dsatax
        # transitive with multi-syllable noun: 2 zewg, 3 tliet, 4 erba', 5 ħames, 6 sitt, 7 seba', 8 tmien, 9 disa', 10 għaxar
        # transitive with one-syllable noun: 2 zewgt, 3 tlett, 4 erbat, 5 ħamest, 6 sitt, 7 sebat, 8 tmint, 9 disat, 10 għaxart
        # certain transitive cardinals are followed by a singular noun: 11 ħdax-il, 12 tnax-il, 13 tlettax-il, 14 erbatax-il, 15 ħmistax-il, 16 sittax-il, 17 sbatax-il, 18 tmintax-il, 19 dsatax-il
        # numeral, cardinal
        # both expressed in words and in digits
        # examples: żewġ, 2010, 2009, tliet, 3 (two, 2010, 2009, three, 3)
        'NC'    => ['pos' => 'num', 'numtype' => 'card'],
        # numeral, cardinal, intransitive (i.e. the number is a label of something, no counted noun follows)
        # examples: 5, 1968, 1984, 1791, 1998
        # all examples found are numbers expressed using digits, although it is probably not guaranteed
        'NCI'   => ['pos' => 'num', 'numtype' => 'card', 'numform' => 'digit', 'other' => {'cardtype' => 'intr'}],
        # numeral, cardinal, transitive
        # no occurrence in the corpus
        #'NCT'   => ['pos' => 'num', 'numtype' => 'card'],
        # common noun
        # examples: persuna, lingwa, mod, istudenti, tagħlim (person, language, way, students, teaching)
        'NN'    => ['pos' => 'noun', 'nountype' => 'com'],
        # numeral, ordinal
        # examples: ewwel, tieni, tielet, erbgħin, għaxar (first, second, third, fifth, tenth)
        'NO'    => ['pos' => 'adj', 'numtype' => 'ord'],
        # proper name
        # examples: Vassalli, Malta, Għawdex, Kummerċ, Ġust (Vassalli, Malta, Gozo, Trade, Fair)
        'NP'    => ['pos' => 'noun', 'nountype' => 'prop'],
        # initial in proper name
        # no occurrence in the corpus
        #'NPI'   => ['pos' => 'noun', 'nountype' => 'prop', 'abbr' => 'yes'],
        # verbal negator
        # examples: ma, mhux, m', mhix, mhuwiex (not, not, not, not, not)
        'NV'    => ['pos' => 'part', 'polarity' => 'neg'],
        # numeral or indefinite determiner 'one'?
        # examples: wieħed, waħda, wħud, uħud, ċaħda (one, one, one, some, some)
        'NW'    => ['pos' => 'num', 'numtype' => 'card', 'numvalue' => '1'],
        # not documented; perhaps the same as PAC?
        # examples: għad (yet)
        # there are only three occurrences of għad/PA, and there are 17 occurrences of għad/PAC; is PA a tagging error?
        #'PA'    => ['pos' => 'part'],
        # particle, aspect marker, continuous aspect
        # examples: qed, għad, għadx (still)
        'PAC'   => ['pos' => 'part', 'aspect' => 'prog'],
        # particle, aspect marker, prospective aspect
        # examples: se (would)
        'PAF'   => ['pos' => 'part', 'aspect' => 'prosp'],
        # pronoun, demonstrative
        # examples: dan, din, dawn, dak, dik, dawk (this, this, these, that, that, those)
        'PD'    => ['pos' => 'noun|adj', 'prontype' => 'dem'],
        # pronoun, indefinite
        # examples: kollha, kollu, kulħadd, xejn, kollox (all, all, all, nothing, all)
        'PI'    => ['pos' => 'noun|adj', 'prontype' => 'ind'],
        # preposition ma' with bound pronoun
        # examples: miegħu, magħhom, magħha, irwieħhom, magħna (with him, with them, with her, ?, with us)
        ###!!! We should remove adpostype=preppron from Interset! If the fused word cannot be split, then it should together be a pronoun in a strange case, not a preposition!
        'PMP'   => ['pos' => 'adp', 'adpostype' => 'preppron'],
        # pronoun, personal
        # examples: huwa, huma, hija, hu, hi (he, they, she, he, she)
        'PP'    => ['pos' => 'noun', 'prontype' => 'prs'],
        # pronoun, reflexive
        # examples: ruħu, nnifsu, innifsu, ruħhom, nnifisha (himself, herself, itself, themselves, itself)
        'PR'    => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'],
        # preposition
        # examples: ta', f', fuq, minn, b' (of, ?, ?, from, in)
        'PRP'   => ['pos' => 'adp', 'adpostype' => 'prep'],
        # fused preposition-article
        # examples: tal-, fil-, fl-, għall-, mill- (of, in, in, to, from)
        'PRPC'  => ['pos' => 'adp', 'adpostype' => 'prep', 'prontype' => 'art', 'definiteness' => 'def'],
        # pronoun, possessive
        # examples: tiegħu, tagħhom, tagħha, tagħna, tiegħi (his, their, her, our, my)
        'PT'    => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
        # punctuation
        # examples: , . ' ( )
        'PUN'   => ['pos' => 'punc'],
        # pronoun, interrogative?
        # examples: x', min, liema (?, who, what)
        'PW'    => ['pos' => 'noun|adj', 'prontype' => 'int'],
        # residual, acronym
        # examples: Dr, ICT, Prof., UE, PARC
        'RA'    => ['pos' => 'noun', 'nountype' => 'prop', 'abbr' => 'yes'],
        # residual, abbreviation
        # examples: ..., Ltd, Ed, GĦST, ICT
        'RB'    => ['abbr' => 'yes'],
        # residual, date
        # examples: 13, 631, 22, 158, 33
        # this tag is not restricted to dates, it appears e.g. in "artikolu 631" (article 631)
        'RD'    => ['pos' => 'num', 'numtype' => 'card', 'other' => {'cardtype' => 'date'}],
        # residual, formula, mathematical symbol
        'RFR'   => ['pos' => 'sym'],
        # residual, foreign word
        # examples: of, the, for, in, e
        'RFW'   => ['foreign' => 'yes'],
        # residual, honorific
        # examples: Sur, San, Dun, European, Fr
        'RH'    => ['pos' => 'noun', 'nountype' => 'com', 'other' => {'nountype' => 'title'}],
        # residual, other
        # examples: a, b, S, A, d
        'RO'    => [],
        # residual, other symbol
        # III, II, V, I, XVIII
        # all examples observed in the corpus are Roman numerals
        'RS'    => ['pos' => 'num', 'numtype' => 'card|ord', 'numform' => 'roman'],
        # (unique, unassigned) multiword utterance
        # no occurrence in the corpus
        #'UAM'   => [],
        # verb, auxiliary
        # examples: kien, kienu, kienet, jkun, tkun (was, were, would, be, be)
        'VA'    => ['pos' => 'verb', 'verbtype' => 'aux'],
        # pseudo verb
        # inflected forms of the preposition 'għand', e.g. 'għandu' = at/to him = he has
        # past tense: kellu = kien ("he was") + l- + "to" = he had / he had to (if followed by verb)
        # examples: għandu, kellu, għandhom, għandha, kellhom (has, had, have, has, had)
        'VG'    => ['pos' => 'verb', 'other' => {'verbtype' => 'have'}],
        # participle, active, or passive
        # examples: qiegħed, mgħallma, qegħdin, miftuħa, meqjus (being, taught, being, open, considered)
        'VP'    => ['pos' => 'verb', 'verbform' => 'part'],
        # main verb
        # examples: jistgħu, jista', jiġi, jgħid, tista' (can, could, be, say, can)
        'VV'    => ['pos' => 'verb']
    );
    # Construct encode_map in the form expected by Atom.
    my %em =
    (
        'prontype' => { 'art' => { 'pos' => { 'adp' => 'PRPC',
                                              '@'   => 'DDC' }},
                        'dem' => 'PD',
                        'ind' => { 'number' => { 'sing' => 'DS',
                                                 'plur' => 'DP',
                                                 '@'    => 'PI' }},
                        'tot' => 'PI',
                        'neg' => 'PI',
                        'int' => 'PW',
                        'rel' => 'PW',
                        'prs' => { 'poss' => { 'yes' => 'PT',
                                               '@'    => { 'reflex' => { 'yes' => 'PR',
                                                                         '@'      => 'PP' }}}},
                        '@'   => { 'pos' => { 'noun' => { 'nountype' => { 'prop' => { 'abbr' => { 'yes' => 'RA',
                                                                                                  '@'    => 'NP' }},
                                                                          '@'    => { 'other/nountype' => { 'title' => 'RH',
                                                                                                            '@'     => 'NN' }}}},
                                              'adj'  => { 'numtype' => { 'ord' => 'NO',
                                                                         '@'   => 'MJ' }},
                                              'num'  => { 'other/cardtype' => { 'intr' => 'NCI',
                                                                                'date' => 'RD',
                                                                                '@'    => { 'numform' => { 'roman' => 'RS',
                                                                                                           '@'     => { 'numvalue' => { '1' => 'NW',
                                                                                                                                        '@' => 'NC' }}}}}},
                                              'verb' => { 'verbtype' => { 'aux' => 'VA',
                                                                          '@'   => { 'other/verbtype' => { 'have' => 'VG',
                                                                                                           '@'    => { 'verbform' => { 'part' => 'VP',
                                                                                                                                       '@'    => 'VV' }}}}}},
                                              'adv'  => { 'advtype' => { 'ex' => 'EX',
                                                                         '@'  => 'MV' }},
                                              'adp'  => { 'adpostype' => { 'preppron' => 'PMP',
                                                                           '@'        => 'PRP' }},
                                              'conj' => { 'conjtype' => { 'sub'  => { 'other/conjtype' => { 'cmp' => 'CMP',
                                                                                                            '@'   => 'CS' }},
                                                                          '@'    => { 'other/conjtype' => { 'cr'  => 'CR',
                                                                                                            '@'   => 'CC' }}}},
                                              'part' => { 'polarity' => { 'neg' => 'NV',
                                                                          '@'   => { 'aspect' => { 'prosp' => 'PAF',
                                                                                                   '@'     => 'PAC' }}}},
                                              'int'  => 'II',
                                              'sym'  => 'RFR',
                                              'punc' => 'PUN',
                                              '@'    => { 'abbr' => { 'yes' => 'RB',
                                                                      '@'    => { 'foreign' => { 'yes' => 'RFW',
                                                                                                 '@'       => 'RO' }}}}}}}
    );
    # Now add the references to the attribute hash.
    $attr->{surfeature} = 'pos';
    $attr->{decode_map} = \%dm;
    $attr->{encode_map} = \%em;
    $attr->{tagset}     = 'mt::mlss';
    return $attr;
};



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure. In addition to Atom, we just need to identify the tagset of
# origin.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = $self->SUPER::decode($tag);
    $fs->set_tagset('mt::mlss');
    return $fs;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::MT::Mlss - Driver for the tagset of the Maltese Language Software Services (TnT tagger).

=head1 VERSION

version 3.011

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::MT::Mlss;
  my $driver = Lingua::Interset::Tagset::MT::Mlss->new();
  my $fs = $driver->decode('NN');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('mt::mlss', 'NN');

=head1 DESCRIPTION

Interset driver for the part-of-speech tagset of the Maltese Language Software Services
(TnT tagger; see L<http://metanet4u.research.um.edu.mt/POS.jsp>).
The tagset is used in the MLRS (Maltese Language Resource Server) corpus,
L<http://mlrs.research.um.edu.mt/index.php?page=31>.

=head1 SEE ALSO

L<Lingua::Interset>
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>
L<Lingua::Interset::Tagset::EN::Penn>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
