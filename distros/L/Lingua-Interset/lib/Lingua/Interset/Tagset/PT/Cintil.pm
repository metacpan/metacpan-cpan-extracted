# ABSTRACT: Driver for the Portuguese tagset of the CINTIL corpus (Corpus Internacional do Portugues).
# http://cintil.ul.pt/
# http://cintil.ul.pt/cintilwhatsin.html#guidelines
# Copyright © 2014 Martin Popel <popel@ufal.mff.cuni.cz>
# Copyright © 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::PT::Cintil;
use strict;
use warnings;
our $VERSION = '3.016';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms' => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms', lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'pt::cintil';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
# See http://cintil.ul.pt/cintilwhatsin.html#guidelines
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'tagset' => 'pt::cintil',
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # Adjective (bom, brilhante, eficaz)
            'ADJ'    => ['pos' => 'adj'],
            # Adverb (hoje, já, sim, felizmente)
            'ADV'    => ['pos' => 'adv'],
            # Cardinal number (zero, dez, cem, mil)
            'CARD'   => ['pos' => 'num', 'numtype' => 'card'],
            # Conjunction (e, ou, que, como)
            'CJ'     => ['pos' => 'conj'],
            # Clitic (-se, o, -lhe)
            ###!!! Should Interset have a new feature for encliticized personal pronouns? They are not necessarily reflexive.
            'CL'     => ['pos' => 'noun', 'prontype' => 'prs', 'variant' => 'short', 'other' => {'pos' => 'clitic'}],
            # Common noun (computador, cidade, ideia)
            'CN'     => ['pos' => 'noun', 'nountype' => 'com'],
            # Definite article (o, a, os, as)
            'DA'     => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'def'],
            # Demonstrative pronoun or determiner (este, esses, aquele)
            'DEM'    => ['pos' => 'noun|adj', 'prontype' => 'dem'],
            # Denominator of a fraction (meio, terço, décimo, %)
            'DFR'    => ['pos' => 'num', 'numtype' => 'frac'],
            # Roman numeral (VI, LX, MMIII, MCMXCIX)
            'DGTR'   => ['pos' => 'num', 'numform' => 'roman'],
            # Number expressed in digits (0, 1, 42, 12345, 67890)
            'DGT'    => ['pos' => 'num', 'numform' => 'digit'],
            # Discourse marker "olá"
            'DM'     => ['pos' => 'int', 'other' => {'pos' => 'discourse'}],
            # Electronic address (http://www.di.fc.ul.pt)
            'EADR'   => ['pos' => 'noun', 'other' => {'pos' => 'url'}],
            # End of enumeration (etc.)
            'EOE'    => ['pos' => 'part', 'abbr' => 'yes'],
            # Exclamation (que, quanto)
            'EXC'    => ['pos' => 'int'],
            # Gerund (sendo, afirmando, vivendo)
            'GER'    => ['pos' => 'verb', 'verbform' => 'part', 'tense' => 'pres', 'aspect' => 'prog'],
            # Gerund of an auxiliary verb in compound tenses (tendo, havendo)
            'GERAUX' => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'part', 'tense' => 'pres', 'aspect' => 'prog'],
            # Indefinite article (uns, umas)
            'IA'     => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'ind'],
            # Indefinite pronoun or determiner (tudo, alguém, ninguém)
            'IND'    => ['pos' => 'noun|adj', 'prontype' => 'ind|neg|tot'],
            # Infinitive (ser, afirmar, viver)
            'INF'    => ['pos' => 'verb', 'verbform' => 'inf'],
            # Infinitive of an auxiliary verb in compound tenses (ter, haver)
            'INFAUX' => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'inf'],
            # Interrogative pronoun, determiner or adverb (quem, como, quando)
            'INT'    => ['pos' => 'noun|adj|adv', 'prontype' => 'int'],
            # Interjection (bolas, caramba)
            'ITJ'    => ['pos' => 'int'],
            # Letter (a, b, c)
            'LTR'    => ['pos' => 'sym', 'other' => {'pos' => 'letter'}],
            # Magnitude class (unidade, dezena, dúzia, resma)
            # unidade = unit; dezena = dozen; dúzia = dozen; resma = ream = hromada
            'MGT'    => ['pos' => 'noun', 'numtype' => 'card', 'numform' => 'word', 'other' => {'pos' => 'magnitude'}],
            # Month (Janeiro, Dezembro)
            'MTH'    => ['pos' => 'noun', 'other' => {'pos' => 'month'}],
            # Noun phrase (idem)
            'NP'     => ['pos' => 'noun', 'abbr' => 'yes'],
            # Ordinal numeral (primeiro, centésimo, penúltimo)
            'ORD'    => ['pos' => 'adj', 'numtype' => 'ord'],
            # Part of address (Rua, av., rot.)
            'PADR'   => ['pos' => 'noun', 'other' => {'pos' => 'address'}],
            # Part of name (Lisboa, António, Jo&atil;o)
            'PNM'    => ['pos' => 'noun', 'nountype' => 'prop'],
            # Punctuation (., ?, (, ))
            'PNT'    => ['pos' => 'punc'],
            # Possessive pronoun or determiner (meu, teu, seu)
            'POSS'   => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
            # Past participle not in compound tenses (sido, afirmados, vivida)
            'PPA'    => ['pos' => 'adj', 'verbform' => 'part', 'tense' => 'past'],
            ###!!! According to Martin/documentation?, PP should mean "prepositional phrase" (algures = somewhere).
            ###!!! However, there are only a few occurrences, always with the ellipsis punctuation ("...").
            'PP'     => ['pos' => 'punc'],
            # Past participle in compound tenses (sido, afirmado, vivido)
            'PPT'    => ['pos' => 'verb', 'verbform' => 'part', 'tense' => 'past'],
            # Preposition (de, para, em redor de)
            'PREP'   => ['pos' => 'adp', 'adpostype' => 'prep'],
            # Personal pronoun (eu, tu, ele)
            'PRS'    => ['pos' => 'noun', 'prontype' => 'prs'],
            # Quantifier (todos, muitos, nenhum)
            'QNT'    => ['pos' => 'adj', 'prontype' => 'ind|tot|neg', 'numtype' => 'card'],
            # Relative pronoun, determiner or adverb (que, cujo, tal que)
            'REL'    => ['pos' => 'noun|adj|adv', 'prontype' => 'rel'],
            # Social title (Presidente, drª., prof.)
            'STT'    => ['pos' => 'noun', 'other' => {'pos' => 'title'}],
            # Symbol (@, #, &)
            'SYB'    => ['pos' => 'sym'],
            # Optional termination ((s), (as))
            'TERMN'  => [],
            # "um" or "uma" (they could be either indefinite articles or cardinal numerals meaning "one")
            'UM'     => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'ind', 'numtype' => 'card', 'numform' => 'word', 'numvalue' => '1'],
            # Abbreviated measurement unit (Kg, h, seg, Hz, Mbytes)
            'UNIT'   => ['pos' => 'noun', 'abbr' => 'yes'],
            # Finite form of an auxiliary verb in compound tenses (temos, haveriam)
            'VAUX'   => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'fin'],
            # Verb (other than PPA, PPT, INF or GER) (falou, falaria)
            'V'      => ['pos' => 'verb', 'verbform' => 'fin'],
            # Day of week (segunda, terça-feira, sábado)
            'WD'     => ['pos' => 'noun', 'other' => {'pos' => 'weekday'}]
            # LADVn ... multi-word adverb (de facto, em suma, um pouco)
            # LCJn .... multi-word conjunction (assim como, já que)
            # LDEMn ... multi-word demonstrative (o mesmo)
            # LDFRn ... multi-word denominator of fraction (por cento)
            # LDMn .... multi-word discourse marker (pois n&atil;o, até logo)
            # LITJn ... multi-word interjection (meu Deus)
            # LPRSn ... multi-word personal (a gente, si mesmo, V. Exa.)
            # LPREPn .. multi-word preposition (através de, a partir de)
            # LQDn .... multi-word quantifier (uns quantos)
            # LRELn ... multi-word relative (tal como)
        },
        'encode_map' =>

            { 'prontype' => { 'prs' => { 'poss' => { 'yes' => 'POSS',
                                                     '@'    => { 'variant' => { 'short' => 'CL',
                                                                                '@'     => 'PRS' }}}},
                              'art' => { 'definite' => { 'def' => 'DA',
                                                         '@'   => { 'numtype' => { 'card' => 'UM',
                                                                                   '@'    => 'IA' }}}},
                              'dem' => 'DEM',
                              'ind' => { 'numtype' => { ''  => 'IND',
                                                        '@' => 'QNT' }},
                              'neg' => { 'numtype' => { ''  => 'IND',
                                                        '@' => 'QNT' }},
                              'tot' => { 'numtype' => { ''  => 'IND',
                                                        '@' => 'QNT' }},
                              'int' => 'INT',
                              'rel' => 'REL',
                              '@'   => { 'pos' => { 'noun' => { 'other/pos' => { 'month'     => 'MTH',
                                                                                 'weekday'   => 'WD',
                                                                                 'magnitude' => 'MGT',
                                                                                 'address'   => 'PADR',
                                                                                 'title'     => 'STT',
                                                                                 '@'         => 'CN' }},
                                                    'adj'  => { 'verbform' => { 'part' => 'PPA',
                                                                                '@'    => { 'numtype' => { 'ord' => 'ORD',
                                                                                                           '@'   => 'ADJ' }}}},
                                                    'num'  => { 'numtype' => { 'frac' => 'DFR',
                                                                               '@'    => { 'numform' => { 'digit' => 'DGT',
                                                                                                          'roman' => 'DGTR',
                                                                                                          '@'     => 'CARD' }}}},
                                                    # We decode INF and INFAUX but we never encode it. Instead, we encode "V V inf".
                                                    # The input data are not consistent but the "V" tag is more frequent with infinitives.
                                                    # Similar with GER and GERAUX.
                                                    'verb' => { 'verbtype' => { 'aux' => { 'verbform' => { '@'    => 'VAUX' }},
                                                                                '@'   => { 'verbform' => { '@'    => 'V' }}}},
                                                    'adv'  => 'ADV',
                                                    'adp'  => 'PREP',
                                                    'conj' => 'CJ',
                                                    'int'  => { 'other/pos' => { 'discourse' => 'DM',
                                                                                 '@'         => 'ITJ' }},
                                                    'punc' => 'PNT',
                                                    'sym'  => { 'other/pos' => { 'letter' => 'LTR',
                                                                                 '@'      => 'SYB' }}}}}}
    );
    # FEATURES ####################
    $atoms{feature} = $self->create_atom
    (
        'surfeature' => 'feature',
        'decode_map' =>
        {
            'm'    => ['gender' => 'masc'],
            'f'    => ['gender' => 'fem'],
            'g'    => [], # undetermined gender
            's'    => ['number' => 'sing'],
            'p'    => ['number' => 'plur'],
            'n'    => [], # undetermined number
            # diminutive
            'dim'  => ['other' => {'diminutive' => 'yes'}],
            'comp' => ['degree' => 'cmp'],
            'sup'  => ['degree' => 'sup'],
            '1'    => ['person' => '1'],
            '2'    => ['person' => '2'],
            '3'    => ['person' => '3'],
            # presente do indicativo
            'pi'   => ['mood' => 'ind', 'tense' => 'pres'],
            # préterito perfeito do indicativo
            'ppi'  => ['mood' => 'ind', 'tense' => 'past', 'aspect' => 'perf'],
            # préterito imperfeito do indicativo
            'ii'   => ['mood' => 'ind', 'tense' => 'past', 'aspect' => 'imp'],
            # préterito mais que perfeito do indicativo
            'mpi'  => ['mood' => 'ind', 'tense' => 'pqp', 'aspect' => 'perf'],
            # futuro do indicativo
            'fi'   => ['mood' => 'ind', 'tense' => 'fut'],
            # condicional
            'c'    => ['mood' => 'cnd'],
            # presente do conjuntivo
            'pc'   => ['mood' => 'sub', 'tense' => 'pres'],
            # préterito imperfeito do conjuntivo
            'ic'   => ['mood' => 'sub', 'tense' => 'past', 'aspect' => 'imp'],
            # futuro do conjuntivo
            'fc'   => ['mood' => 'sub', 'tense' => 'fut'],
            # imperativo
            'imp'  => ['mood' => 'imp'],
            # There are two ways of tagging infinitives: either at the part-of-speech level or in the features:
            # V V inf-nInf
            # V V inf-3s
            # V V inf-3p
            # INF INF ninf
            # INF INF ifl-1p
            'inf'  => ['verbform' => 'inf'],
            'ifl'  => [], # inflected infinitive; person+number feature follows
            'ninf' => [], # uninflected infinitive
            'nInf' => [], # uninflected infinitive
            # Similarly, there are multiple ways of tagging gerunds / present participles:
            # V V ger ... 21
            # V V GER ... 88
            # GER GER <lemma> ... 12
            # GERAUX GERAUX ... 0 (but documented)
            'ger'  => ['verbform' => 'ger'],
            # Similarly, there are multiple ways of tagging past participles (used in compound tenses, not used adjectively):
            # PPT PPT <lemma> ... 27
            # V V PPT-ms ... 184
            'PPT'  => ['verbform' => 'part', 'tense' => 'past', 'aspect' => 'perf'],
            # Part of name (Lisboa, António, Jo&atil;o)
            # The documentation says that this is a part-of-speech tag. However, in the data it appears as a feature of the "CN" tag.
            'PNM'    => ['nountype' => 'prop'],
            # other undocumented features that occur in the data
            '?'    => [], # unknown gender or number
            '??'   => [], # unknown gender and number
        },
        'encode_map' =>

            { 'pos' => '' }
    );
    # GENDER+NUMBER ####################
    $atoms{gn} = $self->create_atom
    (
        'surfeature' => 'gn',
        'decode_map' =>
        {
            'ms' => ['gender' => 'masc', 'number' => 'sing'],
            'mp' => ['gender' => 'masc', 'number' => 'plur'],
            'mn' => ['gender' => 'masc'],
            'fs' => ['gender' => 'fem', 'number' => 'sing'],
            'fp' => ['gender' => 'fem', 'number' => 'plur'],
            'fn' => ['gender' => 'fem'],
            'gs' => ['number' => 'sing'],
            'gp' => ['number' => 'plur'],
            'gn' => []
        },
        'encode_map' =>

            { 'gender' => { 'masc' => { 'number' => { 'sing' => 'ms',
                                                      'plur' => 'mp',
                                                      '@'    => 'mn' }},
                            'fem'  => { 'number' => { 'sing' => 'fs',
                                                      'plur' => 'fp',
                                                      '@'    => 'fn' }},
                            '@'    => { 'number' => { 'sing' => 'gs',
                                                      'plur' => 'gp',
                                                      '@'    => 'gn' }}}}
    );
    # PERSON+NUMBER ####################
    $atoms{pn} = $self->create_atom
    (
        'surfeature' => 'pn',
        'decode_map' =>
        {
            '1s' => ['person' => '1', 'number' => 'sing'],
            '2s' => ['person' => '2', 'number' => 'sing'],
            '3s' => ['person' => '3', 'number' => 'sing'],
            '1p' => ['person' => '1', 'number' => 'plur'],
            '2p' => ['person' => '2', 'number' => 'plur'],
            '3p' => ['person' => '3', 'number' => 'plur']
        },
        'encode_map' =>

            { 'number' => { 'sing' => { 'person' => { '1' => '1s',
                                                      '2' => '2s',
                                                      '3' => '3s' }},
                            'plur' => { 'person' => { '1' => '1p',
                                                      '2' => '2p',
                                                      '3' => '3p' }}}}
    );
    # TENSE+MOOD ####################
    $atoms{tm} = $self->create_atom
    (
        'surfeature' => 'tm',
        'decode_map' =>
        {
            # presente do indicativo
            'pi'   => ['mood' => 'ind', 'tense' => 'pres'],
            # préterito perfeito do indicativo
            'ppi'  => ['mood' => 'ind', 'tense' => 'past', 'aspect' => 'perf'],
            # préterito imperfeito do indicativo
            'ii'   => ['mood' => 'ind', 'tense' => 'past', 'aspect' => 'imp'],
            # préterito mais que perfeito do indicativo
            'mpi'  => ['mood' => 'ind', 'tense' => 'pqp', 'aspect' => 'perf'],
            # futuro do indicativo
            'fi'   => ['mood' => 'ind', 'tense' => 'fut'],
            # condicional
            'c'    => ['mood' => 'cnd'],
            # presente do conjuntivo
            'pc'   => ['mood' => 'sub', 'tense' => 'pres'],
            # préterito imperfeito do conjuntivo
            'ic'   => ['mood' => 'sub', 'tense' => 'past', 'aspect' => 'imp'],
            # futuro do conjuntivo
            'fc'   => ['mood' => 'sub', 'tense' => 'fut'],
            # imperativo
            'imp'  => ['mood' => 'imp'],
            # There are two ways of tagging infinitives: either at the part-of-speech level or in the features:
            # V V inf-nInf
            # V V inf-3s
            # V V inf-3p
            # INF INF ninf
            # INF INF ifl-1p
            'inf'  => ['verbform' => 'inf'],
            # Similarly, there are multiple ways of tagging gerunds / present participles:
            # V V ger ... 21
            # V V GER ... 88
            # GER GER <lemma> ... 12
            # GERAUX GERAUX ... 0 (but documented)
            'GER'  => ['verbform' => 'ger'],
            'ger'  => ['verbform' => 'ger'],
            # Similarly, there are multiple ways of tagging past participles (used in compound tenses, not used adjectively):
            # PPT PPT <lemma> ... 27
            # V V PPT-ms ... 184
            'PPT'  => ['verbform' => 'part', 'tense' => 'past', 'aspect' => 'perf'],
        },
        'encode_map' =>

            { 'verbform' => { 'inf'  => 'inf',
                              'ger'  => 'ger',
                              'part' => { 'tense' => { 'pres' => 'ger',
                                                       '@'    => 'PPT' }},
                              '@'    => { 'mood' => { 'ind' => { 'tense' => { 'pres' => 'pi',
                                                                              'past' => { 'aspect' => { 'imp'  => 'ii',
                                                                                                        'perf' => 'ppi' }},
                                                                              'pqp'  => 'mpi',
                                                                              'fut'  => 'fi' }},
                                                      'cnd' => 'c',
                                                      'sub' => { 'tense' => { 'pres' => 'pc',
                                                                              'past' => 'ic',
                                                                              'imp'  => 'ic',
                                                                              'fut'  => 'fc' }},
                                                      'imp' => 'imp' }}}}
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('pt::cintil');
    my $atoms = $self->atoms();
    # Three components, and the first two are identical: pos, pos, features.
    # example: CN\tCN\tms
    my ($pos, $subpos, $features) = split(/\s+/, $tag);
    # Multi-word expressions: The tags are preceded by "L" and followed by
    # a numerical index: LADV1, LADV2, ..., LADV7, LDFR1, LDFR2, LPREP1, ...
    $pos =~ s/^L(.+)\d+$/$1/;
    # Some features are separated by a hyphen, others are not separated.
    # The underscore character is used if there are no features.
    $features = '' if($features eq '_');
    my @features = split(/-/, $features);
    # Separate gender, number and person.
    # g is the undistinguishable gender, i.e. g = m|f
    # n is the undistinguishable number, i.e. n = s|p
    @features = map {m/^([mfg])([spn])([123])$/ ? ($1, $2, $3) : $_} (@features);
    @features = map {m/^([mfg123])([spn])$/ ? ($1, $2) : $_} (@features);
    $atoms->{pos}->decode_and_merge_hard($pos, $fs);
    foreach my $feature (@features)
    {
        $atoms->{feature}->decode_and_merge_hard($feature, $fs);
    }
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $atoms = $self->atoms();
    my $pos = $atoms->{pos}->encode($fs);
    my $features = '_';
    # Proper nouns / parts of names ("PNM"): according to documentation they should be POS tags but in fact they appear as features.
    if($fs->is_proper_noun())
    {
        $features = 'PNM';
    }
    elsif($pos =~ m/^(ADJ|CARD|CL|CN|DA|DEM|IA|IND|MGT|MTH|ORD|PADR|POSS|PPA|PRS|QNT|REL|STT|UM|WD)$/)
    {
        $features = $atoms->{gn}->encode($fs);
        # Relative adverbs do not encode gender and number.
        $features = '_' if($pos eq 'REL' && $features eq 'gn');
        # Is it a degree of comparison other than positive?
        if($fs->is_comparative())
        {
            $features .= '-comp';
        }
        elsif($fs->is_superlative())
        {
            $features .= '-sup';
        }
        # Is it a diminutive?
        $features .= '-dim' if($fs->is_other('pt::cintil', 'diminutive', 'yes'));
    }
    if($pos =~ m/^(CL|PRS)$/)
    {
        $features .= $fs->person();
    }
    if($pos =~ m/^(V|VAUX)$/)
    {
        my $tm = $atoms->{tm}->encode($fs);
        my $pn = $atoms->{pn}->encode($fs);
        $pn = 'nInf' if($tm eq 'inf' && $pn eq '');
        $pn = 'ms' if($tm eq 'PPT'); # actually this is gender+number, not person+number
        $features = $tm;
        $features .= "-$pn" if($pn ne '');
    }
    my $tag = "$pos\t$pos\t$features";
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus.
# 240 tag-features combinations have been observed in the sample Jo&atil;o sent
# us. Some of them are errors and were removed from our list. (We can decode
# them but we will not try to encode them.)
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
ADJ	ADJ	fp
ADJ	ADJ	fp-comp
ADJ	ADJ	fp-sup
ADJ	ADJ	fs
ADJ	ADJ	fs-comp
ADJ	ADJ	fs-dim
ADJ	ADJ	fs-sup
ADJ	ADJ	gn
ADJ	ADJ	gp
ADJ	ADJ	gp-comp
ADJ	ADJ	gs
ADJ	ADJ	gs-comp
ADJ	ADJ	mp
ADJ	ADJ	mp-comp
ADJ	ADJ	mp-dim
ADJ	ADJ	mp-sup
ADJ	ADJ	ms
ADJ	ADJ	ms-comp
ADJ	ADJ	ms-dim
ADJ	ADJ	ms-sup
ADV	ADV	_
CARD	CARD	fp
CARD	CARD	fs
CARD	CARD	gp
CARD	CARD	mp
CARD	CARD	ms
CJ	CJ	_
CL	CL	fp3
CL	CL	fs3
CL	CL	gn3
CL	CL	gp2
CL	CL	gp3
CL	CL	gs1
CL	CL	gs2
CL	CL	gs3
CL	CL	mp3
CL	CL	ms3
CN	CN	PNM
CN	CN	fp
CN	CN	fp-dim
CN	CN	fs
CN	CN	fs-dim
CN	CN	gp
CN	CN	gs
CN	CN	mn
CN	CN	mp
CN	CN	mp-dim
CN	CN	ms
CN	CN	ms-dim
CN	CN	ms-sup
DA	DA	fp
DA	DA	fs
DA	DA	mp
DA	DA	ms
DEM	DEM	fp
DEM	DEM	fs
DEM	DEM	gp
DEM	DEM	gs
DEM	DEM	mp
DEM	DEM	ms
DFR	DFR	_
DGT	DGT	_
DGTR	DGTR	_
DM	DM	_
IA	IA	fp
IA	IA	mp
IND	IND	mp
IND	IND	ms
INT	INT	_
ITJ	ITJ	_
LTR	LTR	_
MGT	MGT	mp
MTH	MTH	ms
ORD	ORD	fn
ORD	ORD	fp
ORD	ORD	fs
ORD	ORD	mn
ORD	ORD	mp
ORD	ORD	ms
PADR	PADR	fs
PADR	PADR	ms
PNT	PNT	_
POSS	POSS	fp
POSS	POSS	fs
POSS	POSS	mp
POSS	POSS	ms
PPA	PPA	fp
PPA	PPA	fs
PPA	PPA	gp
PPA	PPA	gs
PPA	PPA	mp
PPA	PPA	ms
PREP	PREP	_
PRS	PRS	fp3
PRS	PRS	fs3
PRS	PRS	gp1
PRS	PRS	gp2
PRS	PRS	gs1
PRS	PRS	gs2
PRS	PRS	gs3
PRS	PRS	mp1
PRS	PRS	mp3
PRS	PRS	ms1
PRS	PRS	ms3
QNT	QNT	fp
QNT	QNT	fs
QNT	QNT	gp
QNT	QNT	gs
QNT	QNT	mp
QNT	QNT	ms
REL	REL	_
REL	REL	fp
REL	REL	fs
REL	REL	gp
REL	REL	gs
REL	REL	mp
REL	REL	ms
STT	STT	fs
STT	STT	ms
SYB	SYB	_
UM	UM	fs
UM	UM	ms
V	V	PPT-ms
V	V	c-1p
V	V	c-1s
V	V	c-2s
V	V	c-3p
V	V	c-3s
V	V	fc-1p
V	V	fc-2s
V	V	fc-3p
V	V	fc-3s
V	V	fi-1p
V	V	fi-1s
V	V	fi-2s
V	V	fi-3p
V	V	fi-3s
V	V	ger
V	V	ic-1p
V	V	ic-2s
V	V	ic-3p
V	V	ic-3s
V	V	ii-1p
V	V	ii-1s
V	V	ii-2s
V	V	ii-3p
V	V	ii-3s
V	V	imp-2s
V	V	inf-1p
V	V	inf-3p
V	V	inf-3s
V	V	inf-nInf
V	V	mpi-3s
V	V	pc-1p
V	V	pc-1s
V	V	pc-3p
V	V	pc-3s
V	V	pi-1p
V	V	pi-1s
V	V	pi-2s
V	V	pi-3p
V	V	pi-3s
V	V	ppi-1p
V	V	ppi-1s
V	V	ppi-2s
V	V	ppi-3p
V	V	ppi-3s
VAUX	VAUX	c-3p
VAUX	VAUX	c-3s
VAUX	VAUX	fi-3s
VAUX	VAUX	ic-3s
VAUX	VAUX	ii-3p
VAUX	VAUX	ii-3s
VAUX	VAUX	pc-3p
VAUX	VAUX	pc-3s
VAUX	VAUX	pi-1s
VAUX	VAUX	pi-3p
VAUX	VAUX	pi-3s
WD	WD	fs
WD	WD	mp
WD	WD	ms
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/[ \t]+/\t/sg;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::PT::Cintil - Driver for the Portuguese tagset of the CINTIL corpus (Corpus Internacional do Portugues).

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::PT::Cintil;
  my $driver = Lingua::Interset::Tagset::PT::Cintil->new();
  my $fs = $driver->decode("CN\tCN\tms");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('pt::cintil', "CN\tCN\tms");

=head1 DESCRIPTION

Interset driver for the Portuguese tagset of the CINTIL corpus
(Corpus Internacional do Portugu&ecir;s,
L<http://cintil.ul.pt/>).

=head1 SEE ALSO

L<http://cintil.ul.pt/cintilwhatsin.html#guidelines>

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
