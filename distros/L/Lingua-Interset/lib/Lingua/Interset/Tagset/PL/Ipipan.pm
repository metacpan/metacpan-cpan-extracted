# ABSTRACT: Driver for the tagset of the Korpus Języka Polskiego IPI PAN for Polish.
# Copyright © 2009, 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::PL::Ipipan;
use strict;
use warnings;
our $VERSION = '3.014';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::Conll';



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'pl::ipipan';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
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
            # rzeczownik / noun
            'subst'   => ['pos' => 'noun'],
            # rzeczownik deprecjatywny = depreciative noun
            # (possible explanation:)
            # This paper deals with the Polish construction “iść w sołdaty [be drafted; lit. become a sołdat (solider)]”,
            # which is grammatically atypical: it is not clear what the value of its noun constituent's case is. The point
            # of departure for the analysis is Igor Mel'čuk's paper about the parallel Russian construction. (The Polish
            # construction was borrowed from Russian during the Russian rule on Polish territory.) The solution is similar
            # to that for Russian: “sołdaty” in this expression is an atypical (non-virile or depreciative) accusative form.
            # Additionally, some similar expressions consisting of a preposition and a noun form analogous to “sołdaty” are
            # discussed. It is possible to see in them a trace of a new case in Polish (post-prepositional Accusative).
            'depr'    => ['pos' => 'noun', 'other' => {'nountype' => 'depr'}],
            # liczebnik główny = main numeral (kilka, czterdziestu, sto, tyle, dwanaście)
            # liczebnik zbiorowy = collective numeral (should be 'numcol'; not found any examples!)
            'num'     => ['pos' => 'num'],
            # przymiotnik = adjective ((Feliks) Koneczny, znakomitego, dzisiejszego, liczne, Polskim)
            'adj'     => ['pos' => 'adj'],
            # przymiotnik przyprzym. = adjective hyphen-connected to another adjective (Chrześcijańsko(-Demokratycznym))
            # occurred in version 1 of corpus, does not occur in version 2 ("Chrześcijańsko" has new tag "ign")
            'adja'    => ['pos' => 'adj', 'hyph' => 'yes'],
            # przymiotnik poprzyim. = adjective after preposition "po", forming together an adverbial ("po prostu": [prosty:adjp])
            'adjp'    => ['pos' => 'adj', 'prepcase' => 'pre'],
            # przysłówek = adverb (naukowo, szybko, codziennie, ciężko, lepiej)
            'adv'     => ['pos' => 'adv'],
            # zaimek nietrzecioosobowy = non-3rd person personal pronoun (mi, ja, mnie, nam, nas)
            'ppron12' => ['pos' => 'noun', 'prontype' => 'prs'],
            # zaimek trzecioosobowy = 3rd person personal pronoun (nich, ich, ją, nim, ona)
            'ppron3'  => ['pos' => 'noun', 'prontype' => 'prs', 'person' => '3'],
            # zaimek SIEBIE = pronoun SIEBIE (sobie, siebie, sobą)
            'siebie'  => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'],
            # forma nieprzeszła = finite verb form (jestem, mówią, mówi, występuje, ma)
            'fin'     => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres'],
            # forma przyszła BYĆ = future form of the verb "to be", BYĆ (będę, będzie, będziesz, będziemy)
            'bedzie'  => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'fut'],
            # aglutynant BYĆ = agglutinative morpheme of "to be", BYĆ (em, śmy)
            # in text attached to the preceding verb participle, split during tokenization
            'aglt'    => ['pos' => 'verb', 'verbtype' => 'aux', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres'],
            # pseudoimiesłów = past tense verb (wyjechał, otrzymała, zaczęła, byli, mieszkali)
            # occurs before the agglutinative morpheme or independently
            'praet'   => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past'],
            # rozkaźnik = verb imperative (ładuj, krępuj, powiedz, trzymaj, oślep)
            'impt'    => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'imp'],
            # bezosobnik = verb passive participle, impersonate (odpowiedziano, urządzano, odmówiono, wykryto, napisano)
            'imps'    => ['pos' => 'verb', 'verbform' => 'part', 'voice' => 'pass', 'number' => 'sing', 'gender' => 'neut', 'case' => 'nom', 'polarity' => 'pos', 'other' => {'verbform' => 'imps'}],
            # bezokolicznik = verb infinitive (pracować, wytrzymać, pozwolić, sprężyć, pokazać)
            'inf'     => ['pos' => 'verb', 'verbform' => 'inf'],
            # im. przys. współczesny = transgressive present (posapując, wiedząc, zapraszając, wyjeżdżając, będąc)
            'pcon'    => ['pos' => 'verb', 'verbform' => 'conv', 'tense' => 'pres'],
            # im. przys. uprzedni = transgressive past (usłyszawszy, zostawiwszy, zrobiwszy, upewniwszy, włożywszy)
            'pant'    => ['pos' => 'verb', 'verbform' => 'conv', 'tense' => 'past'],
            # odsłownik = verbal noun (uparcie, ustąpieniu, wprowadzeniu, odcięciu, tłumaczenia)
            'ger'     => ['pos' => 'verb', 'verbform' => 'vnoun'],
            # im. przym. czynny = active present participle (mieszkającej, śpiącego, wzruszające, kuszącej, kusząca)
            'pact'    => ['pos' => 'verb', 'verbform' => 'part', 'tense' => 'pres', 'voice' => 'act'],
            # im. przym. bierny = passive participle (położonej, otoczony, zwodzony, afiliowanym, wybrany)
            'ppas'    => ['pos' => 'verb', 'verbform' => 'part', 'voice' => 'pass'],
            # winien (word 'winien' and its relatives considered a hybrid between verbs and adjectives) (powinien, winien, powinno, winny)
            'winien'  => ['pos' => 'adj', 'other' => {'adjtype' => 'winien'}],
            # predykatyw = predicative (to, można, wiadomo, warto, potrzeba)
            # non-verb part of speech (demonstrative pronoun, adverb etc.) replacing clause-main verb (and sometimes the subject at the same time)
            'pred'    => ['pos' => 'verb', 'other' => {'verbtype' => 'pred'}],
            # przyimek = preposition (na, w, z, do, po)
            'prep'    => ['pos' => 'adp', 'adpostype' => 'prep'],
            # complementizer (że, bo, gdy, aby, by)
            # The tag is 'comp', without features. For us it conflicts with the feature 'comp' (comparative degree).
            # Therefore we first change 'comp' (part of speech) to 'compl', then decode. Encoding goes directly to 'comp' here.
            'compl'   => ['pos' => 'conj', 'conjtype' => 'sub'],
            # spójnik = conjunction (i, a, ale, więc, oraz)
            'conj'    => ['pos' => 'conj', 'conjtype' => 'coor'],
            # kublik = particle, interjection, indeclinable adjective etc. (wówczas, gdzie, się, też, wkrótce)
            'qub'     => ['pos' => 'part'],
            # abbreviation (r, tys, zł, ul, proc)
            # Most abbreviations in the Polish treebank are nouns but not all.
            # For example, "ok" is the abbreviated preposition "około" ("about, approximately").
            'brev'    => ['abbr' => 'yes'],
            # ciało obce nominalne (no occurrences found)
            'xxs'     => ['foreign' => 'yes', 'other' => {'pos' => 'xxs'}],
            # ciało obce luźne = foreign word (International, European, investment, Office, Deutsche)
            'xxx'     => ['foreign' => 'yes'],
            # forma nierozpoznana = unrecognized form (1985, Wandzia, Queens, University, Rodera)
            'ign'     => [],
            # interpunkcja = punctuation (, . : „ !)
            'interp'  => ['pos' => 'punc']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''  => { 'other/nountype' => { 'depr' => 'depr',
                                                                                  '@'    => 'subst' }},
                                                   '@' => { 'reflex' => { 'yes' => 'siebie',
                                                                          '@'      => { 'person' => { '3' => 'ppron3',
                                                                                                      '@' => 'ppron12' }}}}}},
                       'adj'  => { 'other/adjtype' => { 'winien' => 'winien',
                                                        '@'      => { 'aspect' => { ''  => { 'hyph' => { 'yes' => 'adja',
                                                                                                         '@'    => { 'prepcase' => { 'pre' => 'adjp',
                                                                                                                                     '@'   => 'adj' }}}},
                                                                                    '@' => 'winien' }}}},
                       'num'  => 'num',
                       'verb' => { 'other/verbtype' => { 'pred' => 'pred',
                                                         '@'    => { 'verbform' => { 'inf'   => 'inf',
                                                                                     'fin'   => { 'mood' => { 'imp' => 'impt',
                                                                                                              '@'   => { 'tense' => { 'pres' => { 'verbtype' => { 'aux' => 'aglt',
                                                                                                                                                                  '@'   => 'fin' }},
                                                                                                                                      'fut'  => 'bedzie',
                                                                                                                                      'past' => 'praet' }}}},
                                                                                     'part'  => { 'voice' => { 'act' => 'pact',
                                                                                                               '@'   => { 'other/verbform' => { 'imps' => 'imps',
                                                                                                                                                '@'    => 'ppas' }}}},
                                                                                     'vnoun' => 'ger',
                                                                                     'conv'  => { 'tense' => { 'pres' => 'pcon',
                                                                                                               '@'    => 'pant' }},
                                                                                     '@'     => 'pred' }}}},
                       'adv'  => 'adv',
                       'adp'  => 'prep',
                       'conj' => { 'conjtype' => { 'sub' => 'comp',
                                                   '@'   => 'conj' }},
                       'part' => 'qub',
                       'punc' => 'interp',
                       'sym'  => 'interp',
                       '@'    => { 'foreign' => { 'yes' => { 'other/pos' => { 'xxs' => 'xxs',
                                                                                  '@'   => 'xxx' }},
                                                  '@'       => { 'abbr' => { 'yes' => 'brev',
                                                                             '@'    => 'ign' }}}}}
        }
    );
    # RODZAJ / GENDER ####################
    $atoms{gender} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' =>
        {
            'm1' => ['gender' => 'masc', 'animacy' => 'hum'],
            'm2' => ['gender' => 'masc', 'animacy' => 'nhum'],
            'm3' => ['gender' => 'masc', 'animacy' => 'inan'],
            'f'  => ['gender' => 'fem'],
            'n'  => ['gender' => 'neut']
        },
        'encode_map' =>
        {
            'gender' => { 'masc' => { 'animacy' => { 'anim' => 'm1',
                                                     'hum'  => 'm1',
                                                     'nhum' => 'm2',
                                                     '@'    => 'm3' }},
                          'fem'  => 'f',
                          'neut' => 'n' }
        }
    );
    # LICZBA / NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'sg' => 'sing',
            'pl' => 'plur'
        }
    );
    # PRZYPADEK / CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'nom'  => 'nom',
            'gen'  => 'gen',
            'dat'  => 'dat',
            'acc'  => 'acc',
            'voc'  => 'voc',
            'loc'  => 'loc',
            'inst' => 'ins'
        }
    );
    # OSOBA / PERSON ####################
    $atoms{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            'pri' => '1',
            'sec' => '2',
            'ter' => '3'
        }
    );
    # STOPIEŃ / DEGREE OF COMPARISON ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'pos'  => 'pos',
            'comp' => 'cmp',
            'sup'  => 'sup'
        }
    );
    # ASPEKT / ASPECT ####################
    $atoms{aspect} = $self->create_simple_atom
    (
        'intfeature' => 'aspect',
        'simple_decode_map' =>
        {
            'imperf' => 'imp',
            'perf'   => 'perf'
        }
    );
    # ZANEGOWANIE / POLARITY ####################
    $atoms{polarity} = $self->create_simple_atom
    (
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            'aff' => 'pos',
            'neg' => 'neg'
        }
    );
    # AKCENTOWOŚĆ / ACCENTABILITY ####################
    $atoms{accentability} = $self->create_simple_atom
    (
        'intfeature' => 'variant',
        'simple_decode_map' =>
        {
            'nakc' => 'short',
            'akc'  => 'long'
        }
    );
    # POPRZYIMKOWOŚĆ / SPECIAL FORM AFTER PREPOSITION ####################
    $atoms{prepcase} = $self->create_simple_atom
    (
        'intfeature' => 'prepcase',
        'simple_decode_map' =>
        {
            'praep'  => 'pre', # (niego, -ń)
            'npraep' => 'npr'  # (jego, go)
        }
    );
    # AKOMODACYJNOŚĆ / ACCOMMODABILITY ####################
    # This is a strange feature that deals with case of numerals. I do not know
    # exactly what it encodes. Some numerals govern the counted nouns and force
    # them to genitive plural (pięciu mych współpracowników), some agree with the
    # counted nouns in case (trzech wileńskich i dwóch warszawskich). This also
    # happens in Czech. However, it does not seem to be THE distinction. Both
    # above examples appear with accommodability=rec. However, in Polish, sometimes
    # the numeral itself is in genitive plural, despite the counted noun (wszyci
    # trzej prowadzili; dwaj synowie; czterej profesorowie głosowali). These cases
    # have accommodability=congr. Moreover, the accommodability attribute is often
    # empty. It only occurs with numerals in plural nominative masculine human
    # gender (and it need not occur even there).
    # Note: accommodability=congr seems to only apply to numerical values 2-4:
    # dwaj, obaj, obydwaj, trzej, czterej.
    # dwaj [dwa:num:pl:nom:m1:congr]
    # (jacyś dwaj [dwa:num:pl:nom:m1:congr] szesnastolatkowie znaleźli)
    # dwóch [dwa:num:pl:nom:m1:rec]
    # (jeden gra na grzebieniu, dwóch [dwa:num:pl:nom:m1:rec] rzuca w siebie papierowymi strzałami)
    # for num:pl:nom:m1, without accommodability set, the following lemmas have been observed:
    # dwoje, czworo, kilkoro, jedenaścioro
    # (Kiedy dwoje [dwoje:num:pl:nom:m1] ludzi mówi)
    $atoms{accommodability} = $self->create_atom
    (
        'surfeature' => 'accommodability',
        'decode_map' =>
        {
            'congr' => ['other' => {'accom' => 'congr'}],
            'rec'   => ['other' => {'accom' => 'rec'}]
        },
        'encode_map' =>
        {
            'other/accom' => { 'congr' => 'congr',
                               'rec'   => 'rec' }
        }
    );
    # AGLUTYNACYJNOŚĆ / AGGLUTINATION ####################
    # Whether there is an attached (although split by tokenization)
    # agglutinative morpheme (clitic?) of the verb "być" ("to be").
    # nagl: niósł
    # agl:  niosł- (e.g. niosłem, niosłeś)
    $atoms{agglutination} = $self->create_atom
    (
        'surfeature' => 'agglutination',
        'decode_map' =>
        {
            'nagl' => ['other' => {'agglutination' => 'nagl'}],
            'agl'  => ['other' => {'agglutination' => 'agl'}]
        },
        'encode_map' =>
        {
            'other/agglutination' => { 'nagl' => 'nagl',
                                       'agl'  => 'agl' }
        }
    );
    # WOKALICZNOŚĆ / VOCALICITY ####################
    $atoms{vocalicity} = $self->create_simple_atom
    (
        'intfeature' => 'variant',
        'simple_decode_map' =>
        {
            'nwok' => 'short',
            'wok'  => 'long'
        }
    );
    # IS THERE PUNCTUATION AFTER ABBREVIATION? ####################
    $atoms{brev} = $self->create_atom
    (
        'surfeature' => 'brev',
        'decode_map' =>
        {
            'npun' => ['other' => {'brev' => 'npun'}],
            'pun'  => ['other' => {'brev' => 'pun'}]
        },
        'encode_map' =>
        {
            'other/brev' => { 'npun' => 'npun',
                              '@'    => 'pun' }
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map {$atoms{$_}} (@{$self->features_all()});
    $atoms{feature} = $self->create_merged_atom
    (
        'surfeature' => 'feature',
        'atoms'      => \@fatoms
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates the list of all surface CoNLL features that can appear in the FEATS
# column. This list will be used in decode().
#------------------------------------------------------------------------------
sub _create_features_all
{
    my $self = shift;
    my @features = ('pos', 'gender', 'number', 'case', 'person', 'degree', 'aspect', 'polarity', 'accentability', 'prepcase', 'accommodability', 'agglutination', 'vocalicity', 'brev');
    return \@features;
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
    $fs->set_tagset('pl::ipipan');
    my $atoms = $self->atoms();
    # The part of speech and all other features form one string with colons as delimiters.
    # example: subst:sg:nom:m1
    # In order to distinguish complementizer (part of speech) and comparative (degree feature),
    # we change the former from 'comp' to 'compl'. The respective atom expects it.
    $tag = 'compl' if($tag =~ m/^comp(:.*)?$/);
    my @features = split(/:/, $tag);
    foreach my $feature (@features)
    {
        $atoms->{feature}->decode_and_merge_hard($feature, $fs);
    }
    return $fs;
}



#------------------------------------------------------------------------------
# Creates the list of surface CoNLL features that can appear in the FEATS
# column with particular parts of speech. This list will be used in encode().
#------------------------------------------------------------------------------
sub _create_features_pos
{
    my $self = shift;
    my %features =
    (
        'adj'     => ['number', 'case', 'gender', 'degree'],
        'adv'     => ['degree'],
        'aglt'    => ['number', 'person', 'aspect', 'vocalicity'],
        'bedzie'  => ['number', 'person', 'aspect'],
        'depr'    => ['number', 'case', 'gender'],
        'fin'     => ['number', 'person', 'aspect'],
        'ger'     => ['number', 'case', 'gender', 'aspect', 'polarity'],
        'imps'    => ['aspect'],
        'impt'    => ['number', 'person', 'aspect'],
        'inf'     => ['aspect'],
        'num'     => ['number', 'case', 'gender', 'accommodability'],
        'pact'    => ['number', 'case', 'gender', 'aspect', 'polarity'],
        'pant'    => ['aspect'],
        'pcon'    => ['aspect'],
        'ppas'    => ['number', 'case', 'gender', 'aspect', 'polarity'],
        'ppron12' => ['number', 'case', 'gender', 'person', 'accentability'],
        'ppron3'  => ['number', 'case', 'gender', 'person', 'accentability', 'prepcase'],
        'praet'   => ['number', 'gender', 'aspect', 'agglutination'],
        'prep'    => ['case', 'vocalicity'],
        'siebie'  => ['case'],
        'subst'   => ['number', 'case', 'gender'],
        'winien'  => ['number', 'gender', 'aspect'],
        'brev'    => ['brev']
    );
    return \%features;
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
    my $fpos = $pos;
    my $feature_names = $self->get_feature_names($fpos);
    my @features = ($pos);
    if(defined($feature_names) && ref($feature_names) eq 'ARRAY')
    {
        foreach my $feature (@{$feature_names})
        {
            my $value = $atoms->{$feature}->encode($fs);
            push(@features, $value) unless($value eq '');
        }
    }
    my $tag = join(':', @features);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# 1282
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
adj:pl:acc:f:comp
adj:pl:acc:f:pos
adj:pl:acc:f:sup
adj:pl:acc:m1:comp
adj:pl:acc:m1:pos
adj:pl:acc:m1:sup
adj:pl:acc:m2:comp
adj:pl:acc:m2:pos
adj:pl:acc:m2:sup
adj:pl:acc:m3:comp
adj:pl:acc:m3:pos
adj:pl:acc:m3:sup
adj:pl:acc:n:comp
adj:pl:acc:n:pos
adj:pl:acc:n:sup
adj:pl:dat:f:comp
adj:pl:dat:f:pos
adj:pl:dat:f:sup
adj:pl:dat:m1:comp
adj:pl:dat:m1:pos
adj:pl:dat:m1:sup
adj:pl:dat:m2:comp
adj:pl:dat:m2:pos
adj:pl:dat:m2:sup
adj:pl:dat:m3:comp
adj:pl:dat:m3:pos
adj:pl:dat:m3:sup
adj:pl:dat:n:comp
adj:pl:dat:n:pos
adj:pl:dat:n:sup
adj:pl:gen:f:comp
adj:pl:gen:f:pos
adj:pl:gen:f:sup
adj:pl:gen:m1:comp
adj:pl:gen:m1:pos
adj:pl:gen:m1:sup
adj:pl:gen:m2:comp
adj:pl:gen:m2:pos
adj:pl:gen:m2:sup
adj:pl:gen:m3:comp
adj:pl:gen:m3:pos
adj:pl:gen:m3:sup
adj:pl:gen:n:comp
adj:pl:gen:n:pos
adj:pl:gen:n:sup
adj:pl:inst:f:comp
adj:pl:inst:f:pos
adj:pl:inst:f:sup
adj:pl:inst:m1:comp
adj:pl:inst:m1:pos
adj:pl:inst:m1:sup
adj:pl:inst:m2:comp
adj:pl:inst:m2:pos
adj:pl:inst:m2:sup
adj:pl:inst:m3:comp
adj:pl:inst:m3:pos
adj:pl:inst:m3:sup
adj:pl:inst:n:comp
adj:pl:inst:n:pos
adj:pl:inst:n:sup
adj:pl:loc:f:comp
adj:pl:loc:f:pos
adj:pl:loc:f:sup
adj:pl:loc:m1:comp
adj:pl:loc:m1:pos
adj:pl:loc:m1:sup
adj:pl:loc:m2:comp
adj:pl:loc:m2:pos
adj:pl:loc:m2:sup
adj:pl:loc:m3:comp
adj:pl:loc:m3:pos
adj:pl:loc:m3:sup
adj:pl:loc:n:comp
adj:pl:loc:n:pos
adj:pl:loc:n:sup
adj:pl:nom:f:comp
adj:pl:nom:f:pos
adj:pl:nom:f:sup
adj:pl:nom:m1:comp
adj:pl:nom:m1:pos
adj:pl:nom:m1:sup
adj:pl:nom:m2:comp
adj:pl:nom:m2:pos
adj:pl:nom:m2:sup
adj:pl:nom:m3:comp
adj:pl:nom:m3:pos
adj:pl:nom:m3:sup
adj:pl:nom:n:comp
adj:pl:nom:n:pos
adj:pl:nom:n:sup
adj:sg:acc:f:comp
adj:sg:acc:f:pos
adj:sg:acc:f:sup
adj:sg:acc:m1:comp
adj:sg:acc:m1:pos
adj:sg:acc:m1:sup
adj:sg:acc:m2:comp
adj:sg:acc:m2:pos
adj:sg:acc:m2:sup
adj:sg:acc:m3:comp
adj:sg:acc:m3:pos
adj:sg:acc:m3:sup
adj:sg:acc:n:comp
adj:sg:acc:n:pos
adj:sg:acc:n:sup
adj:sg:dat:f:comp
adj:sg:dat:f:pos
adj:sg:dat:f:sup
adj:sg:dat:m1:comp
adj:sg:dat:m1:pos
adj:sg:dat:m1:sup
adj:sg:dat:m2:comp
adj:sg:dat:m2:pos
adj:sg:dat:m2:sup
adj:sg:dat:m3:comp
adj:sg:dat:m3:pos
adj:sg:dat:m3:sup
adj:sg:dat:n:comp
adj:sg:dat:n:pos
adj:sg:dat:n:sup
adj:sg:gen:f:comp
adj:sg:gen:f:pos
adj:sg:gen:f:sup
adj:sg:gen:m1:comp
adj:sg:gen:m1:pos
adj:sg:gen:m1:sup
adj:sg:gen:m2:comp
adj:sg:gen:m2:pos
adj:sg:gen:m2:sup
adj:sg:gen:m3:comp
adj:sg:gen:m3:pos
adj:sg:gen:m3:sup
adj:sg:gen:n:comp
adj:sg:gen:n:pos
adj:sg:gen:n:sup
adj:sg:inst:f:comp
adj:sg:inst:f:pos
adj:sg:inst:f:sup
adj:sg:inst:m1:comp
adj:sg:inst:m1:pos
adj:sg:inst:m1:sup
adj:sg:inst:m2:comp
adj:sg:inst:m2:pos
adj:sg:inst:m2:sup
adj:sg:inst:m3:comp
adj:sg:inst:m3:pos
adj:sg:inst:m3:sup
adj:sg:inst:n:comp
adj:sg:inst:n:pos
adj:sg:inst:n:sup
adj:sg:loc:f:comp
adj:sg:loc:f:pos
adj:sg:loc:f:sup
adj:sg:loc:m1:comp
adj:sg:loc:m1:pos
adj:sg:loc:m1:sup
adj:sg:loc:m2:comp
adj:sg:loc:m2:pos
adj:sg:loc:m2:sup
adj:sg:loc:m3:comp
adj:sg:loc:m3:pos
adj:sg:loc:m3:sup
adj:sg:loc:n:comp
adj:sg:loc:n:pos
adj:sg:loc:n:sup
adj:sg:nom:f:comp
adj:sg:nom:f:pos
adj:sg:nom:f:sup
adj:sg:nom:m1:comp
adj:sg:nom:m1:pos
adj:sg:nom:m1:sup
adj:sg:nom:m2:comp
adj:sg:nom:m2:pos
adj:sg:nom:m2:sup
adj:sg:nom:m3:comp
adj:sg:nom:m3:pos
adj:sg:nom:m3:sup
adj:sg:nom:n:comp
adj:sg:nom:n:pos
adj:sg:nom:n:sup
adjp
adv:comp
adv:pos
adv:sup
aglt:pl:pri:imperf:nwok
aglt:pl:sec:imperf:nwok
aglt:sg:pri:imperf:nwok
aglt:sg:pri:imperf:wok
aglt:sg:sec:imperf:nwok
aglt:sg:sec:imperf:wok
bedzie:pl:pri:imperf
bedzie:pl:sec:imperf
bedzie:pl:ter:imperf
bedzie:sg:pri:imperf
bedzie:sg:sec:imperf
bedzie:sg:ter:imperf
brev:npun
brev:pun
comp
conj
depr:pl:nom:m2
depr:pl:voc:m2
fin:pl:pri:imperf
fin:pl:pri:perf
fin:pl:sec:imperf
fin:pl:sec:perf
fin:pl:ter:imperf
fin:pl:ter:perf
fin:sg:pri:imperf
fin:sg:pri:perf
fin:sg:sec:imperf
fin:sg:sec:perf
fin:sg:ter:imperf
fin:sg:ter:perf
ger:sg:acc:n:imperf:aff
ger:sg:acc:n:imperf:neg
ger:sg:acc:n:perf:aff
ger:sg:acc:n:perf:neg
ger:sg:dat:n:imperf:aff
ger:sg:dat:n:imperf:neg
ger:sg:dat:n:perf:aff
ger:sg:dat:n:perf:neg
ger:sg:gen:n:imperf:aff
ger:sg:gen:n:imperf:neg
ger:sg:gen:n:perf:aff
ger:sg:gen:n:perf:neg
ger:sg:inst:n:imperf:aff
ger:sg:inst:n:imperf:neg
ger:sg:inst:n:perf:aff
ger:sg:inst:n:perf:neg
ger:sg:loc:n:imperf:aff
ger:sg:loc:n:imperf:neg
ger:sg:loc:n:perf:aff
ger:sg:loc:n:perf:neg
ger:sg:nom:n:imperf:aff
ger:sg:nom:n:imperf:neg
ger:sg:nom:n:perf:aff
ger:sg:nom:n:perf:neg
ign
imps:imperf
imps:perf
impt:pl:pri:imperf
impt:pl:pri:perf
impt:pl:sec:imperf
impt:pl:sec:perf
impt:sg:sec:imperf
impt:sg:sec:perf
inf:imperf
inf:perf
interp
num:pl:acc:f
num:pl:acc:m1
num:pl:acc:m2
num:pl:acc:m3
num:pl:acc:n
num:pl:dat:f
num:pl:dat:m1
num:pl:dat:m2
num:pl:dat:m3
num:pl:dat:n
num:pl:gen:f
num:pl:gen:m1
num:pl:gen:m2
num:pl:gen:m3
num:pl:gen:n
num:pl:inst:f
num:pl:inst:m1
num:pl:inst:m2
num:pl:inst:m3
num:pl:inst:n
num:pl:loc:f
num:pl:loc:m1
num:pl:loc:m2
num:pl:loc:m3
num:pl:loc:n
num:pl:nom:f
num:pl:nom:m1
num:pl:nom:m1:congr
num:pl:nom:m1:rec
num:pl:nom:m2
num:pl:nom:m3
num:pl:nom:n
num:pl:voc:f
num:pl:voc:m1
num:pl:voc:m2
num:pl:voc:m3
num:pl:voc:n
pact:pl:acc:f:imperf:aff
pact:pl:acc:f:imperf:neg
pact:pl:acc:f:perf:aff
pact:pl:acc:f:perf:neg
pact:pl:acc:m1:imperf:aff
pact:pl:acc:m1:imperf:neg
pact:pl:acc:m1:perf:aff
pact:pl:acc:m1:perf:neg
pact:pl:acc:m2:imperf:aff
pact:pl:acc:m2:imperf:neg
pact:pl:acc:m2:perf:aff
pact:pl:acc:m2:perf:neg
pact:pl:acc:m3:imperf:aff
pact:pl:acc:m3:imperf:neg
pact:pl:acc:m3:perf:aff
pact:pl:acc:m3:perf:neg
pact:pl:acc:n:imperf:aff
pact:pl:acc:n:imperf:neg
pact:pl:acc:n:perf:aff
pact:pl:acc:n:perf:neg
pact:pl:dat:f:imperf:aff
pact:pl:dat:f:imperf:neg
pact:pl:dat:f:perf:aff
pact:pl:dat:f:perf:neg
pact:pl:dat:m1:imperf:aff
pact:pl:dat:m1:imperf:neg
pact:pl:dat:m1:perf:aff
pact:pl:dat:m1:perf:neg
pact:pl:dat:m2:imperf:aff
pact:pl:dat:m2:imperf:neg
pact:pl:dat:m2:perf:aff
pact:pl:dat:m2:perf:neg
pact:pl:dat:m3:imperf:aff
pact:pl:dat:m3:imperf:neg
pact:pl:dat:m3:perf:aff
pact:pl:dat:m3:perf:neg
pact:pl:dat:n:imperf:aff
pact:pl:dat:n:imperf:neg
pact:pl:dat:n:perf:aff
pact:pl:dat:n:perf:neg
pact:pl:gen:f:imperf:aff
pact:pl:gen:f:imperf:neg
pact:pl:gen:f:perf:aff
pact:pl:gen:f:perf:neg
pact:pl:gen:m1:imperf:aff
pact:pl:gen:m1:imperf:neg
pact:pl:gen:m1:perf:aff
pact:pl:gen:m1:perf:neg
pact:pl:gen:m2:imperf:aff
pact:pl:gen:m2:imperf:neg
pact:pl:gen:m2:perf:aff
pact:pl:gen:m2:perf:neg
pact:pl:gen:m3:imperf:aff
pact:pl:gen:m3:imperf:neg
pact:pl:gen:m3:perf:aff
pact:pl:gen:m3:perf:neg
pact:pl:gen:n:imperf:aff
pact:pl:gen:n:imperf:neg
pact:pl:gen:n:perf:aff
pact:pl:gen:n:perf:neg
pact:pl:inst:f:imperf:aff
pact:pl:inst:f:imperf:neg
pact:pl:inst:f:perf:aff
pact:pl:inst:f:perf:neg
pact:pl:inst:m1:imperf:aff
pact:pl:inst:m1:imperf:neg
pact:pl:inst:m1:perf:aff
pact:pl:inst:m1:perf:neg
pact:pl:inst:m2:imperf:aff
pact:pl:inst:m2:imperf:neg
pact:pl:inst:m2:perf:aff
pact:pl:inst:m2:perf:neg
pact:pl:inst:m3:imperf:aff
pact:pl:inst:m3:imperf:neg
pact:pl:inst:m3:perf:aff
pact:pl:inst:m3:perf:neg
pact:pl:inst:n:imperf:aff
pact:pl:inst:n:imperf:neg
pact:pl:inst:n:perf:aff
pact:pl:inst:n:perf:neg
pact:pl:loc:f:imperf:aff
pact:pl:loc:f:imperf:neg
pact:pl:loc:f:perf:aff
pact:pl:loc:f:perf:neg
pact:pl:loc:m1:imperf:aff
pact:pl:loc:m1:imperf:neg
pact:pl:loc:m1:perf:aff
pact:pl:loc:m1:perf:neg
pact:pl:loc:m2:imperf:aff
pact:pl:loc:m2:imperf:neg
pact:pl:loc:m2:perf:aff
pact:pl:loc:m2:perf:neg
pact:pl:loc:m3:imperf:aff
pact:pl:loc:m3:imperf:neg
pact:pl:loc:m3:perf:aff
pact:pl:loc:m3:perf:neg
pact:pl:loc:n:imperf:aff
pact:pl:loc:n:imperf:neg
pact:pl:loc:n:perf:aff
pact:pl:loc:n:perf:neg
pact:pl:nom:f:imperf:aff
pact:pl:nom:f:imperf:neg
pact:pl:nom:f:perf:aff
pact:pl:nom:f:perf:neg
pact:pl:nom:m1:imperf:aff
pact:pl:nom:m1:imperf:neg
pact:pl:nom:m1:perf:aff
pact:pl:nom:m1:perf:neg
pact:pl:nom:m2:imperf:aff
pact:pl:nom:m2:imperf:neg
pact:pl:nom:m2:perf:aff
pact:pl:nom:m2:perf:neg
pact:pl:nom:m3:imperf:aff
pact:pl:nom:m3:imperf:neg
pact:pl:nom:m3:perf:aff
pact:pl:nom:m3:perf:neg
pact:pl:nom:n:imperf:aff
pact:pl:nom:n:imperf:neg
pact:pl:nom:n:perf:aff
pact:pl:nom:n:perf:neg
pact:sg:acc:f:imperf:aff
pact:sg:acc:f:imperf:neg
pact:sg:acc:f:perf:aff
pact:sg:acc:f:perf:neg
pact:sg:acc:m1:imperf:aff
pact:sg:acc:m1:imperf:neg
pact:sg:acc:m1:perf:aff
pact:sg:acc:m1:perf:neg
pact:sg:acc:m2:imperf:aff
pact:sg:acc:m2:imperf:neg
pact:sg:acc:m2:perf:aff
pact:sg:acc:m2:perf:neg
pact:sg:acc:m3:imperf:aff
pact:sg:acc:m3:imperf:neg
pact:sg:acc:m3:perf:aff
pact:sg:acc:m3:perf:neg
pact:sg:acc:n:imperf:aff
pact:sg:acc:n:imperf:neg
pact:sg:acc:n:perf:aff
pact:sg:acc:n:perf:neg
pact:sg:dat:f:imperf:aff
pact:sg:dat:f:imperf:neg
pact:sg:dat:f:perf:aff
pact:sg:dat:f:perf:neg
pact:sg:dat:m1:imperf:aff
pact:sg:dat:m1:imperf:neg
pact:sg:dat:m1:perf:aff
pact:sg:dat:m1:perf:neg
pact:sg:dat:m2:imperf:aff
pact:sg:dat:m2:imperf:neg
pact:sg:dat:m2:perf:aff
pact:sg:dat:m2:perf:neg
pact:sg:dat:m3:imperf:aff
pact:sg:dat:m3:imperf:neg
pact:sg:dat:m3:perf:aff
pact:sg:dat:m3:perf:neg
pact:sg:dat:n:imperf:aff
pact:sg:dat:n:imperf:neg
pact:sg:dat:n:perf:aff
pact:sg:dat:n:perf:neg
pact:sg:gen:f:imperf:aff
pact:sg:gen:f:imperf:neg
pact:sg:gen:f:perf:aff
pact:sg:gen:f:perf:neg
pact:sg:gen:m1:imperf:aff
pact:sg:gen:m1:imperf:neg
pact:sg:gen:m1:perf:aff
pact:sg:gen:m1:perf:neg
pact:sg:gen:m2:imperf:aff
pact:sg:gen:m2:imperf:neg
pact:sg:gen:m2:perf:aff
pact:sg:gen:m2:perf:neg
pact:sg:gen:m3:imperf:aff
pact:sg:gen:m3:imperf:neg
pact:sg:gen:m3:perf:aff
pact:sg:gen:m3:perf:neg
pact:sg:gen:n:imperf:aff
pact:sg:gen:n:imperf:neg
pact:sg:gen:n:perf:aff
pact:sg:gen:n:perf:neg
pact:sg:inst:f:imperf:aff
pact:sg:inst:f:imperf:neg
pact:sg:inst:f:perf:aff
pact:sg:inst:f:perf:neg
pact:sg:inst:m1:imperf:aff
pact:sg:inst:m1:imperf:neg
pact:sg:inst:m1:perf:aff
pact:sg:inst:m1:perf:neg
pact:sg:inst:m2:imperf:aff
pact:sg:inst:m2:imperf:neg
pact:sg:inst:m2:perf:aff
pact:sg:inst:m2:perf:neg
pact:sg:inst:m3:imperf:aff
pact:sg:inst:m3:imperf:neg
pact:sg:inst:m3:perf:aff
pact:sg:inst:m3:perf:neg
pact:sg:inst:n:imperf:aff
pact:sg:inst:n:imperf:neg
pact:sg:inst:n:perf:aff
pact:sg:inst:n:perf:neg
pact:sg:loc:f:imperf:aff
pact:sg:loc:f:imperf:neg
pact:sg:loc:f:perf:aff
pact:sg:loc:f:perf:neg
pact:sg:loc:m1:imperf:aff
pact:sg:loc:m1:imperf:neg
pact:sg:loc:m1:perf:aff
pact:sg:loc:m1:perf:neg
pact:sg:loc:m2:imperf:aff
pact:sg:loc:m2:imperf:neg
pact:sg:loc:m2:perf:aff
pact:sg:loc:m2:perf:neg
pact:sg:loc:m3:imperf:aff
pact:sg:loc:m3:imperf:neg
pact:sg:loc:m3:perf:aff
pact:sg:loc:m3:perf:neg
pact:sg:loc:n:imperf:aff
pact:sg:loc:n:imperf:neg
pact:sg:loc:n:perf:aff
pact:sg:loc:n:perf:neg
pact:sg:nom:f:imperf:aff
pact:sg:nom:f:imperf:neg
pact:sg:nom:f:perf:aff
pact:sg:nom:f:perf:neg
pact:sg:nom:m1:imperf:aff
pact:sg:nom:m1:imperf:neg
pact:sg:nom:m1:perf:aff
pact:sg:nom:m1:perf:neg
pact:sg:nom:m2:imperf:aff
pact:sg:nom:m2:imperf:neg
pact:sg:nom:m2:perf:aff
pact:sg:nom:m2:perf:neg
pact:sg:nom:m3:imperf:aff
pact:sg:nom:m3:imperf:neg
pact:sg:nom:m3:perf:aff
pact:sg:nom:m3:perf:neg
pact:sg:nom:n:imperf:aff
pact:sg:nom:n:imperf:neg
pact:sg:nom:n:perf:aff
pact:sg:nom:n:perf:neg
pant:imperf
pant:perf
pcon:imperf
pcon:perf
ppas:pl:acc:f:imperf:aff
ppas:pl:acc:f:imperf:neg
ppas:pl:acc:f:perf:aff
ppas:pl:acc:f:perf:neg
ppas:pl:acc:m1:imperf:aff
ppas:pl:acc:m1:imperf:neg
ppas:pl:acc:m1:perf:aff
ppas:pl:acc:m1:perf:neg
ppas:pl:acc:m2:imperf:aff
ppas:pl:acc:m2:imperf:neg
ppas:pl:acc:m2:perf:aff
ppas:pl:acc:m2:perf:neg
ppas:pl:acc:m3:imperf:aff
ppas:pl:acc:m3:imperf:neg
ppas:pl:acc:m3:perf:aff
ppas:pl:acc:m3:perf:neg
ppas:pl:acc:n:imperf:aff
ppas:pl:acc:n:imperf:neg
ppas:pl:acc:n:perf:aff
ppas:pl:acc:n:perf:neg
ppas:pl:dat:f:imperf:aff
ppas:pl:dat:f:imperf:neg
ppas:pl:dat:f:perf:aff
ppas:pl:dat:f:perf:neg
ppas:pl:dat:m1:imperf:aff
ppas:pl:dat:m1:imperf:neg
ppas:pl:dat:m1:perf:aff
ppas:pl:dat:m1:perf:neg
ppas:pl:dat:m2:imperf:aff
ppas:pl:dat:m2:imperf:neg
ppas:pl:dat:m2:perf:aff
ppas:pl:dat:m2:perf:neg
ppas:pl:dat:m3:imperf:aff
ppas:pl:dat:m3:imperf:neg
ppas:pl:dat:m3:perf:aff
ppas:pl:dat:m3:perf:neg
ppas:pl:dat:n:imperf:aff
ppas:pl:dat:n:imperf:neg
ppas:pl:dat:n:perf:aff
ppas:pl:dat:n:perf:neg
ppas:pl:gen:f:imperf:aff
ppas:pl:gen:f:imperf:neg
ppas:pl:gen:f:perf:aff
ppas:pl:gen:f:perf:neg
ppas:pl:gen:m1:imperf:aff
ppas:pl:gen:m1:imperf:neg
ppas:pl:gen:m1:perf:aff
ppas:pl:gen:m1:perf:neg
ppas:pl:gen:m2:imperf:aff
ppas:pl:gen:m2:imperf:neg
ppas:pl:gen:m2:perf:aff
ppas:pl:gen:m2:perf:neg
ppas:pl:gen:m3:imperf:aff
ppas:pl:gen:m3:imperf:neg
ppas:pl:gen:m3:perf:aff
ppas:pl:gen:m3:perf:neg
ppas:pl:gen:n:imperf:aff
ppas:pl:gen:n:imperf:neg
ppas:pl:gen:n:perf:aff
ppas:pl:gen:n:perf:neg
ppas:pl:inst:f:imperf:aff
ppas:pl:inst:f:imperf:neg
ppas:pl:inst:f:perf:aff
ppas:pl:inst:f:perf:neg
ppas:pl:inst:m1:imperf:aff
ppas:pl:inst:m1:imperf:neg
ppas:pl:inst:m1:perf:aff
ppas:pl:inst:m1:perf:neg
ppas:pl:inst:m2:imperf:aff
ppas:pl:inst:m2:imperf:neg
ppas:pl:inst:m2:perf:aff
ppas:pl:inst:m2:perf:neg
ppas:pl:inst:m3:imperf:aff
ppas:pl:inst:m3:imperf:neg
ppas:pl:inst:m3:perf:aff
ppas:pl:inst:m3:perf:neg
ppas:pl:inst:n:imperf:aff
ppas:pl:inst:n:imperf:neg
ppas:pl:inst:n:perf:aff
ppas:pl:inst:n:perf:neg
ppas:pl:loc:f:imperf:aff
ppas:pl:loc:f:imperf:neg
ppas:pl:loc:f:perf:aff
ppas:pl:loc:f:perf:neg
ppas:pl:loc:m1:imperf:aff
ppas:pl:loc:m1:imperf:neg
ppas:pl:loc:m1:perf:aff
ppas:pl:loc:m1:perf:neg
ppas:pl:loc:m2:imperf:aff
ppas:pl:loc:m2:imperf:neg
ppas:pl:loc:m2:perf:aff
ppas:pl:loc:m2:perf:neg
ppas:pl:loc:m3:imperf:aff
ppas:pl:loc:m3:imperf:neg
ppas:pl:loc:m3:perf:aff
ppas:pl:loc:m3:perf:neg
ppas:pl:loc:n:imperf:aff
ppas:pl:loc:n:imperf:neg
ppas:pl:loc:n:perf:aff
ppas:pl:loc:n:perf:neg
ppas:pl:nom:f:imperf:aff
ppas:pl:nom:f:imperf:neg
ppas:pl:nom:f:perf:aff
ppas:pl:nom:f:perf:neg
ppas:pl:nom:m1:imperf:aff
ppas:pl:nom:m1:imperf:neg
ppas:pl:nom:m1:perf:aff
ppas:pl:nom:m1:perf:neg
ppas:pl:nom:m2:imperf:aff
ppas:pl:nom:m2:imperf:neg
ppas:pl:nom:m2:perf:aff
ppas:pl:nom:m2:perf:neg
ppas:pl:nom:m3:imperf:aff
ppas:pl:nom:m3:imperf:neg
ppas:pl:nom:m3:perf:aff
ppas:pl:nom:m3:perf:neg
ppas:pl:nom:n:imperf:aff
ppas:pl:nom:n:imperf:neg
ppas:pl:nom:n:perf:aff
ppas:pl:nom:n:perf:neg
ppas:sg:acc:f:imperf:aff
ppas:sg:acc:f:imperf:neg
ppas:sg:acc:f:perf:aff
ppas:sg:acc:f:perf:neg
ppas:sg:acc:m1:imperf:aff
ppas:sg:acc:m1:imperf:neg
ppas:sg:acc:m1:perf:aff
ppas:sg:acc:m1:perf:neg
ppas:sg:acc:m2:imperf:aff
ppas:sg:acc:m2:imperf:neg
ppas:sg:acc:m2:perf:aff
ppas:sg:acc:m2:perf:neg
ppas:sg:acc:m3:imperf:aff
ppas:sg:acc:m3:imperf:neg
ppas:sg:acc:m3:perf:aff
ppas:sg:acc:m3:perf:neg
ppas:sg:acc:n:imperf:aff
ppas:sg:acc:n:imperf:neg
ppas:sg:acc:n:perf:aff
ppas:sg:acc:n:perf:neg
ppas:sg:dat:f:imperf:aff
ppas:sg:dat:f:imperf:neg
ppas:sg:dat:f:perf:aff
ppas:sg:dat:f:perf:neg
ppas:sg:dat:m1:imperf:aff
ppas:sg:dat:m1:imperf:neg
ppas:sg:dat:m1:perf:aff
ppas:sg:dat:m1:perf:neg
ppas:sg:dat:m2:imperf:aff
ppas:sg:dat:m2:imperf:neg
ppas:sg:dat:m2:perf:aff
ppas:sg:dat:m2:perf:neg
ppas:sg:dat:m3:imperf:aff
ppas:sg:dat:m3:imperf:neg
ppas:sg:dat:m3:perf:aff
ppas:sg:dat:m3:perf:neg
ppas:sg:dat:n:imperf:aff
ppas:sg:dat:n:imperf:neg
ppas:sg:dat:n:perf:aff
ppas:sg:dat:n:perf:neg
ppas:sg:gen:f:imperf:aff
ppas:sg:gen:f:imperf:neg
ppas:sg:gen:f:perf:aff
ppas:sg:gen:f:perf:neg
ppas:sg:gen:m1:imperf:aff
ppas:sg:gen:m1:imperf:neg
ppas:sg:gen:m1:perf:aff
ppas:sg:gen:m1:perf:neg
ppas:sg:gen:m2:imperf:aff
ppas:sg:gen:m2:imperf:neg
ppas:sg:gen:m2:perf:aff
ppas:sg:gen:m2:perf:neg
ppas:sg:gen:m3:imperf:aff
ppas:sg:gen:m3:imperf:neg
ppas:sg:gen:m3:perf:aff
ppas:sg:gen:m3:perf:neg
ppas:sg:gen:n:imperf:aff
ppas:sg:gen:n:imperf:neg
ppas:sg:gen:n:perf:aff
ppas:sg:gen:n:perf:neg
ppas:sg:inst:f:imperf:aff
ppas:sg:inst:f:imperf:neg
ppas:sg:inst:f:perf:aff
ppas:sg:inst:f:perf:neg
ppas:sg:inst:m1:imperf:aff
ppas:sg:inst:m1:imperf:neg
ppas:sg:inst:m1:perf:aff
ppas:sg:inst:m1:perf:neg
ppas:sg:inst:m2:imperf:aff
ppas:sg:inst:m2:imperf:neg
ppas:sg:inst:m2:perf:aff
ppas:sg:inst:m2:perf:neg
ppas:sg:inst:m3:imperf:aff
ppas:sg:inst:m3:imperf:neg
ppas:sg:inst:m3:perf:aff
ppas:sg:inst:m3:perf:neg
ppas:sg:inst:n:imperf:aff
ppas:sg:inst:n:imperf:neg
ppas:sg:inst:n:perf:aff
ppas:sg:inst:n:perf:neg
ppas:sg:loc:f:imperf:aff
ppas:sg:loc:f:imperf:neg
ppas:sg:loc:f:perf:aff
ppas:sg:loc:f:perf:neg
ppas:sg:loc:m1:imperf:aff
ppas:sg:loc:m1:imperf:neg
ppas:sg:loc:m1:perf:aff
ppas:sg:loc:m1:perf:neg
ppas:sg:loc:m2:imperf:aff
ppas:sg:loc:m2:imperf:neg
ppas:sg:loc:m2:perf:aff
ppas:sg:loc:m2:perf:neg
ppas:sg:loc:m3:imperf:aff
ppas:sg:loc:m3:imperf:neg
ppas:sg:loc:m3:perf:aff
ppas:sg:loc:m3:perf:neg
ppas:sg:loc:n:imperf:aff
ppas:sg:loc:n:imperf:neg
ppas:sg:loc:n:perf:aff
ppas:sg:loc:n:perf:neg
ppas:sg:nom:f:imperf:aff
ppas:sg:nom:f:imperf:neg
ppas:sg:nom:f:perf:aff
ppas:sg:nom:f:perf:neg
ppas:sg:nom:m1:imperf:aff
ppas:sg:nom:m1:imperf:neg
ppas:sg:nom:m1:perf:aff
ppas:sg:nom:m1:perf:neg
ppas:sg:nom:m2:imperf:aff
ppas:sg:nom:m2:imperf:neg
ppas:sg:nom:m2:perf:aff
ppas:sg:nom:m2:perf:neg
ppas:sg:nom:m3:imperf:aff
ppas:sg:nom:m3:imperf:neg
ppas:sg:nom:m3:perf:aff
ppas:sg:nom:m3:perf:neg
ppas:sg:nom:n:imperf:aff
ppas:sg:nom:n:imperf:neg
ppas:sg:nom:n:perf:aff
ppas:sg:nom:n:perf:neg
ppron12:pl:acc:f:pri
ppron12:pl:acc:f:sec
ppron12:pl:acc:m1:pri
ppron12:pl:acc:m1:sec
ppron12:pl:acc:m2:pri
ppron12:pl:acc:m2:sec
ppron12:pl:acc:m3:pri
ppron12:pl:acc:m3:sec
ppron12:pl:acc:n:pri
ppron12:pl:acc:n:sec
ppron12:pl:dat:f:pri
ppron12:pl:dat:f:sec
ppron12:pl:dat:m1:pri
ppron12:pl:dat:m1:sec
ppron12:pl:dat:m2:pri
ppron12:pl:dat:m2:sec
ppron12:pl:dat:m3:pri
ppron12:pl:dat:m3:sec
ppron12:pl:dat:n:pri
ppron12:pl:dat:n:sec
ppron12:pl:gen:f:pri
ppron12:pl:gen:f:sec
ppron12:pl:gen:m1:pri
ppron12:pl:gen:m1:sec
ppron12:pl:gen:m2:pri
ppron12:pl:gen:m2:sec
ppron12:pl:gen:m3:pri
ppron12:pl:gen:m3:sec
ppron12:pl:gen:n:pri
ppron12:pl:gen:n:sec
ppron12:pl:inst:f:pri
ppron12:pl:inst:f:sec
ppron12:pl:inst:m1:pri
ppron12:pl:inst:m1:sec
ppron12:pl:inst:m2:pri
ppron12:pl:inst:m2:sec
ppron12:pl:inst:m3:pri
ppron12:pl:inst:m3:sec
ppron12:pl:inst:n:pri
ppron12:pl:inst:n:sec
ppron12:pl:loc:f:pri
ppron12:pl:loc:f:sec
ppron12:pl:loc:m1:pri
ppron12:pl:loc:m1:sec
ppron12:pl:loc:m2:pri
ppron12:pl:loc:m2:sec
ppron12:pl:loc:m3:pri
ppron12:pl:loc:m3:sec
ppron12:pl:loc:n:pri
ppron12:pl:loc:n:sec
ppron12:pl:nom:f:pri
ppron12:pl:nom:f:sec
ppron12:pl:nom:m1:pri
ppron12:pl:nom:m1:sec
ppron12:pl:nom:m2:pri
ppron12:pl:nom:m2:sec
ppron12:pl:nom:m3:pri
ppron12:pl:nom:m3:sec
ppron12:pl:nom:n:pri
ppron12:pl:nom:n:sec
ppron12:sg:acc:f:pri:akc
ppron12:sg:acc:f:pri:nakc
ppron12:sg:acc:f:sec:akc
ppron12:sg:acc:f:sec:nakc
ppron12:sg:acc:m1:pri:akc
ppron12:sg:acc:m1:pri:nakc
ppron12:sg:acc:m1:sec:akc
ppron12:sg:acc:m1:sec:nakc
ppron12:sg:acc:m2:pri:akc
ppron12:sg:acc:m2:pri:nakc
ppron12:sg:acc:m2:sec:akc
ppron12:sg:acc:m2:sec:nakc
ppron12:sg:acc:m3:pri:akc
ppron12:sg:acc:m3:pri:nakc
ppron12:sg:acc:m3:sec:akc
ppron12:sg:acc:m3:sec:nakc
ppron12:sg:acc:n:pri:akc
ppron12:sg:acc:n:pri:nakc
ppron12:sg:acc:n:sec:akc
ppron12:sg:acc:n:sec:nakc
ppron12:sg:dat:f:pri:akc
ppron12:sg:dat:f:pri:nakc
ppron12:sg:dat:f:sec:akc
ppron12:sg:dat:f:sec:nakc
ppron12:sg:dat:m1:pri:akc
ppron12:sg:dat:m1:pri:nakc
ppron12:sg:dat:m1:sec:akc
ppron12:sg:dat:m1:sec:nakc
ppron12:sg:dat:m2:pri:akc
ppron12:sg:dat:m2:pri:nakc
ppron12:sg:dat:m2:sec:akc
ppron12:sg:dat:m2:sec:nakc
ppron12:sg:dat:m3:pri:akc
ppron12:sg:dat:m3:pri:nakc
ppron12:sg:dat:m3:sec:akc
ppron12:sg:dat:m3:sec:nakc
ppron12:sg:dat:n:pri:akc
ppron12:sg:dat:n:pri:nakc
ppron12:sg:dat:n:sec:akc
ppron12:sg:dat:n:sec:nakc
ppron12:sg:gen:f:pri:akc
ppron12:sg:gen:f:pri:nakc
ppron12:sg:gen:f:sec:akc
ppron12:sg:gen:f:sec:nakc
ppron12:sg:gen:m1:pri:akc
ppron12:sg:gen:m1:pri:nakc
ppron12:sg:gen:m1:sec:akc
ppron12:sg:gen:m1:sec:nakc
ppron12:sg:gen:m2:pri:akc
ppron12:sg:gen:m2:pri:nakc
ppron12:sg:gen:m2:sec:akc
ppron12:sg:gen:m2:sec:nakc
ppron12:sg:gen:m3:pri:akc
ppron12:sg:gen:m3:pri:nakc
ppron12:sg:gen:m3:sec:akc
ppron12:sg:gen:m3:sec:nakc
ppron12:sg:gen:n:pri:akc
ppron12:sg:gen:n:pri:nakc
ppron12:sg:gen:n:sec:akc
ppron12:sg:gen:n:sec:nakc
ppron12:sg:inst:f:pri
ppron12:sg:inst:f:sec
ppron12:sg:inst:m1:pri
ppron12:sg:inst:m1:sec
ppron12:sg:inst:m2:pri
ppron12:sg:inst:m2:sec
ppron12:sg:inst:m3:pri
ppron12:sg:inst:m3:sec
ppron12:sg:inst:n:pri
ppron12:sg:inst:n:sec
ppron12:sg:loc:f:pri
ppron12:sg:loc:f:sec
ppron12:sg:loc:m1:pri
ppron12:sg:loc:m1:sec
ppron12:sg:loc:m2:pri
ppron12:sg:loc:m2:sec
ppron12:sg:loc:m3:pri
ppron12:sg:loc:m3:sec
ppron12:sg:loc:n:pri
ppron12:sg:loc:n:sec
ppron12:sg:nom:f:pri
ppron12:sg:nom:f:sec
ppron12:sg:nom:m1:pri
ppron12:sg:nom:m1:sec
ppron12:sg:nom:m2:pri
ppron12:sg:nom:m2:sec
ppron12:sg:nom:m3:pri
ppron12:sg:nom:m3:sec
ppron12:sg:nom:n:pri
ppron12:sg:nom:n:sec
ppron3:pl:acc:f:ter:akc:npraep
ppron3:pl:acc:f:ter:akc:praep
ppron3:pl:acc:f:ter:nakc:npraep
ppron3:pl:acc:f:ter:nakc:praep
ppron3:pl:acc:m1:ter:akc:npraep
ppron3:pl:acc:m1:ter:akc:praep
ppron3:pl:acc:m1:ter:nakc:npraep
ppron3:pl:acc:m1:ter:nakc:praep
ppron3:pl:acc:m2:ter:akc:npraep
ppron3:pl:acc:m2:ter:akc:praep
ppron3:pl:acc:m2:ter:nakc:npraep
ppron3:pl:acc:m2:ter:nakc:praep
ppron3:pl:acc:m3:ter:akc:npraep
ppron3:pl:acc:m3:ter:akc:praep
ppron3:pl:acc:m3:ter:nakc:npraep
ppron3:pl:acc:m3:ter:nakc:praep
ppron3:pl:acc:n:ter:akc:npraep
ppron3:pl:acc:n:ter:akc:praep
ppron3:pl:acc:n:ter:nakc:npraep
ppron3:pl:acc:n:ter:nakc:praep
ppron3:pl:dat:f:ter:akc:npraep
ppron3:pl:dat:f:ter:akc:praep
ppron3:pl:dat:f:ter:nakc:npraep
ppron3:pl:dat:f:ter:nakc:praep
ppron3:pl:dat:m1:ter:akc:npraep
ppron3:pl:dat:m1:ter:akc:praep
ppron3:pl:dat:m1:ter:nakc:npraep
ppron3:pl:dat:m1:ter:nakc:praep
ppron3:pl:dat:m2:ter:akc:npraep
ppron3:pl:dat:m2:ter:akc:praep
ppron3:pl:dat:m2:ter:nakc:npraep
ppron3:pl:dat:m2:ter:nakc:praep
ppron3:pl:dat:m3:ter:akc:npraep
ppron3:pl:dat:m3:ter:akc:praep
ppron3:pl:dat:m3:ter:nakc:npraep
ppron3:pl:dat:m3:ter:nakc:praep
ppron3:pl:dat:n:ter:akc:npraep
ppron3:pl:dat:n:ter:akc:praep
ppron3:pl:dat:n:ter:nakc:npraep
ppron3:pl:dat:n:ter:nakc:praep
ppron3:pl:gen:f:ter:akc:npraep
ppron3:pl:gen:f:ter:akc:praep
ppron3:pl:gen:f:ter:nakc:npraep
ppron3:pl:gen:f:ter:nakc:praep
ppron3:pl:gen:m1:ter:akc:npraep
ppron3:pl:gen:m1:ter:akc:praep
ppron3:pl:gen:m1:ter:nakc:npraep
ppron3:pl:gen:m1:ter:nakc:praep
ppron3:pl:gen:m2:ter:akc:npraep
ppron3:pl:gen:m2:ter:akc:praep
ppron3:pl:gen:m2:ter:nakc:npraep
ppron3:pl:gen:m2:ter:nakc:praep
ppron3:pl:gen:m3:ter:akc:npraep
ppron3:pl:gen:m3:ter:akc:praep
ppron3:pl:gen:m3:ter:nakc:npraep
ppron3:pl:gen:m3:ter:nakc:praep
ppron3:pl:gen:n:ter:akc:npraep
ppron3:pl:gen:n:ter:akc:praep
ppron3:pl:gen:n:ter:nakc:npraep
ppron3:pl:gen:n:ter:nakc:praep
ppron3:pl:inst:f:ter:akc:npraep
ppron3:pl:inst:f:ter:akc:praep
ppron3:pl:inst:f:ter:nakc:npraep
ppron3:pl:inst:f:ter:nakc:praep
ppron3:pl:inst:m1:ter:akc:npraep
ppron3:pl:inst:m1:ter:akc:praep
ppron3:pl:inst:m1:ter:nakc:npraep
ppron3:pl:inst:m1:ter:nakc:praep
ppron3:pl:inst:m2:ter:akc:npraep
ppron3:pl:inst:m2:ter:akc:praep
ppron3:pl:inst:m2:ter:nakc:npraep
ppron3:pl:inst:m2:ter:nakc:praep
ppron3:pl:inst:m3:ter:akc:npraep
ppron3:pl:inst:m3:ter:akc:praep
ppron3:pl:inst:m3:ter:nakc:npraep
ppron3:pl:inst:m3:ter:nakc:praep
ppron3:pl:inst:n:ter:akc:npraep
ppron3:pl:inst:n:ter:akc:praep
ppron3:pl:inst:n:ter:nakc:npraep
ppron3:pl:inst:n:ter:nakc:praep
ppron3:pl:loc:f:ter:akc:praep
ppron3:pl:loc:f:ter:nakc:praep
ppron3:pl:loc:m1:ter:akc:praep
ppron3:pl:loc:m1:ter:nakc:praep
ppron3:pl:loc:m2:ter:akc:praep
ppron3:pl:loc:m2:ter:nakc:praep
ppron3:pl:loc:m3:ter:akc:praep
ppron3:pl:loc:m3:ter:nakc:praep
ppron3:pl:loc:n:ter:akc:praep
ppron3:pl:loc:n:ter:nakc:praep
ppron3:pl:nom:f:ter:akc:npraep
ppron3:pl:nom:f:ter:akc:praep
ppron3:pl:nom:f:ter:nakc:npraep
ppron3:pl:nom:f:ter:nakc:praep
ppron3:pl:nom:m1:ter:akc:npraep
ppron3:pl:nom:m1:ter:akc:praep
ppron3:pl:nom:m1:ter:nakc:npraep
ppron3:pl:nom:m1:ter:nakc:praep
ppron3:pl:nom:m2:ter:akc:npraep
ppron3:pl:nom:m2:ter:akc:praep
ppron3:pl:nom:m2:ter:nakc:npraep
ppron3:pl:nom:m2:ter:nakc:praep
ppron3:pl:nom:m3:ter:akc:npraep
ppron3:pl:nom:m3:ter:akc:praep
ppron3:pl:nom:m3:ter:nakc:npraep
ppron3:pl:nom:m3:ter:nakc:praep
ppron3:pl:nom:n:ter:akc:npraep
ppron3:pl:nom:n:ter:akc:praep
ppron3:pl:nom:n:ter:nakc:npraep
ppron3:pl:nom:n:ter:nakc:praep
ppron3:sg:acc:f:ter:akc:npraep
ppron3:sg:acc:f:ter:akc:praep
ppron3:sg:acc:f:ter:nakc:npraep
ppron3:sg:acc:f:ter:nakc:praep
ppron3:sg:acc:m1:ter:akc:npraep
ppron3:sg:acc:m1:ter:akc:praep
ppron3:sg:acc:m1:ter:nakc:npraep
ppron3:sg:acc:m1:ter:nakc:praep
ppron3:sg:acc:m2:ter:akc:npraep
ppron3:sg:acc:m2:ter:akc:praep
ppron3:sg:acc:m2:ter:nakc:npraep
ppron3:sg:acc:m2:ter:nakc:praep
ppron3:sg:acc:m3:ter:akc:npraep
ppron3:sg:acc:m3:ter:akc:praep
ppron3:sg:acc:m3:ter:nakc:npraep
ppron3:sg:acc:m3:ter:nakc:praep
ppron3:sg:acc:n:ter:akc:npraep
ppron3:sg:acc:n:ter:akc:praep
ppron3:sg:acc:n:ter:nakc:npraep
ppron3:sg:acc:n:ter:nakc:praep
ppron3:sg:dat:f:ter:akc:npraep
ppron3:sg:dat:f:ter:akc:praep
ppron3:sg:dat:f:ter:nakc:npraep
ppron3:sg:dat:f:ter:nakc:praep
ppron3:sg:dat:m1:ter:akc:npraep
ppron3:sg:dat:m1:ter:akc:praep
ppron3:sg:dat:m1:ter:nakc:npraep
ppron3:sg:dat:m1:ter:nakc:praep
ppron3:sg:dat:m2:ter:akc:npraep
ppron3:sg:dat:m2:ter:akc:praep
ppron3:sg:dat:m2:ter:nakc:npraep
ppron3:sg:dat:m2:ter:nakc:praep
ppron3:sg:dat:m3:ter:akc:npraep
ppron3:sg:dat:m3:ter:akc:praep
ppron3:sg:dat:m3:ter:nakc:npraep
ppron3:sg:dat:m3:ter:nakc:praep
ppron3:sg:dat:n:ter:akc:npraep
ppron3:sg:dat:n:ter:akc:praep
ppron3:sg:dat:n:ter:nakc:npraep
ppron3:sg:dat:n:ter:nakc:praep
ppron3:sg:gen:f:ter:akc:npraep
ppron3:sg:gen:f:ter:akc:praep
ppron3:sg:gen:f:ter:nakc:npraep
ppron3:sg:gen:f:ter:nakc:praep
ppron3:sg:gen:m1:ter:akc:npraep
ppron3:sg:gen:m1:ter:akc:praep
ppron3:sg:gen:m1:ter:nakc:npraep
ppron3:sg:gen:m1:ter:nakc:praep
ppron3:sg:gen:m2:ter:akc:npraep
ppron3:sg:gen:m2:ter:akc:praep
ppron3:sg:gen:m2:ter:nakc:npraep
ppron3:sg:gen:m2:ter:nakc:praep
ppron3:sg:gen:m3:ter:akc:npraep
ppron3:sg:gen:m3:ter:akc:praep
ppron3:sg:gen:m3:ter:nakc:npraep
ppron3:sg:gen:m3:ter:nakc:praep
ppron3:sg:gen:n:ter:akc:npraep
ppron3:sg:gen:n:ter:akc:praep
ppron3:sg:gen:n:ter:nakc:npraep
ppron3:sg:inst:f:ter:akc:praep
ppron3:sg:inst:f:ter:nakc:praep
ppron3:sg:inst:m1:ter:akc:npraep
ppron3:sg:inst:m1:ter:akc:praep
ppron3:sg:inst:m1:ter:nakc:npraep
ppron3:sg:inst:m1:ter:nakc:praep
ppron3:sg:inst:m2:ter:akc:npraep
ppron3:sg:inst:m2:ter:akc:praep
ppron3:sg:inst:m2:ter:nakc:npraep
ppron3:sg:inst:m2:ter:nakc:praep
ppron3:sg:inst:m3:ter:akc:npraep
ppron3:sg:inst:m3:ter:akc:praep
ppron3:sg:inst:m3:ter:nakc:npraep
ppron3:sg:inst:m3:ter:nakc:praep
ppron3:sg:inst:n:ter:akc:npraep
ppron3:sg:inst:n:ter:akc:praep
ppron3:sg:inst:n:ter:nakc:npraep
ppron3:sg:inst:n:ter:nakc:praep
ppron3:sg:loc:f:ter:akc:npraep
ppron3:sg:loc:f:ter:akc:praep
ppron3:sg:loc:f:ter:nakc:npraep
ppron3:sg:loc:f:ter:nakc:praep
ppron3:sg:loc:m1:ter:akc:npraep
ppron3:sg:loc:m1:ter:akc:praep
ppron3:sg:loc:m1:ter:nakc:npraep
ppron3:sg:loc:m1:ter:nakc:praep
ppron3:sg:loc:m2:ter:akc:npraep
ppron3:sg:loc:m2:ter:akc:praep
ppron3:sg:loc:m2:ter:nakc:npraep
ppron3:sg:loc:m2:ter:nakc:praep
ppron3:sg:loc:m3:ter:akc:npraep
ppron3:sg:loc:m3:ter:akc:praep
ppron3:sg:loc:m3:ter:nakc:npraep
ppron3:sg:loc:m3:ter:nakc:praep
ppron3:sg:loc:n:ter:akc:npraep
ppron3:sg:loc:n:ter:akc:praep
ppron3:sg:loc:n:ter:nakc:npraep
ppron3:sg:loc:n:ter:nakc:praep
ppron3:sg:nom:f:ter:akc:npraep
ppron3:sg:nom:f:ter:akc:praep
ppron3:sg:nom:f:ter:nakc:npraep
ppron3:sg:nom:f:ter:nakc:praep
ppron3:sg:nom:m1:ter:akc:npraep
ppron3:sg:nom:m1:ter:akc:praep
ppron3:sg:nom:m1:ter:nakc:npraep
ppron3:sg:nom:m1:ter:nakc:praep
ppron3:sg:nom:m2:ter:akc:npraep
ppron3:sg:nom:m2:ter:akc:praep
ppron3:sg:nom:m2:ter:nakc:npraep
ppron3:sg:nom:m2:ter:nakc:praep
ppron3:sg:nom:m3:ter:akc:npraep
ppron3:sg:nom:m3:ter:akc:praep
ppron3:sg:nom:m3:ter:nakc:npraep
ppron3:sg:nom:m3:ter:nakc:praep
ppron3:sg:nom:n:ter:akc:npraep
ppron3:sg:nom:n:ter:akc:praep
ppron3:sg:nom:n:ter:nakc:npraep
ppron3:sg:nom:n:ter:nakc:praep
praet:pl:f:imperf
praet:pl:f:perf
praet:pl:m1:imperf
praet:pl:m1:perf
praet:pl:m2:imperf
praet:pl:m2:perf
praet:pl:m3:imperf
praet:pl:m3:perf
praet:pl:n:imperf
praet:pl:n:perf
praet:sg:f:imperf
praet:sg:f:perf
praet:sg:m1:imperf
praet:sg:m1:imperf:agl
praet:sg:m1:imperf:nagl
praet:sg:m1:perf
praet:sg:m1:perf:agl
praet:sg:m1:perf:nagl
praet:sg:m2:imperf
praet:sg:m2:imperf:agl
praet:sg:m2:imperf:nagl
praet:sg:m2:perf
praet:sg:m2:perf:agl
praet:sg:m2:perf:nagl
praet:sg:m3:imperf
praet:sg:m3:imperf:agl
praet:sg:m3:imperf:nagl
praet:sg:m3:perf
praet:sg:m3:perf:agl
praet:sg:m3:perf:nagl
praet:sg:n:imperf
praet:sg:n:perf
pred
prep:acc
prep:acc:nwok
prep:acc:wok
prep:dat
prep:dat:nwok
prep:gen
prep:gen:nwok
prep:gen:wok
prep:inst
prep:inst:nwok
prep:inst:wok
prep:loc
prep:loc:nwok
prep:loc:wok
prep:nom
prep:nom:nwok
prep:voc:nwok
qub
siebie:acc
siebie:dat
siebie:gen
siebie:inst
siebie:loc
subst:pl:acc:f
subst:pl:acc:m1
subst:pl:acc:m2
subst:pl:acc:m3
subst:pl:acc:n
subst:pl:dat:f
subst:pl:dat:m1
subst:pl:dat:m2
subst:pl:dat:m3
subst:pl:dat:n
subst:pl:gen:f
subst:pl:gen:m1
subst:pl:gen:m2
subst:pl:gen:m3
subst:pl:gen:n
subst:pl:inst:f
subst:pl:inst:m1
subst:pl:inst:m2
subst:pl:inst:m3
subst:pl:inst:n
subst:pl:loc:f
subst:pl:loc:m1
subst:pl:loc:m2
subst:pl:loc:m3
subst:pl:loc:n
subst:pl:nom:f
subst:pl:nom:m1
subst:pl:nom:m2
subst:pl:nom:m3
subst:pl:nom:n
subst:pl:voc:f
subst:pl:voc:m1
subst:pl:voc:m2
subst:pl:voc:m3
subst:pl:voc:n
subst:sg:acc:f
subst:sg:acc:m1
subst:sg:acc:m2
subst:sg:acc:m3
subst:sg:acc:n
subst:sg:dat:f
subst:sg:dat:m1
subst:sg:dat:m2
subst:sg:dat:m3
subst:sg:dat:n
subst:sg:gen:f
subst:sg:gen:m1
subst:sg:gen:m2
subst:sg:gen:m3
subst:sg:gen:n
subst:sg:inst:f
subst:sg:inst:m1
subst:sg:inst:m2
subst:sg:inst:m3
subst:sg:inst:n
subst:sg:loc:f
subst:sg:loc:m1
subst:sg:loc:m2
subst:sg:loc:m3
subst:sg:loc:n
subst:sg:nom:f
subst:sg:nom:m1
subst:sg:nom:m2
subst:sg:nom:m3
subst:sg:nom:n
subst:sg:voc:f
subst:sg:voc:m1
subst:sg:voc:m2
subst:sg:voc:m3
subst:sg:voc:n
winien:pl:f:imperf
winien:pl:m1:imperf
winien:pl:m2:imperf
winien:pl:m3:imperf
winien:pl:n:imperf
winien:sg:f:imperf
winien:sg:m1:imperf
winien:sg:m2:imperf
winien:sg:m3:imperf
winien:sg:n:imperf
xxx
end_of_list
    ;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::PL::Ipipan - Driver for the tagset of the Korpus Języka Polskiego IPI PAN for Polish.

=head1 VERSION

version 3.014

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::PL::Ipipan;
  my $driver = Lingua::Interset::Tagset::PL::Ipipan->new();
  my $fs = $driver->decode('subst:sg:nom:m1');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('pl::ipipan', 'subst:sg:nom:m1');

=head1 DESCRIPTION

Interset driver for the tagset of the Korpus Języka Polskiego IPI PAN for Polish.

=head1 SEE ALSO

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
