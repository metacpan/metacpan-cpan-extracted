# ABSTRACT: Atomic driver for a surface feature.
# Copyright © 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::SimpleAtom;
use strict;
use warnings;
our $VERSION = '3.016';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
use MooseX::SemiAffordanceAccessor; # attribute x is written using set_x($value) and read using x()
use Lingua::Interset;
use Lingua::Interset::FeatureStructure;
extends 'Lingua::Interset::Atom';



has 'intfeature' => ( isa => 'Str', is => 'ro', required => 1, documentation => 'Name of the corresponding Interset feature.' );
# In this special case of Atom, decoding map is taken as a simple hash; Atom::(de|en)code_map will be automatically derived:
# { 1 => 'nom', 2 => 'gen', 3 => 'dat', 4 => 'acc', 5 => 'voc', 6 => 'loc', 7 => 'ins' }
has 'simple_decode_map' => ( isa => 'HashRef', is => 'ro', required => 1 );
# If you want a simple de/encoding table with an additional default encoding rule, e.g. {'@' => '-'}, then set 'encode_default' => '-'.
has 'encode_default' => ( isa => 'Str', is => 'ro', default => '' );



#------------------------------------------------------------------------------
# This block will be called before object construction. It will take the
# simple_decode_map attribute from the user and use it to construct parent class
# decode_map and encode_map. Then it will pass all the attributes to the
# constructor.
#------------------------------------------------------------------------------
around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;
    # Call the default BUILDARGS in Moose::Object. It will take care of distinguishing between a hash reference and a plain hash.
    my $attr = $class->$orig(@_);
    if($attr->{intfeature} && $attr->{simple_decode_map})
    {
        # Construct decode_map in the form expected by Atom.
        my %dm;
        # Construct encode_map in the form expected by Atom.
        my %em;
        # The encode_default attribute has default value '' but it may not have been set yet.
        $attr->{encode_default} = '' if(!defined($attr->{encode_default}));
        my %valuehash = ('@' => $attr->{encode_default});
        $em{$attr->{intfeature}} = \%valuehash;
        my @survalues = keys(%{$attr->{simple_decode_map}});
        foreach my $sv (@survalues)
        {
            my $iv = $attr->{simple_decode_map}{$sv};
            $dm{$sv} = [$attr->{intfeature} => $iv];
            $valuehash{$iv} = $sv;
        }
        # Now add the references to the driver functions to the attribute hash.
        $attr->{surfeature} = $attr->{intfeature};
        $attr->{decode_map} = \%dm;
        $attr->{encode_map} = \%em;
    }
    else
    {
        confess("Missing attribute 'intfeature' or 'simple_decode_map'");
    }
    return $attr;
};



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::SimpleAtom - Atomic driver for a surface feature.

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::SimpleAtom;

  my $atom = Lingua::Interset::SimpleAtom->new
  (
      'intfeature'        => 'case',
      'simple_decode_map' => { 1 => 'nom', 2 => 'gen', 3 => 'dat', 4 => 'acc', 5 => 'voc', 6 => 'loc', 7 => 'ins' }
  );

=head1 DESCRIPTION

SimpleAtom is a special simple case of L<Lingua::Interset::Atom>.
Unlike in general Atom, for SimpleAtom there is an I<injective> function mapping the surface strings to values of just one Interset feature.
This makes defining the decoding and encoding maps much easier.

=head1 ATTRIBUTES

=head2 intfeature

Name of the Interset feature to which the atom maps.

=head2 simple_decode_map

A compact description of mapping from the surface tags to the Interset feature values.
It is a hash reference.
Hash keys are surface tags and hash values are the values of the corresponding Interset feature.

=head2 encode_default

If you want a simple decoding/encoding table with an additional default encoding rule, e.g. C<< {'@' => '-'} >>, then set C<< 'encode_default' => '-' >>.
By default, this attribute is set to the empty string.

=head1 SEE ALSO

L<Lingua::Interset::Atom>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
