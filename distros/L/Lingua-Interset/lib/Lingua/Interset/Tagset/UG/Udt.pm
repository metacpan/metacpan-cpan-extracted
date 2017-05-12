# ABSTRACT: Driver for the tagset of the Uyghur Dependency Treebank.
# Copyright © 2016 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::UG::Udt;
use strict;
use warnings;
our $VERSION = '3.004';

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
    return 'ug::udt';
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
        # Some help with Uyghur parts of speech but not the same tagset:
        # http://www.aclweb.org/anthology/Y03-1025
        # noun / isim ئىسىم
        'N'  => ['pos' => 'noun'],
        # verb / pë'il پېئىل
        'V'  => ['pos' => 'verb'],
        # adjective / süpet سۈپەت
        'A'  => ['pos' => 'adj'],
        # verbal adjective / lewzan / söz-herp سۆز-ھەرپ
        'LW' => ['pos' => 'adj', 'verbform' => 'part'],
        # pronoun / almash ئالماش
        'P'  => ['pos' => 'noun', 'prontype' => 'prn'],
        # quantifier / miqtar söz مىقدار سۆز
        'Q'  => ['pos' => 'adj', 'numtype' => 'card', 'prontype' => 'ind'],
        # numeral / san سان
        'M'  => ['pos' => 'num'],
        # adverb / rewish رەۋىش
        'D'  => ['pos' => 'adv'],
        # postposition / tirkelme تىركەلمە
        'R'  => ['pos' => 'adp'],
        # conjunction / baghlighuchi باغلىغۇچى
        'C'  => ['pos' => 'conj'],
        # particle / yüklime يۈكلىمە (e.g. the question particle "mu", or "too")
        'T'  => ['pos' => 'part'],
        # exclamation / imliq söz ئىملىق سۆز / ündesh # uff, wow, cool
        'E'  => ['pos' => 'int', 'other' => {'pos' => 'exclamation'}],
        # onomatopoeia / imitative word / teqlid söz تەقلىد سۆز # nock nock (on the door) etc.
        'I'  => ['pos' => 'int', 'other' => {'pos' => 'onomatopoeia'}],
        # extra / surplus / residual / qoshumche قوشۇمچە
        'X'  => [],
        # punctuation / tinish belgiliri تىنىش بەلگىلىرى
        'Y'  => ['pos' => 'punc']
    );
    # Construct encode_map in the form expected by Atom.
    my %em =
    (
        'pos' => { 'noun' => { 'prontype' => { ''  => 'N',
                                               '@' => 'P' }},
                   'verb' => 'V',
                   'adj'  => { 'verbform' => { 'part' => 'LW',
                                               '@'    => { 'prontype' => { ''  => 'A',
                                                                           '@' => 'Q' }}}},
                   'num'  => 'M',
                   'adv'  => 'D',
                   'adp'  => 'R',
                   'conj' => 'C',
                   'part' => 'T',
                   'int'  => { 'other/pos' => { 'exclamation' => 'E',
                                                '@'           => 'I' }},
                   'punc' => 'Y',
                   '@'    => 'X' }
    );
    # Now add the references to the attribute hash.
    $attr->{surfeature} = 'pos';
    $attr->{decode_map} = \%dm;
    $attr->{encode_map} = \%em;
    $attr->{tagset}     = 'ug::udt';
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
    $fs->set_tagset('ug::udt');
    return $fs;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::UG::Udt - Driver for the tagset of the Uyghur Dependency Treebank.

=head1 VERSION

version 3.004

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::UG::Udt;
  my $driver = Lingua::Interset::Tagset::UG::Udt->new();
  my $fs = $driver->decode('N');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('ug::udt', 'N');

=head1 DESCRIPTION

Interset driver for the part-of-speech tagset of the Uyghur Dependency Treebank.

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
