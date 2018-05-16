# ABSTRACT: Driver for the tagset of the Penn Treebank.
# Copyright © 2006, 2009, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>
# 25.3.2009: added new tags HYPH, AFX from PennBioIE, 2005 (HYPH appears in the CoNLL 2009 data)
# 25.3.2009: new tag NIL appears in CoNLL 2009 English data for tokens &, $, %
# 6.6.2014: moved to the new object-oriented Interset

package Lingua::Interset::Tagset::EN::Penn;
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
    return 'en::penn';
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
        # sentence-final punctuation
        # examples: . ! ?
        '.'     => ['pos' => 'punc', 'punctype' => 'peri'],
        # comma
        # example: ,
        ','     => ['pos' => 'punc', 'punctype' => 'comm'],
        # left bracket
        # example: -LRB- -LCB- [ {
        '-LRB-' => ['pos' => 'punc', 'punctype' => 'brck', 'puncside' => 'ini'],
        # right bracket
        # example: -RRB- -RCB- ] }
        '-RRB-' => ['pos' => 'punc', 'punctype' => 'brck', 'puncside' => 'fin'],
        # left quotation mark
        # example: ``
        '``'    => ['pos' => 'punc', 'punctype' => 'quot', 'puncside' => 'ini'],
        # right quotation mark
        # example: ''
        "''"    => ['pos' => 'punc', 'punctype' => 'quot', 'puncside' => 'fin'],
        # generic other punctuation
        # examples: : ; ...
        ':'     => ['pos' => 'punc'],
        # currency
        # example: $ US$ C$ A$ NZ$
        '$'     => ['pos' => 'sym', 'other' => {'symtype' => 'currency'}],
        # channel
        # example: #
        "\#"    => ['pos' => 'sym', 'other' => {'symtype' => 'numbersign'}],
        # "common postmodifiers of biomedical entities such as genes" (Blitzer, McDonald, Pereira, Proc of EMNLP 2006, Sydney)
        # Example 1: "anti-CYP2E1-IgG" is tokenized and tagged as "anti/AFX -/HYPH CYP2E1-IgG/NN".
        # Example 2: "mono- and diglycerides" is tokenized and tagged as "mono/AFX -/HYPH and/CC di/AFX glycerides/NNS".
        'AFX'   => ['pos' => 'adj',  'hyph' => 'yes'],
        # coordinating conjunction
        # examples: and, or
        'CC'    => ['pos' => 'conj', 'conjtype' => 'coor'],
        # cardinal number
        # examples: one, two, three
        'CD'    => ['pos' => 'num', 'numtype' => 'card'],
        # determiner
        # examples: a, the, some
        'DT'    => ['pos' => 'adj', 'prontype' => 'prn'],
        # existential there (UD English makes it a PRON)
        # examples: there
        'EX'    => ['pos' => 'noun', 'prontype' => 'prn', 'advtype' => 'ex'],
        # foreign word
        # examples: kašpárek
        'FW'    => ['foreign' => 'yes'],
        # This tag is new in PennBioIE. In older data hyphens are tagged ":".
        # hyphen
        # example: -
        'HYPH'  => ['pos' => 'punc', 'punctype' => 'dash'],
        # preposition or subordinating conjunction
        # examples: in, on, because
        # We could create array of "prep" and "conj/sub" but arrays generally complicate things and the benefit is uncertain.
        'IN'    => ['pos' => 'adp'],
        # adjective
        # examples: good
        'JJ'    => ['pos' => 'adj', 'degree' => 'pos'],
        # adjective, comparative
        # examples: better
        'JJR'   => ['pos' => 'adj', 'degree' => 'cmp'],
        # adjective, superlative
        # examples: best
        'JJS'   => ['pos' => 'adj', 'degree' => 'sup'],
        # list item marker
        # examples: 1., a), *
        # no POS used because punc should not be used for alphanumeric strings
        'LS'    => ['numtype' => 'ord'],
        # modal
        # examples: can, must
        'MD'    => ['pos' => 'verb', 'verbtype' => 'mod'],
        'NIL'   => [],
        # noun, singular or mass
        # examples: animal
        'NN'    => ['pos' => 'noun', 'number' => 'sing'],
        # proper noun, singular
        # examples: America
        'NNP'   => ['pos' => 'noun', 'nountype' => 'prop', 'number' => 'sing'],
        # proper noun, plural
        # examples: Americas
        'NNPS'  => ['pos' => 'noun', 'nountype' => 'prop', 'number' => 'plur'],
        # noun, plural
        # examples: animals
        'NNS'   => ['pos' => 'noun', 'number' => 'plur'],
        # predeterminer
        # examples: "all" in "all the flowers" or "both" in "both his children"
        'PDT'   => ['pos' => 'adj', 'adjtype' => 'pdt', 'prontype' => 'prn'],
        # possessive ending
        # examples: 's
        'POS'   => ['pos' => 'part', 'poss' => 'yes'],
        # personal pronoun
        # examples: I, you, he, she, it, we, they
        'PRP'   => ['pos' => 'noun', 'prontype' => 'prs'],
        # possessive pronoun
        # examples: my, your, his, her, its, our, their
        'PRP$'  => ['pos' => 'adj', 'prontype' => 'prs', 'poss' => 'yes'],
        # adverb
        # examples: here, tomorrow, easily
        'RB'    => ['pos' => 'adv', 'degree' => 'pos'],
        # adverb, comparative
        # examples: more, less
        'RBR'   => ['pos' => 'adv', 'degree' => 'cmp'],
        # adverb, superlative
        # examples: most, least
        'RBS'   => ['pos' => 'adv', 'degree' => 'sup'],
        # particle (in the case of English, only the particles of phrasal verbs, which in UD should be tagged ADP or ADV)
        # examples: up, on
        'RP'    => ['pos' => 'part', 'parttype' => 'vbp'],
        # symbol
        # Penn Treebank definition (Santorini 1990):
        # This tag should be used for mathematical, scientific and technical symbols
        # or expressions that aren't words of English. It should not be used for any
        # and all technical expressions. For instance, the names of chemicals, units
        # of measurements (including abbreviations thereof) and the like should be
        # tagged as nouns.
        'SYM'   => ['pos' => 'sym'],
        # to
        # examples: to
        # Both the infinitival marker "to" and the preposition "to" get this tag.
        'TO'    => ['pos' => 'part', 'parttype' => 'inf', 'verbform' => 'inf'],
        # interjection
        # examples: uh
        'UH'    => ['pos' => 'int'],
        # verb, base form
        # examples: do, go, see, walk
        'VB'    => ['pos' => 'verb', 'verbform' => 'inf'],
        # verb, past tense
        # examples: did, went, saw, walked
        'VBD'   => ['pos' => 'verb', 'verbform' => 'fin', 'tense' => 'past'],
        # verb, gerund or present participle
        # examples: doing, going, seeing, walking
        'VBG'   => ['pos' => 'verb', 'verbform' => 'part', 'tense' => 'pres', 'aspect' => 'prog'],
        # verb, past participle
        # examples: done, gone, seen, walked
        'VBN'   => ['pos' => 'verb', 'verbform' => 'part', 'tense' => 'past', 'aspect' => 'perf'],
        # verb, non-3rd person singular present
        # examples: do, go, see, walk
        'VBP'   => ['pos' => 'verb', 'verbform' => 'fin', 'tense' => 'pres'],
        # verb, 3rd person singular present
        # examples: does, goes, sees, walks
        'VBZ'   => ['pos' => 'verb', 'verbform' => 'fin', 'tense' => 'pres', 'number' => 'sing', 'person' => 3],
        # wh-determiner
        # examples: which
        'WDT'   => ['pos' => 'adj', 'prontype' => 'int|rel'],
        # wh-pronoun
        # examples: who
        'WP'    => ['pos' => 'noun', 'prontype' => 'int|rel'],
        # possessive wh-pronoun
        # examples: whose
        'WP$'   => ['pos' => 'adj', 'poss' => 'yes', 'prontype' => 'int|rel'],
        # wh-adverb
        # examples: where, when, how
        'WRB'   => ['pos' => 'adv', 'prontype' => 'int|rel'],
    );
    # Construct encode_map in the form expected by Atom.
    my %em =
    (
        'hyph' => { 'yes' => 'AFX',
                    '@'   => { 'advtype' => { 'ex' => 'EX',
                                              '@'  => { 'prontype' => { 'rel' => { 'poss' => { 'yes' => 'WP$',
                                                                                               '@'   => { 'pos' => { 'adv' => 'WRB',
                                                                                                                     'adj' => 'WDT',
                                                                                                                     '@'   => 'WP' }}}},
                                                                        'int' => { 'poss' => { 'yes' => 'WP$',
                                                                                               '@'    => { 'pos' => { 'adv' => 'WRB',
                                                                                                                      'adj' => 'WDT',
                                                                                                                      '@'   => 'WP' }}}},
                                                                        'prs' => { 'poss' => { 'yes' => 'PRP$',
                                                                                               '@'    => 'PRP' }},
                                                                        '@'   => { 'pos' => { 'noun' => { 'nountype' => { 'prop' => { 'number' => { 'plur' => 'NNPS',
                                                                                                                                                    '@'    => 'NNP' }},
                                                                                                                          '@'    => { 'number' => { 'plur' => 'NNS',
                                                                                                                                                    '@'    => 'NN' }}}},
                                                                                              'adj'  => { 'adjtype' => { 'pdt' => 'PDT',
                                                                                                                         '@'   => { 'prontype' => { ''  => { 'degree' => { 'sup' => 'JJS',
                                                                                                                                                                           'cmp' => 'JJR',
                                                                                                                                                                           '@'   => 'JJ' }},
                                                                                                                                                    '@' => 'DT' }}}},
                                                                                              'num'  => 'CD',
                                                                                              'verb' => { 'verbtype' => { 'mod' => 'MD',
                                                                                                                          '@'   => { 'verbform' => { 'part' => { 'tense' => { 'pres' => 'VBG',
                                                                                                                                                                              '@'    => { 'aspect' => { 'imp'  => 'VBG',
                                                                                                                                                                                                        'prog' => 'VBG',
                                                                                                                                                                                                        '@'    => 'VBN' }}}},
                                                                                                                                                     '@'    => { 'tense' => { 'past' => 'VBD',
                                                                                                                                                                              'pres' => { 'number' => { 'sing' => { 'person' => { '3' => 'VBZ',
                                                                                                                                                                                                                                  '@' => 'VBP' }},
                                                                                                                                                                                                        '@'    => 'VBP' }},
                                                                                                                                                                              '@'    => 'VB' }}}}}},
                                                                                              'adv'  => { 'advtype' => { 'ex' => 'EX',
                                                                                                                         '@'  => { 'degree' => { 'sup' => 'RBS',
                                                                                                                                                 'cmp' => 'RBR',
                                                                                                                                                 '@'   => 'RB' }}}},
                                                                                              # IN is either preposition or subordinating conjunction
                                                                                              # TO is either preposition or infinitive mark
                                                                                              'adp'  => 'IN',
                                                                                              'conj' => { 'conjtype' => { 'sub' => 'IN',
                                                                                                                          '@'   => 'CC' }},
                                                                                              'part' => { 'poss' => { 'yes' => 'POS',
                                                                                                                      '@'    => { 'verbform' => { 'inf' => 'TO',
                                                                                                                                                  '@'   => { 'parttype' => { 'inf' => 'TO',
                                                                                                                                                                             '@'   => 'RP' }}}}}},
                                                                                              'int'  => 'UH',
                                                                                              'punc' => { 'numtype' => { 'ord' => 'LS',
                                                                                                                         '@'   => { 'punctype' => { 'peri' => '.',
                                                                                                                                                    'qest' => '.',
                                                                                                                                                    'excl' => '.',
                                                                                                                                                    'comm' => ',',
                                                                                                                                                    'brck' => { 'puncside' => { 'fin' => '-RRB-',
                                                                                                                                                                                '@'   => '-LRB-' }},
                                                                                                                                                    'quot' => { 'puncside' => { 'fin' => "''",
                                                                                                                                                                                '@'   => "``" }},
                                                                                                                                                    # This tag is new in PennBioIE. In older data hyphens are tagged ":".
                                                                                                                                                    'dash' => 'HYPH',
                                                                                                                                                    '@'    => ':' }}}},
                                                                                              'sym'  => { 'other/symtype' => { 'currency'   => '$',
                                                                                                                               'numbersign' => "\#",
                                                                                                                               '@'          => 'SYM' }},
                                                                                              '@'    => { 'foreign' => { 'yes' => 'FW',
                                                                                                                         '@'   => { 'numtype' => { 'ord' => 'LS',
                                                                                                                                                   '@'   => 'NIL' }}}}}}}}}}}
    );
    # Now add the references to the attribute hash.
    $attr->{surfeature} = 'pos';
    $attr->{decode_map} = \%dm;
    $attr->{encode_map} = \%em;
    $attr->{tagset}     = 'en::penn';
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
    $fs->set_tagset('en::penn');
    return $fs;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::EN::Penn - Driver for the tagset of the Penn Treebank.

=head1 VERSION

version 3.012

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::EN::Penn;
  my $driver = Lingua::Interset::Tagset::EN::Penn->new();
  my $fs = $driver->decode('NN');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('en::penn', 'NN');

=head1 DESCRIPTION

Interset driver for the part-of-speech tagset of the Penn Treebank.

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
