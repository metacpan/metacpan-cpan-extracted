# ABSTRACT: Driver for the German tagset of the CoNLL 2006 Shared Task.
# Copyright © 2008, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::DE::Conll;
use strict;
use warnings;
our $VERSION = '3.010';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::DE::Stts';



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    # three components: coarse-grained pos, fine-grained pos, features
    # example: NE\tNE\t_
    my ($pos, $subpos, $features) = split(/\s+/, $tag);
    # The CoNLL tagset is derived from the STTS tagset.
    # Coarse-grained POS is the STTS tag.
    # Fine-grained POS is another copy of the STTS tag.
    # Features is an underscore.
    my $fs = $self->SUPER::decode($pos);
    # Here we could set $fs->set_tagset('de::conll') but we will not so that all
    # the descendants of de::stts can share the same feature structures.
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    # The CoNLL tagset is derived from the STTS tagset.
    # Coarse-grained POS is the STTS tag.
    # Fine-grained POS is another copy of the STTS tag.
    # Features is an underscore.
    my $tag = $self->SUPER::encode($fs);
    return "$tag\t$tag\t_";
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = $self->SUPER::list();
    my @list = map {"$_\t$_\t_"} (@{$list});
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::DE::Conll - Driver for the German tagset of the CoNLL 2006 Shared Task.

=head1 VERSION

version 3.010

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::DE::Conll;
  my $driver = Lingua::Interset::Tagset::DE::Conll->new();
  my $fs = $driver->decode("NN\tNN\t_");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('de::conll', "NN\tNN\t_");

=head1 DESCRIPTION

Interset driver for the German tagset of the CoNLL 2006 Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For German,
these values are trivially derived from the Stuttgart-Tübingen Tagset.
Thus this driver is only a translation layer above the C<de::stts> driver.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::DE::Stts>,
L<Lingua::Interset::Tagset::DE::Conll2009>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
