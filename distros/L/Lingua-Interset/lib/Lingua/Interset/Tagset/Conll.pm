# ABSTRACT: Common code for drivers of tagsets from files in CoNLL 2006 format.
# This will be the common ancestor of e.g. BG::Conll and DA::Conll.
# It will not be used for tagsets that are derived from non-Conll tagsets, e.g. CS::Conll and EN::Conll.
# (Most Conll tagsets are derived from non-Conll tagsets but we do not care unless we also have a driver for the non-Conll ancestor.)
# Copyright © 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::Conll;
use strict;
use warnings;
our $VERSION = '3.012';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms'        => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms', lazy => 1 );
has 'features_all' => ( isa => 'ArrayRef', is => 'ro', builder => '_create_features_all', lazy => 1 );
has 'features_pos' => ( isa => 'HashRef', is => 'ro', builder => '_create_features_pos', lazy => 1 );



#------------------------------------------------------------------------------
# These methods must be defined in the derived classes.
#------------------------------------------------------------------------------
sub _create_atoms { confess("The _create_atoms() method must be defined in a class derived from Lingua::Interset::Tagset::Conll"); }
sub _create_features_all { confess("The _create_features_all() method must be defined in a class derived from Lingua::Interset::Tagset::Conll"); }
sub _create_features_pos { confess("The _create_features_pos() method must be defined in a class derived from Lingua::Interset::Tagset::Conll"); }



#------------------------------------------------------------------------------
# Returns the list of surface CoNLL features for a given part of speech.
#------------------------------------------------------------------------------
sub get_feature_names
{
    my $self = shift;
    my $pos = shift;
    my $feature_names_pos = $self->features_pos();
    if(exists($feature_names_pos->{$pos}))
    {
        return $feature_names_pos->{$pos};
    }
    else
    {
        my @dummy = ();
        return \@dummy;
    }
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode_conll
{
    my $self = shift;
    my $tag = shift;
    my $poskey = shift; # pos | subpos | both; subpos is default
    $poskey = 'subpos' if(!defined($poskey));
    my $delimiter = shift; # Feature-value delimiter. Default is '=' but eu::conll has ':' and Hyderabad tagsets have '-'.
    $delimiter = '=' if(!defined($delimiter));
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset($self->get_tagset_id());
    my $atoms = $self->atoms();
    my $feature_names = $self->features_all();
    # Three components: coarse-grained pos, fine-grained pos, features
    # Only features with non-empty values appear in the tag.
    # example: N\nNC\ngender=common|number=sing|case=unmarked|def=indef
    my ($pos, $subpos, $features) = split(/\s+/, $tag);
    $features = '' if($features eq '_');
    my @features_conll = split(/\|/, $features);
    my %features_conll;
    foreach my $f (@features_conll)
    {
        if($f =~ m/^([-\w]+)$delimiter(.+)$/)
        {
            $features_conll{$1} = $2;
        }
        else
        {
            $features_conll{$f} = $f;
        }
    }
    my $posvalue = $poskey eq 'pos' ? $pos : $poskey eq 'both' ? "$pos\t$subpos" : $subpos;
    $atoms->{pos}->decode_and_merge_hard($posvalue, $fs);
    foreach my $name (@{$feature_names})
    {
        if(defined($features_conll{$name}) && $features_conll{$name} ne '')
        {
            $atoms->{$name}->decode_and_merge_hard($features_conll{$name}, $fs);
        }
    }
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
# Encodes only features while the CPOS and POS must have been encoded in
# tagset-specific code.
#------------------------------------------------------------------------------
sub encode_conll
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    # Every CoNLL tagset has a different relation between pos and subpos, so we want them already encoded.
    my $pos = shift;
    my $subpos = shift;
    # The list of feature names may differ for different parts of speech so we want to get a reference to the list.
    my $feature_names = shift;
    # By default, feature names are included (e.g. "gender=masc"). Some CoNLL tagsets contain only values without feature names (e.g. "masc").
    my $value_only = shift;
    my $delimiter = shift; # Feature-value delimiter. Default is '=' but eu::conll has ':' and Hyderabad tagsets have '-'.
    $delimiter = '=' if(!defined($delimiter));
    my $atoms = $self->atoms();
    my @features;
    foreach my $name (@{$feature_names})
    {
        # Sanity check: did we define atoms for all features?
        confess("Undefined atom for feature $name") if(!defined($atoms->{$name}));
        my $value = $atoms->{$name}->encode($fs);
        if($value ne '')
        {
            # Value adjustments tailored for this physical tagset would come here.
            if($value_only)
            {
                push(@features, $value);
            }
            else
            {
                push(@features, $name.$delimiter.$value);
            }
        }
    }
    my $features = '_';
    if(scalar(@features) > 0)
    {
        $features = join('|', @features);
    }
    my $tag = "$pos\t$subpos\t$features";
    return $tag;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::Conll - Common code for drivers of tagsets from files in CoNLL 2006 format.

=head1 VERSION

version 3.012

=head1 DESCRIPTION

Common code for drivers of tagsets from files in the CoNLL 2006 format.
These tags always consists of three tab-separated parts:
C<pos> (from the CoNLL C<CPOS> column),
C<subpos> (from the CoNLL C<POS> column), and
C<features> (from the CoNLL C<FEATS> column).
Features are always separated by a vertical bar.
The values of C<CPOS>, C<POS> and features differ across tagsets/treebanks.
Nevertheless, there is some minimal code that repeats for every CoNLL tagset.
This module provides the code and is thus intended as a common predecessor of
the language-specific CoNLL drivers.

Most CoNLL tagsets are derived from other pre-existing tagsets that use
a different format. If we have a driver for such pre-existing tagset,
then its CoNLL variant will be probably derived from that driver rather than
from this common CoNLL module.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::AR::Conll>,
L<Lingua::Interset::Tagset::AR::Conll2007>,
L<Lingua::Interset::Tagset::BG::Conll>,
L<Lingua::Interset::Tagset::DA::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
