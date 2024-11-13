# ABSTRACT: Driver for the Google Universal Part-of-Speech Tagset.
# http://code.google.com/p/universal-pos-tags/
# Copyright © 2014 Martin Popel <popel@ufal.mff.cuni.cz>
# Copyright © 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::MUL::Google;
use strict;
use warnings;
our $VERSION = '3.016';

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
    return 'mul::google';
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
        # punctuation
        '.'     => ['pos' => 'punc'],
        # adjective
        'ADJ'   => ['pos' => 'adj'],
        # adposition (preposition or postposition)
        'ADP'   => ['pos' => 'adp'],
        # adverb
        'ADV'   => ['pos' => 'adv'],
        # auxiliary verb (appears in later versions of the tagset, e.g. UDTv2)
        'AUX'   => ['pos' => 'verb', 'verbtype' => 'aux'],
        # conjunction
        'CONJ'  => ['pos' => 'conj'],
        # determiner
        'DET'   => ['pos' => 'adj', 'prontype' => 'prn'],
        # noun (common and proper)
        'NOUN'  => ['pos' => 'noun'],
        # cardinal number
        'NUM'   => ['pos' => 'num', 'numtype' => 'card'],
        # proper noun (appears in later versions of the tagset, e.g. UDTv2)
        'PNOUN' => ['pos' => 'noun', 'nountype' => 'prop'],
        # pronoun
        'PRON'  => ['pos' => 'noun', 'prontype' => 'prn'],
        # particle
        'PRT'   => ['pos' => 'part'],
        # verb (all tenses and modes)
        'VERB'  => ['pos' => 'verb'],
        # other: foreign words, typos, abbreviations, interjections
        'X'     => []
    );
    # Construct encode_map in the form expected by Atom.
    my %em =
    (
        'pos' => { 'verb' => { 'verbtype' => { 'aux' => 'AUX',
                                               '@'   => 'VERB' }},
                   'noun' => { 'prontype' => { ''  => { 'nountype' => { 'prop' => 'PNOUN',
                                                                        '@'    => 'NOUN' }},
                                               '@' => 'PRON' }},
                   'adj'  => { 'adjtype' => { 'pdt' => 'DET',
                                              '@'   => { 'prontype' => { ''  => 'ADJ',
                                                                         '@' => 'DET' }}}},
                   'adv'  => 'ADV',
                   'adp'  => 'ADP',
                   'conj' => 'CONJ',
                   'num'  => 'NUM',
                   'part' => 'PRT',
                   'punc' => '.',
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
    $fs->set_tagset('mul::google');
    return $fs;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::MUL::Google - Driver for the Google Universal Part-of-Speech Tagset.

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::MUL::Google;
  my $driver = Lingua::Interset::Tagset::MUL::Google->new();
  my $fs = $driver->decode('NOUN');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('mul::google', 'NOUN');

=head1 DESCRIPTION

Interset driver for the Google Universal Part-of-Speech Tagset
in its first published version, see

Slav Petrov, Dipanjan Das and Ryan McDonald:
A Universal Part-of-Speech Tagset.
In: Proceedings of LREC 2012
(L<http://www.lrec-conf.org/proceedings/lrec2012/summaries/274.html>).

For more resources on the tagset see
L<http://code.google.com/p/universal-pos-tags/>.

=head1 SEE ALSO

L<Lingua::Interset>
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::MUL::Upos>,
L<Lingua::Interset::Atom>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
