# ABSTRACT: Driver for a Norwegian tagset.
# Copyright © 2013, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Based on code contributed by Arne Skjærholt.

package Lingua::Interset::Tagset::NO::Conll;
use strict;
use warnings;
our $VERSION = '3.010';

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
    return 'no::conll';
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
            'adj'              => ['pos' => 'adj'],
            'adv'              => ['pos' => 'adv'],
            '<anf>'            => ['pos' => 'punc', 'punctype' => 'quot'],
            'clb'              => ['pos' => 'punc', 'other' => {'punctype' => 'clb'}], # something for spoken language?
            'det'              => ['pos' => 'adj', 'prontype' => 'prn'],
            'inf-merke'        => ['pos' => 'conj', 'parttype' => 'inf'],
            'interj'           => ['pos' => 'int'],
            '<komma>'          => ['pos' => 'punc', 'punctype' => 'comm'],
            'konj'             => ['pos' => 'conj', 'conjtype' => 'coor'],
            '<parentes-beg>'   => ['pos' => 'punc', 'punctype' => 'brck', 'puncside' => 'ini'],
            '<parentes-slutt>' => ['pos' => 'punc', 'punctype' => 'brck', 'puncside' => 'fin'],
            'prep'             => ['pos' => 'adp', 'adpostype' => 'prep'],
            'prep+subst'       => ['pos' => 'noun'], # 'i_tilfelle'. Probably corpus bug.
            'pron'             => ['pos' => 'noun', 'prontype' => 'prn'],
            'sbu'              => ['pos' => 'conj', 'conjtype' => 'sub'],
            '<strek>'          => ['pos' => 'punc', 'punctype' => 'dash'],
            'subst'            => ['pos' => 'noun'],
            'symb'             => ['pos' => 'sym'],
            'ukjent'           => [],
            'verb'             => ['pos' => 'verb']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'prontype' => { ''  => 'subst',
                                                   '@' => 'pron' }},
                       'adj'  => { 'prontype' => { ''  => 'adj',
                                                   '@' => 'det' }},
                       'verb' => 'verb',
                       'adv'  => 'adv',
                       'adp'  => 'prep',
                       'conj' => { 'parttype' => { 'inf' => 'inf-merke',
                                                   '@'   => { 'conjtype' => { 'sub' => 'sbu',
                                                                              '@'   => 'konj' }}}},
                       'int'  => 'interj',
                       'punc' => { 'punctype' => { 'quot' => '<anf>',
                                                   'comm' => '<komma>',
                                                   'dash' => '<strek>',
                                                   'brck' => { 'puncside' => { 'ini' => '<parentes-beg>',
                                                                               '@'   => '<parentes-slutt>' }},
                                                   '@'    => 'clb' }},
                       'sym'  => 'symb',
                       '@'    => 'ukjent' }
        }
    );
    # NOUN TYPE ####################
    $atoms{nountype} = $self->create_simple_atom
    (
        'intfeature' => 'nountype',
        'simple_decode_map' =>
        {
            'prop' => 'prop'
        }
    );
    # PRONOUN TYPE ####################
    $atoms{prontype} = $self->create_atom
    (
        'surfeature' => 'prontype',
        'decode_map' =>
        {
            'refl'   => ['reflex'      => 'yes'],
            'hum'    => ['animateness' => 'anim'], # not strictly animate
            'pers'   => ['prontype'    => 'prs'],
            'høflig' => ['politeness'  => 'pol'],
            'sp'     => ['prontype'    => 'int'],
            'res'    => ['prontype'    => 'rcp']
        },
        'encode_map' =>
        {
            'reflex' => { 'yes' => 'refl',
                          '@'      => { 'animateness' => { 'anim' => 'hum',
                                                           '@'    => { 'politeness' => { 'pol' => 'høflig',
                                                                                         '@'   => { 'prs' => 'pers',
                                                                                                    'rcp' => 'res',
                                                                                                    'int' => 'sp' }}}}}}
        }
    );
    # POSSESSIVITY ####################
    $atoms{poss} = $self->create_simple_atom
    (
        'intfeature' => 'poss',
        'simple_decode_map' =>
        {
            'poss' => 'yes'
        }
    );
    # SPECIAL TYPE ####################
    $atoms{spectype} = $self->create_atom
    (
        'surfeature' => 'spectype',
        'decode_map' =>
        {
            'unorm' => ['typo' => 'yes'],
            'fork'  => ['abbr' => 'yes']
        },
        'encode_map' =>
        {
            'typo' => { 'yes' => 'unorm',
                        '@'    => { 'abbr' => { 'yes' => 'fork' }}}
        }
    );
    # PUNCTUATION TYPE ####################
    $atoms{punctype} = $self->create_simple_atom
    (
        'intfeature' => 'punctype',
        'simple_decode_map' =>
        {
            '<anf>'     => 'quot',
            '<kolon>'   => 'colo',
            '<komma>'   => 'comm',
            '<ellipse>' => 'peri', # ellipsis = "..."; Interset does not have a value for this ###!!! yet
            '<punkt>'   => 'peri',
            '<semi>'    => 'semi',
            '<spm>'     => 'qest',
            '<utrop>'   => 'excl'
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
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            'nom' => 'nom',
            'gen' => 'gen',
            'akk' => 'acc'
        }
    );
    # DEFINITENESS ####################
    $atoms{definiteness} = $self->create_simple_atom
    (
        'intfeature' => 'definiteness',
        'simple_decode_map' =>
        {
            'be' => 'def',
            'ub' => 'ind'
        }
    );
    # DEGREE ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            'pos'  => 'pos',
            'komp' => 'cmp',
            'sup'  => 'sup'
        }
    );
    # GENDER ####################
    $atoms{gender} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' =>
        {
            'mask' => ['gender' => 'masc'],
            'fem'  => ['gender' => 'fem'],
            'nøyt' => ['gender' => 'neut'],
            'n'    => ['gender' => 'neut'], ###!!! Corpus bug?
            'm/f'  => ['gender' => 'masc|fem'],
            'ubøy' => [] # Indeclinable nouns.
        },
        'encode_map' =>
        {
            'gender' => { 'masc'     => 'mask',
                          'fem'      => 'fem',
                          'fem|masc' => 'm/f',
                          'neut'     => 'nøyt',
                          '@'        => 'ubøy' }
        }
    );
    # NUMBER ####################
    $atoms{number} = $self->create_simple_atom
    (
        'intfeature' => 'number',
        'simple_decode_map' =>
        {
            'ent' => 'sing',
            'fl'  => 'plur'
        }
    );
    # VERB FORM ####################
    $atoms{verbform} = $self->create_atom
    (
        'surfeature' => 'verbform',
        'decode_map' =>
        {
            'inf'       => ['verbform' => 'inf'],
            'pres'      => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres'],
            'pret'      => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past'],
            'imp'       => ['verbform' => 'fin', 'mood' => 'imp'],
            'perf-part' => ['verbform' => 'part', 'aspect' => 'perf', 'tense' => 'past'],
            'pass'      => ['voice' => 'pass']
        },
        'encode_map' =>
        {
            'verbform' => { 'inf'  => 'inf',
                            'part' => 'perf-part',
                            '@'    => { 'mood' => { 'imp' => 'imp',
                                                    '@'   => { 'tense' => { 'pres' => 'pres',
                                                                            'past' => 'pret',
                                                                            '@'    => { 'voice' => { 'pass' => 'pass' }}}}}}}
        }
    );
    # Classifying tags for multi-word expressions.
    #'adj+kon+adj'         => [qw/field value/],
    #'adj+verb'            => [qw/field value/],
    #'adv+adj'             => [qw/field value/],
    #'adv+adv+prep'        => [qw/field value/],
    #'det+subst'           => [qw/field value/],
    #'interj+adv'          => [qw/field value/],
    #'prep+adj'            => [qw/field value/],
    #'prep+adv'            => [qw/field value/],
    #'prep+adv+subst'      => [qw/field value/],
    #'prep+det+sbu'        => [qw/field value/],
    #'prep+det+subst'      => [qw/field value/],
    #'prep+konj+prep'      => [qw/field value/],
    #'prep+prep'           => [qw/field value/],
    #'prep+subst'          => [qw/field value/],
    #'prep+subst+prep'     => [qw/field value/],
    #'prep+subst+prep+sbu' => [qw/field value/],
    #'prep+subst+subst'    => [qw/field value/],
    #'pron+verb+verb'      => [qw/field value/],
    #'subst+perf-part'     => [qw/field value/],
    #'subst+prep'          => [qw/field value/],

    ###### UNSORTED ######
    #'<adj>'               => [qw/field value/],
    #'<adv>'               => [qw/field value/],
    #appell                => [qw/field value/], # Appellative (common nouns). Can probably be ignored.
    #'<aux1/inf>'          => [qw/field value/],
    #'<aux1/infinitiv>'    => [qw/field value/],
    #'<aux1/perf_part>'    => [qw/field value/],
    #clb                   => [qw/field value/], # Clause boundary. Can probably be ignored.
    #'<dato>'              => [qw/field value/],
    #dem                   => [qw/field value/], # TODO: Demonstrative
    #forst                 => [qw/field value/], # TODO: Emphasis
    #g                     => [qw/field value/], # Corpus bug?
    #'<ikke-clb>'          => [qw/field value/], # Non-clause boundary. Can probably be ignored.
    #'<klokke>'            => [qw/field value/],
    #kvant                 => [qw/field value/], # TODO
    #'<ordenstall>'        => [qw/field value/],
    #'<overskrift>'        => [qw/field value/],
    #pa                    => [qw/field value/],
    #pa1refl4              => [qw/field value/],
    #pa6                   => [qw/field value/],
    #'pa/til'              => [qw/field value/],
    #'<perf-part>'         => [qw/field value/],
    #pr2                   => [qw/field value/],
    #'<pres-part>'         => [qw/field value/],
    #'<romertall>'         => [qw/field value/],
    #samset                => [qw/field value/], # Compound word. Can probably be ignored.
    #sbu                   => [qw/field value/], # Probably corpus bug.
    #'<s-verb>'            => [qw/field value/],
    #tr                    => [qw/field value/], # Subcat frame.
    #w                     => [qw/field value/], # Corpus bug?
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
    my @features = ('nountype', 'prontype', 'poss', 'spectype', 'punctype', 'person', 'case', 'definiteness', 'degree', 'gender', 'number', 'verbform');
    return \@features;
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
        '@' => ['nountype', 'prontype', 'poss', 'spectype', 'punctype', 'person', 'case', 'definiteness', 'degree', 'gender', 'number', 'verbform']
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
    ###!!! Our list of known tags currently contains only the main part of speech but not the features.
    ###!!!my $fs = $self->decode_conll($tag);
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset($self->get_tagset_id());
    my $atoms = $self->atoms();
    $atoms->{pos}->decode_and_merge_hard($tag, $fs);
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
    my $fpos = $pos;
    my $feature_names = $self->get_feature_names($fpos);
    my $tag = $self->encode_conll($fs, $pos, $pos, $feature_names);
    ###!!!return $tag;
    return $pos;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
adj
adv
<anf>
clb
det
inf-merke
interj
<komma>
konj
<parentes-beg>
<parentes-slutt>
prep
pron
sbu
<strek>
subst
symb
ukjent
verb
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

Lingua::Interset::Tagset::NO::Conll - Driver for a Norwegian tagset.

=head1 VERSION

version 3.010

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::NO::Conll;
  my $driver = Lingua::Interset::Tagset::NO::Conll->new();
  my $fs = $driver->decode('subst');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('no::conll', 'subst');

=head1 DESCRIPTION

Interset driver for the Norwegian tagset,
based on code contributed by Arne Skjærholt.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Arne Skjærholt
Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
