# ABSTRACT: Driver for the PADT 2.0 / ElixirFM Arabic positional tagset.
# See also http://quest.ms.mff.cuni.cz/cgi-bin/elixir/index.fcgi
# Copyright © 2013, 2014, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::AR::Padt;
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
    return 'ar::padt';
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
        'tagset' => 'ar::padt',
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # common noun
            'N-' => ['pos' => 'noun', 'nountype' => 'com'],
            # proper noun
            'Z-' => ['pos' => 'noun', 'nountype' => 'prop'],
            # adjective
            'A-' => ['pos' => 'adj'],
            # pronoun (probably personal)
            'S-' => ['pos' => 'noun|adj', 'prontype' => 'prn'],
            # personal pronoun
            'SP' => ['pos' => 'noun', 'prontype' => 'prs'],
            # demonstrative pronoun
            'SD' => ['pos' => 'noun|adj', 'prontype' => 'dem'],
            # relative pronoun
            'SR' => ['pos' => 'noun|adj', 'prontype' => 'rel'],
            # numeral: number
            'Q-' => ['pos' => 'num', 'numform' => 'digit'],
            # numeral: hundred
            'QC' => ['pos' => 'num', 'numform' => 'word', 'other' => {'numvalue' => 100}],
            # numeral: one
            'QI' => ['pos' => 'num', 'numform' => 'word', 'numvalue' => '1'],
            # numeral: twenty, thirty, ..., ninety
            'QL' => ['pos' => 'num', 'numform' => 'word', 'other' => {'numvalue' => 20}],
            # numeral: thousand, million, billion, ...
            'QM' => ['pos' => 'num', 'numform' => 'word', 'other' => {'numvalue' => 1000}],
            # numeral: -teen
            'QU' => ['pos' => 'num', 'numform' => 'word', 'other' => {'numvalue' => 15}],
            # numeral: three, four, ..., nine
            'QV' => ['pos' => 'num', 'numform' => 'word', 'numvalue' => '3'],
            # numeral: ten
            'QX' => ['pos' => 'num', 'numform' => 'word', 'other' => {'numvalue' => 10}],
            # numeral: two
            'QY' => ['pos' => 'num', 'numform' => 'word', 'numvalue' => '2'],
            # verb
            'V-' => ['pos' => 'verb'],
            'VI' => ['pos' => 'verb', 'aspect' => 'imp'],
            'VP' => ['pos' => 'verb', 'aspect' => 'perf'],
            'VC' => ['pos' => 'verb', 'verbform' => 'fin', 'mood' => 'imp'],
            # adverb
            'D-' => ['pos' => 'adv'],
            # preposition
            'P-' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # inflected preposition (nominative, genitive, accusative)
            'PI' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # conjunction
            'C-' => ['pos' => 'conj'],
            # function word, particle
            'F-' => ['pos' => 'part'],
            # interrogative particle
            'FI' => ['pos' => 'part', 'prontype' => 'int'],
            # negative particle
            'FN' => ['pos' => 'part', 'polarity' => 'neg'],
            # interjection
            'I-' => ['pos' => 'int'],
            # abbreviation
            'Y-' => ['abbr' => 'yes'],
            # typo
            'T-' => ['typo' => 'yes'],
            # punctuation (not used in UMH subcorpus)
            'G-' => ['pos' => 'punc'],
            # non-Arabic script
            'X-' => ['foreign' => 'yes'],
            # residual class for unknown words
            'U-' => [],
            # if empty tag occurs treat it as unknown word
            '_' => []
        },
        'encode_map' =>

            { 'abbr' => { 'yes' => 'Y-',
                 '@' => { 'typo' => { 'yes' => 'T-',
                             '@' => { 'foreign' => { 'yes' => 'X-',
                                            '@' => { 'numtype' => { ''  => { 'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => 'Z-',
                                                                                                                                               '@'    => 'N-' }},
                                                                                                                    'prs' => 'SP',
                                                                                                                    'dem' => 'SD',
                                                                                                                    'rel' => 'SR',
                                                                                                                    '@'   => 'S-' }},
                                                                                        'adj'  => { 'prontype' => { ''    => 'A-',
                                                                                                                    'art' => '--',
                                                                                                                    'dem' => 'SD',
                                                                                                                    'rel' => 'SR',
                                                                                                                    '@'   => 'S-' }},
                                                                                        'num'  => { 'numform' => { 'word' => { 'other/numvalue' => { 10   => 'QX',
                                                                                                                                                     15   => 'QU',
                                                                                                                                                     20   => 'QL',
                                                                                                                                                     100  => 'QC',
                                                                                                                                                     1000 => 'QM',
                                                                                                                                                     '@'  => { 'numvalue' => { '1' => 'QI',
                                                                                                                                                                               '2' => 'QY',
                                                                                                                                                                               '3' => 'QV',
                                                                                                                                                                               '@' => { 'number' => { ''  => { 'gender' => { ''  => 'QL',
                                                                                                                                                                                                                             '@' => { 'case' => { ''  => 'QU',
                                                                                                                                                                                                                                                  '@' => 'QX' }}}},
                                                                                                                                                                                                      '@' => 'QC' }}}}}}, # or QM but we cannot decide that
                                                                                                                   '@'    => 'Q-' }},
                                                                                        'verb' => { 'mood' => { 'imp' => 'VC',
                                                                                                                '@'   => { 'aspect' => { 'perf' => 'VP',
                                                                                                                                         '@'    => 'VI' }}}},
                                                                                        'adv'  => 'D-',
                                                                                        'adp'  => { 'case' => { ''  => 'P-',
                                                                                                                '@' => 'PI' }},
                                                                                        'conj' => 'C-',
                                                                                        'part' => { 'prontype' => { 'int' => 'FI',
                                                                                                                    '@'   => { 'polarity' => { 'neg' => 'FN',
                                                                                                                                               '@'   => 'F-' }}}},
                                                                                        'int'  => 'I-',
                                                                                        'punc' => 'G-',
                                                                                        '@'    => 'U-' }},
                                                                    '@' => 'Q-' }}}}}}}}
    );
    # GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'M' => 'masc',
            'F' => 'fem'
        },
        'encode_default' => '-'
    );
    # NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'S' => 'sing',
            'D' => 'dual',
            'P' => 'plur'
        },
        'encode_default' => '-'
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
        },
        'encode_default' => '-'
    );
    # DEFINITENESS ####################
    $atoms{definite} = $self->create_atom
    (
        'surfeature' => 'state',
        'decode_map' =>
        {
            # definite
            'D' => ['definite' => 'def'],
            # indefinite
            'I' => ['definite' => 'ind'],
            # reduced = construct state
            'R' => ['definite' => 'cons'],
            # complex
            'C' => ['definite' => 'com'],
            # absolute/negative
            'A' => ['polarity' => 'neg']
        },
        'encode_map' =>
        {
            'polarity' => { 'neg' => 'A',
                            '@'   => { 'definite' => { 'def'  => 'D',
                                                       'ind'  => 'I',
                                                       'cons' => 'R',
                                                       'com'  => 'C',
                                                       '@'    => '-' }}}
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
        },
        'encode_default' => '-'
    );
    # MOOD ####################
    $atoms{mood} = $self->create_atom
    (
        'tagset' => 'ar::padt',
        'surfeature' => 'mood',
        'decode_map' =>
        {
            'I' => ['verbform' => 'fin', 'mood' => 'ind'],
            'S' => ['verbform' => 'fin', 'mood' => 'sub'],
            'J' => ['verbform' => 'fin', 'mood' => 'jus'],
            # undecided between subjunctive and jussive
            'D' => ['verbform' => 'fin', 'mood' => 'sub|jus'],
            # "energetic" mood, only with imperative verbs (VC) ("imperative" itself is a mood!), found only one example:
            # فُوزَانِّ ... win, be victorious ... VCE----D-- 	fūzānni 	فُوزَانِّ 	-FūL-ānni 	imperative verb, energetic, dual
            # see http://quest.ms.mff.cuni.cz/cgi-bin/elixir/index.fcgi?mode=resolve
            'E' => ['verbform' => 'fin', 'mood' => 'imp', 'other' => {'mood' => 'energetic'}]
        },
        'encode_map' =>

            { 'mood' => { 'imp'     => { 'other/mood' => { 'energetic' => 'E',
                                                           '@'         => { 'number' => { 'dual' => 'E',
                                                                                          '@'    => 'J' }}}},
                          'jus|sub' => 'D',
                          'sub'     => 'S',
                          'jus'     => 'J',
                          'ind'     => 'I',
                          '@'       => '-' }}
    );
    # VOICE ####################
    $atoms{voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            'A' => 'act',
            'P' => 'pass'
        },
        'encode_default' => '-'
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
    $fs->set_tagset('ar::padt');
    my $atoms = $self->atoms();
    # The tags are positional, there are 10 character positions:
    # pos subpos mood voice ??? pers gen num case def
    # example: N------S1I
    my @chars = split(//, $tag);
    my @features = ('pos', 'subpos', 'mood', 'voice', undef, 'person', 'gender', 'number', 'case', 'definite');
    for(my $i = 0; $i<=$#chars; $i++)
    {
        next if(!defined($features[$i]));
        my $feature = $features[$i];
        my $value = $chars[$i];
        $value .= $chars[++$i] if($i==0);
        $atoms->{$feature}->decode_and_merge_hard($value, $fs);
    }
    # Clean up mood (jussive --> imperative).
    $fs->set('mood', 'imp') if($tag =~ m/^VCJ/);
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
    my @features = ('pos', 'subpos', 'mood', 'voice', undef, 'person', 'gender', 'number', 'case', 'definite');
    my $tag = $atoms->{pos}->encode($fs);
    for(my $i = 2; $i<=$#features; $i++)
    {
        my $feature = $features[$i];
        my $value = '-';
        if(defined($feature))
        {
            $value = $atoms->{$feature}->encode($fs);
        }
        $tag .= $value;
    }
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# 335 tags
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
A-----FD1D
A-----FD1I
A-----FD1R
A-----FD2D
A-----FD2I
A-----FD4D
A-----FD4I
A-----FP1D
A-----FP1I
A-----FP1R
A-----FP2D
A-----FP2I
A-----FP2R
A-----FP4D
A-----FP4I
A-----FP4R
A-----FS1D
A-----FS1I
A-----FS1R
A-----FS2C
A-----FS2D
A-----FS2I
A-----FS2R
A-----FS4C
A-----FS4D
A-----FS4I
A-----FS4R
A-----MD1C
A-----MD1D
A-----MD1I
A-----MD2D
A-----MD2I
A-----MD2R
A-----MD4D
A-----MD4I
A-----MP1D
A-----MP1I
A-----MP1R
A-----MP2C
A-----MP2D
A-----MP2I
A-----MP2R
A-----MP4C
A-----MP4D
A-----MP4I
A-----MP4R
A-----MS1C
A-----MS1D
A-----MS1I
A-----MS1R
A-----MS2C
A-----MS2D
A-----MS2I
A-----MS2R
A-----MS4A
A-----MS4C
A-----MS4D
A-----MS4I
A-----MS4R
C---------
D---------
F---------
G---------
I---------
N------D1D
N------D1I
N------D1R
N------D2D
N------D2I
N------D2R
N------D4D
N------D4I
N------D4R
N------P1D
N------P1I
N------P1R
N------P2D
N------P2I
N------P2R
N------P4D
N------P4I
N------P4R
N------S1D
N------S1I
N------S1R
N------S2D
N------S2I
N------S2R
N------S4A
N------S4D
N------S4I
N------S4R
P---------
PI------1-
PI------2-
PI------4-
Q---------
QC-----S1I
QC-----S2I
QC-----S4I
QC-----S1R
QC-----S2R
QC-----S4R
QC-----S1D
QC-----S2D
QC-----S4D
QC-----S1A
QC-----S2A
QC-----S4A
QC-----D1I
QC-----D2I
QC-----D4I
QC-----D1R
QC-----D2R
QC-----D4R
QC-----D1D
QC-----D2D
QC-----D4D
QC-----D1A
QC-----D2A
QC-----D4A
QC-----P1I
QC-----P2I
QC-----P4I
QC-----P1R
QC-----P2R
QC-----P4R
QC-----P1D
QC-----P2D
QC-----P4D
QC-----P1A
QC-----P2A
QC-----P4A
QI----F-2D
QI----F-2I
QI----F-4I
QI----M-1I
QI----M-2D
QI----M-2I
QI----M-4D
QI----M-4I
QI----M-4R
QL------1I
QL------2D
QL------2I
QL------4D
QL------4I
QL------4R
QM-----S1I
QM-----S2I
QM-----S4I
QM-----S1R
QM-----S2R
QM-----S4R
QM-----S1D
QM-----S2D
QM-----S4D
QM-----S1A
QM-----S2A
QM-----S4A
QM-----D1I
QM-----D2I
QM-----D4I
QM-----D1R
QM-----D2R
QM-----D4R
QM-----D1D
QM-----D2D
QM-----D4D
QM-----D1A
QM-----D2A
QM-----D4A
QM-----P1I
QM-----P2I
QM-----P4I
QM-----P1R
QM-----P2R
QM-----P4R
QM-----P1D
QM-----P2D
QM-----P4D
QM-----P1A
QM-----P2A
QM-----P4A
QU----F---
QU----M---
QV----F-1D
QV----F-1I
QV----F-1R
QV----F-2D
QV----F-2I
QV----F-2R
QV----F-4C
QV----F-4D
QV----F-4I
QV----F-4R
QV----M-1D
QV----M-1I
QV----M-1R
QV----M-2C
QV----M-2D
QV----M-2I
QV----M-2R
QV----M-4C
QV----M-4D
QV----M-4I
QV----M-4R
QX----F-1D
QX----F-2D
QX----F-2R
QX----F-4R
QX----M-1D
QX----M-1I
QX----M-1R
QX----M-2D
QX----M-2I
QX----M-2R
QX----M-4D
QX----M-4R
QY----F-1I
QY----F-2R
QY----M-1D
QY----M-1I
QY----M-2D
QY----M-2I
QY----M-4D
QY----M-4I
QY----M-4R
S---------
SD----FD1-
SD----FD2-
SD----FS1-
SD----FS2-
SD----FS4-
SD----MD1-
SD----MD2-
SD----MP2-
SD----MP4-
SD----MS1-
SD----MS2-
SD----MS4-
SP---1MP2-
SP---1MP4-
SP---1MS4-
SP---2FS2-
SP---2MP1-
SP---2MP2-
SP---2MP4-
SP---2MS1-
SP---2MS2-
SP---2MS4-
SP---3FP1-
SP---3FP2-
SP---3FP4-
SP---3FS1-
SP---3FS2-
SP---3FS4-
SP---3MD2-
SP---3MP1-
SP---3MP2-
SP---3MP4-
SP---3MS1-
SP---3MS2-
SP---3MS4-
SR----FD1-
SR----FS1-
SR----FS2-
SR----FS4-
SR----MD1-
SR----MP2-
SR----MP4-
SR----MS1-
SR----MS2-
SR----MS4-
U---------
VCE---MD--
VCJ---FP--
VCJ---FS--
VCJ---MP--
VCJ---MS--
VIIA-1MP--
VIIA-1MS--
VIIA-2MP--
VIIA-2MS--
VIIA-3FD--
VIIA-3FS--
VIIA-3MD--
VIIA-3MP--
VIIA-3MS--
VIIP-2MS--
VIIP-3FS--
VIIP-3MD--
VIIP-3MP--
VIIP-3MS--
VIJA-1MP--
VIJA-2MS--
VIJA-3FD--
VIJA-3FS--
VIJA-3MD--
VIJA-3MP--
VIJA-3MS--
VIJP-1MS--
VIJP-3FS--
VIJP-3MP--
VIJP-3MS--
VISA-1MP--
VISA-2MP--
VISA-2MS--
VISA-3FD--
VISA-3FP--
VISA-3FS--
VISA-3MD--
VISA-3MP--
VISA-3MS--
VISP-3FS--
VISP-3MD--
VISP-3MP--
VISP-3MS--
VP-A-1MS--
VP-A-2MP--
VP-A-2MS--
VP-A-3FD--
VP-A-3FP--
VP-A-3FS--
VP-A-3MD--
VP-A-3MP--
VP-A-3MS--
VP-P-3FP--
VP-P-3FS--
VP-P-3MD--
VP-P-3MP--
VP-P-3MS--
X---------
Y---------
Z---------
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

Lingua::Interset::Tagset::AR::Padt - Driver for the PADT 2.0 / ElixirFM Arabic positional tagset.

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::AR::Padt;
  my $driver = Lingua::Interset::Tagset::AR::Padt->new();
  my $fs = $driver->decode('N------S1I');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('ar::padt', 'N------S1I');

=head1 DESCRIPTION

Interset driver for the Arabic tagset of the Prague Arabic Dependency Treebank
(PADT) 2.0. The same tagset is also used by the ElixirFM Arabic morphological
analyzer. It is a positional tagset. Every tag consists of 10 characters and
the position of the character in the tag determines its interpretation:
I<pos, subpos, mood, voice, RESERVED, person, gender, number, case, definite.>

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::AR::Conll>,
L<Lingua::Interset::Tagset::AR::Conll2007>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
