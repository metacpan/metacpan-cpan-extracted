# ABSTRACT: Driver for the tagset of the Czech National Corpus (Český národní korpus).
# Copyright © 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::CS::Cnk;
use strict;
use warnings;
our $VERSION = '3.010';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::CS::Pdt';



#------------------------------------------------------------------------------
# Creates atomic drivers for 12 surface features (11 inherited from Pdt).
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my $atoms = $self->SUPER::_create_atoms();
    # ASPECT ####################
    $atoms->{aspect} = $self->create_atom
    (
        'surfeature' => 'aspect',
        'decode_map' =>
        {
            'I' => ['aspect' => 'imp'],
            'P' => ['aspect' => 'perf'],
            'B' => ['aspect' => 'imp|perf'] # example: nehodí
        },
        'encode_map' =>

            { 'pos' => { 'verb' => { 'aspect' => { 'imp'      => 'I',
                                                   'perf'     => 'P',
                                                   'imp|perf' => 'B',
                                                   '@'        => '-' }},
                         '@'    => '-' }}
    );
    return $atoms;
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $pdt = substr($tag, 0, 15);
    my $aspect = substr($tag, 15, 1);
    my $fs = $self->SUPER::decode($pdt);
    my $atoms = $self->atoms();
    $atoms->{aspect}->decode_and_merge_hard($aspect, $fs);
    # Here we could set $fs->set_tagset('cs::cnk') but we will not so that all
    # the descendants of cs::pdt can share the same feature structures.
    # (The cs::cnk feature structures are not identical to cs::pdt but they do
    # not add their own 'other' values and that matters.)
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $pdt = $self->SUPER::encode($fs);
    my $atoms = $self->atoms();
    my $aspect = $atoms->{aspect}->encode($fs);
    return $pdt.$aspect;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list_pdt = $self->SUPER::list();
    # Add the sixteenth character to every tag.
    # For verbs, it is I, P or B. For everything else, it is -.
    my @list;
    foreach my $tag (@{$list_pdt})
    {
        if($tag =~ m/^V/)
        {
            push(@list, $tag.'B', $tag.'I', $tag.'P');
        }
        else
        {
            push(@list, $tag.'-');
        }
    }
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::CS::Cnk - Driver for the tagset of the Czech National Corpus (Český národní korpus).

=head1 VERSION

version 3.010

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::CS::Cnk;
  my $driver = Lingua::Interset::Tagset::CS::Cnk->new();
  my $fs = $driver->decode('NNMS1-----A-----');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('cs::cnk', 'NNMS1-----A-----');

=head1 DESCRIPTION

Interset driver for the tagset used in the Czech National Corpus (Český národní korpus).
The tagset is a slight modification of the tagset used in the Prague Dependency Treebank
(see L<Lingua::Interset::Tagset::CS::Pdt>). The only difference is a sixteenth character
that encodes aspect of verbs.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::CS::Pdt>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
