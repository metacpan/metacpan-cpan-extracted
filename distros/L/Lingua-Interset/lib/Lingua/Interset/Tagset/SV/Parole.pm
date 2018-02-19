# ABSTRACT: Driver for the Swedish PAROLE tagset.
# Copyright © 2006-2009, 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::SV::Parole;
use strict;
use warnings;
our $VERSION = '3.011';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms' => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms', lazy => 1 );
has 'features_pos' => ( isa => 'HashRef', is => 'ro', builder => '_create_features_pos', lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'sv::parole';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for the surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # 1. PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # noun
            'NC' => ['pos' => 'noun', 'nountype' => 'com'],
            'NP' => ['pos' => 'noun', 'nountype' => 'prop'],
            # adjective or participle
            'AQ' => ['pos' => 'adj'],
            'AP' => ['pos' => 'verb', 'verbform' => 'part', 'tense' => 'pres', 'aspect' => 'imp'],
            'AF' => ['pos' => 'verb', 'verbform' => 'part', 'tense' => 'past', 'aspect' => 'perf'],
            # determiner
            'D0' => ['pos' => 'adj', 'prontype' => 'prn'],
            'DH' => ['pos' => 'adj', 'prontype' => 'int'],
            'DF' => ['pos' => 'adj', 'prontype' => 'dem'],
            'DI' => ['pos' => 'adj', 'prontype' => 'ind'],
            # pronoun
            'PF' => ['pos' => 'noun', 'prontype' => 'prs'],
            'PS' => ['pos' => 'adj',  'prontype' => 'prs', 'poss' => 'yes'],
            'PH' => ['pos' => 'noun', 'prontype' => 'int'],
            'PE' => ['pos' => 'adj',  'prontype' => 'int', 'poss' => 'yes'],
            'PI' => ['pos' => 'noun', 'prontype' => 'ind'],
            # numeral
            'MC' => ['pos' => 'num', 'numtype' => 'card'],
            'MO' => ['pos' => 'adj', 'numtype' => 'ord'],
            # verb
            'V@' => ['pos' => 'verb'],
            # adverb
            'RG' => ['pos' => 'adv'],
            'RH' => ['pos' => 'adv', 'prontype' => 'int'],
            # preposition
            'SP' => ['pos' => 'adp', 'adpostype' => 'prep'],
            # conjunction
            'CC' => ['pos' => 'conj', 'conjtype' => 'coor'],
            'CS' => ['pos' => 'conj', 'conjtype' => 'sub'],
            'CI' => ['pos' => 'part', 'verbform' => 'inf'], ###!!! what is the current standard about infinitive markers?
            # particle
            'Q' => ['pos' => 'part'],
            # interjection
            'I' => ['pos' => 'int'],
            # punctuation
            'FP' => ['pos' => 'punc'],
            # menningskiljande interpunktion / meaning separating punctuation
            # example: .
            'FE' => ['pos' => 'punc', 'punctype' => 'peri'],
            # interpunktion
            # (DZ: the original legend does not tell the difference between FI and FP. Could FP be paired punctuation?)
            # example: "
            'FI' => ['pos' => 'punc', 'punctype' => 'quot'],
            # foreign word
            'XF' => ['foreign' => 'yes'],
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''    => { 'nountype' => { 'prop' => 'NP',
                                                                              '@'    => 'NC' }},
                                                   'int' => { 'poss' => { 'yes' => 'PE',
                                                                          '@'    => 'PH' }},
                                                   'ind' => 'PI',
                                                   '@'   => { 'poss' => { 'yes' => 'PS',
                                                                          '@'    => 'PF' }}}},
                       'adj'  => { 'prontype' => { ''    => { 'verbform' => { 'part' => { 'tense' => { 'pres' => 'AP',
                                                                                                       '@'    => 'AF' }},
                                                                              '@'    => { 'numtype' => { 'ord' => 'MO',
                                                                                                         '@'   => 'AQ' }}}},
                                                   'int' => { 'poss' => { 'yes' => 'PE',
                                                                          '@'    => 'DH' }},
                                                   'dem' => 'DF',
                                                   'ind' => 'DI',
                                                   '@'   => { 'poss' => { 'yes' => 'PS',
                                                                          '@'    => 'D0' }}}},
                       'num'  => { 'numtype' => { 'ord' => 'MO',
                                                  '@'   => 'MC' }},
                       'verb' => { 'verbform' => { 'part' => { 'tense' => { 'pres' => 'AP',
                                                                            '@'    => 'AF' }},
                                                   '@'    => 'V@' }},
                       'adv'  => { 'prontype' => { 'int' => 'RH',
                                                   '@'   => 'RG' }},
                       'adp'  => 'SP',
                       'conj' => { 'verbform' => { 'inf' => 'CI',
                                                   '@'   => { 'conjtype' => { 'sub' => 'CS',
                                                                              '@'   => 'CC' }}}},
                       'part' => { 'verbform' => { 'inf' => 'CI',
                                                   '@'   => 'Q' }},
                       'int'  => 'I',
                       'punc' => { 'punctype' => { 'peri' => 'FE',
                                                   'quot' => 'FI',
                                                   '@'    => 'FP' }},
                       '@'    => 'XF' }
        }
    );
    # 2. DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'P' => 'pos',
            'C' => 'cmp',
            'S' => 'sup',
            '0' => ''
        }
    );
    # 3. GENDER ####################
    $atoms{gender} = $self->create_simple_atom
    (
        'intfeature' => 'gender',
        'simple_decode_map' =>
        {
            'M' => 'masc',
            'U' => 'com',
            'N' => 'neut',
            '0' => ''
        }
    );
    # 4. NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'S' => 'sing',
            'P' => 'plur',
            '0' => ''
        }
    );
    # 5. CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'N' => 'nom',
            'G' => 'gen',
            '0' => ''
        }
    );
    # 6. SUBJECT / OBJECT FORM ####################
    $atoms{subjobj} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'S' => 'nom',
            'O' => 'acc',
            '0' => ''
        }
    );
    # 7. DEFINITENESS ####################
    $atoms{definite} = $self->create_simple_atom
    (
        'intfeature' => 'definite',
        'simple_decode_map' =>
        {
            'D' => 'def',
            'I' => 'ind',
            '0' => ''
        }
    );
    # 8. VERB FORM AND MOOD ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'N' => ['verbform' => 'inf'],
            'I' => ['verbform' => 'fin', 'mood' => 'ind'],
            'M' => ['verbform' => 'fin', 'mood' => 'imp'],
            'S' => ['verbform' => 'fin', 'mood' => 'sub'],
            '0' => []
        },
        'encode_map' =>
        {
            'verbform' => { 'inf' => 'N',
                            'fin' => { 'mood' => { 'ind' => 'I',
                                                   'imp' => 'M',
                                                   'sub' => 'S',
                                                   '@'   => '0' }},
                            'sup' => 'I',
                            '@'   => '0' }
        }
    );
    # 9. TENSE ####################
    $atoms{tense} = $self->create_atom
    (
        'surfeature' => 'tense',
        'decode_map' =>
        {
            'P' => ['tense' => 'pres'],
            'I' => ['tense' => 'past'], # preteritum
            'U' => ['tense' => 'past', 'verbform' => 'sup'], # supinum
            '0' => []
        },
        'encode_map' =>
        {
            'tense' => { 'pres' => 'P',
                         'past' => { 'verbform' => { 'sup' => 'U',
                                                     '@'   => 'I' }},
                         '@'    => '0' }
        }
    );
    # 10. VOICE ####################
    $atoms{voice} = $self->create_simple_atom
    (
        'intfeature' => 'voice',
        'simple_decode_map' =>
        {
            # E.g. verb preteritum aktiv
            # Example: hänvisade = referred
            'A' => 'act',
            # E.g. verb preteritum s-form
            # Example: tillfrågades = asked
            ###!!! How did we come to conclude that "s-form" means passive?
            'S' => 'pass',
            '0' => ''
        }
    );
    # 11. FORM ####################
    $atoms{form} = $self->create_atom
    (
        'surfeature' => 'form',
        'decode_map' =>
        {
            # full form
            'S' => [],
            # hyphenated prefix
            'C' => ['hyph' => 'yes'],
            # abbreviation
            'A' => ['abbr' => 'yes']
        },
        'encode_map' =>
        {
            'hyph' => { 'yes' => 'C',
                        '@'    => { 'abbr' => { 'yes' => 'A',
                                                '@'    => 'S' }}}
        }
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates the list of surface features (character positions) that can appear
# with particular parts of speech.
#------------------------------------------------------------------------------
sub _create_features_pos
{
    my $self = shift;
    my %features =
    (
        'N' => ['gender', 'number', 'case', undef, 'definite', 'form'],
        'A' => ['degree', 'gender', 'number', 'case', 'definite', 'form'],
        'D' => [undef,    'gender', 'number', undef, 'form'],
        'P' => [undef,    'gender', 'number', 'subjobj', undef, 'form'],
        'M' => ['gender', 'number', 'case', 'definite', 'form'],
        'V' => ['verbform', 'tense', 'voice', 'form'],
        'R' => ['degree', 'form'],
        'S' => ['form'],
        'C' => ['form'],
        'Q' => ['form']
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
    $fs->set_tagset('sv::parole');
    my $atoms = $self->atoms();
    my @chars = split(//, $tag);
    my $fpos = shift(@chars);
    my $pos = $fpos;
    if($pos ne 'Q' && scalar(@chars)>0)
    {
        $pos .= shift(@chars);
    }
    $atoms->{pos}->decode_and_merge_hard($pos, $fs);
    my $features = $self->features_pos()->{$fpos};
    for(my $i = 0; $i<=$#chars; $i++)
    {
        if(defined($features->[$i]) && defined($atoms->{$features->[$i]}))
        {
            $atoms->{$features->[$i]}->decode_and_merge_hard($chars[$i], $fs);
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
    my $tag = $atoms->{pos}->encode($fs);
    $tag =~ m/^(.)/;
    my $pos = $1;
    my $features = $self->features_pos()->{$pos};
    if(defined($features))
    {
        foreach my $feature (@{$features})
        {
            if(defined($feature) && defined($atoms->{$feature}))
            {
                $tag .= $atoms->{$feature}->encode($fs);
            }
            else
            {
                $tag .= '@';
            }
        }
    }
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# The source list is the Parole tag set of the Swedish SUC corpus.
# http://spraakbanken.gu.se/parole/tags.phtml
# Modifications by Jan Hajič:
# - replace @ by W
# - add trailing dashes so every tag has 9 characters
# total tags:
# 156
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
NC000\@0A
NC000\@0C
NC000\@0S
NCN00\@0C
NCN00\@0S
NCNPG\@DS
NCNPG\@IS
NCNPN\@DS
NCNPN\@IS
NCNSG\@DS
NCNSG\@IS
NCNSN\@DS
NCNSN\@IS
NCU00\@0C
NCU00\@0S
NCUPG\@DS
NCUPG\@IS
NCUPN\@DS
NCUPN\@IS
NCUSG\@DS
NCUSG\@IS
NCUSN\@DS
NCUSN\@IS
NP000\@0C
NP00G\@0S
NP00N\@0S
AF00000A
AF00PG0S
AF00PN0S
AF00SGDS
AF00SNDS
AF0MSGDS
AF0MSNDS
AF0NSNIS
AF0USGIS
AF0USNIS
AP000G0S
AP000N0S
AQ00000A
AQC0000C
AQC00G0S
AQC00N0S
AQP0000C
AQP00N0S
AQP00NIS
AQP0PG0S
AQP0PN0S
AQP0PNIS
AQP0SGDS
AQP0SNDS
AQPMSGDS
AQPMSNDS
AQPNSGIS
AQPNSN0S
AQPNSNIS
AQPU000C
AQPUSGIS
AQPUSN0S
AQPUSNIS
AQS00NDS
AQS00NIS
AQS0PNDS
AQS0PNIS
AQSMSGDS
AQSMSNDS
D0\@00\@A
D0\@0P\@S
D0\@NS\@S
D0\@US\@S
DF\@0P\@S
DF\@0S\@S
DF\@MS\@S
DF\@NS\@S
DF\@US\@S
DH\@0P\@S
DH\@NS\@S
DH\@US\@S
DI\@00\@S
DI\@0P\@S
DI\@0S\@S
DI\@MS\@S
DI\@NS\@S
DI\@US\@S
PF\@00O\@S
PF\@0P0\@S
PF\@0PO\@S
PF\@0PS\@S
PF\@MS0\@S
PF\@NS0\@S
PF\@UPO\@S
PF\@UPS\@S
PF\@US0\@S
PF\@USO\@S
PF\@USS\@S
PE\@000\@S
PH\@000\@S
PH\@0P0\@S
PH\@NS0\@C
PH\@NS0\@S
PH\@US0\@S
PI\@0P0\@S
PI\@NS0\@S
PI\@US0\@S
PI\@USS\@S
PS\@000\@A
PS\@000\@S
PS\@0P0\@S
PS\@NS0\@S
PS\@US0\@S
MC0000C
MC00G0S
MC00N0S
MC0SNDS
MCMSGDS
MCMSNDS
MCNSNIS
MCUSNIS
MO0000C
MO00G0S
MO00N0S
MOMSNDS
V\@000A
V\@000C
V\@IIAS
V\@IISS
V\@IPAS
V\@IPSS
V\@IUAS
V\@IUSS
V\@M0AS
V\@M0SS
V\@N0AS
V\@N0SS
V\@SIAS
V\@SISS
V\@SPAS
RG0A
RG0C
RG0S
RGCS
RGPS
RGSS
RH0S
SPC
SPS
CCA
CCS
CIS
CSS
QC
QS
I
FE
FI
FP
XF
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/ \s+/\t/sg;
    my @list = split(/\r?\n/, $list);
    pop(@list) if($list[$#list] eq "");
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::SV::Parole - Driver for the Swedish PAROLE tagset.

=head1 VERSION

version 3.011

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::SV::Parole;
  my $driver = Lingua::Interset::Tagset::SV::Parole->new();
  my $fs = $driver->decode('NCNSN@IS');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('sv::parole', 'NCNSN@IS');

=head1 DESCRIPTION

Interset driver for the Swedish PAROLE tagset
(L<http://spraakbanken.gu.se/parole/tags.phtml>).

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
