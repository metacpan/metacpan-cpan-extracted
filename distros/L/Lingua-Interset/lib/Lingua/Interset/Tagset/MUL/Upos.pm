# ABSTRACT: Driver for the Universal Part-of-Speech Tagset, version 2014-10-01, part of Universal Dependencies.
# http://universaldependencies.github.io/docs/
# Copyright © 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::MUL::Upos;
use strict;
use warnings;
our $VERSION = '3.013';

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
    return 'mul::upos';
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
        # adjective
        'ADJ'   => ['pos' => 'adj'],
        # adposition (preposition or postposition)
        'ADP'   => ['pos' => 'adp'],
        # adverb
        'ADV'   => ['pos' => 'adv'],
        # auxiliary verb
        'AUX'   => ['pos' => 'verb', 'verbtype' => 'aux'],
        # coordinating conjunction (CONJ in UD v1, CCONJ since UD v2)
        'CCONJ' => ['pos' => 'conj', 'conjtype' => 'coor'],
        'CONJ'  => ['pos' => 'conj', 'conjtype' => 'coor'],
        # determiner
        'DET'   => ['pos' => 'adj', 'prontype' => 'prn'],
        # interjection
        'INTJ'  => ['pos' => 'int'],
        # common noun
        'NOUN'  => ['pos' => 'noun', 'nountype' => 'com'],
        # cardinal number (but not an indefinite quantifier)
        'NUM'   => ['pos' => 'num', 'numtype' => 'card'],
        # particle
        'PART'  => ['pos' => 'part'],
        # pronoun
        'PRON'  => ['pos' => 'noun', 'prontype' => 'prn'],
        # proper noun
        'PROPN' => ['pos' => 'noun', 'nountype' => 'prop'],
        # punctuation
        'PUNCT' => ['pos' => 'punc'],
        # subordinating conjunction
        'SCONJ' => ['pos' => 'conj', 'conjtype' => 'sub'],
        # symbol
        'SYM'   => ['pos' => 'sym'],
        # verb (non-auxiliary, all tenses and modes)
        'VERB'  => ['pos' => 'verb'],
        # other: foreign words, unanalyzable tokens
        'X'     => []
    );
    # Construct encode_map in the form expected by Atom.
    my %em =
    (
        'pos' => { 'verb' => { 'verbtype' => { 'aux' => 'AUX',
                                               '@'   => 'VERB' }},
                   'noun' => { 'prontype' => { ''  => { 'nountype' => { 'prop' => 'PROPN', ###!!! a co kdyz je to adj,noun???
                                                                        '@'    => 'NOUN' }},
                                               '@' => 'PRON' }},
                   'adj'  => { 'adjtype' => { 'pdt' => 'DET',
                                              '@'   => { 'prontype' => { ''  => 'ADJ',
                                                                         '@' => 'DET' }}}},
                   'num'  => { 'prontype' => { ''  => 'NUM',
                                               '@' => 'DET' }},
                   'adv'  => 'ADV',
                   'adp'  => 'ADP',
                   'conj' => { 'conjtype' => { 'sub' => 'SCONJ',
                                               '@'   => 'CCONJ' }},
                   # Make sure that RP particles from the Penn Treebank and separable verb prefixes from German STTS
                   # do not end up as PART; UD clearly documents that they should be ADP or ADV.
                   'part' => { 'parttype' => { 'vbp' => 'ADP',
                                               '@'   => 'PART' }},
                   'int'  => 'INTJ',
                   'punc' => 'PUNCT',
                   'sym'  => 'SYM',
                   '@'    => 'X' }
    );
    # Now add the references to the attribute hash.
    $attr->{surfeature} = 'pos';
    $attr->{decode_map} = \%dm;
    $attr->{encode_map} = \%em;
    return $attr;
};



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure. In addition to Atom, we just need to identify the tagset of
# origin (it is not crucial because we do not use the 'other' feature but it
# is customary).
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = $self->SUPER::decode($tag);
    $fs->set_tagset('mul::upos');
    return $fs;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags, useful for testing. The Atom class
# will generate the list for us but we have to remove CONJ from the list
# because we do not want to preserve it on the output.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = $self->SUPER::list();
    my @without_conj = grep {$_ ne 'CONJ'} (@{$list});
    return \@without_conj;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::MUL::Upos - Driver for the Universal Part-of-Speech Tagset, version 2014-10-01, part of Universal Dependencies.

=head1 VERSION

version 3.013

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::MUL::Upos;
  my $driver = Lingua::Interset::Tagset::MUL::Upos->new();
  my $fs = $driver->decode('NOUN');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('mul::upos', 'NOUN');

=head1 DESCRIPTION

Interset driver for the Universal Part-of-Speech Tagset
as of its extended version for the Universal Dependencies (2014-10-01),
see L<http://universaldependencies.github.io/docs/>.

=head1 SEE ALSO

L<Lingua::Interset>
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::MUL::Google>,
L<Lingua::Interset::Tagset::MUL::Uposf>,
L<Lingua::Interset::Atom>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
