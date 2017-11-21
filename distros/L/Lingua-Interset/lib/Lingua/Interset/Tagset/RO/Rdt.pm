# ABSTRACT: Driver for the tagset of the Romanian Dependency Treebank (RDT).
# Copyright © 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Copyright © 2011 Martin Popel <popel@ufal.mff.cuni.cz>
# Brief tagset documentation in $TMT_ROOT/share/data/resources/treebanks/ro/2008_calacean.pdf
# Useful resource http://dexonline.ro

# ă â î ș ț (ş ţ)

# NOTE:
# The original RDT annotation is *not consistent*:
# Four of the twenty POS tags and one dependency type appear only in the first 6% of the material,
# reducing significantly the POS tagset for the rest of the material. For instance, verbs and
# adjectives in participle form are annotated as such only in the first part of the material.
# On the other hand, the definite article POS tag is present only in the last 90% of the material.

package Lingua::Interset::Tagset::RO::Rdt;
use strict;
use warnings;
our $VERSION = '3.008';

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
    return 'ro::rdt';
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
        'adjectiv'           => ['pos' => 'adj'],
        'adverb'             => ['pos' => 'adv'],
        # cel (demonstrative article, used only before adjectives "cel bun")
        'art. dem.'          => ['pos' => 'adj', 'prontype' => 'dem', 'definite' => 'def'],
        # lui (definite article, used only in possessive constructions with male gender)
        'art. hot.'          => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'def', 'poss' => 'yes', 'gender' => 'masc'],
        # al, a, ai, ale (genitival/possessive article)
        'art. poses.'        => ['pos' => 'adj', 'prontype' => 'art', 'poss' => 'yes'],
        # o, un, niște
        'art. nehot.'        => ['pos' => 'adj', 'prontype' => 'art', 'definite' => 'ind'],
        'conj. aux.'         => ['pos' => 'conj', 'conjtype' => 'sub'],
        'conj. coord.'       => ['pos' => 'conj', 'conjtype' => 'coor'],
        'numeral'            => ['pos' => 'num'],
        'prepozitie'         => ['pos' => 'adp', 'adpostype' => 'prep'],
        # se, ne, mă
        'pron. reflex.'      => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'],
        # care, ce, le, noi, nimic, totul
        'pronume'            => ['pos' => 'noun|adj', 'prontype' => 'prn'],
        'substantiv'         => ['pos' => 'noun'],
        'verb'               => ['pos' => 'verb', 'verbform' => 'fin'],
        # a, au, fost, fi, vor, fie, este, sunt
        'verb aux.'          => ['pos' => 'verb', 'verbtype' => 'aux'],
        # fi (a fi = infinitive to be), cântând (converb/transgressive, note that in Romainan it is called "gerunziu", but it is not a gerund like "doing" in English)
        'verb nepred.'       => ['pos' => 'verb', 'verbform' => 'inf|conv'],
        # Due to inconsistent annotation, the following tags appear only in the test set :-(
        'verb la participiu' => ['pos' => 'verb', 'verbform' => 'part'],
        # iluminat (tagged as 'verb nepred.' in the rest of RDT)
        'verb la infinitiv'  => ['pos' => 'verb', 'verbform' => 'inf'],
        'adj. particip.'     => ['pos' => 'adj', 'verbform' => 'part'],
        # cel, aceasta
        'pron. dem.'         => ['pos' => 'adj', 'prontype' => 'dem']
    );
    # Construct encode_map in the form expected by Atom.
    my %em =
    (
        'pos' => { 'noun' => { 'prontype' => { ''    => 'substantiv',
                                               '@'   => { 'reflex' => { 'yes' => 'pron. reflex.',
                                                                        '@'      => 'pronume' }}}},
                   'adj'  => { 'prontype' => { ''    => { 'verbform' => { 'part' => 'adj. particip.',
                                                                          '@'    => 'adjectiv' }},
                                               'dem' => { 'definite' => { 'def' => 'art. dem.',
                                                                          '@'   => 'pron. dem.' }},
                                               'art' => { 'poss' => { 'yes' => { 'definite' => { 'def' => 'art. hot.',
                                                                                                  '@'   => 'art. poses.' }},
                                                                      '@'    => 'art. nehot.' }},
                                               '@'   => 'pronume' }},
                   'num'  => 'numeral',
                   'verb' => { 'verbtype' => { 'aux' => 'verb aux.',
                                               '@'   => { 'verbform' => { 'inf'      => 'verb la infinitiv',
                                                                          'fin'      => 'verb',
                                                                          'inf|conv' => 'verb nepred.',
                                                                          'trans'    => 'verb nepred.',
                                                                          'ger'      => 'verb nepred.',
                                                                          'part'     => 'verb la participiu' }}}},
                   'adv'  => 'adverb',
                   'adp'  => 'prepozitie',
                   'conj' => { 'conjtype' => { 'sub' => 'conj. aux.',
                                               '@'   => 'conj. coord.' }}}
    );
    # Now add the references to the attribute hash.
    $attr->{surfeature} = 'pos';
    $attr->{decode_map} = \%dm;
    $attr->{encode_map} = \%em;
    $attr->{tagset}     = 'ro::rdt';
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
    $fs->set_tagset('ro::rdt');
    return $fs;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::RO::Rdt - Driver for the tagset of the Romanian Dependency Treebank (RDT).

=head1 VERSION

version 3.008

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::RO::Rdt;
  my $driver = Lingua::Interset::Tagset::RO::Rdt->new();
  my $fs = $driver->decode('substantiv');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('ro::rdt', 'substantiv');

=head1 DESCRIPTION

Interset driver for the tagset of the Romanian Dependency Treebank (RDT).

The original RDT annotation is I<not consistent:>
Four of the twenty POS tags and one dependency type appear only in the first 6% of the material,
reducing significantly the POS tagset for the rest of the material. For instance, verbs and
adjectives in participle form are annotated as such only in the first part of the material.
On the other hand, the definite article POS tag is present only in the last 90% of the material.

=head1 AUTHOR

Dan Zeman
Martin Popel

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
