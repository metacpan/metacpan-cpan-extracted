# ABSTRACT: Driver for the tagset of the Swedish treebank from the CoNLL 2006 Shared Task (Talbanken / Mamba).
# Copyright © 2006, 2015 Dan Zeman <zeman@ufal.mff.cuni.cz>
# 25.1.2015: moved to the new object-oriented Interset

package Lingua::Interset::Tagset::SV::Conll;
use strict;
use warnings;
our $VERSION = '3.004';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::SV::Mamba';



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure. In addition to Atom, we just need to identify the tagset of
# origin.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    $tag =~ s/\t.*//;
    my $fs = $self->SUPER::decode($tag);
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature hash.
# Returns tag string.
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $tag = $self->SUPER::encode($fs);
    return "$tag\t$tag\t_";
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# cat otrain.conll etest.conll | perl -pe '@x = split(/\s+/, $_); $_ = "$x[3]\n"' | sort -u | wc -l
# 42
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = $self->SUPER::list();
    my @list = map {"$_\t$_\t_"} @{$list};
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::SV::Conll - Driver for the tagset of the Swedish treebank from the CoNLL 2006 Shared Task (Talbanken / Mamba).

=head1 VERSION

version 3.004

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::SV::Conll;
  my $driver = Lingua::Interset::Tagset::SV::Conll->new();
  my $fs = $driver->decode("NN\tNN\t_");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('sv::conll', "NN\tNN\t_");

=head1 DESCRIPTION

Interset driver for the tagset of the Swedish treebank (Talbanken) from the CoNLL 2006 Shared Task.
It was derived from the two-letter tags of the Mamba tagset.
The sv::conll driver only handles a slight change in formatting.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT.

=head1 SEE ALSO

L<Lingua::Interset>
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::SV::Mamba>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
