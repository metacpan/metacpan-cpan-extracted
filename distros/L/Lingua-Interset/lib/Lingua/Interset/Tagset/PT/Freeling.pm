# ABSTRACT: Driver for the EAGLES-based tagset for Portuguese in Freeling.
# Copyright © 2016, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::PT::Freeling;
use strict;
use warnings;
our $VERSION = '3.011';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms'       => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms',       lazy => 1 );
has 'feature_map' => ( isa => 'HashRef', is => 'ro', builder => '_create_feature_map', lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'pt::freeling';
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
            # noun
            'N' => ['pos' => 'noun'],
            # adjective
            'A' => ['pos' => 'adj'],
            # pronoun
            'P' => ['pos' => 'noun', 'prontype' => 'prn'],
            # determiner (but not article)
            'D' => ['pos' => 'adj', 'prontype' => 'prn'],
            # number
            'Z' => ['pos' => 'num'],
            # date
            # We don't have a specific feature for dates. Maybe we should use the 'other' feature.
            'W' => ['pos' => 'num', 'nountype' => 'prop'],
            # verb
            'V' => ['pos' => 'verb'],
            # adverb
            'R' => ['pos' => 'adv'],
            # adposition
            'S' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # conjunction
            'C' => ['pos' => 'conj'],
            # interjection
            'I' => ['pos' => 'int'],
            # punctuation
            'F' => ['pos' => 'punc']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''  => 'N',
                                                   '@' => 'P' }},
                       'adj'  => { 'prontype' => { ''  => 'A',
                                                   '@' => 'D' }},
                       'num'  => { 'nountype' => { 'prop' => 'W',
                                                   '@'    => 'Z' }},
                       'verb' => 'V',
                       'adv'  => 'R',
                       'adp'  => 'S',
                       'conj' => 'C',
                       'int'  => 'I',
                       'punc' => 'F' }
        }
    );
    # NOUNTYPE ####################
    $atoms{nountype} = $self->create_simple_atom
    (
        'intfeature' => 'nountype',
        'simple_decode_map' =>
        {
            'C' => 'com',
            'P' => 'prop'
        }
    );
    # NAMETYPE ####################
    $atoms{nametype} = $self->create_simple_atom
    (
        'intfeature' => 'nametype',
        'simple_decode_map' =>
        {
            'S' => 'prs',
            'G' => 'geo',
            'O' => 'com',
            'V' => 'oth'
        },
        'encode_default' => '0'
    );
    # ADJTYPE ####################
    $atoms{adjtype} = $self->create_atom
    (
        'surfeature' => 'adjtype',
        'decode_map' =>
        {
            # qualificative adjective
            'Q' => [],
            # possessive adjective
            'P' => ['poss' => 'yes'],
            # ordinal numeral/adjective
            'O' => ['numtype' => 'ord']
        },
        'encode_map' =>
        {
            'numtype' => { 'ord' => 'O',
                           '@'   => { 'poss' => { 'yes' => 'P',
                                                  '@'    => 'Q' }}}
        }
    );
    # PRONTYPE ####################
    $atoms{prontype} = $self->create_atom
    (
        'surfeature' => 'prontype',
        'decode_map' =>
        {
            # personal pronoun
            # OR possessive determiner (depends on the first character of the tag)
            'P' => ['prontype' => 'prs'],
            # article
            'A' => ['prontype' => 'art'],
            # demonstrative pronoun
            'D' => ['prontype' => 'dem'],
            # indefinite pronoun
            'I' => ['prontype' => 'ind'],
            # interrogative pronoun
            'T' => ['prontype' => 'int'],
            # relative pronoun
            'R' => ['prontype' => 'rel'],
            # exclamative pronoun
            'E' => ['prontype' => 'exc'],
            # numeral (?)
            'N' => ['numtype' => 'card']
        },
        'encode_map' =>
        {
            'poss' => { 'yes' => 'P',
                        '@'    => { 'prontype' => { 'prs' => 'P',
                        # Freeling does not allow article with pronoun ("PA").
                                                    'art' => { 'pos' => { 'noun' => 'D',
                                                                          '@'    => 'A' }},
                                                    'dem' => 'D',
                                                    'ind' => 'I',
                                                    'int' => 'T',
                        # Freeling does not allow relative determiner
                        # (see https://talp-upc.gitbooks.io/freeling-user-manual/content/tagsets/tagset-pt.html).
                                                    'rel' => { 'pos' => { 'adj' => 'T',
                                                                          '@'   => 'R' }},
                                                    'exc' => 'E',
                                                    '@'   => 'N' }}}
        }
    );
    # NUMTYPE ####################
    # d: partitive; m: currency; p: ratio; u: unit
    ###!!!
    $atoms{numtype} = $self->create_atom
    (
        'surfeature' => 'numtype',
        'decode_map' =>
        {
        },
        'encode_map' =>
        {
            'numtype' => { '@' => '0' }
        }
    );
    # VERBTYPE ####################
    $atoms{verbtype} = $self->create_atom
    (
        'surfeature' => 'verbtype',
        'decode_map' =>
        {
            # main verb
            'M' => [],
            # auxiliary verb
            'A' => ['verbtype' => 'aux'],
            # semiauxiliary verb
            'S' => ['verbtype' => 'aux', 'other' => {'verbtype' => 'semi'}]
        },
        'encode_map' =>
        {
            'verbtype' => { 'aux' => { 'other/verbtype' => { 'semi' => 'S',
                                                             '@'    => 'A' }},
                            '@'   => 'M' }
        }
    );
    # ADVTYPE ####################
    $atoms{advtype} = $self->create_atom
    (
        'surfeature' => 'advtype',
        'decode_map' =>
        {
            # general adverb
            'G' => [],
            # negative adverb (particle)
            'N' => ['prontype' => 'neg']
        },
        'encode_map' =>
        {
            'prontype' => { 'neg' => 'N',
                            '@'   => 'G' }
        }
    );
    # CONJTYPE ####################
    $atoms{conjtype} = $self->create_atom
    (
        'surfeature' => 'conjtype',
        'decode_map' =>
        {
            # coordinating conjunction
            'C' => ['conjtype' => 'coor'],
            # subordinating conjunction
            'S' => ['conjtype' => 'sub']
        },
        'encode_map' =>
        {
            'conjtype' => { 'coor' => 'C',
                            'sub'  => 'S',
                            '@'    => 'C' }
        }
    );
    # GENDER ####################
    $atoms{gender} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' =>
        {
            'M' => ['gender' => 'masc'],
            'F' => ['gender' => 'fem'],
            'N' => ['gender' => 'neut'],
            # Common is not the common gender in the Scandinavian sense. It is just indistinguishable between M and F.
            # That's why we do not set 'gender' => 'com'.
            'C' => ['other' => {'gender' => 'common'}]
        },
        'encode_map' =>
        {
            'gender' => { 'masc' => 'M',
                          'fem'  => 'F',
                          'neut' => 'N',
                          '@'    => { 'other/gender' => { 'common' => 'C',
                                                          '@'      => '0' }}}
        }
    );
    # NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'S' => 'sing',
            'P' => 'plur',
            # Invariable.
            #'N' => ''
        },
        ###!!! We are conflating N and 0. Without a genuine list of tags and Portuguese examples, it is hard to say where either of them will occur.
        'encode_default' => '0'
    );
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'N' => 'nom',
            'D' => 'dat',
            'A' => 'acc',
            # Oblique. ###!!! What is it and how does it differ from the other cases?
            #'O' => 'acc',
        },
        'encode_default' => '0'
    );
    # DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            # Evaluative. ###!!!???
            'V' => 'pos',
            'S' => 'sup',
            # For nouns: augmentative and diminutive.
            'A' => 'aug',
            'D' => 'dim'
        },
        'encode_default' => '0'
    );
    # PERSON ####################
    $atoms{person} = $self->create_atom
    (
        'surfeature' => 'person',
        'decode_map' =>
        {
            '1' => ['person' => '1'],
            '2' => ['person' => '2'],
            '3' => ['person' => '3']
        },
        'encode_map' =>
        {
            'person' => { '1' => '1',
                          '2' => '2',
                          '3' => '3',
                          '@' => '0' }
        }
    );
    # POLITENESS ####################
    $atoms{polite} = $self->create_simple_atom
    (
        'intfeature' => 'polite',
        'simple_decode_map' =>
        {
            'P' => 'form'
        },
        'encode_default' => '0'
    );
    # OWNER NUMBER ####################
    $atoms{possnumber} = $self->create_simple_atom
    (
        'intfeature' => 'possnumber',
        'simple_decode_map' =>
        {
            'S' => 'sing',
            'P' => 'plur',
            # Invariable.
            #'N' => ''
        },
        ###!!! We are conflating N and 0. Without a genuine list of tags and Portuguese examples, it is hard to say where either of them will occur.
        'encode_default' => '0'
    );
    # VERB FORM ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'I' => ['verbform' => 'fin', 'mood' => 'ind'],
            'M' => ['verbform' => 'fin', 'mood' => 'imp'],
            'S' => ['verbform' => 'fin', 'mood' => 'sub'],
            'N' => ['verbform' => 'inf'],
            # Past participle.
            'P' => ['verbform' => 'part'],
            # Gerund (meaning present participle in Romance languages).
            'G' => ['verbform' => 'ger']
        },
        'encode_map' =>
        {
            'mood' => { 'imp' => 'M',
                        'sub' => 'S',
                        'ind' => 'I',
                        # Conditional is considered a tense in Portuguese but a mood in Interset.
                        # Even in Portuguese we cannot say that it belongs to one of the existing moods, so it could be a mood of its own.
                        'cnd' => '0',
                        '@'   => { 'verbform' => { 'part' => 'P',
                                                   'ger'  => 'G',
                                                   'inf'  => 'N',
                                                   '@'    => '0' }}}
        }
    );
    # TENSE ####################
    $atoms{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            'P' => ['tense' => 'pres'],
            'F' => ['tense' => 'fut'],
            'S' => ['tense' => 'past'],
            'I' => ['tense' => 'imp'],
            'M' => ['tense' => 'pqp'],
            # Portuguese grammar treats conditional as a tense while in Interset it is a mood.
            'C' => ['mood' => 'cnd']
        },
        'encode_map' =>
        {
            'mood' => { 'cnd' => 'C',
                        '@'   => { 'tense' => { 'pres' => 'P',
                                                'fut'  => 'F',
                                                'past' => 'S',
                                                'imp'  => 'I',
                                                'pqp'  => 'M',
                                                '@'    => '0' }}}
        }
    );
    # NEGATIVENESS ####################
    $atoms{negativeness} = $self->create_simple_atom
    (
        'intfeature' => 'negativeness',
        'simple_decode_map' =>
        {
            'y' => 'neg',
            'n' => 'pos'
        },
        'encode_default' => '-'
    );
    # ADVERB TYPE ####################
    $atoms{adverb_type} = $self->create_atom
    (
        'surfeature' => 'adverb_type',
        'decode_map' =>
        {
            # general adverb
            'G' => [],
            # negative adverb
            'N' => ['prontype' => 'neg'],
        },
        'encode_map' =>
        {
            'prontype' => { 'neg' => 'N',
                            '@'   => 'G' }
        }
    );
    # ADPOSITION TYPE ####################
    $atoms{adpostype} = $self->create_atom
    (
        'surfeature' => 'adpostype',
        'decode_map' =>
        {
            'P' => ['adpostype' => 'prep']
        },
        'encode_map' =>
        {
            'adpostype' => { '@' => 'P' }
        }
    );
    # PUNCTUATION TYPE ####################
    $atoms{punctype} = $self->create_atom
    (
        'surfeature' => 'punctype',
        'decode_map' =>
        {
            'a' => ['punctype' => 'excl'], # exclamation mark
            'c' => ['punctype' => 'comm'], # comma
            'd' => ['punctype' => 'colo'], # colon
            'e' => ['punctype' => 'quot'], # quotation
            'g' => ['punctype' => 'dash'], # hyphen
            'h' => ['other' => {'punctype' => 'slash'}], # slash
            'i' => ['punctype' => 'qest'], # question mark
            'l' => ['punctype' => 'brck', 'other' => {'brcktype' => 'curly'}], # curly bracket
            'p' => ['punctype' => 'peri'], # period
            'r' => ['punctype' => 'quot'], # opening or closing quotation
            's' => ['other' => {'punctype' => 'etc'}], # etc
            't' => ['other' => {'punctype' => 'percent'}], # percentage
            'x' => ['punctype' => 'semi'], # semicolon
            'z' => [], # other
            'P' => ['punctype' => 'brck'], # parenthesis
            'C' => ['punctype' => 'brck', 'other' => {'brcktype' => 'square'}]  # square bracket
        },
        'encode_map' =>
        {
            'punctype' => { 'colo' => 'd',
                            'comm' => 'c',
                            'dash' => 'g',
                            'peri' => 'p',
                            'semi' => 'x',
                            'excl' => 'a',
                            'qest' => 'i',
                            'brck' => { 'other/brcktype' => { 'square' => 'c',
                                                              'curly'  => 'l',
                                                              '@'      => 'p' }},
                            'quot' => { 'puncside' => { 'ini' => 'r',
                                                        'fin' => 'r',
                                                        '@'   => 'e' }},
                            '@'    => { 'other/punctype' => { 'etc'     => 's',
                                                              'percent' => 't',
                                                              'slash'   => 'h',
                                                              '@'       => 'z' }}}
        }
    );
    # PUNCTUATION SIDE ####################
    # Marking of terminating punctuation is inconsistent. It is 't' almost
    # everywhere but it is 'c' in 'Frc'.
    $atoms{puncside} = $self->create_atom
    (
        'surfeature' => 'puncside',
        'decode_map' =>
        {
            'a' => ['puncside' => 'ini'],
            't' => ['puncside' => 'fin'],
            'c' => ['puncside' => 'fin']
        },
        'encode_map' =>
        {
            'puncside' => { 'ini' => 'a',
                            'fin' => { 'punctype' => { 'quot' => 'c',
                                                       '@'    => 't' }},
                            '@'   => '0' }
        }
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates a map that tells for each surface part of speech which features are
# relevant and in what order they appear.
#------------------------------------------------------------------------------
sub _create_feature_map
{
    my $self = shift;
    my %features =
    (
        # Declaring a feature as undef means that there will be always a zero at that position of the tag.
        'N' => ['pos', 'nountype', 'gender', 'number', 'nametype', undef, 'degree'],
        'A' => ['pos', 'adjtype', 'degree', 'gender', 'number', 'person', 'possnumber'],
        'P' => ['pos', 'prontype', 'person', 'gender', 'number', 'case', 'polite'],
        'D' => ['pos', 'prontype', 'person', 'gender', 'number', 'possnumber'],
        'Z' => ['pos'], # 'numtype' currently ignored
        'W' => ['pos'],
        'V' => ['pos', 'verbtype', 'verbform', 'tense', 'person', 'number', 'gender'],
        'R' => ['pos', 'advtype'],
        'S' => ['pos', 'adpostype'],
        'C' => ['pos', 'conjtype'],
        'I' => ['pos'],
        'F' => ['pos', 'punctype', 'puncside']
    );
    return \%features;
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    # Modify ambiguous punctuation types so they work like atoms.
    $tag =~ s/^Fp([at])$/FP$1/;
    $tag =~ s/^Fc([at])$/FC$1/;
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset($self->get_tagset_id());
    my $atoms = $self->atoms();
    my $features = $self->feature_map();
    my @chars = split(//, $tag);
    $atoms->{pos}->decode_and_merge_hard($chars[0], $fs);
    my @features;
    @features = @{$features->{$chars[0]}} if(defined($features->{$chars[0]}));
    for(my $i = 1; $i<=$#features; $i++)
    {
        if(defined($features[$i]) && defined($chars[$i]))
        {
            # Tagset drivers normally do not throw exceptions because they should be able to digest any input.
            # However, if we know we expect a feature and we have not defined an atom to handle that feature,
            # then it is an error of our code, not of the input data.
            if(!defined($atoms->{$features[$i]}))
            {
                confess("There is no atom to handle the feature '$features[$i]'");
            }
            $atoms->{$features[$i]}->decode_and_merge_hard($chars[$i], $fs);
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
    my $features = $self->feature_map();
    my $tag = $atoms->{pos}->encode($fs);
    my @features;
    @features = @{$features->{$tag}} if(defined($features->{$tag}));
    for(my $i = 1; $i<=$#features; $i++)
    {
        if(defined($features[$i]))
        {
            # Tagset drivers normally do not throw exceptions because they should be able to digest any input.
            # However, if we know we expect a feature and we have not defined an atom to handle that feature,
            # then it is an error of our code, not of the input data.
            if(!defined($atoms->{$features[$i]}))
            {
                confess("There is no atom to handle the feature '$features[$i]'");
            }
            $tag .= $atoms->{$features[$i]}->encode($fs);
        }
        else
        {
            $tag .= '0';
        }
    }
    # Even without 'other' being set, we can sometimes disambiguate between the common gender and 0.
    $tag =~ s/^(N.)0/${1}C/;
    $tag =~ s/^(A..)0/${1}C/;
    $tag =~ s/^(A...)0/${1}N/;
    # Remove trailing zeroes.
    # I have seen only one sample of genuine data with this tagset, and it suggests that trailing
    # zeroes are actually not removed, except for the punctuation tags, which are considered
    # non-positional:
    # O            o           DA0MS0  0.950254
    # primeiro     primeiro    AO0MS00 0.722944
    # ministro     ministro    NCMS000 0.99763
    # aprovou      aprovar     VMIS3S0 1
    # dois         2           Z       1
    # novos        novo        AQ0MP00 0.952586
    # regulamentos regulamento NCMP000 1
    # .            .           Fp      1
    $tag =~ s/^(F.)0+$/$1/;
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
NCMS000
NCMS00A
NCMS00D
NCMP000
NCMP00A
NCMP00D
NCFS000
NCFS00A
NCFS00D
NCFP000
NCFP00A
NCFP00D
NCCS000
NCCP000
NCNS000
NPMSS00
NPMSS0A
NPMSS0D
NPMPS00
NPMPS0A
NPMPS0D
NPFSS00
NPFSS0A
NPFSS0D
NPFPS00
NPFPS0A
NPFPS0D
NPCSS00
NPCPS00
NPMSG00
NPMPG00
NPFSG00
NPFPG00
NPCSG00
NPCPG00
NPMSO00
NPMPO00
NPFSO00
NPFPO00
NPCSO00
NPCPO00
NPMSV00
NPMPV00
NPFSV00
NPFPV00
NPCSV00
NPCPV00
AQVMS00
AQVMP00
AQVFS00
AQVFP00
AQVCS00
AQVCP00
AQVCN00
AQSMS00
AQSMP00
AQSFS00
AQSFP00
AQSCS00
AQSCP00
AQSCN00
APVMS1S
APVMS2S
APVMS3S
APVMS1P
APVMS2P
APVMS3P
APVMP1S
APVMP2S
APVMP3S
APVMP1P
APVMP2P
APVMP3P
APVFS1S
APVFS2S
APVFS3S
APVFS1P
APVFS2P
APVFS3P
APVFP1S
APVFP2S
APVFP3S
APVFP1P
APVFP2P
APVFP3P
APVCS1S
APVCS2S
APVCS3S
APVCS1P
APVCS2P
APVCS3P
APVCP1S
APVCP2S
APVCP3S
APVCP1P
APVCP2P
APVCP3P
APVCN1S
APVCN2S
APVCN3S
APVCN1P
APVCN2P
APVCN3P
AO0MS00
AO0MP00
AO0FS00
AO0FP00
AO0CS00
AO0CP00
AO0CN00
PP10SN0
PP10SD0
PP10SA0
PP20SN0
PP20SD0
PP20SA0
PP20SNP
PP20SDP
PP20SAP
PP3MSN0
PP3MSD0
PP3MSA0
PP3FSN0
PP3FSD0
PP3FSA0
PP10PN0
PP10PD0
PP10PA0
PP20PN0
PP20PD0
PP20PA0
PP20PNP
PP20PDP
PP20PAP
PP3MPN0
PP3MPD0
PP3MPA0
PP3FPN0
PP3FPD0
PP3FPA0
PD00000
PT00000
PR00000
PE00000
DA0MS0
DA0FS0
DA0MP0
DA0FP0
DP1MSS
DP1MPS
DP1FSS
DP1FPS
DP2MSS
DP2MPS
DP2FSS
DP2FPS
DP3MSS
DP3MPS
DP3FSS
DP3FPS
DP1MSP
DP1MPP
DP1FSP
DP1FPP
DP2MSP
DP2MPP
DP2FSP
DP2FPP
DP3MSP
DP3MPP
DP3FSP
DP3FPP
DD0MS0
DD0FS0
DD0MP0
DD0FP0
DT0000
DE0000
Z
W
VMN0000
VMIP1S0
VMIP2S0
VMIP3S0
VMIP1P0
VMIP2P0
VMIP3P0
VMIF1S0
VMIF2S0
VMIF3S0
VMIF1P0
VMIF2P0
VMIF3P0
VMIS1S0
VMIS2S0
VMIS3S0
VMIS1P0
VMIS2P0
VMIS3P0
VMII1S0
VMII2S0
VMII3S0
VMII1P0
VMII2P0
VMII3P0
VMIM1S0
VMIM2S0
VMIM3S0
VMIM1P0
VMIM2P0
VMIM3P0
VMSP1S0
VMSP2S0
VMSP3S0
VMSP1P0
VMSP2P0
VMSP3P0
VMSF1S0
VMSF2S0
VMSF3S0
VMSF1P0
VMSF2P0
VMSF3P0
VMSI1S0
VMSI2S0
VMSI3S0
VMSI1P0
VMSI2P0
VMSI3P0
VM0C1S0
VM0C2S0
VM0C3S0
VM0C1P0
VM0C2P0
VM0C3P0
VMM02S0
VMM03S0
VMM01P0
VMM02P0
VMM03P0
VMPS0SM
VMPS0SF
VMPS0PM
VMPS0PF
VMGP0SM
VMGP0SF
VMGP0PM
VMGP0PF
VAN0000
VAIP1S0
VAIP2S0
VAIP3S0
VAIP1P0
VAIP2P0
VAIP3P0
VAIF1S0
VAIF2S0
VAIF3S0
VAIF1P0
VAIF2P0
VAIF3P0
VAIS1S0
VAIS2S0
VAIS3S0
VAIS1P0
VAIS2P0
VAIS3P0
VAII1S0
VAII2S0
VAII3S0
VAII1P0
VAII2P0
VAII3P0
VAIM1S0
VAIM2S0
VAIM3S0
VAIM1P0
VAIM2P0
VAIM3P0
VASP1S0
VASP2S0
VASP3S0
VASP1P0
VASP2P0
VASP3P0
VASF1S0
VASF2S0
VASF3S0
VASF1P0
VASF2P0
VASF3P0
VASI1S0
VASI2S0
VASI3S0
VASI1P0
VASI2P0
VASI3P0
VA0C1S0
VA0C2S0
VA0C3S0
VA0C1P0
VA0C2P0
VA0C3P0
VAM02S0
VAM03S0
VAM01P0
VAM02P0
VAM03P0
VAPS0SM
VAPS0SF
VAPS0PM
VAPS0PF
VAGP0SM
VAGP0SF
VAGP0PM
VAGP0PF
VSN0000
VSIP1S0
VSIP2S0
VSIP3S0
VSIP1P0
VSIP2P0
VSIP3P0
VSIF1S0
VSIF2S0
VSIF3S0
VSIF1P0
VSIF2P0
VSIF3P0
VSIS1S0
VSIS2S0
VSIS3S0
VSIS1P0
VSIS2P0
VSIS3P0
VSII1S0
VSII2S0
VSII3S0
VSII1P0
VSII2P0
VSII3P0
VSIM1S0
VSIM2S0
VSIM3S0
VSIM1P0
VSIM2P0
VSIM3P0
VSSP1S0
VSSP2S0
VSSP3S0
VSSP1P0
VSSP2P0
VSSP3P0
VSSF1S0
VSSF2S0
VSSF3S0
VSSF1P0
VSSF2P0
VSSF3P0
VSSI1S0
VSSI2S0
VSSI3S0
VSSI1P0
VSSI2P0
VSSI3P0
VS0C1S0
VS0C2S0
VS0C3S0
VS0C1P0
VS0C2P0
VS0C3P0
VSM02S0
VSM03S0
VSM01P0
VSM02P0
VSM03P0
VSPS0SM
VSPS0SF
VSPS0PM
VSPS0PF
VSGP0SM
VSGP0SF
VSGP0PM
VSGP0PF
RG
RN
SP
CC
CS
I
Fd
Fc
Fs
Faa
Fat
Fg
Fz
Ft
Fp
Fia
Fit
Fe
Fra
Frc
Fx
Fh
Fpa
Fpt
Fca
Fct
Fla
Flt
end_of_list
    ;
    my @list = split(/\r?\n/, $list);
    pop(@list) if($list[$#list] eq '');
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::PT::Freeling - Driver for the EAGLES-based tagset for Portuguese in Freeling.

=head1 VERSION

version 3.011

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::PT::Freeling;
  my $driver = Lingua::Interset::Tagset::PT::Freeling->new();
  my $fs = $driver->decode('NCMS000');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('pt::freeling', 'NCMS000');

=head1 DESCRIPTION

Interset driver for the EAGLES-based Portuguese tagset from the Freeling project
(L<http://talp-upc.gitbooks.io/freeling-user-manual/content/tagsets/tagset-pt.html>).

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
