# ABSTRACT: Driver for the Mamba tagset of Swedish (Talbanken).
# Copyright © 2006, 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# 25.1.2015: moved to the new object-oriented Interset

package Lingua::Interset::Tagset::SV::Mamba;
use strict;
use warnings;
our $VERSION = '3.012';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Atom';



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'sv::mamba';
}



#------------------------------------------------------------------------------
# This block will be called before object construction. It will build the
# decoding and encoding maps for this particular tagset.
# Then it will pass all the attributes to the constructor.
#------------------------------------------------------------------------------
around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;
    # Call the default BUILDARGS in Moose::Object. It will take care of distinguishing between a hash reference and a plain hash.
    my $attr = $class->$orig(@_);
    # Construct decode_map in the form expected by Atom.
    my %dm =
    (
        # ++ Coordinating conjunction
        # Examples: och, eller, men, utan, samt
        '++' => ['pos' => 'conj', 'conjtype' => 'coor'],
        # AB Adverb
        # Examples: inte, så, också, i, där
        'AB' => ['pos' => 'adv'],
        # AJ Adjective
        # Examples: stor, olika, större, stora, nya
        'AJ' => ['pos' => 'adj'],
        # AN Adjectival noun
        # Examples: möjlighet, trygghet, möjligheter, frihet, svårigheter
        # möjlig = possible => möjlighet = possibility
        'AN' => ['pos' => 'noun', 'other' => {'nountype' => 'adj'}],
        # AV The verb "vara" (be)
        # Examples: är, vara, var, varit, vore
        'AV' => ['pos' => 'verb', 'other' => {'verb' => 'vara'}],
        # BV The verb "bli(va)" (become)
        # Examples: blir, bli, blivit, blev, bör
        'BV' => ['pos' => 'verb', 'other' => {'verb' => 'bliva'}],
        # EN Indefinite article or numeral "en", "ett" (one)
        # Examples: en, ett, 1
        'EN' => ['pos' => 'adj|num', 'prontype' => 'art', 'definite' => 'ind'],
        # FV The verb "faa" (get)
        # Examples: får, få, fått, fick, finns
        'FV' => ['pos' => 'verb', 'other' => {'verb' => 'faa'}],
        # GV The verb "göra" (do, make)
        # Examples: göra, gör, gjort, gjorde, görs
        'GV' => ['pos' => 'verb', 'other' => {'verb' => 'göra'}],
        # HV The verb "ha(va)" (have)
        # Examples: har, ha, hade, haft, hava
        'HV' => ['pos' => 'verb', 'other' => {'verb' => 'hava'}],
        # I? Question mark
        # Examples: ?
        'I?' => ['pos' => 'punc', 'punctype' => 'qest'],
        # IC Quotation mark
        # Examples: '
        'IC' => ['pos' => 'punc', 'punctype' => 'quot'],
        # ID Part of idiom (multi-word unit)
        # Examples: att, Backberger, och, av, Hellsten
        'ID' => ['hyph' => 'yes'], ###!!! Some other solution should be found.
        # IG Other punctuation mark
        # Examples: ..., /, =, ...., 1
        'IG' => ['pos' => 'punc'],
        # IK Comma
        # Examples: ,
        'IK' => ['pos' => 'punc', 'punctype' => 'comm'],
        # IM Infinitive marker
        # Examples: att
        'IM' => ['pos' => 'conj', 'verbform' => 'inf'], ###!!! or particle?
        # IP Period
        # Examples: .
        'IP' => ['pos' => 'punc', 'punctype' => 'peri'],
        # IQ Colon
        # Examples: :
        'IQ' => ['pos' => 'punc', 'punctype' => 'colo'],
        # IR Parenthesis
        # Examples: (, )
        'IR' => ['pos' => 'punc', 'punctype' => 'brck'],
        # IS Semicolon
        # Examples: ;
        'IS' => ['pos' => 'punc', 'punctype' => 'semi'],
        # IT Dash
        # Examples: -, ---
        'IT' => ['pos' => 'punc', 'punctype' => 'dash'],
        # IU Exclamation mark
        # Examples: !
        'IU' => ['pos' => 'punc', 'punctype' => 'excl'],
        # KV The verb "komma att" (periphrastic future)
        # Examples: kommer, kommit, kom, komma, komer
        'KV' => ['pos' => 'verb', 'other' => {'verb' => 'komma'}],
        # MN Adversative
        'MN' => ['pos' => 'conj', 'conjtype' => 'coor', 'other' => {'conjtype' => 'adversative'}],
        # MV The verb "maaste" (must)
        # Examples: måste, måsk
        'MV' => ['pos' => 'verb', 'other' => {'verb' => 'maaste'}],
        # NN Other noun
        # Examples: äktenskapet, barn, äktenskap, familjen, människor
        'NN' => ['pos' => 'noun', 'nountype' => 'com'],
        # PN Proper name
        # Examples: Barbro, Stig, Sverige, Gud, Hellsten
        'PN' => ['pos' => 'noun', 'nountype' => 'prop'],
        # PO Pronoun
        # Examples: det, som, den, man, de
        'PO' => ['pos' => 'noun', 'prontype' => 'prn'],
        # PR Preposition
        # Examples: i, av, på, för, med
        'PR' => ['pos' => 'adp', 'adpostype' => 'prep'],
        # PU Pause
        # Examples: *, -
        'PU' => ['pos' => 'int', 'other' => {'inttype' => 'pause'}],
        # QV The verb "kunna" (can)
        # Examples: kan, kunna, kunde, kunnat
        'QV' => ['pos' => 'verb', 'other' => {'verb' => 'kunna'}],
        # RO Numeral other than "en", "ett" (one)
        # Examples: två, tre, 20, 1968, 10
        'RO' => ['pos' => 'num'],
        # SP Present participle
        # Examples: kommande, bestående, gällande, växande, nuvarande
        'SP' => ['pos' => 'verb', 'verbform' => 'part', 'tense' => 'pres'],
        # SV The verb "skola" (will, shall)
        # Examples: skall, skulle, ska, skola
        'SV' => ['pos' => 'verb', 'other' => {'verb' => 'skola'}],
        ###!!! The old sv::mamba driver decoded TP as total pronoun.
        ###!!! Given the examples from the corpus, it must have been an error.
        ###!!! I am inclined to believe that TP stands for past participles.
        # TP Past participle
        # Examples: ökade, ingångna, ökad, utlämnade, baserat
        'TP' => ['pos' => 'verb', 'verbform' => 'part', 'tense' => 'past'],
        # UK Subordinating conjunction
        # Examples: att, som, om, än, så
        'UK' => ['pos' => 'conj', 'conjtype' => 'sub'],
        # VN Verbal noun
        # Examples: uppfattning, betydelse, uppfostran, utsträckning, utveckling
        'VN' => ['pos' => 'noun', 'verbform' => 'ger'],
        # VV Other verb
        # Examples: finns, bör, tror, anser, säger
        'VV' => ['pos' => 'verb'],
        # WV The verb "vilja" (want)
        # Examples: vill, vilja, ville, velat
        'WV' => ['pos' => 'verb', 'other' => {'verb' => 'vilja'}],
        # XX Unclassifiable part-of-speech
        # Examples: som, lika, =, brattom, för
        'XX' => [],
        # YY Interjection
        # Examples: ja, nej, jo, jodå, javisst
        'YY' => ['pos' => 'int'],
        # EH Filled pause
        'EH' => ['pos' => 'int', 'other' => {'inttype' => 'filledpause'}],
        # RJ Juncture - straight
        'RJ' => ['pos' => 'int', 'other' => {'inttype' => 'straightjuncture'}],
        # UJ Juncture - rise
        'UJ' => ['pos' => 'int', 'other' => {'inttype' => 'risejuncture'}],
        # NJ Juncture - fall
        'NJ' => ['pos' => 'int', 'other' => {'inttype' => 'falljuncture'}],
        # QQ Dummy for final omission
        'QQ' => ['other' => {'pos' => 'dummy'}],
        # UU Exclamative or optative
        'UU' => ['other' => {'pos' => 'excl'}], ###!!!???
        # TT Vocative
        'TT' => ['other' => {'pos' => 'voc'}], ###!!!???
    );
    # Construct encode_map in the form expected by Atom.
    my %em =
    (
        'pos' => { 'noun' => { 'verbform' => { 'ger' => 'VN',
                                               '@'   => { 'prontype' => { ''  => { 'nountype' => { 'prop' => 'PN',
                                                                                                   '@'    => { 'other/nountype' => { 'adj' => 'AN',
                                                                                                                                     '@'   => 'NN' }}}},
                                                                          '@' => 'PO' }}}},
                   'adj'  => { 'definite' => { 'ind' => 'EN',
                                               '@'   => 'AJ' }},
                   'num'  => { 'definite' => { 'ind' => 'EN',
                                               '@'   => 'RO' }},
                   'verb' => { 'verbform' => { 'part' => { 'tense' => { 'pres' => 'SP',
                                                                        '@'    => 'TP' }},
                                               '@'    => { 'other/verb' => { 'vara'   => 'AV',
                                                                             'bliva'  => 'BV',
                                                                             'faa'    => 'FV',
                                                                             'göra'   => 'GV',
                                                                             'hava'   => 'HV',
                                                                             'komma'  => 'KV',
                                                                             'maaste' => 'MV',
                                                                             'kunna'  => 'QV',
                                                                             'skola'  => 'SV',
                                                                             'vilja'  => 'WV',
                                                                             '@'      => 'VV' }}}},
                   'adv'  => 'AB',
                   'adp'  => 'PR',
                   'conj' => { 'verbform' => { 'inf' => 'IM',
                                               '@'   => { 'conjtype' => { 'sub' => 'UK',
                                                                          '@'   => { 'other/conjtype' => { 'adversative' => 'MN',
                                                                                                           '@'           => '++' }}}}}},
                   'int'  => { 'other/inttype' => { 'pause'            => 'PU',
                                                    'filledpause'      => 'EH',
                                                    'straightjuncture' => 'RJ',
                                                    'risejuncture'     => 'UJ',
                                                    'falljuncture'     => 'NJ',
                                                    '@'                => 'YY' }},
                   'punc' => { 'punctype' => { 'qest' => 'I?',
                                               'quot' => 'IC',
                                               'comm' => 'IK',
                                               'peri' => 'IP',
                                               'colo' => 'IQ',
                                               'brck' => 'IR',
                                               'semi' => 'IS',
                                               'dash' => 'IT',
                                               'excl' => 'IU',
                                               '@'    => 'IG' }},
                   '@'    => { 'hyph' => { 'yes' => 'ID',
                                           '@'    => { 'other/pos' => { 'dummy' => 'QQ',
                                                                        'excl'  => 'UU',
                                                                        'voc'   => 'TT',
                                                                        '@'     => 'XX' }}}}}
    );
    # Now add the references to the attribute hash.
    $attr->{surfeature} = 'pos';
    $attr->{decode_map} = \%dm;
    $attr->{encode_map} = \%em;
    $attr->{tagset}     = 'sv::mamba';
    return $attr;
};



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure. In addition to Atom, we just need to identify the tagset of
# origin.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = $self->SUPER::decode($tag);
    $fs->set_tagset('sv::mamba');
    return $fs;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::SV::Mamba - Driver for the Mamba tagset of Swedish (Talbanken).

=head1 VERSION

version 3.012

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::SV::Mamba;
  my $driver = Lingua::Interset::Tagset::SV::Mamba->new();
  my $fs = $driver->decode('NN');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('sv::mamba', 'NN');

=head1 DESCRIPTION

Interset driver for the Mamba tagset of Swedish, used e.g. in the older versions of the Talbanken corpus.

=head1 SEE ALSO

L<Lingua::Interset>
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
