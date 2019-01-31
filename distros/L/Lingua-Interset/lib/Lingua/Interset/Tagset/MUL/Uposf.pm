# ABSTRACT: Driver for the Universal Part-of-Speech Tagset + Universal Features, version 2014-10-01, part of Universal Dependencies.
# http://universaldependencies.github.io/docs/
# Copyright © 2014, 2015 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::MUL::Uposf;
use strict;
use warnings;
our $VERSION = '3.014';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
use Lingua::Interset::FeatureStructure;
extends 'Lingua::Interset::Tagset';



has 'upos_driver' => ( isa => 'Lingua::Interset::Tagset::MUL::Upos', is => 'ro', default => sub { new Lingua::Interset::Tagset::MUL::Upos } );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'mul::uposf';
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    # There are two parts separated by a tabulator: part-of-speech tag and features.
    my ($pos, $features) = split(/\t/, $tag);
    my $fs = $self->upos_driver()->decode($pos);
    $fs->set_tagset('mul::uposf');
    if(defined($features) && $features ne '' && $features ne '_')
    {
        my @features = split(/\|/, $features);
        $fs->add_ufeatures(@features);
    }
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $pos = $self->upos_driver()->encode($fs);
    my @features = $fs->get_ufeatures();
    my $tag;
    if(@features)
    {
        $tag = "$pos\t".join('|', @features);
    }
    else
    {
        $tag = "$pos\t_";
    }
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# We return the list of the universal part-of-speech tags, without features.
# In future we may want to add all combinations of features observed in corpora
# of various languages.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = $self->upos_driver()->list();
    my @list = map {$_ eq 'NUM' ? "NUM\tNumType=Card" : "$_\t_"} (@{$list});
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::MUL::Uposf - Driver for the Universal Part-of-Speech Tagset + Universal Features, version 2014-10-01, part of Universal Dependencies.

=head1 VERSION

version 3.014

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::MUL::Uposf;
  my $driver = Lingua::Interset::Tagset::MUL::Uposf->new();
  my $fs = $driver->decode("NOUN\tCase=Nom|Gender=Masc|Number=Sing");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('mul::uposf', "NOUN\tCase=Nom|Gender=Masc|Number=Sing");

=head1 DESCRIPTION

Interset driver for the Universal Part-of-Speech Tagset + Universal Features
as of its extended version for the Universal Dependencies (2014-10-01),
see L<http://universaldependencies.github.io/docs/>.

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
