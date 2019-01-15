# ABSTRACT: Driver for the German tagset of SMOR (Stuttgart Morphology)
# Modified by Lefteris Avramidis, based on original script from Dan Zeman <zeman@ufal.mff.cuni.cz>
# Completed by Dan Zeman.
# 2017: adapted to Universal Dependencies v2.

package Lingua::Interset::Tagset::DE::Smor;
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
    return 'de::smor';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
# http://www.cis.uni-muenchen.de/~schmid/tools/SMOR/dspin/ch01s03.html#id558692
# https://github.com/rsennrich/SMORLemma/blob/master/symbols.fst
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            '+ADJ'     => ['pos' => 'adj'],
            '+ADV'     => ['pos' => 'adv'],
            '+ART'     => ['pos' => 'adj', 'prontype' => 'art'],
            '+CARD'    => ['pos' => 'num', 'numtype' => 'card'],
            #'+CHAR' TODO
            #'+CIRCP
            '+CONJ'    => ['pos' => 'conj'],
            '+DEM'     => ['pos' => 'adj', 'prontype' => 'dem'],
            # if morph feature <Attr> then pos => 'adj'
            # if morph feature <Subst> then pos => 'noun'
            '+INDEF'   => ['pos' => 'adj', 'prontype' => 'ind'],
            # if morph feature <Attr> then pos => 'adj'
            # if morph feature <Subst> then pos => 'noun'
            '+INTJ'    => ['pos' => 'int'],
            '+NN'      => ['pos' => 'noun', 'nountype' => 'com'],
            '+NPROP'   => ['pos' => 'noun', 'nountype' => 'prop'],
            '+ORD'     => ['pos' => 'adj', 'numtype' => 'ord'],
            # possessive pronoun
            '+POSS'    => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
            # if morph feature <Attr> then pos => 'adj'
            # if morph feature <Subst> then pos => 'noun'
            '+POSTP'   => ['pos' => 'adp', 'adpostype' => 'post'],
            '+PPRO'    => ['pos' => 'noun', 'prontype' => 'prs'],
            '+PREP'    => ['pos' => 'adp', 'adpostype' => 'prep'],
            '+PREPART' => ['pos' => 'adp', 'adpostype' => 'preppron'],
            # dabei, dadurch, dagegen, damit, danach, daran, darauf, daraus, darunter, darüber, davor, dazu,
            # demnach, dran, drauf, draus, drunter, hieran, hierauf, wobei, wodurch, womit
            '+PROADV'  => ['pos' => 'adv', 'prontype' => 'dem|rel'],
            # answer particle: bitte, doch, ja, nein, nö, schon
            # negative particle: nicht, net
            '+PTCL'    => ['pos' => 'part'],
            '+PUNCT'   => ['pos' => 'punc'],
            '+REL'     => ['pos' => 'noun', 'prontype' => 'rel'],
            # if morph feature <Attr> then pos => 'adj'
            # if morph feature <Subst> then pos => 'noun'
            '+SYMBOL'  => ['pos' => 'sym'],
            '+TRUNC'   => ['hyph' => 'yes'],
            '+V'       => ['pos' => 'verb'],
            '+VPART'   => ['pos' => 'part', 'parttype' => 'vbp'],
            '+WADV'    => ['pos' => 'adv', 'prontype' => 'int'],
            '+WPRO'    => ['pos' => 'noun', 'prontype' => 'int']
            # if morph feature <Attr> then pos => 'adj'
            # if morph feature <Subst> then pos => 'noun'
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { 'dem' => '+DEM',
                                                   'ind' => '+INDEF',
                                                   'prs' => { 'poss' => { 'yes' => '+POSS',
                                                                          '@'    => '+PPRO' }},
                                                   'rcp' => '+PPRO',
                                                   'rel' => '+REL',
                                                   'int' => '+WPRO',
                                                   '@'   => { 'numtype' => { 'card' => '+CARD',
                                                                             '@'    => { 'nountype' => { 'prop' => '+NPROP',
                                                                                                         '@'    => '+NN' }}}}}},
                       'adj'  => { 'prontype' => { 'art' => '+ART',
                                                   'dem' => '+DEM',
                                                   'ind' => '+INDEF',
                                                   'prs' => '+POSS',
                                                   'rel' => '+REL',
                                                   'int' => '+WPRO',
                                                   '@'   => { 'numtype' => { 'card' => '+CARD',
                                                                             'ord'  => '+ORD',
                                                                             '@'    => '+ADJ' }}}},
                       'num'  => '+CARD',
                       'verb' => '+V',
                       'adv'  => { 'prontype' => { 'dem' => '+PROADV',
                                                   'rel' => '+PROADV',
                                                   'int' => '+WADV',
                                                   '@'   => '+ADV' }},
                       'adp'  => { 'adpostype' => { 'post'     => '+POSTP',
                                                    'preppron' => '+PREPART',
                                                    '@'        => '+PREP' }},
                       'conj' => '+CONJ',
                       'part' => { 'parttype' => { 'vbp' => '+VPART',
                                                   '@'   => '+PTCL' }},
                       'int'  => '+INTJ',
                       'sym'  => '+SYMBOL',
                       'punc' => '+PUNCT',
                       '@'    => { 'hyph' => { 'yes' => '+TRUNC' }}}
        }
    );
    # UNINFLECTED SHORT FORMS OF ADJECTIVES ####################
    # Adjectives that modify the following noun inflect for gender, number and case: ein alter Mann, eine alte Frau, ein altes Auto...
    # Adjectives used adverbially and predicatively do not inflect: der Mann ist alt; ein grün gemaltes Haus.
    $atoms{adjform} = $self->create_atom
    (
        'surfeature' => 'adjform',
        'decode_map' =>
        {
            ###!!! Could we use the 'morphpos' feature? But the Adv and Pred forms never differ, or do they?
            'Adv'   => ['other' => {'adjform' => 'adv'}],
            'Pred'  => ['other' => {'adjform' => 'pred'}],
            # uninflected adjective such as "lila"
            'Invar' => ['other' => {'adjform' => 'invar'}]
        },
        'encode_map' =>
        {
            'other/adjform' => { 'adv'   => 'Adv',
                                 'pred'  => 'Pred',
                                 'invar' => 'Invar' }
        }
    );
    # SUBSTANTIVE AND ATTRIBUTIVE PRONOUNS AND NUMERALS ####################
    # Knowing that this feature always comes after part of speech, we silently overwrite the previously decoded value of pos.
    # <+INDEF><Attr>: all, alle, allen, allerlei, alles, andere, andre, andres, beide, eine, einem, einen, einer, eines, einige
    # <+INDEF><Subst>: alle, allen, alles, andere, andre, andres, beide, beides, eine, einem, einen, einer, eines, einige, einigen
    # <+DEM><Attr>: dasselbe, deren, derjenige, derselben, dessen, diejenigen, dies, diese, dieselbe, diesem, diesen, dieser, dieses
    # <+DEM><Subst>: dasselbe, denen, der, deren, derjenige, derselben, dessen, die, diejenigen, dies, diese, dieselbe, diesem
    # <+POSS><Attr>: dein, deinem, deinen, euer, eure, euren, eurer, ihr, ihre, ihrem, ihren, ihrer, ihres, mein, meine, meinen
    # <+POSS><Subst>: deinem, deinen, eure, euren, eurer, ihre, ihrem, ihren, ihrer, ihres, meine, meinen, meiner, meines, seine
    # <+REL><Attr>: deren, dessen
    # <+REL><Subst>: das, dem, den, denen, der, deren, derer, dessen, die, was, welche, welchem, welchen, welcher, welches
    # <+WPRO><Attr>: was, welch, welche, welchem, welchen, welcher, welches, wieviele
    # <+WPRO><Subst>: was, welche, welchem, welcher, welches, wem, wen, wieviele, wer, wessen
    # <+CARD><Pro>: acht, achtundfünfzig, achtzehn, anderthalb, drei, dreieinhalb, dreieinviertel, dreihundert, dreizehn, dreißig,
    # eindreiviertel, eine, eineinhalb, eineinviertel, einem, einen, einer, eines, einhundert, einhundertfünfzig, eintausend, einundvierzig, elf,
    # fünf, fünfeinhalb, fünfhundert, fünftausend, fünfundzwanzig, fünfzehn, fünfzig, hundert, hunderttausend, I, II, III, IV, L, M, MMD,
    # neun, neunzehn, neunzig, null, sechs, sechseinhalb, sechzehn, sechzehneinhalb, sechzig, sieben, siebeneinhalb, siebzehn, siebzig,
    # tausend, VI, VIII, vier, viereinhalb, viertausend, vierzig, X, XIII, XIV, XV,
    # zehn, zehntausend, zwanzig, zwei, zweidreiviertel, zweidrittel, zweieinhalb, zweieinviertel, zweier, zwölf, zwölfeinhalb, 0, 0,02, ...
    # <+CARD><Attr>: ein
    # <+CARD><Subst>: einer, eines, eins, fünfe
    $atoms{pronform} = $self->create_atom
    (
        'surfeature' => 'pronform',
        'decode_map' =>
        {
            # Substituierende Form.
            'Subst' => ['pos' => 'noun'],
            # Attributive Form (z.B. attributive Adjektive).
            'Attr'  => ['pos' => 'adj'],
            # Documentation: Pronomialer Gebrauch, beispielsweise bei Possessivpronomen "seiner".
            # However, I never saw this feature with "seiner". I saw it with cardinal numerals.
            # In fact, most occurrences of cardinals are <Pro> and only some special cases can be <Attr> or <Subst>.
            # It does not seem to have anything in common with pronouns.
            'Pro'   => ['other' => {'pronform' => 'pro'}],
            # <+PPRO><Pers> = personal pronoun (ich, du, er, sie, es, wir, ihr)
            # <+PPRO><Rec> = reciprocal pronoun (einander)
            # <+PPRO><Refl> = reflexive pronoun (dich, dir, euch, mich, mir, sich, uns)
            'Pers'  => ['prontype' => 'prs'],
            'Rec'   => ['prontype' => 'rcp'],
            'Refl'  => ['prontype' => 'prs', 'reflex' => 'yes']
        },
        'encode_map' =>
        {
            'reflex' => { 'yes' => 'Refl',
                          '@'      => { 'prontype' => { 'rcp' => 'Rec',
                                                        'prs' => { 'poss' => { 'yes' => { 'pos' => { 'noun' => 'Subst',
                                                                                                      'adj'  => 'Attr' }},
                                                                               '@'    => 'Pers' }},
                                                        '@'   => { 'other/pronform' => { 'pro' => 'Pro',
                                                                                         '@'   => { 'pos' => { 'noun' => 'Subst',
                                                                                                               'adj'  => 'Attr' }}}}}}}
        }
    );
    # CONJUNCTION TYPE ####################
    $atoms{conjtype} = $self->create_simple_atom
    (
        'intfeature' => 'conjtype',
        'simple_decode_map' =>
        {
            'Coord'  => 'coor',
            'Sub'    => 'sub',
            'Compar' => 'comp'
        }
    );
    # PARTICLE TYPE ####################
    $atoms{parttype} = $self->create_atom
    (
        'surfeature' => 'parttype',
        'decode_map' =>
        {
            # response particle: bitte, doch, ja, nein, nö, schon
            'Ans' => ['parttype' => 'res'],
            # negative particle: nicht, net
            'Neg' => ['polarity' => 'neg']
        },
        'encode_map' =>
        {
            'parttype' => { 'res' => 'Ans',
                            '@'   => { 'polarity' => { 'neg' => 'Neg' }}}
        }
    );
    # PUNCTUATION TYPE ####################
    $atoms{punctype} = $self->create_atom
    (
        'surfeature' => 'punctype',
        'decode_map' =>
        {
            'Comma' => ['punctype' => 'comm'],
            'Left'  => ['puncside' => 'ini'],
            'Right' => ['puncside' => 'fin'],
            # ! . : ; ?
            'Norm'  => ['punctype' => 'peri']
        },
        'encode_map' =>
        {
            'punctype' => { 'comm' => 'Comma',
                            'peri' => 'Norm',
                            '@'    => { 'puncside' => { 'ini' => 'Left',
                                                        'fin' => 'Right' }}}
        }
    );
    # GENUS / GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'Masc' => 'masc',
            'Fem'  => 'fem',
            'Neut' => 'neut'
        },
        'encode_default' => 'NoGend'
    );
    # NUMERUS / NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'Sg' => 'sing',
            'Pl' => 'plur'
        }
    );
    # KASUS / CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'Nom' => 'nom',
            'Gen' => 'gen',
            'Dat' => 'dat',
            'Acc' => 'acc'
        }
    );
    # GRAD / DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'Pos'  => 'pos',
            'Comp' => 'cmp',
            'Sup'  => 'sup'
        }
    );
    # DEFINITHEIT / DEFINITENESS ####################
    $atoms{definiteness} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            'Def'   => 'def',
            'Indef' => 'ind'
        }
    );
    # PERSON ####################
    $atoms{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '1' => '1',
            '2' => '2',
            '3' => '3'
        }
    );
    # TENSE ####################
    $atoms{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            # Simple past (präteritum), not participle.
            # Examples: abfuhr, abgaben, abschied, abschnitt, abschnitte
            'Past'  => ['verbform' => 'fin', 'tense' => 'past'],
            # Present tense, not participle.
            # Examples: abschweifen, absegnen, absichten, abstoßen, abstreifen
            'Pres'  => ['verbform' => 'fin', 'tense' => 'pres'],
            # Past participle, used also for passive voice.
            # Examples: amüsiert, anerkannt, angeboten, angebunden, angehört
            'PPast' => ['verbform' => 'part', 'tense' => 'past'],
            # Present participle.
            # Examples: anscheinend, anschließend, auffallend, ausgehend, ausreichend
            'PPres' => ['verbform' => 'part', 'tense' => 'pres']
        },
        'encode_map' =>
        {
            'tense' => { 'pres' => { 'verbform' => { 'part' => 'PPres',
                                                     '@'    => 'Pres' }},
                         'past' => { 'verbform' => { 'part' => 'PPast',
                                                     '@'    => 'Past' }}}
        }
    );
    # VERB FORM ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            # infinitive: "abkommen"
            'Inf'   => ['verbform' => 'inf'],
            # Imperative is mood but in the ordering of features it appears at the place of verb form.
            'Imp'   => ['verbform' => 'fin', 'mood' => 'imp']
        },
        'encode_map' =>
        {
            'verbform' => { 'inf' => 'Inf',
                            '@'   => { 'mood' => { 'imp' => 'Imp' }}}
        }
    );
    # INFINITIVE WITH INCORPORATED PREPOSITION ZU ####################
    # Example without zu: abkommen
    # Example with zu: abzukommen
    $atoms{zu} = $self->create_atom
    (
        'surfeature' => 'zu',
        'decode_map' =>
        {
            'zu' => ['other' => {'verbform' => 'infzu'}]
        },
        'encode_map' =>
        {
            'other/verbform' => { 'infzu' => 'zu' }
        }
    );
    # MODUS / MOOD ####################
    $atoms{mood} = $self->create_simple_atom
    (
        'intfeature' => 'mood',
        'simple_decode_map' =>
        {
            'Ind'  => 'ind',
            'Subj' => 'sub'
        }
    );
    # STARKE UND SCHWACHE FLEXION / STRONG AND WEAK INFLECTION ####################
    $atoms{inflection} = $self->create_atom
    (
        'surfeature' => 'inflection',
        'decode_map' =>
        {
            'St' => ['other' => {'inflection' => 'strong'}],
            'Wk' => ['other' => {'inflection' => 'weak'}]
        },
        'encode_map' =>
        {
            'other/inflection' => { 'strong' => 'St',
                                    'weak'   => 'Wk' }
        }
    );
    # ALTERNATIVE FORMS ####################
    # <Old>	Schreibweise	Früherer, heute ungebrauchter Dativ
    # <Simp>	Schreibweise	Verkürzte Formen im Dativ/Akkusativ (dem Mensch statt dem Menschen)
    $atoms{variant} = $self->create_atom
    (
        'surfeature' => 'variant',
        'decode_map' =>
        {
            # Old form of dative, not used today: "dem Abnahmepreise" instead of "dem Abnahmepreis".
            'Old'  => ['variant' => '1', 'style' => 'arch'],
            # Simplified form of dative or accusative: "dem Mensch" instead of "dem Menschen".
            'Simp' => ['variant' => 'short']
        },
        'encode_map' =>
        {
            'style' => { 'arch' => 'Old',
                         '@'    => { 'variant' => { '1'     => 'Old',
                                                    'short' => 'Simp' }}}
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map {$atoms{$_}} (qw(pos gender number case degree adjform pronform conjtype parttype punctype definiteness person tense verbform zu mood inflection variant));
    $atoms{feature} = $self->create_merged_atom
    (
        'surfeature' => 'feature',
        'atoms'      => \@fatoms
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
    # Every feature value is enclosed in angle brackets.
    # The first feature is the part of speech.
    # example: <+NN><Masc><Nom><Sg>
    my $fs = Lingua::Interset::FeatureStructure->new();
    $tag =~ s/^<//;
    $tag =~ s/>$//;
    my @features = split(/[<>]+/, $tag);
    $fs->set_tagset('de::smor');
    my $atoms = $self->atoms();
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
    my $pos = '<'.$atoms->{pos}->encode($fs).'>';
    my @features = ($pos);
    # Encode the features.
    my %feature_names =
    (
        '@'        => ['degree', 'adjform', 'definiteness', 'gender', 'case', 'number', 'inflection', 'variant', 'conjtype', 'parttype', 'punctype'],
        '<+CARD>'  => ['pronform', 'gender', 'case', 'number', 'inflection'],
        '<+DEM>'   => ['pronform', 'gender', 'case', 'number', 'inflection'],
        '<+INDEF>' => ['pronform', 'adjform', 'gender', 'case', 'number', 'inflection'],
        '<+POSS>'  => ['pronform', 'gender', 'case', 'number', 'inflection'],
        '<+PPRO>'  => ['pronform', 'adjform', 'person', 'number', 'gender', 'case', 'inflection'],
        '<+REL>'   => ['pronform', 'gender', 'case', 'number', 'inflection'],
        '<+V>'     => ['verbform', 'zu', 'person', 'number', 'tense', 'mood'],
        '<+WPRO>'  => ['pronform', 'adjform', 'gender', 'case', 'number', 'inflection']
    );
    my @feature_names = @{exists($feature_names{$pos}) ? $feature_names{$pos} : $feature_names{'@'}};
    foreach my $name (@feature_names)
    {
        my $feature = $atoms->{$name}->encode($fs);
        unless($feature eq '')
        {
            push(@features, "<$feature>");
        }
    }
    my $tag = join('', @features);
    # There are multiple ways of indicating empty values, e.g. gender can either
    # not appear, or appear as <NoGend>, or covered by <Invar>.
    # The <NoGend> tag is only used if there are the case and number features.
    if($tag !~ m/<(Nom|Gen|Dat|Acc)>/ || $tag =~ m/<\+(PREP|POSTP)>/)
    {
        $tag =~ s/<NoGend>//;
    }
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# This approximate list was obtained by applying the Zmorge analyzer to all
# words from the Tiger treebank (CoNLL 2009 training data) and collecting the
# tags.
# 558 tags have been observed.
# 554 tags remained after removing the following tags (we would have to
#          distinguish possgender from gender, possnumber from number etc.)
#          <+INDEF><Subst><Invar><3><Pl><NoGend> ... ihresgleichen
#          <+INDEF><Subst><Invar><3><Sg><Fem> ...... ihresgleichen
#          <+INDEF><Subst><Invar><3><Sg><Masc> ..... seinesgleichen
#          <+INDEF><Subst><Invar><3><Sg><Neut> ..... seinesgleichen
# 857 tags after adding other-resistant tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
<+ADJ><Comp>
<+ADJ><Comp><Adv>
<+ADJ><Comp><Fem><Acc><Sg>
<+ADJ><Comp><Fem><Dat><Sg>
<+ADJ><Comp><Fem><Dat><Sg><St>
<+ADJ><Comp><Fem><Gen><Sg>
<+ADJ><Comp><Fem><Gen><Sg><St>
<+ADJ><Comp><Fem><Gen><Sg><Wk>
<+ADJ><Comp><Fem><Nom><Sg>
<+ADJ><Comp><Masc><Acc><Sg>
<+ADJ><Comp><Masc><Dat><Sg>
<+ADJ><Comp><Masc><Dat><Sg><St>
<+ADJ><Comp><Masc><Gen><Sg>
<+ADJ><Comp><Masc><Nom><Sg>
<+ADJ><Comp><Masc><Nom><Sg><St>
<+ADJ><Comp><Masc><Nom><Sg><Wk>
<+ADJ><Comp><Neut><Acc><Sg>
<+ADJ><Comp><Neut><Acc><Sg><St>
<+ADJ><Comp><Neut><Acc><Sg><Wk>
<+ADJ><Comp><Neut><Dat><Sg>
<+ADJ><Comp><Neut><Dat><Sg><St>
<+ADJ><Comp><Neut><Gen><Sg>
<+ADJ><Comp><Neut><Nom><Sg>
<+ADJ><Comp><Neut><Nom><Sg><St>
<+ADJ><Comp><Neut><Nom><Sg><Wk>
<+ADJ><Comp><NoGend><Acc><Pl>
<+ADJ><Comp><NoGend><Acc><Pl><St>
<+ADJ><Comp><NoGend><Acc><Pl><Wk>
<+ADJ><Comp><NoGend><Dat><Pl>
<+ADJ><Comp><NoGend><Dat><Sg>
<+ADJ><Comp><NoGend><Dat><Sg><Wk>
<+ADJ><Comp><NoGend><Gen><Pl>
<+ADJ><Comp><NoGend><Gen><Pl><St>
<+ADJ><Comp><NoGend><Gen><Pl><Wk>
<+ADJ><Comp><NoGend><Nom><Pl>
<+ADJ><Comp><NoGend><Nom><Pl><St>
<+ADJ><Comp><NoGend><Nom><Pl><Wk>
<+ADJ><Comp><Pred>
<+ADJ><Pos>
<+ADJ><Pos><Adv>
<+ADJ><Pos><Fem><Acc><Sg>
<+ADJ><Pos><Fem><Dat><Sg>
<+ADJ><Pos><Fem><Dat><Sg><St>
<+ADJ><Pos><Fem><Gen><Sg>
<+ADJ><Pos><Fem><Gen><Sg><St>
<+ADJ><Pos><Fem><Gen><Sg><Wk>
<+ADJ><Pos><Fem><Nom><Sg>
<+ADJ><Pos><Invar>
<+ADJ><Pos><Masc><Acc><Sg>
<+ADJ><Pos><Masc><Dat><Sg>
<+ADJ><Pos><Masc><Dat><Sg><St>
<+ADJ><Pos><Masc><Gen><Sg>
<+ADJ><Pos><Masc><Nom><Sg>
<+ADJ><Pos><Masc><Nom><Sg><St>
<+ADJ><Pos><Masc><Nom><Sg><Wk>
<+ADJ><Pos><Neut><Acc><Sg>
<+ADJ><Pos><Neut><Acc><Sg><St>
<+ADJ><Pos><Neut><Acc><Sg><Wk>
<+ADJ><Pos><Neut><Dat><Sg>
<+ADJ><Pos><Neut><Dat><Sg><St>
<+ADJ><Pos><Neut><Gen><Sg>
<+ADJ><Pos><Neut><Nom><Sg>
<+ADJ><Pos><Neut><Nom><Sg><St>
<+ADJ><Pos><Neut><Nom><Sg><Wk>
<+ADJ><Pos><NoGend><Acc><Pl>
<+ADJ><Pos><NoGend><Acc><Pl><St>
<+ADJ><Pos><NoGend><Acc><Pl><Wk>
<+ADJ><Pos><NoGend><Dat><Pl>
<+ADJ><Pos><NoGend><Dat><Sg>
<+ADJ><Pos><NoGend><Dat><Sg><Wk>
<+ADJ><Pos><NoGend><Gen><Pl>
<+ADJ><Pos><NoGend><Gen><Pl><St>
<+ADJ><Pos><NoGend><Gen><Pl><Wk>
<+ADJ><Pos><NoGend><Nom><Pl>
<+ADJ><Pos><NoGend><Nom><Pl><St>
<+ADJ><Pos><NoGend><Nom><Pl><Wk>
<+ADJ><Pos><Pred>
<+ADJ><Sup>
<+ADJ><Sup><Adv>
<+ADJ><Sup><Fem><Acc><Sg>
<+ADJ><Sup><Fem><Dat><Sg>
<+ADJ><Sup><Fem><Dat><Sg><St>
<+ADJ><Sup><Fem><Gen><Sg>
<+ADJ><Sup><Fem><Gen><Sg><St>
<+ADJ><Sup><Fem><Gen><Sg><Wk>
<+ADJ><Sup><Fem><Nom><Sg>
<+ADJ><Sup><Masc><Acc><Sg>
<+ADJ><Sup><Masc><Dat><Sg>
<+ADJ><Sup><Masc><Dat><Sg><St>
<+ADJ><Sup><Masc><Gen><Sg>
<+ADJ><Sup><Masc><Nom><Sg>
<+ADJ><Sup><Masc><Nom><Sg><St>
<+ADJ><Sup><Masc><Nom><Sg><Wk>
<+ADJ><Sup><Neut><Acc><Sg>
<+ADJ><Sup><Neut><Acc><Sg><St>
<+ADJ><Sup><Neut><Acc><Sg><Wk>
<+ADJ><Sup><Neut><Dat><Sg>
<+ADJ><Sup><Neut><Dat><Sg><St>
<+ADJ><Sup><Neut><Gen><Sg>
<+ADJ><Sup><Neut><Nom><Sg>
<+ADJ><Sup><Neut><Nom><Sg><St>
<+ADJ><Sup><Neut><Nom><Sg><Wk>
<+ADJ><Sup><NoGend><Acc><Pl>
<+ADJ><Sup><NoGend><Acc><Pl><St>
<+ADJ><Sup><NoGend><Acc><Pl><Wk>
<+ADJ><Sup><NoGend><Dat><Pl>
<+ADJ><Sup><NoGend><Dat><Sg>
<+ADJ><Sup><NoGend><Dat><Sg><Wk>
<+ADJ><Sup><NoGend><Gen><Pl>
<+ADJ><Sup><NoGend><Gen><Pl><St>
<+ADJ><Sup><NoGend><Gen><Pl><Wk>
<+ADJ><Sup><NoGend><Nom><Pl>
<+ADJ><Sup><NoGend><Nom><Pl><St>
<+ADJ><Sup><NoGend><Nom><Pl><Wk>
<+ADJ><Sup><Pred>
<+ADV>
<+ART><Def><Fem><Acc><Sg>
<+ART><Def><Fem><Acc><Sg><St>
<+ART><Def><Fem><Dat><Sg>
<+ART><Def><Fem><Dat><Sg><St>
<+ART><Def><Fem><Gen><Sg>
<+ART><Def><Fem><Gen><Sg><St>
<+ART><Def><Fem><Nom><Sg>
<+ART><Def><Fem><Nom><Sg><St>
<+ART><Def><Masc><Acc><Sg>
<+ART><Def><Masc><Acc><Sg><St>
<+ART><Def><Masc><Dat><Sg>
<+ART><Def><Masc><Dat><Sg><St>
<+ART><Def><Masc><Gen><Sg>
<+ART><Def><Masc><Gen><Sg><St>
<+ART><Def><Masc><Nom><Sg>
<+ART><Def><Masc><Nom><Sg><St>
<+ART><Def><Neut><Acc><Sg>
<+ART><Def><Neut><Acc><Sg><St>
<+ART><Def><Neut><Dat><Sg>
<+ART><Def><Neut><Dat><Sg><St>
<+ART><Def><Neut><Gen><Sg>
<+ART><Def><Neut><Gen><Sg><St>
<+ART><Def><Neut><Nom><Sg>
<+ART><Def><Neut><Nom><Sg><St>
<+ART><Def><NoGend><Acc><Pl>
<+ART><Def><NoGend><Acc><Pl><St>
<+ART><Def><NoGend><Dat><Pl>
<+ART><Def><NoGend><Dat><Pl><St>
<+ART><Def><NoGend><Gen><Pl>
<+ART><Def><NoGend><Gen><Pl><St>
<+ART><Def><NoGend><Nom><Pl>
<+ART><Def><NoGend><Nom><Pl><St>
<+ART><Indef><Fem><Acc><Sg>
<+ART><Indef><Fem><Acc><Sg><St>
<+ART><Indef><Fem><Dat><Sg>
<+ART><Indef><Fem><Dat><Sg><St>
<+ART><Indef><Fem><Gen><Sg>
<+ART><Indef><Fem><Gen><Sg><St>
<+ART><Indef><Fem><Nom><Sg>
<+ART><Indef><Fem><Nom><Sg><St>
<+ART><Indef><Masc><Acc><Sg>
<+ART><Indef><Masc><Acc><Sg><St>
<+ART><Indef><Masc><Dat><Sg>
<+ART><Indef><Masc><Dat><Sg><St>
<+ART><Indef><Masc><Gen><Sg>
<+ART><Indef><Masc><Gen><Sg><St>
<+ART><Indef><Masc><Nom><Sg>
<+ART><Indef><Masc><Nom><Sg><Wk>
<+ART><Indef><Neut><Acc><Sg>
<+ART><Indef><Neut><Acc><Sg><Wk>
<+ART><Indef><Neut><Dat><Sg>
<+ART><Indef><Neut><Dat><Sg><St>
<+ART><Indef><Neut><Gen><Sg>
<+ART><Indef><Neut><Gen><Sg><St>
<+ART><Indef><Neut><Nom><Sg>
<+ART><Indef><Neut><Nom><Sg><Wk>
<+CARD><Attr><Masc><Nom><Sg>
<+CARD><Attr><Masc><Nom><Sg><Wk>
<+CARD><Attr><Neut><Acc><Sg>
<+CARD><Attr><Neut><Acc><Sg><Wk>
<+CARD><Attr><Neut><Nom><Sg>
<+CARD><Attr><Neut><Nom><Sg><Wk>
<+CARD><Fem><Acc><Sg>
<+CARD><Fem><Dat><Sg>
<+CARD><Fem><Gen><Sg>
<+CARD><Fem><Nom><Sg>
<+CARD><Masc><Acc><Sg>
<+CARD><Masc><Dat><Sg>
<+CARD><Masc><Gen><Sg>
<+CARD><Masc><Nom><Sg>
<+CARD><Neut><Acc><Sg>
<+CARD><Neut><Dat><Sg>
<+CARD><Neut><Gen><Sg>
<+CARD><Neut><Nom><Sg>
<+CARD><NoGend><Acc><Pl>
<+CARD><NoGend><Dat><Pl>
<+CARD><NoGend><Dat><Sg>
<+CARD><NoGend><Gen><Pl>
<+CARD><NoGend><Gen><Sg>
<+CARD><NoGend><Nom><Pl>
<+CARD><Pro><Fem><Acc><Sg>
<+CARD><Pro><Fem><Dat><Sg><St>
<+CARD><Pro><Fem><Gen><Sg><St>
<+CARD><Pro><Fem><Nom><Sg>
<+CARD><Pro><Masc><Acc><Sg>
<+CARD><Pro><Masc><Dat><Sg><St>
<+CARD><Pro><Masc><Gen><Sg><St>
<+CARD><Pro><Masc><Nom><Sg><Wk>
<+CARD><Pro><Neut><Acc><Sg><Wk>
<+CARD><Pro><Neut><Dat><Sg><St>
<+CARD><Pro><Neut><Gen><Sg><St>
<+CARD><Pro><Neut><Nom><Sg><Wk>
<+CARD><Pro><NoGend><Acc><Pl><Wk>
<+CARD><Pro><NoGend><Dat><Pl><Wk>
<+CARD><Pro><NoGend><Dat><Sg><Wk>
<+CARD><Pro><NoGend><Gen><Pl><St>
<+CARD><Pro><NoGend><Gen><Pl><Wk>
<+CARD><Pro><NoGend><Gen><Sg><Wk>
<+CARD><Pro><NoGend><Nom><Pl><Wk>
<+CARD><Subst><Masc><Nom><Sg>
<+CARD><Subst><Masc><Nom><Sg><St>
<+CARD><Subst><Neut><Acc><Sg>
<+CARD><Subst><Neut><Acc><Sg><St>
<+CARD><Subst><Neut><Nom><Sg>
<+CARD><Subst><Neut><Nom><Sg><St>
<+CARD><Subst><NoGend><Acc><Pl>
<+CARD><Subst><NoGend><Acc><Pl><St>
<+CARD><Subst><NoGend><Dat><Pl>
<+CARD><Subst><NoGend><Dat><Pl><St>
<+CARD><Subst><NoGend><Nom><Pl>
<+CARD><Subst><NoGend><Nom><Pl><St>
<+CONJ><Compar>
<+CONJ><Coord>
<+CONJ><Sub>
<+DEM><Attr><Fem><Acc><Sg>
<+DEM><Attr><Fem><Acc><Sg><St>
<+DEM><Attr><Fem><Dat><Sg>
<+DEM><Attr><Fem><Dat><Sg><St>
<+DEM><Attr><Fem><Gen><Sg>
<+DEM><Attr><Fem><Gen><Sg><St>
<+DEM><Attr><Fem><Nom><Sg>
<+DEM><Attr><Fem><Nom><Sg><St>
<+DEM><Attr><Masc><Acc><Sg>
<+DEM><Attr><Masc><Acc><Sg><St>
<+DEM><Attr><Masc><Acc><Sg><Wk>
<+DEM><Attr><Masc><Dat><Sg>
<+DEM><Attr><Masc><Dat><Sg><St>
<+DEM><Attr><Masc><Gen><Sg>
<+DEM><Attr><Masc><Gen><Sg><St>
<+DEM><Attr><Masc><Nom><Sg>
<+DEM><Attr><Masc><Nom><Sg><St>
<+DEM><Attr><Neut><Acc><Sg>
<+DEM><Attr><Neut><Acc><Sg><St>
<+DEM><Attr><Neut><Dat><Sg>
<+DEM><Attr><Neut><Dat><Sg><St>
<+DEM><Attr><Neut><Gen><Sg>
<+DEM><Attr><Neut><Gen><Sg><St>
<+DEM><Attr><Neut><Nom><Sg>
<+DEM><Attr><Neut><Nom><Sg><St>
<+DEM><Attr><NoGend><Acc><Pl>
<+DEM><Attr><NoGend><Acc><Pl><St>
<+DEM><Attr><NoGend><Acc><Pl><Wk>
<+DEM><Attr><NoGend><Dat><Pl>
<+DEM><Attr><NoGend><Dat><Pl><St>
<+DEM><Attr><NoGend><Dat><Pl><Wk>
<+DEM><Attr><NoGend><Dat><Sg>
<+DEM><Attr><NoGend><Dat><Sg><Wk>
<+DEM><Attr><NoGend><Gen><Pl>
<+DEM><Attr><NoGend><Gen><Pl><St>
<+DEM><Attr><NoGend><Gen><Pl><Wk>
<+DEM><Attr><NoGend><Gen><Sg>
<+DEM><Attr><NoGend><Gen><Sg><Wk>
<+DEM><Attr><NoGend><Nom><Pl>
<+DEM><Attr><NoGend><Nom><Pl><St>
<+DEM><Attr><NoGend><Nom><Pl><Wk>
<+DEM><Subst><Fem><Acc><Sg>
<+DEM><Subst><Fem><Acc><Sg><St>
<+DEM><Subst><Fem><Dat><Sg>
<+DEM><Subst><Fem><Dat><Sg><St>
<+DEM><Subst><Fem><Gen><Sg>
<+DEM><Subst><Fem><Gen><Sg><St>
<+DEM><Subst><Fem><Nom><Sg>
<+DEM><Subst><Fem><Nom><Sg><St>
<+DEM><Subst><Masc><Acc><Sg>
<+DEM><Subst><Masc><Acc><Sg><St>
<+DEM><Subst><Masc><Acc><Sg><Wk>
<+DEM><Subst><Masc><Dat><Sg>
<+DEM><Subst><Masc><Dat><Sg><St>
<+DEM><Subst><Masc><Gen><Sg>
<+DEM><Subst><Masc><Gen><Sg><St>
<+DEM><Subst><Masc><Nom><Sg>
<+DEM><Subst><Masc><Nom><Sg><St>
<+DEM><Subst><Neut><Acc><Sg>
<+DEM><Subst><Neut><Acc><Sg><St>
<+DEM><Subst><Neut><Dat><Sg>
<+DEM><Subst><Neut><Dat><Sg><St>
<+DEM><Subst><Neut><Gen><Sg>
<+DEM><Subst><Neut><Gen><Sg><St>
<+DEM><Subst><Neut><Nom><Sg>
<+DEM><Subst><Neut><Nom><Sg><St>
<+DEM><Subst><NoGend><Acc><Pl>
<+DEM><Subst><NoGend><Acc><Pl><St>
<+DEM><Subst><NoGend><Acc><Pl><Wk>
<+DEM><Subst><NoGend><Dat><Pl>
<+DEM><Subst><NoGend><Dat><Pl><St>
<+DEM><Subst><NoGend><Dat><Pl><Wk>
<+DEM><Subst><NoGend><Dat><Sg>
<+DEM><Subst><NoGend><Dat><Sg><Wk>
<+DEM><Subst><NoGend><Gen><Pl>
<+DEM><Subst><NoGend><Gen><Pl><St>
<+DEM><Subst><NoGend><Gen><Pl><Wk>
<+DEM><Subst><NoGend><Gen><Sg>
<+DEM><Subst><NoGend><Gen><Sg><Wk>
<+DEM><Subst><NoGend><Nom><Pl>
<+DEM><Subst><NoGend><Nom><Pl><St>
<+DEM><Subst><NoGend><Nom><Pl><Wk>
<+INDEF><Attr>
<+INDEF><Attr><Fem><Acc><Sg>
<+INDEF><Attr><Fem><Acc><Sg><St>
<+INDEF><Attr><Fem><Dat><Sg>
<+INDEF><Attr><Fem><Dat><Sg><St>
<+INDEF><Attr><Fem><Gen><Sg>
<+INDEF><Attr><Fem><Gen><Sg><St>
<+INDEF><Attr><Fem><Nom><Sg>
<+INDEF><Attr><Fem><Nom><Sg><St>
<+INDEF><Attr><Invar>
<+INDEF><Attr><Masc><Acc><Sg>
<+INDEF><Attr><Masc><Acc><Sg><St>
<+INDEF><Attr><Masc><Dat><Sg>
<+INDEF><Attr><Masc><Dat><Sg><St>
<+INDEF><Attr><Masc><Gen><Sg>
<+INDEF><Attr><Masc><Gen><Sg><St>
<+INDEF><Attr><Masc><Nom><Sg>
<+INDEF><Attr><Masc><Nom><Sg><St>
<+INDEF><Attr><Masc><Nom><Sg><Wk>
<+INDEF><Attr><Neut><Acc><Sg>
<+INDEF><Attr><Neut><Acc><Sg><St>
<+INDEF><Attr><Neut><Acc><Sg><Wk>
<+INDEF><Attr><Neut><Dat><Sg>
<+INDEF><Attr><Neut><Dat><Sg><St>
<+INDEF><Attr><Neut><Gen><Sg>
<+INDEF><Attr><Neut><Gen><Sg><St>
<+INDEF><Attr><Neut><Nom><Sg>
<+INDEF><Attr><Neut><Nom><Sg><St>
<+INDEF><Attr><Neut><Nom><Sg><Wk>
<+INDEF><Attr><NoGend><Acc><Pl>
<+INDEF><Attr><NoGend><Acc><Pl><St>
<+INDEF><Attr><NoGend><Acc><Pl><Wk>
<+INDEF><Attr><NoGend><Dat><Pl>
<+INDEF><Attr><NoGend><Dat><Pl><St>
<+INDEF><Attr><NoGend><Dat><Pl><Wk>
<+INDEF><Attr><NoGend><Dat><Sg>
<+INDEF><Attr><NoGend><Dat><Sg><Wk>
<+INDEF><Attr><NoGend><Gen><Pl>
<+INDEF><Attr><NoGend><Gen><Pl><St>
<+INDEF><Attr><NoGend><Gen><Pl><Wk>
<+INDEF><Attr><NoGend><Gen><Sg>
<+INDEF><Attr><NoGend><Gen><Sg><Wk>
<+INDEF><Attr><NoGend><Nom><Pl>
<+INDEF><Attr><NoGend><Nom><Pl><St>
<+INDEF><Attr><NoGend><Nom><Pl><Wk>
<+INDEF><Subst>
<+INDEF><Subst><Fem><Acc><Sg>
<+INDEF><Subst><Fem><Acc><Sg><St>
<+INDEF><Subst><Fem><Dat><Sg>
<+INDEF><Subst><Fem><Dat><Sg><St>
<+INDEF><Subst><Fem><Gen><Sg>
<+INDEF><Subst><Fem><Gen><Sg><St>
<+INDEF><Subst><Fem><Nom><Sg>
<+INDEF><Subst><Fem><Nom><Sg><St>
<+INDEF><Subst><Invar>
<+INDEF><Subst><Masc><Acc><Sg>
<+INDEF><Subst><Masc><Acc><Sg><St>
<+INDEF><Subst><Masc><Dat><Sg>
<+INDEF><Subst><Masc><Dat><Sg><St>
<+INDEF><Subst><Masc><Gen><Sg>
<+INDEF><Subst><Masc><Gen><Sg><St>
<+INDEF><Subst><Masc><Nom><Sg>
<+INDEF><Subst><Masc><Nom><Sg><St>
<+INDEF><Subst><Masc><Nom><Sg><Wk>
<+INDEF><Subst><Neut><Acc><Sg>
<+INDEF><Subst><Neut><Acc><Sg><St>
<+INDEF><Subst><Neut><Acc><Sg><Wk>
<+INDEF><Subst><Neut><Dat><Sg>
<+INDEF><Subst><Neut><Dat><Sg><St>
<+INDEF><Subst><Neut><Gen><Sg>
<+INDEF><Subst><Neut><Gen><Sg><St>
<+INDEF><Subst><Neut><Nom><Sg>
<+INDEF><Subst><Neut><Nom><Sg><St>
<+INDEF><Subst><Neut><Nom><Sg><Wk>
<+INDEF><Subst><NoGend><Acc><Pl>
<+INDEF><Subst><NoGend><Acc><Pl><St>
<+INDEF><Subst><NoGend><Acc><Pl><Wk>
<+INDEF><Subst><NoGend><Acc><Sg>
<+INDEF><Subst><NoGend><Acc><Sg><St>
<+INDEF><Subst><NoGend><Dat><Pl>
<+INDEF><Subst><NoGend><Dat><Pl><St>
<+INDEF><Subst><NoGend><Dat><Pl><Wk>
<+INDEF><Subst><NoGend><Dat><Sg>
<+INDEF><Subst><NoGend><Dat><Sg><St>
<+INDEF><Subst><NoGend><Dat><Sg><Wk>
<+INDEF><Subst><NoGend><Gen><Pl>
<+INDEF><Subst><NoGend><Gen><Pl><St>
<+INDEF><Subst><NoGend><Gen><Pl><Wk>
<+INDEF><Subst><NoGend><Gen><Sg>
<+INDEF><Subst><NoGend><Gen><Sg><Wk>
<+INDEF><Subst><NoGend><Nom><Pl>
<+INDEF><Subst><NoGend><Nom><Pl><St>
<+INDEF><Subst><NoGend><Nom><Pl><Wk>
<+INDEF><Subst><NoGend><Nom><Sg>
<+INDEF><Subst><NoGend><Nom><Sg><Wk>
<+INTJ>
<+NN><Fem><Acc><Pl>
<+NN><Fem><Acc><Sg>
<+NN><Fem><Dat><Pl>
<+NN><Fem><Dat><Sg>
<+NN><Fem><Dat><Sg><St>
<+NN><Fem><Gen><Pl>
<+NN><Fem><Gen><Sg>
<+NN><Fem><Gen><Sg><St>
<+NN><Fem><Gen><Sg><Wk>
<+NN><Fem><Nom><Pl>
<+NN><Fem><Nom><Sg>
<+NN><Masc><Acc><Pl>
<+NN><Masc><Acc><Pl><St>
<+NN><Masc><Acc><Pl><Wk>
<+NN><Masc><Acc><Sg>
<+NN><Masc><Acc><Sg><Simp>
<+NN><Masc><Dat><Pl>
<+NN><Masc><Dat><Sg>
<+NN><Masc><Dat><Sg><Old>
<+NN><Masc><Dat><Sg><Simp>
<+NN><Masc><Dat><Sg><St>
<+NN><Masc><Dat><Sg><Wk>
<+NN><Masc><Gen><Pl>
<+NN><Masc><Gen><Pl><St>
<+NN><Masc><Gen><Pl><Wk>
<+NN><Masc><Gen><Sg>
<+NN><Masc><Nom><Pl>
<+NN><Masc><Nom><Pl><St>
<+NN><Masc><Nom><Pl><Wk>
<+NN><Masc><Nom><Sg>
<+NN><Masc><Nom><Sg><St>
<+NN><Masc><Nom><Sg><Wk>
<+NN><Neut><Acc><Pl>
<+NN><Neut><Acc><Sg>
<+NN><Neut><Acc><Sg><St>
<+NN><Neut><Acc><Sg><Wk>
<+NN><Neut><Dat><Pl>
<+NN><Neut><Dat><Sg>
<+NN><Neut><Dat><Sg><Old>
<+NN><Neut><Dat><Sg><St>
<+NN><Neut><Gen><Pl>
<+NN><Neut><Gen><Sg>
<+NN><Neut><Nom><Pl>
<+NN><Neut><Nom><Sg>
<+NN><Neut><Nom><Sg><St>
<+NN><Neut><Nom><Sg><Wk>
<+NN><NoGend><Acc><Pl>
<+NN><NoGend><Acc><Pl><St>
<+NN><NoGend><Acc><Pl><Wk>
<+NN><NoGend><Dat><Pl>
<+NN><NoGend><Dat><Sg>
<+NN><NoGend><Dat><Sg><Wk>
<+NN><NoGend><Gen><Pl>
<+NN><NoGend><Gen><Pl><St>
<+NN><NoGend><Gen><Pl><Wk>
<+NN><NoGend><Nom><Pl>
<+NN><NoGend><Nom><Pl><St>
<+NN><NoGend><Nom><Pl><Wk>
<+NPROP><Fem><Acc><Sg>
<+NPROP><Fem><Dat><Sg>
<+NPROP><Fem><Gen><Sg>
<+NPROP><Fem><Nom><Sg>
<+NPROP><Masc><Acc><Sg>
<+NPROP><Masc><Dat><Sg>
<+NPROP><Masc><Gen><Sg>
<+NPROP><Masc><Nom><Sg>
<+NPROP><Neut><Acc><Sg>
<+NPROP><Neut><Dat><Sg>
<+NPROP><Neut><Gen><Sg>
<+NPROP><Neut><Nom><Sg>
<+NPROP><NoGend><Acc><Pl>
<+NPROP><NoGend><Acc><Sg>
<+NPROP><NoGend><Dat><Pl>
<+NPROP><NoGend><Dat><Sg>
<+NPROP><NoGend><Gen><Pl>
<+NPROP><NoGend><Gen><Sg>
<+NPROP><NoGend><Nom><Pl>
<+NPROP><NoGend><Nom><Sg>
<+ORD>
<+ORD><Fem><Acc><Sg>
<+ORD><Fem><Dat><Sg>
<+ORD><Fem><Dat><Sg><St>
<+ORD><Fem><Gen><Sg>
<+ORD><Fem><Gen><Sg><St>
<+ORD><Fem><Gen><Sg><Wk>
<+ORD><Fem><Nom><Sg>
<+ORD><Masc><Acc><Sg>
<+ORD><Masc><Dat><Sg>
<+ORD><Masc><Dat><Sg><St>
<+ORD><Masc><Gen><Sg>
<+ORD><Masc><Nom><Sg>
<+ORD><Masc><Nom><Sg><St>
<+ORD><Masc><Nom><Sg><Wk>
<+ORD><Neut><Acc><Sg>
<+ORD><Neut><Acc><Sg><St>
<+ORD><Neut><Acc><Sg><Wk>
<+ORD><Neut><Dat><Sg>
<+ORD><Neut><Dat><Sg><St>
<+ORD><Neut><Gen><Sg>
<+ORD><Neut><Nom><Sg>
<+ORD><Neut><Nom><Sg><St>
<+ORD><Neut><Nom><Sg><Wk>
<+ORD><NoGend><Acc><Pl>
<+ORD><NoGend><Acc><Pl><St>
<+ORD><NoGend><Acc><Pl><Wk>
<+ORD><NoGend><Dat><Pl>
<+ORD><NoGend><Dat><Sg>
<+ORD><NoGend><Dat><Sg><Wk>
<+ORD><NoGend><Gen><Pl>
<+ORD><NoGend><Gen><Pl><St>
<+ORD><NoGend><Gen><Pl><Wk>
<+ORD><NoGend><Nom><Pl>
<+ORD><NoGend><Nom><Pl><St>
<+ORD><NoGend><Nom><Pl><Wk>
<+ORD><Pred>
<+POSS><Attr><Fem><Acc><Sg>
<+POSS><Attr><Fem><Dat><Sg>
<+POSS><Attr><Fem><Dat><Sg><St>
<+POSS><Attr><Fem><Gen><Sg>
<+POSS><Attr><Fem><Gen><Sg><St>
<+POSS><Attr><Fem><Nom><Sg>
<+POSS><Attr><Masc><Acc><Sg>
<+POSS><Attr><Masc><Dat><Sg>
<+POSS><Attr><Masc><Dat><Sg><St>
<+POSS><Attr><Masc><Gen><Sg>
<+POSS><Attr><Masc><Gen><Sg><St>
<+POSS><Attr><Masc><Nom><Sg>
<+POSS><Attr><Masc><Nom><Sg><Wk>
<+POSS><Attr><Neut><Acc><Sg>
<+POSS><Attr><Neut><Acc><Sg><Wk>
<+POSS><Attr><Neut><Dat><Sg>
<+POSS><Attr><Neut><Dat><Sg><St>
<+POSS><Attr><Neut><Gen><Sg>
<+POSS><Attr><Neut><Gen><Sg><St>
<+POSS><Attr><Neut><Nom><Sg>
<+POSS><Attr><Neut><Nom><Sg><Wk>
<+POSS><Attr><NoGend><Acc><Pl>
<+POSS><Attr><NoGend><Acc><Pl><St>
<+POSS><Attr><NoGend><Acc><Pl><Wk>
<+POSS><Attr><NoGend><Dat><Pl>
<+POSS><Attr><NoGend><Dat><Pl><St>
<+POSS><Attr><NoGend><Dat><Pl><Wk>
<+POSS><Attr><NoGend><Dat><Sg>
<+POSS><Attr><NoGend><Dat><Sg><Wk>
<+POSS><Attr><NoGend><Gen><Pl>
<+POSS><Attr><NoGend><Gen><Pl><St>
<+POSS><Attr><NoGend><Gen><Pl><Wk>
<+POSS><Attr><NoGend><Gen><Sg>
<+POSS><Attr><NoGend><Gen><Sg><Wk>
<+POSS><Attr><NoGend><Nom><Pl>
<+POSS><Attr><NoGend><Nom><Pl><St>
<+POSS><Attr><NoGend><Nom><Pl><Wk>
<+POSS><Subst><Fem><Acc><Sg>
<+POSS><Subst><Fem><Dat><Sg>
<+POSS><Subst><Fem><Dat><Sg><St>
<+POSS><Subst><Fem><Gen><Sg>
<+POSS><Subst><Fem><Gen><Sg><St>
<+POSS><Subst><Fem><Nom><Sg>
<+POSS><Subst><Masc><Acc><Sg>
<+POSS><Subst><Masc><Dat><Sg>
<+POSS><Subst><Masc><Dat><Sg><St>
<+POSS><Subst><Masc><Gen><Sg>
<+POSS><Subst><Masc><Gen><Sg><St>
<+POSS><Subst><Masc><Nom><Sg>
<+POSS><Subst><Masc><Nom><Sg><St>
<+POSS><Subst><Masc><Nom><Sg><Wk>
<+POSS><Subst><Neut><Acc><Sg>
<+POSS><Subst><Neut><Acc><Sg><St>
<+POSS><Subst><Neut><Acc><Sg><Wk>
<+POSS><Subst><Neut><Dat><Sg>
<+POSS><Subst><Neut><Dat><Sg><St>
<+POSS><Subst><Neut><Gen><Sg>
<+POSS><Subst><Neut><Gen><Sg><St>
<+POSS><Subst><Neut><Nom><Sg>
<+POSS><Subst><Neut><Nom><Sg><St>
<+POSS><Subst><Neut><Nom><Sg><Wk>
<+POSS><Subst><NoGend><Acc><Pl>
<+POSS><Subst><NoGend><Acc><Pl><St>
<+POSS><Subst><NoGend><Acc><Pl><Wk>
<+POSS><Subst><NoGend><Dat><Pl>
<+POSS><Subst><NoGend><Dat><Pl><St>
<+POSS><Subst><NoGend><Dat><Pl><Wk>
<+POSS><Subst><NoGend><Dat><Sg>
<+POSS><Subst><NoGend><Dat><Sg><Wk>
<+POSS><Subst><NoGend><Gen><Pl>
<+POSS><Subst><NoGend><Gen><Pl><St>
<+POSS><Subst><NoGend><Gen><Pl><Wk>
<+POSS><Subst><NoGend><Gen><Sg>
<+POSS><Subst><NoGend><Gen><Sg><Wk>
<+POSS><Subst><NoGend><Nom><Pl>
<+POSS><Subst><NoGend><Nom><Pl><St>
<+POSS><Subst><NoGend><Nom><Pl><Wk>
<+POSTP><Acc>
<+POSTP><Dat>
<+POSTP><Gen>
<+PPRO><Pers><1><Pl><NoGend><Acc>
<+PPRO><Pers><1><Pl><NoGend><Acc><Wk>
<+PPRO><Pers><1><Pl><NoGend><Dat>
<+PPRO><Pers><1><Pl><NoGend><Dat><Wk>
<+PPRO><Pers><1><Pl><NoGend><Gen>
<+PPRO><Pers><1><Pl><NoGend><Gen><Wk>
<+PPRO><Pers><1><Pl><NoGend><Nom>
<+PPRO><Pers><1><Pl><NoGend><Nom><Wk>
<+PPRO><Pers><1><Sg><NoGend><Acc>
<+PPRO><Pers><1><Sg><NoGend><Acc><Wk>
<+PPRO><Pers><1><Sg><NoGend><Dat>
<+PPRO><Pers><1><Sg><NoGend><Dat><Wk>
<+PPRO><Pers><1><Sg><NoGend><Gen>
<+PPRO><Pers><1><Sg><NoGend><Gen><Wk>
<+PPRO><Pers><1><Sg><NoGend><Nom>
<+PPRO><Pers><1><Sg><NoGend><Nom><Wk>
<+PPRO><Pers><2><Pl><NoGend><Acc>
<+PPRO><Pers><2><Pl><NoGend><Acc><Wk>
<+PPRO><Pers><2><Pl><NoGend><Dat>
<+PPRO><Pers><2><Pl><NoGend><Dat><Wk>
<+PPRO><Pers><2><Pl><NoGend><Gen>
<+PPRO><Pers><2><Pl><NoGend><Gen><Wk>
<+PPRO><Pers><2><Pl><NoGend><Nom>
<+PPRO><Pers><2><Pl><NoGend><Nom><Wk>
<+PPRO><Pers><2><Sg><NoGend><Acc>
<+PPRO><Pers><2><Sg><NoGend><Acc><Wk>
<+PPRO><Pers><2><Sg><NoGend><Dat>
<+PPRO><Pers><2><Sg><NoGend><Dat><Wk>
<+PPRO><Pers><2><Sg><NoGend><Nom>
<+PPRO><Pers><2><Sg><NoGend><Nom><Wk>
<+PPRO><Pers><3><Pl><NoGend><Acc>
<+PPRO><Pers><3><Pl><NoGend><Acc><Wk>
<+PPRO><Pers><3><Pl><NoGend><Dat>
<+PPRO><Pers><3><Pl><NoGend><Dat><Wk>
<+PPRO><Pers><3><Pl><NoGend><Gen>
<+PPRO><Pers><3><Pl><NoGend><Gen><Wk>
<+PPRO><Pers><3><Pl><NoGend><Nom>
<+PPRO><Pers><3><Pl><NoGend><Nom><Wk>
<+PPRO><Pers><3><Sg><Fem><Acc>
<+PPRO><Pers><3><Sg><Fem><Acc><Wk>
<+PPRO><Pers><3><Sg><Fem><Dat>
<+PPRO><Pers><3><Sg><Fem><Dat><Wk>
<+PPRO><Pers><3><Sg><Fem><Gen>
<+PPRO><Pers><3><Sg><Fem><Gen><Wk>
<+PPRO><Pers><3><Sg><Fem><Nom>
<+PPRO><Pers><3><Sg><Fem><Nom><Wk>
<+PPRO><Pers><3><Sg><Masc><Acc>
<+PPRO><Pers><3><Sg><Masc><Acc><Wk>
<+PPRO><Pers><3><Sg><Masc><Dat>
<+PPRO><Pers><3><Sg><Masc><Dat><Wk>
<+PPRO><Pers><3><Sg><Masc><Gen>
<+PPRO><Pers><3><Sg><Masc><Gen><Wk>
<+PPRO><Pers><3><Sg><Masc><Nom>
<+PPRO><Pers><3><Sg><Masc><Nom><Wk>
<+PPRO><Pers><3><Sg><Neut><Acc>
<+PPRO><Pers><3><Sg><Neut><Acc><Wk>
<+PPRO><Pers><3><Sg><Neut><Dat>
<+PPRO><Pers><3><Sg><Neut><Dat><Wk>
<+PPRO><Pers><3><Sg><Neut><Gen>
<+PPRO><Pers><3><Sg><Neut><Gen><Wk>
<+PPRO><Pers><3><Sg><Neut><Nom>
<+PPRO><Pers><3><Sg><Neut><Nom><Wk>
<+PPRO><Rec>
<+PPRO><Rec><Invar>
<+PPRO><Refl><1><Pl><NoGend><Acc>
<+PPRO><Refl><1><Pl><NoGend><Acc><Wk>
<+PPRO><Refl><1><Pl><NoGend><Dat>
<+PPRO><Refl><1><Pl><NoGend><Dat><Wk>
<+PPRO><Refl><1><Sg><NoGend><Acc>
<+PPRO><Refl><1><Sg><NoGend><Acc><Wk>
<+PPRO><Refl><1><Sg><NoGend><Dat>
<+PPRO><Refl><1><Sg><NoGend><Dat><Wk>
<+PPRO><Refl><2><Pl><NoGend><Acc>
<+PPRO><Refl><2><Pl><NoGend><Acc><Wk>
<+PPRO><Refl><2><Pl><NoGend><Dat>
<+PPRO><Refl><2><Pl><NoGend><Dat><Wk>
<+PPRO><Refl><2><Sg><NoGend><Acc>
<+PPRO><Refl><2><Sg><NoGend><Acc><Wk>
<+PPRO><Refl><2><Sg><NoGend><Dat>
<+PPRO><Refl><2><Sg><NoGend><Dat><Wk>
<+PPRO><Refl><3><Pl><NoGend><Acc>
<+PPRO><Refl><3><Pl><NoGend><Acc><Wk>
<+PPRO><Refl><3><Pl><NoGend><Dat>
<+PPRO><Refl><3><Pl><NoGend><Dat><Wk>
<+PPRO><Refl><3><Sg><NoGend><Acc>
<+PPRO><Refl><3><Sg><NoGend><Acc><Wk>
<+PPRO><Refl><3><Sg><NoGend><Dat>
<+PPRO><Refl><3><Sg><NoGend><Dat><Wk>
<+PREP><Acc>
<+PREP><Dat>
<+PREP><Gen>
<+PREPART><Fem><Dat><Sg>
<+PREPART><Masc><Dat><Sg>
<+PREPART><Neut><Acc><Sg>
<+PREPART><Neut><Dat><Sg>
<+PROADV>
<+PTCL><Ans>
<+PTCL><Neg>
<+PUNCT><Comma>
<+PUNCT><Left>
<+PUNCT><Norm>
<+PUNCT><Right>
<+REL><Attr><Fem><Gen><Sg>
<+REL><Attr><Fem><Gen><Sg><St>
<+REL><Attr><Masc><Gen><Sg>
<+REL><Attr><Masc><Gen><Sg><St>
<+REL><Attr><Neut><Gen><Sg>
<+REL><Attr><Neut><Gen><Sg><St>
<+REL><Attr><NoGend><Gen><Pl>
<+REL><Attr><NoGend><Gen><Pl><St>
<+REL><Subst><Fem><Acc><Sg>
<+REL><Subst><Fem><Acc><Sg><St>
<+REL><Subst><Fem><Dat><Sg>
<+REL><Subst><Fem><Dat><Sg><St>
<+REL><Subst><Fem><Gen><Sg>
<+REL><Subst><Fem><Gen><Sg><St>
<+REL><Subst><Fem><Nom><Sg>
<+REL><Subst><Fem><Nom><Sg><St>
<+REL><Subst><Masc><Acc><Sg>
<+REL><Subst><Masc><Acc><Sg><St>
<+REL><Subst><Masc><Dat><Sg>
<+REL><Subst><Masc><Dat><Sg><St>
<+REL><Subst><Masc><Gen><Sg>
<+REL><Subst><Masc><Gen><Sg><St>
<+REL><Subst><Masc><Nom><Sg>
<+REL><Subst><Masc><Nom><Sg><St>
<+REL><Subst><Neut><Acc><Sg>
<+REL><Subst><Neut><Acc><Sg><St>
<+REL><Subst><Neut><Acc><Sg><Wk>
<+REL><Subst><Neut><Dat><Sg>
<+REL><Subst><Neut><Dat><Sg><St>
<+REL><Subst><Neut><Gen><Sg>
<+REL><Subst><Neut><Gen><Sg><St>
<+REL><Subst><Neut><Nom><Sg>
<+REL><Subst><Neut><Nom><Sg><St>
<+REL><Subst><Neut><Nom><Sg><Wk>
<+REL><Subst><NoGend><Acc><Pl>
<+REL><Subst><NoGend><Acc><Pl><St>
<+REL><Subst><NoGend><Dat><Pl>
<+REL><Subst><NoGend><Dat><Pl><St>
<+REL><Subst><NoGend><Gen><Pl>
<+REL><Subst><NoGend><Gen><Pl><St>
<+REL><Subst><NoGend><Nom><Pl>
<+REL><Subst><NoGend><Nom><Pl><St>
<+SYMBOL>
<+TRUNC>
<+V><1><Pl><Past><Ind>
<+V><1><Pl><Past><Subj>
<+V><1><Pl><Pres><Ind>
<+V><1><Pl><Pres><Subj>
<+V><1><Sg><Past><Ind>
<+V><1><Sg><Past><Subj>
<+V><1><Sg><Pres><Ind>
<+V><1><Sg><Pres><Subj>
<+V><2><Pl><Past><Ind>
<+V><2><Pl><Past><Subj>
<+V><2><Pl><Pres><Ind>
<+V><2><Pl><Pres><Subj>
<+V><2><Sg><Past><Ind>
<+V><2><Sg><Past><Subj>
<+V><2><Sg><Pres><Ind>
<+V><2><Sg><Pres><Subj>
<+V><3><Pl><Past><Ind>
<+V><3><Pl><Past><Subj>
<+V><3><Pl><Pres><Ind>
<+V><3><Pl><Pres><Subj>
<+V><3><Sg><Past><Ind>
<+V><3><Sg><Past><Subj>
<+V><3><Sg><Pres><Ind>
<+V><3><Sg><Pres><Subj>
<+V><Imp><Pl>
<+V><Imp><Sg>
<+V><Inf>
<+V><Inf><zu>
<+V><PPast>
<+V><PPres>
<+VPART>
<+WADV>
<+WPRO><Attr>
<+WPRO><Attr><Fem><Acc><Sg>
<+WPRO><Attr><Fem><Acc><Sg><St>
<+WPRO><Attr><Fem><Dat><Sg>
<+WPRO><Attr><Fem><Dat><Sg><St>
<+WPRO><Attr><Fem><Gen><Sg>
<+WPRO><Attr><Fem><Gen><Sg><St>
<+WPRO><Attr><Fem><Nom><Sg>
<+WPRO><Attr><Fem><Nom><Sg><St>
<+WPRO><Attr><Invar>
<+WPRO><Attr><Masc><Acc><Sg>
<+WPRO><Attr><Masc><Acc><Sg><St>
<+WPRO><Attr><Masc><Dat><Sg>
<+WPRO><Attr><Masc><Dat><Sg><St>
<+WPRO><Attr><Masc><Gen><Sg>
<+WPRO><Attr><Masc><Gen><Sg><St>
<+WPRO><Attr><Masc><Nom><Sg>
<+WPRO><Attr><Masc><Nom><Sg><St>
<+WPRO><Attr><Neut><Acc><Sg>
<+WPRO><Attr><Neut><Acc><Sg><St>
<+WPRO><Attr><Neut><Dat><Sg>
<+WPRO><Attr><Neut><Dat><Sg><St>
<+WPRO><Attr><Neut><Gen><Sg>
<+WPRO><Attr><Neut><Gen><Sg><St>
<+WPRO><Attr><Neut><Nom><Sg>
<+WPRO><Attr><Neut><Nom><Sg><St>
<+WPRO><Attr><NoGend><Acc><Pl>
<+WPRO><Attr><NoGend><Acc><Pl><St>
<+WPRO><Attr><NoGend><Dat><Pl>
<+WPRO><Attr><NoGend><Dat><Pl><St>
<+WPRO><Attr><NoGend><Gen><Pl>
<+WPRO><Attr><NoGend><Gen><Pl><St>
<+WPRO><Attr><NoGend><Nom><Pl>
<+WPRO><Attr><NoGend><Nom><Pl><St>
<+WPRO><Subst><Fem><Acc><Sg>
<+WPRO><Subst><Fem><Acc><Sg><St>
<+WPRO><Subst><Fem><Dat><Sg>
<+WPRO><Subst><Fem><Dat><Sg><St>
<+WPRO><Subst><Fem><Gen><Sg>
<+WPRO><Subst><Fem><Gen><Sg><St>
<+WPRO><Subst><Fem><Nom><Sg>
<+WPRO><Subst><Fem><Nom><Sg><St>
<+WPRO><Subst><Masc><Acc><Sg>
<+WPRO><Subst><Masc><Acc><Sg><St>
<+WPRO><Subst><Masc><Dat><Sg>
<+WPRO><Subst><Masc><Dat><Sg><St>
<+WPRO><Subst><Masc><Gen><Sg>
<+WPRO><Subst><Masc><Gen><Sg><St>
<+WPRO><Subst><Masc><Nom><Sg>
<+WPRO><Subst><Masc><Nom><Sg><St>
<+WPRO><Subst><Neut><Acc><Sg>
<+WPRO><Subst><Neut><Acc><Sg><St>
<+WPRO><Subst><Neut><Acc><Sg><Wk>
<+WPRO><Subst><Neut><Dat><Sg>
<+WPRO><Subst><Neut><Dat><Sg><St>
<+WPRO><Subst><Neut><Gen><Sg>
<+WPRO><Subst><Neut><Gen><Sg><St>
<+WPRO><Subst><Neut><Nom><Sg>
<+WPRO><Subst><Neut><Nom><Sg><St>
<+WPRO><Subst><Neut><Nom><Sg><Wk>
<+WPRO><Subst><NoGend><Acc><Pl>
<+WPRO><Subst><NoGend><Acc><Pl><St>
<+WPRO><Subst><NoGend><Acc><Sg>
<+WPRO><Subst><NoGend><Acc><Sg><St>
<+WPRO><Subst><NoGend><Dat><Pl>
<+WPRO><Subst><NoGend><Dat><Pl><St>
<+WPRO><Subst><NoGend><Dat><Sg>
<+WPRO><Subst><NoGend><Dat><Sg><St>
<+WPRO><Subst><NoGend><Gen><Pl>
<+WPRO><Subst><NoGend><Gen><Pl><St>
<+WPRO><Subst><NoGend><Gen><Sg>
<+WPRO><Subst><NoGend><Gen><Sg><St>
<+WPRO><Subst><NoGend><Nom><Pl>
<+WPRO><Subst><NoGend><Nom><Pl><St>
<+WPRO><Subst><NoGend><Nom><Sg>
<+WPRO><Subst><NoGend><Nom><Sg><St>
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/[ \t]+/\t/g;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::DE::Smor - Driver for the German tagset of SMOR (Stuttgart Morphology)

=head1 VERSION

version 3.013

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::DE::Smor;
  my $driver = Lingua::Interset::Tagset::DE::Smor->new();
  my $fs = $driver->decode('<+NN><Masc><Nom><Sg>');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('de::smor', '<+NN><Masc><Nom><Sg>');

=head1 DESCRIPTION

Interset driver for the tagset of the German morphological grammar SMOR,
accompanying the Stuttgart Finite State Transducer (SFST) tools by
Helmut Schmid (L<https://code.google.com/p/cistern/wiki/SFST>,
L<https://code.google.com/p/cistern/wiki/SMOR>).
The same tags are also produced by the
Zurich Morphological Analyzer for German (Zmorge,
L<http://kitt.ifi.uzh.ch/kitt/zmorge/>).

This driver has been tested on the output of Zmorge applied to words found in the Tiger treebank.
We expect the part-of-speech tag (<+XXX>) and the following feature tags on input.
The rest of Zmorge's output, i.e. the derivational tags, other tags such as <CAP>, <TRUNC> etc.,
and the morphemes of the analyzed word should not appear on input to this driver.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::DE::Stts>,
L<Lingua::Interset::Tagset::DE::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>,
Lefteris Avramidis

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
