# ABSTRACT: Driver for the English tagset of the CoNLL 2007 Shared Task.
# Copyright © 2007, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::EN::Conll;
use strict;
use warnings;
our $VERSION = '3.015';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::EN::Penn';



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $penn = _conll_to_penn($tag);
    my $fs = $self->SUPER::decode($penn);
    # Here we could set $fs->set_tagset('en::conll') but we will not so that all
    # the descendants of en::penn can share the same feature structures.
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $tag = $self->SUPER::encode($fs);
    return _penn_to_conll($tag);
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = $self->SUPER::list();
    my @list = map {_penn_to_conll($_)} (@{$list});
    return \@list;
}



#------------------------------------------------------------------------------
# CoNLL tagsets in Interset are traditionally three values separated by tabs.
# The values come from the CoNLL columns CPOS, POS and FEAT. For English,
# these values are trivially derived from the tagset of the Penn Treebank.
# This function translates Penn tags to CoNLL.
#------------------------------------------------------------------------------
sub _penn_to_conll
{
    my $penn = shift;
    if($penn eq '-LRB-')
    {
        $penn = '(';
    }
    elsif($penn eq '-RRB-')
    {
        $penn = ')';
    }
    my $penn2 = substr($penn, 0, 2);
    my $conll = "$penn2\t$penn\t_";
    return $conll;
}



#------------------------------------------------------------------------------
# This function translates CoNLL tags to Penn.
#------------------------------------------------------------------------------
sub _conll_to_penn
{
    my $conll = shift;
    # Do not die if you see bad input! This is not our problem. Decoders typically digest anything.
    my $penn = $conll;
    my @columns = split(/\t/, $conll);
    if(scalar(@columns)==3)
    {
        $penn = $columns[1];
        if($penn eq '(')
        {
            $penn = '-LRB-';
        }
        elsif($penn eq ')')
        {
            $penn = '-RRB-';
        }
    }
    return $penn;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::EN::Conll - Driver for the English tagset of the CoNLL 2007 Shared Task.

=head1 VERSION

version 3.015

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::EN::Conll;
  my $driver = Lingua::Interset::Tagset::EN::Conll->new();
  my $fs = $driver->decode("NN\tNN\t_");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('en::conll', "NN\tNN\t_");

=head1 DESCRIPTION

Interset driver for the English tagset of the CoNLL 2007 Shared Task.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For English,
these values are trivially derived from the tagset of the Penn Treebank.
Thus this driver is only a translation layer above the C<en::penn> driver.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::EN::Penn>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
