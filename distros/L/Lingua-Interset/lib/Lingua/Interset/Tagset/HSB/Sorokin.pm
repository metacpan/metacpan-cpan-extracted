# ABSTRACT: Driver for the Upper Sorbian tagset of the tagger created by Daniil Sorokin.
# https://bitbucket.org/magpie/part-of-speech-tagger-for-upper-sorbian/downloads
# Copyright © 2016, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::HSB::Sorokin;
use strict;
use warnings;
our $VERSION = '3.013';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset'; # Daniil says that the design was inspired by Multext-East but the form of the tags is different, so we do not derive from Multext.



has 'atoms'       => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms',       lazy => 1 );
has 'feature_map' => ( isa => 'HashRef', is => 'ro', builder => '_create_feature_map', lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'hsb::sorokin';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # POS ####################
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            'NOUN'   => ['pos' => 'noun'],
            'ADJ'    => ['pos' => 'adj'],
            'PRON'   => ['pos' => 'noun', 'prontype' => 'prn'],
            'NUM'    => ['pos' => 'num'],
            'VERB'   => ['pos' => 'verb'],
            'ADV'    => ['pos' => 'adv'],
            'ADP'    => ['pos' => 'adp'],
            'CONJ'   => ['pos' => 'conj'],
            'PRT'    => ['pos' => 'part'],
            'INTERJ' => ['pos' => 'int'],
            'ABBR'   => ['abbr' => 'yes'],
            '.'      => ['pos' => 'punc'],
            'X'      => [],
            '_'      => []
        },
        'encode_map' =>
        {
            'abbr' => { 'yes' => 'ABBR',
                        '@'    => { 'pos' => { 'noun' => { 'prontype' => { ''  => 'NOUN',
                                                                           '@' => 'PRON' }},
                                               'adj'  => { 'numtype' => { 'ord' => 'NUM',
                                                                          '@'   => 'ADJ' }},
                                               'num'  => 'NUM',
                                               'verb' => 'VERB',
                                               'adv'  => 'ADV',
                                               'adp'  => 'ADP',
                                               'conj' => 'CONJ',
                                               'part' => 'PRT',
                                               'int'  => 'INTERJ',
                                               'punc' => '.',
                                               '@'    => 'X' }}}
        }
    );
    # NOUN TYPE ####################
    $atoms{nountype} = $self->create_simple_atom
    (
        'intfeature' => 'nountype',
        'simple_decode_map' =>
        {
            'common' => 'com',
            'proper' => 'prop'
        }
    );
    # ADJECTIVE TYPE ####################
    # Either qualificative (which implies non-empty degree) or empty.
    $atoms{adjtype} = $self->create_atom
    (
        'surfeature' => 'adjtype',
        'decode_map' =>
        {
            'qualificative' => ['other' => {'adjtype' => 'qual'}]
        },
        'encode_map' =>
        {
            'other/adjtype' => { 'qual' => 'qualificative',
                                 '@'    => { 'degree' => { ''  => '',
                                                           '@' => 'qualificative' }}}
        }
    );
    # PRONOUN TYPE ####################
    $atoms{prontype} = $self->create_atom
    (
        'surfeature' => 'prontype',
        'decode_map' =>
        {
            'personal'      => ['prontype' => 'prs'],
            'reflexive'     => ['prontype' => 'prs', 'reflex' => 'yes'],
            'relative'      => ['prontype' => 'rel'],
            'demonstrative' => ['prontype' => 'dem'],
            'negative'      => ['prontype' => 'neg']
        },
        'encode_map' =>
        {
            'prontype' => { 'prs' => { 'reflex' => { 'yes' => 'reflexive',
                                                     '@'      => 'personal' }},
                            'rel' => 'relative',
                            'dem' => 'demonstrative',
                            'neg' => 'negative',
                            '@'   => 'personal' }
        }
    );
    # NUMERAL TYPE ####################
    $atoms{numtype} = $self->create_atom
    (
        'surfeature' => 'numtype',
        'decode_map' =>
        {
            'cardinal' => ['pos' => 'num', 'numtype' => 'card'],
            'ordinal'  => ['pos' => 'adj', 'numtype' => 'ord']
        },
        'encode_map' =>
        {
            'numtype' => { 'card' => 'cardinal',
                           'ord'  => 'ordinal' }
        }
    );
    # VERB TYPE ####################
    $atoms{verbtype} = $self->create_simple_atom
    (
        'intfeature' => 'verbtype',
        'simple_decode_map' =>
        {
            'main'  => '',
            'modal' => 'mod'
        }
    );
    # ADPOSITION TYPE ####################
    $atoms{adpostype} = $self->create_simple_atom
    (
        'intfeature' => 'adpostype',
        'simple_decode_map' =>
        {
            'preposition' => 'prep'
        }
    );
    # GENDER ####################
    # The tagger occasionally generates typos ("feminineinine" instead of "feminine").
    $atoms{gender} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' =>
        {
            'masculine'                 => ['gender' => 'masc'],
            'masculineuline'            => ['gender' => 'masc'],
            'masculine,feminine'        => ['gender' => 'masc|fem'],
            'masculine,feminine,neuter' => ['gender' => ''],
            'feminine'                  => ['gender' => 'fem'],
            'feminineinine'             => ['gender' => 'fem'],
            'feminine,neuter'           => ['gender' => 'fem|neut'],
            'neuter'                    => ['gender' => 'neut'],
            'neuterer'                  => ['gender' => 'neut']
        },
        'encode_map' =>
        {
            'gender' => { 'fem|masc' => 'masculine,feminine',
                          'fem|neut' => 'feminine,neuter',
                          'masc'     => 'masculine',
                          'fem'      => 'feminine',
                          'neut'     => 'neuter' }
        }
    );
    # ANIMACY ####################
    # The tagger occasionally generates typos ("animateate" instead of "animate").
    $atoms{animacy} = $self->create_atom
    (
        'surfeature' => 'animacy',
        'decode_map' =>
        {
            'animate'           => ['animacy' => 'anim'],
            'animateate'        => ['animacy' => 'anim'],
            'inanimate,animate' => ['animacy' => ''],
            'inanimate'         => ['animacy' => 'inan'],
            'inanimate '        => ['animacy' => 'inan']
        },
        'encode_map' =>
        {
            'animacy' => { 'anim' => 'animate',
                           'inan' => 'inanimate' }
        }
    );
    # NUMBER ####################
    # The tagger occasionally generates typos ("singularular" instead of "singular").
    # The three strange passive+number features. They do not mark the passive participle!
    # They are used with the auxiliary verb in periphrastic passive constructions (singular "bu", dual "buštej", plural "buchu").
    $atoms{number} = $self->create_atom
    (
        'surfeature' => 'number',
        'decode_map' =>
        {
            'singular'     => ['number' => 'sing'],
            'singularular' => ['number' => 'sing'],
            'dual'         => ['number' => 'dual'],
            'plural'       => ['number' => 'plur'],
            'passivsingular' => ['number' => 'sing', 'other' => {'auxpass' => 'yes'}],
            'passivdual'     => ['number' => 'dual', 'other' => {'auxpass' => 'yes'}],
            'passivplural'   => ['number' => 'plur', 'other' => {'auxpass' => 'yes'}]
        },
        'encode_map' =>
        {
            'other/auxpass' => { 'yes' => { 'number' => { 'sing' => 'passivsingular',
                                                          'dual' => 'passivdual',
                                                          'plur' => 'passivplural' }},
                                 '@'   => { 'mood' => { 'ind' => { 'tense' => { ''  => { 'number' => { 'sing' => 'passivsingular',
                                                                                                       'dual' => 'passivdual',
                                                                                                       'plur' => 'passivplural' }},
                                                                                '@' => { 'number' => { 'sing' => 'singular',
                                                                                                       'dual' => 'dual',
                                                                                                       'plur' => 'plural' }}}},
                                                        '@'   => { 'number' => { 'sing' => 'singular',
                                                                                 'dual' => 'dual',
                                                                                 'plur' => 'plural' }}}}}
        }
    );
    # DEGREE OF COMPARISON ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'positive'    => 'pos',
            'comparative' => 'cmp',
            'superlative' => 'sup'
        }
    );
    # PERSON ####################
    $atoms{person} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            'first'  => '1',
            'second' => '2',
            'third'  => '3'
        }
    );
    # VERB FORM AND MOOD ####################
    $atoms{mood} = $self->create_atom
    (
        'surfeature' => 'mood',
        'decode_map' =>
        {
            'infinitive'  => ['verbform' => 'inf'],
            'indicative'  => ['verbform' => 'fin', 'mood' => 'ind'],
            'imperative'  => ['verbform' => 'fin', 'mood' => 'imp'],
            'conditional' => ['verbform' => 'fin', 'mood' => 'cnd'],
            'participle'  => ['verbform' => 'part']
        },
        'encode_map' =>
        {
            'mood' => { 'ind' => 'indicative',
                        'imp' => 'imperative',
                        'cnd' => 'conditional',
                        '@'   => { 'verbform' => { 'part' => 'participle',
                                                   'inf'  => 'infinitive' }}}
        }
    );
    # TENSE ####################
    $atoms{tense} = $self->create_simple_atom
    (
        'intfeature' => 'tense',
        'simple_decode_map' =>
        {
            'past'    => 'past',
            'present' => 'pres',
            'future'  => 'fut'
        }
    );
    # PARTICIPLE TYPE ####################
    # Used for two participles that do not have gender and number: passive participle and present active participle.
    $atoms{parttype} = $self->create_atom
    (
        'surfeature' => 'parttype',
        'decode_map' =>
        {
            'Pass' => ['voice' => 'pass'],
            'Pres' => ['voice' => 'act', 'tense' => 'pres']
        },
        'encode_map' =>
        {
            'voice' => { 'act'  => 'Pres',
                         'pass' => 'Pass' }
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map {$atoms{$_}} (qw(pos nountype adjtype prontype numtype verbtype adpostype gender animacy number degree person mood tense parttype));
    $atoms{feature} = $self->create_merged_atom
    (
        'surfeature' => 'feature',
        'atoms'      => \@fatoms
    );
    ###!!! THE FOLLOWING FEATURES ARE CURRENTLY IGNORED
    # Participle type:
    # participle-Pass ... waženy, zakopowany, załoženy
    # participle-Pres ... přupućowacy, wotpowědowacy, wobwliwujcy
    # Pass 11
    # Pres 20
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
        'NOUN' => ['pos', 'nountype', 'gender', 'number', 'animacy'],
        'ADJ'  => ['pos', 'adjtype', 'degree', 'gender', 'number'],
        'PRON' => ['pos', 'prontype', 'person', 'gender', 'number'],
        'NUM'  => ['pos', 'numtype', 'gender', 'number'],
        'VERB' => ['pos', 'verbtype', 'mood', 'parttype', 'tense', 'gender', 'number'],
        'ADP'  => ['pos', 'adpostype']
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
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset($self->get_tagset_id());
    my $atoms = $self->atoms();
    my @surfeatures = split(/-/, $tag);
    foreach my $surfeature (@surfeatures)
    {
        $atoms->{feature}->decode_and_merge_hard($surfeature, $fs);
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
    my $tag = $atoms->{pos}->encode($fs);
    my $features = $self->feature_map();
    my @features;
    @features = @{$features->{$tag}} if(defined($features->{$tag}));
    my @tag = ($tag);
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
            my $value = $atoms->{$features[$i]}->encode($fs);
            if(defined($value) && $value ne '')
            {
                push(@tag, $value);
            }
        }
    }
    $tag = join('-', @tag);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# This list has been collected from tagger output and filtered.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
.
ABBR
ADJ-dual
ADJ-feminine-singular
ADJ-masculine-singular
ADJ-neuter-singular
ADJ-plural
ADJ-qualificative-comparative-masculine-singular
ADJ-qualificative-positive-masculine-singular
ADJ-qualificative-superlative-masculine-singular
ADP-preposition
ADV
CONJ
INTERJ
NOUN-common-feminine-dual
NOUN-common-feminine-singular
NOUN-common-masculine,feminine-plural-animate
NOUN-common-masculine,feminine-plural-inanimate
NOUN-common-masculine,feminine-plural-inanimate
NOUN-common-masculine-dual-animate
NOUN-common-masculine-dual-inanimate
NOUN-common-masculine-singular-inanimate
NOUN-common-neuter-dual
NOUN-common-neuter-plural
NOUN-common-neuter-singular
NOUN-common-plural
NOUN-proper
NUM-cardinal
NUM-cardinal-feminine
NUM-cardinal-feminine-singular
NUM-cardinal-masculine-dual
NUM-cardinal-masculine-singular
NUM-cardinal-neuter-singular
NUM-cardinal-plural
NUM-ordinal
PRON-demonstrative-dual
PRON-demonstrative-feminine-singular
PRON-demonstrative-masculine-singular
PRON-demonstrative-neuter-singular
PRON-demonstrative-plural
PRON-negative
PRON-personal-first-plural
PRON-personal-first-singular
PRON-personal-second-plural
PRON-personal-second-singular
PRON-personal-third-feminine,neuter-dual
PRON-personal-third-feminine,neuter-plural
PRON-personal-third-feminine-singular
PRON-personal-third-masculine-dual
PRON-personal-third-masculine-plural
PRON-personal-third-masculine-singular
PRON-personal-third-neuter-singular
PRON-reflexive-singular
PRON-relative-dual
PRON-relative-feminine-singular
PRON-relative-masculine-singular
PRON-relative-neuter-singular
PRON-relative-plural
PRT
VERB-main-conditional-past-plural
VERB-main-conditional-past-singular
VERB-main-imperative-dual
VERB-main-imperative-plural
VERB-main-imperative-singular
VERB-main-indicative-future-plural
VERB-main-indicative-future-singular
VERB-main-indicative-passivdual
VERB-main-indicative-passivplural
VERB-main-indicative-passivsingular
VERB-main-indicative-past-dual
VERB-main-indicative-past-plural
VERB-main-indicative-past-singular
VERB-main-indicative-present-dual
VERB-main-indicative-present-plural
VERB-main-indicative-present-singular
VERB-main-infinitive
VERB-main-participle-Pass
VERB-main-participle-past-dual
VERB-main-participle-past-feminine-singular
VERB-main-participle-past-masculine-singular
VERB-main-participle-past-neuter-singular
VERB-main-participle-past-plural
VERB-main-participle-Pres-present
VERB-modal-indicative-past-plural
X
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

Lingua::Interset::Tagset::HSB::Sorokin - Driver for the Upper Sorbian tagset of the tagger created by Daniil Sorokin.

=head1 VERSION

version 3.013

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::HSB::Sorokin;
  my $driver = Lingua::Interset::Tagset::HSB::Sorokin->new();
  my $fs = $driver->decode('NOUN-common-masculine-singular-inanimate');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('hsb::sorokin', 'NOUN-common-masculine-singular-inanimate');

=head1 DESCRIPTION

Interset driver for the Upper Sorbian tagset of the tagger by Daniil Sorokin.
See L<https://bitbucket.org/magpie/part-of-speech-tagger-for-upper-sorbian/downloads> for a detailed description
of the tagset.

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
