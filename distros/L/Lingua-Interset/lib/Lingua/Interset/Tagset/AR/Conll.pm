# ABSTRACT: Driver for the Arabic tagset of the CoNLL 2006 Shared Task.
# Copyright © 2007, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::AR::Conll;
use strict;
use warnings;
our $VERSION = '3.012';

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
    return 'ar::conll';
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
            # common noun
            'N' => ['pos' => 'noun', 'nountype' => 'com'],
            # proper noun
            'Z' => ['pos' => 'noun', 'nountype' => 'prop'],
            # adjective
            'A' => ['pos' => 'adj'],
            # pronoun
            # personal or possessive pronoun
            'S'  => ['pos' => 'noun|adj', 'prontype' => 'prs'],
            # demonstrative pronoun
            'SD' => ['pos' => 'noun|adj', 'prontype' => 'dem'],
            # relative pronoun
            'SR' => ['pos' => 'noun|adj', 'prontype' => 'rel'],
            # numeral
            'Q' => ['pos' => 'num'],
            # verb
            'VI' => ['pos' => 'verb', 'aspect' => 'imp'],
            'VP' => ['pos' => 'verb', 'aspect' => 'perf'],
            # adverb
            'D' => ['pos' => 'adv'],
            # preposition
            'P' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # conjunction
            'C' => ['pos' => 'conj'],
            # function word, particle
            'F'  => ['pos' => 'part'],
            # interrogative particle
            'FI' => ['pos' => 'part', 'prontype' => 'int'],
            # negative particle
            'FN' => ['pos' => 'part', 'polarity' => 'neg'],
            # interjection
            'I' => ['pos' => 'int'],
            # abbreviation
            'Y' => ['abbr' => 'yes'],
            # typo
            'T' => ['typo' => 'yes'],
            # punctuation (not used in UMH subcorpus)
            'G' => ['pos' => 'punc'],
            # non-alphabetic (also used for punctuation in UMH subcorpus)
            'X' => [],
            # Although not documented, the data contain the tag "-\t-\tdef=D".
            # It is always assigned to the definite article 'al' if separated from its noun or adjective.
            # Normally the article is not tokenized off and makes the definiteness feature of the noun.
            '-' => ['pos' => 'adj', 'prontype' => 'art']
        },
        'encode_map' =>

            { 'abbr' => { 'yes'  => 'Y',
                          '@'    => { 'typo' => { 'yes' => 'T',
                                                  '@'    => { 'numtype' => { ''  => { 'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => 'Z',
                                                                                                                                                        '@'    => 'N' }},
                                                                                                                             'dem' => 'SD',
                                                                                                                             'rel' => 'SR',
                                                                                                                             '@'   => 'S' }},
                                                                                                 'adj'  => { 'prontype' => { ''    => 'A',
                                                                                                                             'art' => '-',
                                                                                                                             'dem' => 'SD',
                                                                                                                             'rel' => 'SR',
                                                                                                                             '@'   => 'S' }},
                                                                                                 'num'  => 'Q',
                                                                                                 'verb' => { 'aspect' => { 'perf' => 'VP',
                                                                                                                           '@'    => 'VI' }},
                                                                                                 'adv'  => 'D',
                                                                                                 'adp'  => 'P',
                                                                                                 'conj' => 'C',
                                                                                                 'part' => { 'prontype' => { 'int' => 'FI',
                                                                                                                             '@'   => { 'polarity' => { 'neg' => 'FN',
                                                                                                                                                        '@'   => 'F' }}}},
                                                                                                 'int'  => 'I',
                                                                                                 'punc' => 'G',
                                                                                                 '@'    => 'X' }},
                                                                             '@' => 'Q' }}}}}}
    );
    # GENDER ####################
    $atoms{gen} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'M' => 'masc',
            'F' => 'fem'
        }
    );
    # NUMBER ####################
    $atoms{num} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'S' => 'sing',
            'D' => 'dual',
            'P' => 'plur'
        }
    );
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            '1' => 'nom',
            '2' => 'gen',
            '4' => 'acc'
        }
    );
    # DEFINITENESS ####################
    $atoms{def} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            # definite
            'D' => 'def',
            # indefinite
            'I' => 'ind',
            # reduced / construct state
            'R' => 'cons',
            # complex
            'C' => 'com'
        }
    );
    # PERSON ####################
    $atoms{pers} = $self->create_simple_atom
    (
        'intfeature' => 'person',
        'simple_decode_map' =>
        {
            '1' => '1',
            '2' => '2',
            '3' => '3'
        }
    );
    # MOOD ####################
    $atoms{mood} = $self->create_atom
    (
        'surfeature' => 'mood',
        'decode_map' =>
        {
            'I' => ['verbform' => 'fin', 'mood' => 'ind'],
            'S' => ['verbform' => 'fin', 'mood' => 'sub'],
            # undecided between subjunctive and jussive
            'D' => ['verbform' => 'fin', 'mood' => 'jus']
        },
        'encode_map' =>

            { 'mood' => { 'jus' => 'D',
                          'sub' => 'S',
                          'ind' => 'I' }}
    );
    # VOICE ####################
    $atoms{voice} = $self->create_atom
    (
        'surfeature' => 'voice',
        'decode_map' =>
        {
            'P' => ['voice' => 'pass']
        },
        'encode_map' =>

            { 'voice' => { 'pass' => 'P' }}
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
    my @features = ('mood', 'voice', 'pers', 'gen', 'num', 'case', 'def');
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
    my $fs = $self->decode_conll($tag);
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
    my $subpos = $atoms->{pos}->encode($fs);
    my $pos = substr($subpos, 0, 1);
    my $feature_names = $self->features_all();
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# 242 tags
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
A   A   _
A   A   case=1|def=D
A   A   case=1|def=I
A   A   case=1|def=R
A   A   case=2|def=D
A   A   case=2|def=I
A   A   case=2|def=R
A   A   case=4|def=D
A   A   case=4|def=I
A   A   case=4|def=R
A   A   def=D
A   A   gen=F|num=D|case=1|def=I
A   A   gen=F|num=D|case=2|def=D
A   A   gen=F|num=D|def=D
A   A   gen=F|num=P
A   A   gen=F|num=P|def=D
A   A   gen=F|num=S
A   A   gen=F|num=S|case=1|def=D
A   A   gen=F|num=S|case=1|def=I
A   A   gen=F|num=S|case=1|def=R
A   A   gen=F|num=S|case=2|def=D
A   A   gen=F|num=S|case=2|def=I
A   A   gen=F|num=S|case=2|def=R
A   A   gen=F|num=S|case=4|def=D
A   A   gen=F|num=S|case=4|def=I
A   A   gen=F|num=S|case=4|def=R
A   A   gen=F|num=S|def=D
A   A   gen=M|num=D|case=1|def=D
A   A   gen=M|num=D|case=1|def=I
A   A   gen=M|num=D|case=1|def=R
A   A   gen=M|num=D|case=2|def=D
A   A   gen=M|num=D|case=2|def=I
A   A   gen=M|num=D|case=4|def=D
A   A   gen=M|num=D|case=4|def=I
A   A   gen=M|num=D|def=D
A   A   gen=M|num=D|def=I
A   A   gen=M|num=P|case=1|def=D
A   A   gen=M|num=P|case=1|def=I
A   A   gen=M|num=P|case=1|def=R
A   A   gen=M|num=P|case=2|def=D
A   A   gen=M|num=P|case=2|def=I
A   A   gen=M|num=P|case=4|def=D
A   A   gen=M|num=P|case=4|def=I
A   A   gen=M|num=P|def=D
A   A   gen=M|num=P|def=I
A   A   gen=M|num=P|def=R
A   A   gen=M|num=S|case=4|def=I
C   C   _
D   D   _
D   D   case=4|def=R
D   D   gen=M|num=S|case=4|def=I
-   -   def=D
F   F   _
F   FI  _
F   FN  _
F   FN  case=1|def=R
F   FN  case=2|def=R
F   FN  case=4|def=R
G   G   _
I   I   _
I   I   gen=M|num=S|case=4|def=I
N   N   _
N   N   case=1|def=D
N   N   case=1|def=I
N   N   case=1|def=R
N   N   case=2|def=D
N   N   case=2|def=I
N   N   case=2|def=R
N   N   case=4|def=D
N   N   case=4|def=I
N   N   case=4|def=R
N   N   def=D
N   N   gen=F|num=D|case=1|def=D
N   N   gen=F|num=D|case=2|def=D
N   N   gen=F|num=D|case=2|def=I
N   N   gen=F|num=D|case=2|def=R
N   N   gen=F|num=D|case=4|def=D
N   N   gen=F|num=D|case=4|def=I
N   N   gen=F|num=D|case=4|def=R
N   N   gen=F|num=D|def=D
N   N   gen=F|num=D|def=I
N   N   gen=F|num=D|def=R
N   N   gen=F|num=P
N   N   gen=F|num=P|case=1|def=D
N   N   gen=F|num=P|case=1|def=I
N   N   gen=F|num=P|case=1|def=R
N   N   gen=F|num=P|case=2|def=D
N   N   gen=F|num=P|case=2|def=I
N   N   gen=F|num=P|case=2|def=R
N   N   gen=F|num=P|case=4|def=D
N   N   gen=F|num=P|case=4|def=I
N   N   gen=F|num=P|case=4|def=R
N   N   gen=F|num=P|def=D
N   N   gen=F|num=S
N   N   gen=F|num=S|case=1|def=D
N   N   gen=F|num=S|case=1|def=I
N   N   gen=F|num=S|case=1|def=R
N   N   gen=F|num=S|case=2|def=D
N   N   gen=F|num=S|case=2|def=I
N   N   gen=F|num=S|case=2|def=R
N   N   gen=F|num=S|case=4|def=D
N   N   gen=F|num=S|case=4|def=I
N   N   gen=F|num=S|case=4|def=R
N   N   gen=F|num=S|def=C
N   N   gen=F|num=S|def=D
N   N   gen=M|num=D|case=1|def=D
N   N   gen=M|num=D|case=1|def=I
N   N   gen=M|num=D|case=1|def=R
N   N   gen=M|num=D|case=2|def=D
N   N   gen=M|num=D|case=2|def=I
N   N   gen=M|num=D|case=2|def=R
N   N   gen=M|num=D|case=4|def=D
N   N   gen=M|num=D|case=4|def=I
N   N   gen=M|num=D|case=4|def=R
N   N   gen=M|num=D|def=D
N   N   gen=M|num=D|def=I
N   N   gen=M|num=D|def=R
N   N   gen=M|num=P|case=1|def=D
N   N   gen=M|num=P|case=1|def=I
N   N   gen=M|num=P|case=1|def=R
N   N   gen=M|num=P|case=2|def=D
N   N   gen=M|num=P|case=2|def=I
N   N   gen=M|num=P|case=2|def=R
N   N   gen=M|num=P|case=4|def=D
N   N   gen=M|num=P|case=4|def=I
N   N   gen=M|num=P|case=4|def=R
N   N   gen=M|num=P|def=D
N   N   gen=M|num=P|def=I
N   N   gen=M|num=P|def=R
N   N   gen=M|num=S|case=4|def=I
P   P   _
P   P   case=2
P   P   case=4
P   P   gen=F|num=S
Q   Q   _
S   SD  gen=F
S   SD  gen=F|num=S
S   SD  gen=M|num=D
S   SD  gen=M|num=P
S   SD  gen=M|num=S
S   S   pers=1|num=P
S   S   pers=1|num=P|case=1
S   S   pers=1|num=P|case=2
S   S   pers=1|num=P|case=4
S   S   pers=1|num=S
S   S   pers=1|num=S|case=2
S   S   pers=1|num=S|case=4
S   S   pers=2|gen=F|num=S
S   S   pers=2|gen=F|num=S|case=4
S   S   pers=2|gen=M|num=P
S   S   pers=2|gen=M|num=P|case=2
S   S   pers=3|gen=F|num=P
S   S   pers=3|gen=F|num=S
S   S   pers=3|gen=F|num=S|case=1
S   S   pers=3|gen=F|num=S|case=2
S   S   pers=3|gen=F|num=S|case=4
S   S   pers=3|gen=M|num=P
S   S   pers=3|gen=M|num=P|case=1
S   S   pers=3|gen=M|num=P|case=2
S   S   pers=3|gen=M|num=P|case=4
S   S   pers=3|gen=M|num=S
S   S   pers=3|gen=M|num=S|case=1
S   S   pers=3|gen=M|num=S|case=2
S   S   pers=3|gen=M|num=S|case=4
S   S   pers=3|num=D
S   S   pers=3|num=D|case=1
S   S   pers=3|num=D|case=2
S   S   pers=3|num=D|case=4
S   SR  _
V   VI  mood=D|pers=2|gen=M|num=P
V   VI  mood=D|pers=3|gen=M|num=D
V   VI  mood=D|pers=3|gen=M|num=P
V   VI  mood=I|pers=1|num=P
V   VI  mood=I|pers=1|num=S
V   VI  mood=I|pers=2|gen=M|num=P
V   VI  mood=I|pers=2|gen=M|num=S
V   VI  mood=I|pers=3|gen=F|num=D
V   VI  mood=I|pers=3|gen=F|num=S
V   VI  mood=I|pers=3|gen=M|num=D
V   VI  mood=I|pers=3|gen=M|num=P
V   VI  mood=I|pers=3|gen=M|num=S
V   VI  mood=I|voice=P|pers=3|gen=F|num=S
V   VI  mood=I|voice=P|pers=3|gen=M|num=S
V   VI  mood=S|pers=1|num=P
V   VI  mood=S|pers=1|num=S
V   VI  mood=S|pers=3|gen=F|num=S
V   VI  mood=S|pers=3|gen=M|num=S
V   VI  mood=S|voice=P|pers=3|gen=M|num=S
V   VI  pers=1|num=P
V   VI  pers=1|num=S
V   VI  pers=2|gen=M|num=S
V   VI  pers=3|gen=F|num=P
V   VI  pers=3|gen=F|num=S
V   VI  pers=3|gen=M|num=S
V   VI  voice=P|pers=3|gen=F|num=S
V   VI  voice=P|pers=3|gen=M|num=S
V   VP  pers=1|num=P
V   VP  pers=1|num=S
V   VP  pers=2|gen=M|num=P
V   VP  pers=3|gen=F|num=D
V   VP  pers=3|gen=F|num=P
V   VP  pers=3|gen=F|num=S
V   VP  pers=3|gen=M|num=D
V   VP  pers=3|gen=M|num=P
V   VP  pers=3|gen=M|num=S
V   VP  voice=P|pers=3|gen=F|num=S
V   VP  voice=P|pers=3|gen=M|num=P
V   VP  voice=P|pers=3|gen=M|num=S
X   X   _
Y   Y   _
Z   Z   _
Z   Z   case=1|def=D
Z   Z   case=1|def=I
Z   Z   case=1|def=R
Z   Z   case=2|def=D
Z   Z   case=2|def=I
Z   Z   case=2|def=R
Z   Z   case=4|def=D
Z   Z   case=4|def=R
Z   Z   def=D
Z   Z   gen=F|num=D|case=2|def=D
Z   Z   gen=F|num=P|case=1|def=D
Z   Z   gen=F|num=P|case=1|def=I
Z   Z   gen=F|num=P|case=2|def=D
Z   Z   gen=F|num=P|case=4|def=D
Z   Z   gen=F|num=P|case=4|def=I
Z   Z   gen=F|num=P|def=D
Z   Z   gen=F|num=S
Z   Z   gen=F|num=S|case=1|def=D
Z   Z   gen=F|num=S|case=1|def=R
Z   Z   gen=F|num=S|case=2|def=D
Z   Z   gen=F|num=S|case=2|def=I
Z   Z   gen=F|num=S|case=2|def=R
Z   Z   gen=F|num=S|case=4|def=R
Z   Z   gen=F|num=S|def=D
Z   Z   gen=M|num=D|case=1|def=D
Z   Z   gen=M|num=D|case=2|def=D
Z   Z   gen=M|num=P|case=1|def=D
Z   Z   gen=M|num=P|def=D
Z   Z   gen=M|num=P|def=I
Z   Z   gen=M|num=P|def=R
Z   Z   gen=M|num=S|case=4|def=I
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

Lingua::Interset::Tagset::AR::Conll - Driver for the Arabic tagset of the CoNLL 2006 Shared Task.

=head1 VERSION

version 3.012

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::AR::Conll;
  my $driver = Lingua::Interset::Tagset::AR::Conll->new();
  my $fs = $driver->decode("N\tN\tcase=1|def=I");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('ar::conll', "N\tN\tcase=1|def=I");

=head1 DESCRIPTION

Interset driver for the Arabic tagset of the CoNLL 2006 (not 2007!) Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Arabic,
these values are derived from the tagset of the Prague Arabic Dependency Treebank.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::Conll>,
L<Lingua::Interset::Tagset::AR::Padt>,
L<Lingua::Interset::Tagset::AR::Conll2007>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
