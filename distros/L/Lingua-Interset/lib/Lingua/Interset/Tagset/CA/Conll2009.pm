# ABSTRACT: Driver for the Catalan tagset of the CoNLL 2009 Shared Task.
# Copyright © 2011, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::CA::Conll2009;
use strict;
use warnings;
our $VERSION = '3.013';

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
    return 'ca::conll2009';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for the surface CoNLL features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    my $atoms = \%atoms;
    # PART OF SPEECH ####################
    $atoms->{pos} = $self->create_atom
    (
        'tagset'     => 'ca::conll2009',
        'surfeature' => 'pos',
        'decode_map' =>
        {
            'n' => ['pos' => 'noun'],
            # p postype=numeral ... numeral: dos, tres, quatre, cinc, sis, set, vuit, nou, deu, ...
            'p' => ['pos' => 'noun', 'prontype' => 'prn'],
            'a' => ['pos' => 'adj'],
            # d postype=numeral ... numeral! (cardinal, ordinal and other): tres, quatre, cinc; doble, triple, múltiple
            'd' => ['pos' => 'adj', 'prontype' => 'prn'],
            # w ... date, name of the day of week:
            # 1999, 1998, 2001, any_2000, mes_de_maig, 11_de_setembre, vuit_del_vespre (eight o'clock)
            # dilluns (Monday), dimarts (Tuesday), dimecres (Wednesday), dijous (Thursday), divendres (Friday), dissabte (Saturday), diumenge (Sunday)
            # gener (January), febrer (February), març, abril, maig, juny, juliol, agost, setembre, octubre, novembre, desembre
            'w' => ['pos' => 'noun', 'advtype' => 'tim'],
            # z ... numbers expressed by digits but not numerals-words; and nouns that are often counted?
            # z (without features) ... 10, 15, 20
            # z postype=currency ... pessetes, euros, d&ogra;lars
            # z postype=percentage ... 50%, 30%, 10%
            # We will assume a number for the moment. The feature postype=currency can later turn it to noun.
            'z' => ['pos' => 'num', 'numform' => 'digit'],
            'v' => ['pos' => 'verb'],
            'r' => ['pos' => 'adv'],
            's' => ['pos' => 'adp', 'adpostype' => 'prep'],
            'c' => ['pos' => 'conj'],
            'i' => ['pos' => 'int'],
            'f' => ['pos' => 'punc']
        },
        'encode_map' =>

            { 'pos' => { 'noun' => { 'prontype' => { ''  => { 'numform' => { 'digit' => 'z',
                                                                             '@'     => { 'advtype' => { 'tim' => 'w',
                                                                                                         '@'   => 'n' }}}},
                                                     '@' => 'p' }},
                         'adj'  => { 'adjtype' => { 'pdt' => 'd',
                                                    '@'   => { 'prontype' => { ''  => 'a',
                                                                               '@' => 'd' }}}},
                         'num'  => { 'numform' => { 'digit' => 'z',
                                                    '@'     => { 'other/synpos' => { 'noun' => 'p',
                                                                                     '@'    => 'd' }}}},
                         'verb' => 'v',
                         'adv'  => 'r',
                         'adp'  => 's',
                         'conj' => 'c',
                         'int'  => 'i',
                         'punc' => 'f',
                         'sym'  => 'f',
                         '@'    => 'n' }}
    );
    # DETAILED PART OF SPEECH ####################
    $atoms->{postype} = $self->create_atom
    (
        'tagset'     => 'ca::conll2009',
        'surfeature' => 'postype',
        'decode_map' =>
        {
            # types of nouns
            'common'        => ['nountype' => 'com'],
            'proper'        => ['nountype' => 'prop'],
            # types of adjectives
            'qualificative' => [], # this is the default type of adjective
            'ordinal'       => ['numtype' => 'ord'],
            # types of pronouns
            'personal'      => ['prontype' => 'prs'],
            'possessive'    => ['prontype' => 'prs', 'poss' => 'yes'],
            'article'       => ['prontype' => 'art'],
            'demonstrative' => ['prontype' => 'dem'],
            'interrogative' => ['prontype' => 'int'],
            'indefinite'    => ['prontype' => 'ind'],
            'relative'      => ['prontype' => 'rel'],
            # Exclamative pronoun: only one occurrence in the Catalan corpus and one in Spanish, 'Que' in
            # ca: Que fort que _ s' hagi mort , per&ogra; tots hem de seguir el mateix camí , _ ens hem de resignar .
            # es: hubiera sospechado siquiera qué lejos estaba Fermina_Daza
            # should at least suspect how long Fermina_Daza was
            # This does not seem to be enough evidence to create a new pronoun type.
            'exclamative'   => ['prontype' => 'rel', 'other' => {'prontype' => 'exc'}],
            # types of numerals
            # Here we override the pos value that has been decoded previously (p => noun, d => adj).
            # In order to not lose information in round-trip, we have to save the p|d distinction.
            # Thus the decode() method modifies the 'numeral' value to either 'pnumeral' or 'dnumeral' before using this decoding map.
            'pnumeral'      => ['pos' => 'num', 'numtype' => 'card', 'prontype' => '', 'other' => {'synpos' => 'noun'}],
            'dnumeral'      => ['pos' => 'num', 'numtype' => 'card', 'prontype' => '', 'other' => {'synpos' => 'adj'}],
            'numeral'       => ['pos' => 'num', 'numtype' => 'card', 'prontype' => ''],
            # pos=z (numbers/digits, currencies and percentage)
            'currency'      => ['pos' => 'noun', 'other' => {'postype' => 'currency'}], # although subclass of number (pos=z), these are noun identifiers of currencies (pesetas, dólares, euros)
            'percentage'    => ['numtype' => 'frac', 'other' => {'postype' => 'percentage'}], # Interset does not distinguish percentual from normal counts: 20_por_ciento, 20%
            # types of verbs
            'main'          => [], # main is the default type of verb
            'auxiliary'     => ['verbtype' => 'aux'], # haver [ca] / haber [es]
            'semiauxiliary' => ['verbtype' => 'aux', 'other' => {'verbtype' => 'semiaux'}], # ser / ser; Interset cannot distinguish semiauxiliary from auxiliary
            # types of adverbs
            ###!!! In theory, non-negative adverbs should have postype=general. In practice, there are only two occurrences of this feature
            ###!!! while all other adverbs have empty postype. Therefore I removed postype=general from the list of known tags.
            'negative'      => ['polarity' => 'neg'], # no; main POS is adverb; in other tagsets it could be negative particle
            # prepositions
            'preposition'   => ['adpostype' => 'prep'], # all prepositions (pos=s) have also postype=preposition; it should not occur with other parts of speech than "s"
            # types of conjunctions
            'coordinating'  => ['conjtype' => 'coor'],
            'subordinating' => ['conjtype' => 'sub'],
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'poss' => { 'yes' => 'possessive',
                                               '@'    => { 'prontype' => { 'prs' => 'personal',
                                                                           'dem' => 'demonstrative',
                                                                           'int' => 'interrogative',
                                                                           'ind' => 'indefinite',
                                                                           'rel' => { 'other/prontype' => { 'exc' => 'exclamative',
                                                                                                            '@'   => 'relative' }},
                                                                           '@'   => { 'nountype' => { 'com'  => 'common',
                                                                                                      'prop' => 'proper',
                                                                                                      '@'    => { 'other/postype' => { 'currency' => 'currency' }}}}}}}},
                       'adj'  => { 'poss' => { 'yes' => 'possessive',
                                               '@'    => { 'prontype' => { 'prs' => 'personal',
                                                                           'art' => 'article',
                                                                           'dem' => 'demonstrative',
                                                                           'int' => 'interrogative',
                                                                           'ind' => 'indefinite',
                                                                           'rel' => { 'other/prontype' => { 'exc' => 'exclamative',
                                                                                                            '@'   => 'relative' }},
                                                                           '@'   => { 'numtype' => { 'ord' => 'ordinal',
                                                                                                     '@'   => 'qualificative' }}}}}},
                       'num'  => { 'numform' => { 'digit' => { 'other/postype' => { 'percentage' => 'percentage',
                                                                                    '@'          => '' }},
                                                  '@'     => 'numeral' }},
                       'verb' => { 'other/verbtype' => { 'semiaux' => 'semiauxiliary',
                                                         '@'       => { 'verbtype' => { 'aux' => 'auxiliary',
                                                                                        '@'   => 'main' }}}},
                       'adp'  => { 'adpostype' => { 'prep'     => 'preposition',
                                                    'preppron' => 'preposition' }},
                       'conj' => { 'conjtype' => { 'coor' => 'coordinating',
                                                   'sub'  => 'subordinating' }},
                       '@'    => { 'polarity' => { 'neg' => 'negative' }}}
        }
    );
    # POS FUNCTION ####################
    # posfunction = participle occurs with syntactic adjectives (and one noun) that are morphologically verb participles
    $atoms->{posfunction} = $self->create_atom
    (
        'surfeature' => 'posfunction',
        'decode_map' =>
        {
            'participle' => ['verbform' => 'part']
        },
        'encode_map' =>

            { 'verbform' => { 'part' => 'participle' }}
    );
    # GENDER ####################
    $atoms->{gen} = $self->create_atom
    (
        'tagset'     => 'ca::conll2009',
        'surfeature' => 'gen',
        'decode_map' =>
        {
            'm' => ['gender' => 'masc'],
            'f' => ['gender' => 'fem'],
            # The common gender in Catalan is different from the common gender in Swedish, for which the Interset value 'com' was added.
            # Catalan has only masculine and feminine genders. If it is undistinguishable for a word, the source tagset uses the 'c' value
            # but we will just leave it empty. That's the standard Interset way of saying that nothing can be said about the gender.
            # Unfortunately, we also have to be able to reproduce the original annotation in encoding.
            # So we have to note when we saw 'c' and when there was nothing.
            'c' => ['other' => {'gender' => 'com'}]
        },
        'encode_map' =>

            { 'other/gender' => { 'com' => 'c',
                                  '@'   => { 'gender' => { 'masc' => 'm',
                                                           'fem'  => 'f' }}}}
    );
    # NUMBER ####################
    $atoms->{num} = $self->create_atom
    (
        'tagset'     => 'ca::conll2009',
        'surfeature' => 'num',
        'decode_map' =>
        {
            's' => ['number' => 'sing'],
            'p' => ['number' => 'plur'],
            # The "common number" means that we cannot decide between singular and plural.
            # Ideally we would represent this just by the empty value of number.
            # Unfortunately, we also have to be able to reproduce the original annotation in encoding.
            # So we have to note when we saw 'c' and when there was nothing.
            'c' => ['other' => {'number' => 'com'}]
        },
        'encode_map' =>

            { 'other/number' => { 'com' => 'c',
                                  '@'   => { 'number' => { 'sing' => 's',
                                                           'plur'  => 'p' }}}}
    );
    # PERSON ####################
    $atoms->{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '1' => '1',
            '2' => '2',
            '3' => '3'
        }
    );
    # POLITENESS ####################
    $atoms->{polite} = $self->create_simple_atom
    (
        'intfeature' => 'polite',
        'simple_decode_map' =>
        {
            # Used only for the two polite 2nd person pronouns, "vost&egra;" (sing) and "vost&egra;s" (plur).
            'yes' => 'form'
        }
    );
    # POSSESSOR NUMBER ####################
    $atoms->{possessornum} = $self->create_atom
    (
        'tagset'     => 'ca::conll2009',
        'surfeature' => 'possessornum',
        'decode_map' =>
        {
            's' => ['possnumber' => 'sing'],
            'p' => ['possnumber' => 'plur'],
            'c' => ['other' => {'possnumber' => 'c'}]
        },
        'encode_map' =>

            { 'possnumber' => { 'sing' => 's',
                                'plur'  => 'p',
                                '@'    => { 'other/possnumber' => { 'c' => 'c',
                                                                    '@' => '' }}}}
    );
    # CASE ####################
    # Catalan pronouns can be also marked for case!
    $atoms->{case} = $self->create_atom
    (
        'surfeature' => 'case',
        'decode_map' =>
        {
            'nominative' => ['case' => 'nom'], # jo
            'dative'     => ['case' => 'dat'], # li, -li
            'accusative' => ['case' => 'acc'], # el, -lo, l', la, -la, els, 'ls, les, -les
            'oblique'    => ['prepcase' => 'pre'] # mi, si
        },
        'encode_map' =>

            { 'prepcase' => { 'pre' => 'oblique',
                              '@'   => { 'case' => { 'nom' => 'nominative',
                                                     'dat' => 'dative',
                                                     'acc' => 'accusative' }}}}
    );
    # MOOD ####################
    $atoms->{mood} = $self->create_atom
    (
        'surfeature' => 'mood',
        'decode_map' =>
        {
            'infinitive'     => ['verbform' => 'inf'],
            'indicative'     => ['verbform' => 'fin', 'mood' => 'ind'],
            'imperative'     => ['verbform' => 'fin', 'mood' => 'imp'],
            'subjunctive'    => ['verbform' => 'fin', 'mood' => 'sub'],
            'gerund'         => ['verbform' => 'ger'],
            'pastparticiple' => ['verbform' => 'part', 'tense' => 'past']
        },
        'encode_map' =>

            { 'verbform' => { 'inf'  => 'infinitive',
                              'fin'  => { 'mood' => { 'ind' => 'indicative',
                                                      'cnd' => 'indicative',
                                                      'imp' => 'imperative',
                                                      'sub' => 'subjunctive' }},
                              'ger'  => 'gerund',
                              'part' => 'pastparticiple' }}
    );
    # TENSE ####################
    $atoms->{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            'past'          => ['tense' => 'past'],
            'imperfect'     => ['tense' => 'imp'],
            'present'       => ['tense' => 'pres'],
            'future'        => ['tense' => 'fut'],
            'conditional'   => ['mood'  => 'cnd']
        },
        'encode_map' =>

            { 'tense' => { 'past' => 'past',
                           'imp'  => 'imperfect',
                           'pres' => 'present',
                           'fut'  => 'future',
                           '@'    => { 'mood' => { 'cnd' => 'conditional' }}}}
    );
    # CONTRACTED PREPOSITION + ARTICLE ####################
    # Contracted preposition with definite article: del, al, pel, des_del, dels, als, a_través_dels
    ###!!! DZ Interset does not cover this yet, although it is planned.
    ###!!! We use adpostype=preppron for the moment because it is the closest match.
    ###!!! Something like adpostype=prepart would be more appropriate.
    ###!!! A dedicated feature for types of fused words would be perhaps even better.
    ###!!! Ideally, we would have two feature structures for the two components. But that would be a new dimension of Interset.
    ###!!! The Universal Dependencies solve this by a second level of tokenization that splits such tokens to syntactic words.
    $atoms->{contracted} = $self->create_atom
    (
        'surfeature' => 'contracted',
        'decode_map' =>
        {
            'yes'           => ['adpostype' => 'preppron']
        },
        'encode_map' =>

            { 'adpostype' => { 'preppron' => 'yes' }}
    );
    # PUNCTUATION TYPE ####################
    $atoms->{punct} = $self->create_atom
    (
        'tagset'     => 'ca::conll2009',
        'surfeature' => 'punct',
        'decode_map' =>
        {
            'bracket'         => ['punctype' => 'brck'],
            'colon'           => ['punctype' => 'colo'],
            'comma'           => ['punctype' => 'comm'],
            'etc'             => ['punctype' => 'comm', 'other' => {'punctype' => 'etc'}],
            'exclamationmark' => ['punctype' => 'excl'],
            'hyphen'          => ['punctype' => 'dash'],
            'mathsign'        => ['pos' => 'sym'],
            'period'          => ['punctype' => 'peri'],
            'questionmark'    => ['punctype' => 'qest'],
            'quotation'       => ['punctype' => 'quot'],
            'semicolon'       => ['punctype' => 'semi'],
            'slash'           => ['punctype' => 'colo', 'other' => {'punctype' => 'slash'}] # no special value for slash in Interset
        },
        'encode_map' =>

            { 'punctype' => { 'brck' => 'bracket',
                              'colo' => { 'other/punctype' => { 'slash' => 'slash',
                                                                '@'     => 'colon' }},
                              'comm' => { 'other/punctype' => { 'etc'   => 'etc',
                                                                '@'     => 'comma' }},
                              'excl' => 'exclamationmark',
                              'dash' => 'hyphen',
                              'peri' => 'period',
                              'qest' => 'questionmark',
                              'quot' => 'quotation',
                              'semi' => 'semicolon',
                              '@'    => { 'pos' => { 'sym' => 'mathsign' }}}}
    );
    # PAIRED PUNCTUATION SIDE ####################
    $atoms->{punctenclose} = $self->create_simple_atom
    (
        'intfeature' => 'puncside',
        'simple_decode_map' =>
        {
            'open'  => 'ini',
            'close' => 'fin'
        }
    );
    return $atoms;
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
    $fs->set_tagset('ca::conll2009');
    my $atoms = $self->atoms();
    # Two components: part-of-speech tag and features
    # Only features with non-empty values appear in the tag.
    # example: n\tpostype=common|gen=m|num=s
    my ($pos, $features) = split(/\s+/, $tag);
    $features = '' if($features eq '_');
    my @features_conll = split(/\|/, $features);
    my %features_conll;
    foreach my $f (@features_conll)
    {
        if($f =~ m/^(\w+)=(.+)$/)
        {
            $features_conll{$1} = $2;
        }
        else
        {
            $features_conll{$f} = $f;
        }
    }
    $atoms->{pos}->decode_and_merge_hard($pos, $fs);
    foreach my $name ('postype', 'gen', 'num', 'posfunction', 'person', 'polite', 'possessornum', 'case', 'mood', 'tense', 'contracted', 'punct', 'punctenclose')
    {
        if(defined($features_conll{$name}) && $features_conll{$name} ne '')
        {
            # The feature postype=numeral will override the pos value that has been decoded previously (p => noun, d => adj, both will change to num).
            # In order to not lose information in round-trip, we have to save the p|d distinction.
            # Thus the decode() method modifies the 'numeral' value to either 'pnumeral' or 'dnumeral' before using this decoding map.
            if($name eq 'postype' && $features_conll{$name} eq 'numeral')
            {
                $features_conll{$name} = $pos.'numeral';
                $fs->set_prontype('');
            }
            $atoms->{$name}->decode_and_merge_hard($features_conll{$name}, $fs);
        }
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
    my @feature_names = ('postype', 'gen', 'num', 'posfunction', 'person', 'polite', 'possessornum', 'case', 'mood', 'tense', 'contracted', 'punct', 'punctenclose');
    my @features;
    foreach my $name (@feature_names)
    {
        my $value = '';
        if(!defined($atoms->{$name}))
        {
            confess("Cannot find atom for '$name'");
        }
        $value = $atoms->{$name}->encode($fs);
        # Corrections: Some features are only mentioned with some words. Especially gen=c and num=c.
        if($name eq 'gen')
        {
            # "Common gender" in Catalan actually means that we cannot decide between masculine and feminine.
            if($pos =~ m/^[napdvs]$/ && $value ne 'm' && $value ne 'f')
            {
                $value = 'c';
            }
        }
        elsif($name eq 'num')
        {
            # "Common number" in Catalan actually means that we cannot decide between singular and plural.
            if($pos =~ m/^[napdvs]$/ && $value ne 's' && $value ne 'p')
            {
                $value = 'c';
            }
        }
        elsif($name eq 'posfunction' && $value eq 'participle' && $fs->pos() eq 'verb')
        {
            # posfunction=participle occurs with syntactic adjectives that are morphologically verb participles.
            # It does not occur with verb where there is mood=pastparticiple instead.
            $value = '';
        }
        elsif($name eq 'mood' && $value eq 'pastparticiple' && $pos eq 'a')
        {
            # mood=pastparticiple occurs with verbs only.
            # It does not occur with participial adjectives where there is posfunction=participle instead.
            $value = '';
        }
        elsif($name eq 'tense' && $value eq 'past' && $fs->verbform() eq 'part')
        {
            # tense=past does not co-occur with mood=pastparticiple.
            $value = '';
        }
        if(defined($value) && $value ne '')
        {
            push(@features, "$name=$value");
        }
    }
    my $features = '_';
    if(scalar(@features) > 0)
    {
        $features = join('|', @features);
    }
    my $tag = "$pos\t$features";
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 276 distinct tags found.
# A few feature combinations were added so that valid tags can be encoded
# without the 'other' feature. A few erroneous combinations were removed.
# The resulting number of tags is 272.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
a	postype=ordinal|gen=c|num=s
a	postype=ordinal|gen=f|num=p
a	postype=ordinal|gen=f|num=s
a	postype=ordinal|gen=m|num=p
a	postype=ordinal|gen=m|num=s
a	postype=qualificative|gen=c|num=c
a	postype=qualificative|gen=c|num=p
a	postype=qualificative|gen=c|num=s
a	postype=qualificative|gen=f|num=p
a	postype=qualificative|gen=f|num=p|posfunction=participle
a	postype=qualificative|gen=f|num=s
a	postype=qualificative|gen=f|num=s|posfunction=participle
a	postype=qualificative|gen=m|num=p
a	postype=qualificative|gen=m|num=p|posfunction=participle
a	postype=qualificative|gen=m|num=s
a	postype=qualificative|gen=m|num=s|posfunction=participle
c	_
c	postype=coordinating
c	postype=subordinating
c	postype=subordinating|gen=c|num=c
d	postype=article|gen=c|num=s
d	postype=article|gen=f|num=p
d	postype=article|gen=f|num=s
d	postype=article|gen=m|num=p
d	postype=article|gen=m|num=s
d	postype=demonstrative|gen=c|num=p
d	postype=demonstrative|gen=c|num=s
d	postype=demonstrative|gen=f|num=p
d	postype=demonstrative|gen=f|num=s
d	postype=demonstrative|gen=m|num=p
d	postype=demonstrative|gen=m|num=s
d	postype=exclamative|gen=c|num=c
d	postype=indefinite|gen=c|num=c
d	postype=indefinite|gen=c|num=p
d	postype=indefinite|gen=c|num=s
d	postype=indefinite|gen=f|num=p
d	postype=indefinite|gen=f|num=s
d	postype=indefinite|gen=m|num=p
d	postype=indefinite|gen=m|num=s
d	postype=interrogative|gen=f|num=p
d	postype=interrogative|gen=f|num=s
d	postype=interrogative|gen=m|num=p
d	postype=interrogative|gen=m|num=s
d	postype=numeral|gen=c|num=p
d	postype=numeral|gen=c|num=s
d	postype=numeral|gen=f|num=p
d	postype=numeral|gen=f|num=s
d	postype=numeral|gen=m|num=p
d	postype=numeral|gen=m|num=s
d	postype=possessive|gen=c|num=p|person=1|possessornum=p
d	postype=possessive|gen=f|num=p|person=1|possessornum=p
d	postype=possessive|gen=f|num=p|person=1|possessornum=s
d	postype=possessive|gen=f|num=p|person=3
d	postype=possessive|gen=f|num=s|person=1|possessornum=p
d	postype=possessive|gen=f|num=s|person=1|possessornum=s
d	postype=possessive|gen=f|num=s|person=2|possessornum=s
d	postype=possessive|gen=f|num=s|person=3
d	postype=possessive|gen=m|num=p|person=1|possessornum=p
d	postype=possessive|gen=m|num=p|person=1|possessornum=s
d	postype=possessive|gen=m|num=p|person=2|possessornum=s
d	postype=possessive|gen=m|num=p|person=3
d	postype=possessive|gen=m|num=s|person=1|possessornum=p
d	postype=possessive|gen=m|num=s|person=1|possessornum=s
d	postype=possessive|gen=m|num=s|person=2|possessornum=s
d	postype=possessive|gen=m|num=s|person=3
d	postype=relative|gen=c|num=c
d	postype=relative|gen=c|num=s
f	punct=bracket|punctenclose=close
f	punct=bracket|punctenclose=open
f	punct=colon
f	punct=comma
f	punct=comma|punctenclose=close
f	punct=comma|punctenclose=open
f	punct=etc
f	punct=exclamationmark|punctenclose=close
f	punct=exclamationmark|punctenclose=open
f	punct=hyphen
f	punct=mathsign
f	punct=period
f	punct=questionmark|punctenclose=close
f	punct=questionmark|punctenclose=open
f	punct=quotation
f	punct=semicolon
f	punct=slash
i	_
n	postype=common|gen=c|num=c
n	postype=common|gen=c|num=p
n	postype=common|gen=c|num=s
n	postype=common|gen=f|num=c
n	postype=common|gen=f|num=p
n	postype=common|gen=f|num=s
n	postype=common|gen=m|num=c
n	postype=common|gen=m|num=p
n	postype=common|gen=m|num=s
n	postype=proper|gen=c|num=c
n	postype=proper|gen=m|num=s
p	gen=c|num=c
p	gen=c|num=c|person=3
p	gen=c|num=p|person=1
p	gen=c|num=p|person=2
p	gen=c|num=s|person=1
p	gen=c|num=s|person=2
p	postype=demonstrative|gen=c|num=p
p	postype=demonstrative|gen=c|num=s
p	postype=demonstrative|gen=f|num=p
p	postype=demonstrative|gen=f|num=s
p	postype=demonstrative|gen=m|num=p
p	postype=demonstrative|gen=m|num=s
p	postype=indefinite|gen=c|num=c
p	postype=indefinite|gen=c|num=p
p	postype=indefinite|gen=c|num=s
p	postype=indefinite|gen=f|num=p
p	postype=indefinite|gen=f|num=s
p	postype=indefinite|gen=m|num=p
p	postype=indefinite|gen=m|num=s
p	postype=interrogative|gen=c|num=c
p	postype=interrogative|gen=c|num=s
p	postype=interrogative|gen=f|num=p
p	postype=interrogative|gen=f|num=s
p	postype=interrogative|gen=m|num=p
p	postype=interrogative|gen=m|num=s
p	postype=numeral|gen=c|num=p
p	postype=numeral|gen=c|num=s
p	postype=numeral|gen=f|num=p
p	postype=numeral|gen=f|num=s
p	postype=numeral|gen=m|num=p
p	postype=numeral|gen=m|num=s
p	postype=personal|gen=c|num=c|person=3
p	postype=personal|gen=c|num=c|person=3|case=oblique
p	postype=personal|gen=c|num=p|person=1
p	postype=personal|gen=c|num=p|person=2
p	postype=personal|gen=c|num=p|person=2|polite=yes
p	postype=personal|gen=c|num=p|person=3
p	postype=personal|gen=c|num=s|person=1
p	postype=personal|gen=c|num=s|person=1|case=nominative
p	postype=personal|gen=c|num=s|person=1|case=oblique
p	postype=personal|gen=c|num=s|person=2
p	postype=personal|gen=c|num=s|person=2|polite=yes
p	postype=personal|gen=c|num=s|person=3|case=accusative
p	postype=personal|gen=c|num=s|person=3|case=dative
p	postype=personal|gen=f|num=p|person=3
p	postype=personal|gen=f|num=p|person=3|case=accusative
p	postype=personal|gen=f|num=s|person=3
p	postype=personal|gen=f|num=s|person=3|case=accusative
p	postype=personal|gen=m|num=p|person=3
p	postype=personal|gen=m|num=p|person=3|case=accusative
p	postype=personal|gen=m|num=s|person=3
p	postype=personal|gen=m|num=s|person=3|case=accusative
p	postype=possessive|gen=c|num=p|person=3|possessornum=p
p	postype=possessive|gen=c|num=s|person=3|possessornum=p
p	postype=possessive|gen=f|num=p|person=1|possessornum=p
p	postype=possessive|gen=f|num=p|person=3
p	postype=possessive|gen=f|num=p|person=3|possessornum=s
p	postype=possessive|gen=f|num=s|person=1|possessornum=p
p	postype=possessive|gen=f|num=s|person=3
p	postype=possessive|gen=f|num=s|person=3|possessornum=s
p	postype=possessive|gen=m|num=p|person=3
p	postype=possessive|gen=m|num=s|person=1|possessornum=p
p	postype=possessive|gen=m|num=s|person=3
p	postype=relative|gen=c|num=c
p	postype=relative|gen=c|num=p
p	postype=relative|gen=c|num=s
p	postype=relative|gen=m|num=s
r	_
r	postype=negative
s	postype=preposition|gen=c|num=c
s	postype=preposition|gen=m|num=p|contracted=yes
s	postype=preposition|gen=m|num=s|contracted=yes
v	postype=auxiliary|gen=c|num=c|mood=gerund
v	postype=auxiliary|gen=c|num=c|mood=infinitive
v	postype=auxiliary|gen=c|num=c|person=1|mood=subjunctive|tense=imperfect
v	postype=auxiliary|gen=c|num=p|person=1|mood=indicative|tense=conditional
v	postype=auxiliary|gen=c|num=p|person=1|mood=indicative|tense=future
v	postype=auxiliary|gen=c|num=p|person=1|mood=indicative|tense=imperfect
v	postype=auxiliary|gen=c|num=p|person=1|mood=indicative|tense=present
v	postype=auxiliary|gen=c|num=p|person=1|mood=subjunctive|tense=imperfect
v	postype=auxiliary|gen=c|num=p|person=1|mood=subjunctive|tense=present
v	postype=auxiliary|gen=c|num=p|person=2|mood=indicative|tense=future
v	postype=auxiliary|gen=c|num=p|person=2|mood=indicative|tense=present
v	postype=auxiliary|gen=c|num=p|person=3|mood=imperative
v	postype=auxiliary|gen=c|num=p|person=3|mood=indicative|tense=conditional
v	postype=auxiliary|gen=c|num=p|person=3|mood=indicative|tense=future
v	postype=auxiliary|gen=c|num=p|person=3|mood=indicative|tense=imperfect
v	postype=auxiliary|gen=c|num=p|person=3|mood=indicative|tense=past
v	postype=auxiliary|gen=c|num=p|person=3|mood=indicative|tense=present
v	postype=auxiliary|gen=c|num=p|person=3|mood=subjunctive|tense=imperfect
v	postype=auxiliary|gen=c|num=p|person=3|mood=subjunctive|tense=present
v	postype=auxiliary|gen=c|num=s|person=1|mood=indicative|tense=future
v	postype=auxiliary|gen=c|num=s|person=1|mood=indicative|tense=imperfect
v	postype=auxiliary|gen=c|num=s|person=1|mood=indicative|tense=present
v	postype=auxiliary|gen=c|num=s|person=2|mood=indicative|tense=present
v	postype=auxiliary|gen=c|num=s|person=3|mood=imperative
v	postype=auxiliary|gen=c|num=s|person=3|mood=indicative|tense=conditional
v	postype=auxiliary|gen=c|num=s|person=3|mood=indicative|tense=future
v	postype=auxiliary|gen=c|num=s|person=3|mood=indicative|tense=imperfect
v	postype=auxiliary|gen=c|num=s|person=3|mood=indicative|tense=past
v	postype=auxiliary|gen=c|num=s|person=3|mood=indicative|tense=present
v	postype=auxiliary|gen=c|num=s|person=3|mood=subjunctive|tense=imperfect
v	postype=auxiliary|gen=c|num=s|person=3|mood=subjunctive|tense=present
v	postype=auxiliary|gen=m|num=s|mood=pastparticiple
v	postype=main|gen=c|num=c
v	postype=main|gen=c|num=c|mood=gerund
v	postype=main|gen=c|num=c|mood=infinitive
v	postype=main|gen=c|num=c|mood=pastparticiple
v	postype=main|gen=c|num=p|person=1|mood=imperative
v	postype=main|gen=c|num=p|person=1|mood=indicative|tense=conditional
v	postype=main|gen=c|num=p|person=1|mood=indicative|tense=future
v	postype=main|gen=c|num=p|person=1|mood=indicative|tense=imperfect
v	postype=main|gen=c|num=p|person=1|mood=indicative|tense=present
v	postype=main|gen=c|num=p|person=1|mood=subjunctive|tense=imperfect
v	postype=main|gen=c|num=p|person=1|mood=subjunctive|tense=present
v	postype=main|gen=c|num=p|person=2|mood=indicative|tense=future
v	postype=main|gen=c|num=p|person=2|mood=indicative|tense=present
v	postype=main|gen=c|num=p|person=2|mood=subjunctive|tense=present
v	postype=main|gen=c|num=p|person=3|mood=imperative
v	postype=main|gen=c|num=p|person=3|mood=indicative|tense=conditional
v	postype=main|gen=c|num=p|person=3|mood=indicative|tense=future
v	postype=main|gen=c|num=p|person=3|mood=indicative|tense=imperfect
v	postype=main|gen=c|num=p|person=3|mood=indicative|tense=past
v	postype=main|gen=c|num=p|person=3|mood=indicative|tense=present
v	postype=main|gen=c|num=p|person=3|mood=subjunctive|tense=imperfect
v	postype=main|gen=c|num=p|person=3|mood=subjunctive|tense=present
v	postype=main|gen=c|num=s|person=1|mood=indicative|tense=conditional
v	postype=main|gen=c|num=s|person=1|mood=indicative|tense=future
v	postype=main|gen=c|num=s|person=1|mood=indicative|tense=imperfect
v	postype=main|gen=c|num=s|person=1|mood=indicative|tense=present
v	postype=main|gen=c|num=s|person=1|mood=subjunctive|tense=imperfect
v	postype=main|gen=c|num=s|person=1|mood=subjunctive|tense=present
v	postype=main|gen=c|num=s|person=2|mood=imperative
v	postype=main|gen=c|num=s|person=2|mood=indicative|tense=present
v	postype=main|gen=c|num=s|person=2|mood=subjunctive|tense=present
v	postype=main|gen=c|num=s|person=3|mood=imperative
v	postype=main|gen=c|num=s|person=3|mood=indicative|tense=conditional
v	postype=main|gen=c|num=s|person=3|mood=indicative|tense=future
v	postype=main|gen=c|num=s|person=3|mood=indicative|tense=imperfect
v	postype=main|gen=c|num=s|person=3|mood=indicative|tense=past
v	postype=main|gen=c|num=s|person=3|mood=indicative|tense=present
v	postype=main|gen=c|num=s|person=3|mood=subjunctive|tense=imperfect
v	postype=main|gen=c|num=s|person=3|mood=subjunctive|tense=present
v	postype=main|gen=f|num=p|mood=pastparticiple
v	postype=main|gen=f|num=s|mood=pastparticiple
v	postype=main|gen=m|num=p|mood=pastparticiple
v	postype=main|gen=m|num=s|mood=pastparticiple
v	postype=semiauxiliary|gen=c|num=c|mood=gerund
v	postype=semiauxiliary|gen=c|num=c|mood=infinitive
v	postype=semiauxiliary|gen=c|num=p|person=1|mood=indicative|tense=imperfect
v	postype=semiauxiliary|gen=c|num=p|person=1|mood=indicative|tense=present
v	postype=semiauxiliary|gen=c|num=p|person=1|mood=subjunctive|tense=present
v	postype=semiauxiliary|gen=c|num=p|person=3|mood=imperative
v	postype=semiauxiliary|gen=c|num=p|person=3|mood=indicative|tense=conditional
v	postype=semiauxiliary|gen=c|num=p|person=3|mood=indicative|tense=future
v	postype=semiauxiliary|gen=c|num=p|person=3|mood=indicative|tense=imperfect
v	postype=semiauxiliary|gen=c|num=p|person=3|mood=indicative|tense=past
v	postype=semiauxiliary|gen=c|num=p|person=3|mood=indicative|tense=present
v	postype=semiauxiliary|gen=c|num=p|person=3|mood=subjunctive|tense=imperfect
v	postype=semiauxiliary|gen=c|num=p|person=3|mood=subjunctive|tense=present
v	postype=semiauxiliary|gen=c|num=s|person=1|mood=indicative|tense=imperfect
v	postype=semiauxiliary|gen=c|num=s|person=1|mood=indicative|tense=present
v	postype=semiauxiliary|gen=c|num=s|person=2|mood=indicative|tense=present
v	postype=semiauxiliary|gen=c|num=s|person=3|mood=imperative
v	postype=semiauxiliary|gen=c|num=s|person=3|mood=indicative|tense=conditional
v	postype=semiauxiliary|gen=c|num=s|person=3|mood=indicative|tense=future
v	postype=semiauxiliary|gen=c|num=s|person=3|mood=indicative|tense=imperfect
v	postype=semiauxiliary|gen=c|num=s|person=3|mood=indicative|tense=past
v	postype=semiauxiliary|gen=c|num=s|person=3|mood=indicative|tense=present
v	postype=semiauxiliary|gen=c|num=s|person=3|mood=subjunctive|tense=imperfect
v	postype=semiauxiliary|gen=c|num=s|person=3|mood=subjunctive|tense=present
v	postype=semiauxiliary|gen=m|num=s|mood=pastparticiple
w	_
z	_
z	postype=currency
z	postype=percentage
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/ \s+/\t/sg;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::CA::Conll2009 - Driver for the Catalan tagset of the CoNLL 2009 Shared Task.

=head1 VERSION

version 3.013

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::CA::Conll2009;
  my $driver = Lingua::Interset::Tagset::CA::Conll2009->new();
  my $fs = $driver->decode("n\tpostype=common|gen=m|num=s");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('ca::conll2009', "n\tpostype=common|gen=m|num=s");

=head1 DESCRIPTION

Interset driver for the Catalan tagset of the CoNLL 2009 Shared Task.
CoNLL 2009 tagsets in Interset are traditionally two values separated by tabs.
The values come from the CoNLL 2009 columns POS and FEAT.

Note that the C<ca::conll2009> and C<es::conll2009> tagsets are identical as
they both come from the AnCora Catalan-Spanish corpus. For convenience,
separate drivers called CA::Conll2009 and ES::Conll2009 are provided, but one
is derived from the other.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::ES::Conll2009>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
