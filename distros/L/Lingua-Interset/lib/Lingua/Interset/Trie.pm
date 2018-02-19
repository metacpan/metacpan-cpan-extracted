# ABSTRACT: A trie-like structure for DZ Interset features and their values.
# Copyright © 2012, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Trie;
use strict;
use warnings;
our $VERSION = '3.011';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
use MooseX::SemiAffordanceAccessor; # attribute x is written using set_x($value) and read using x()
use Carp;



has 'root_hash' => ( isa => 'HashRef',  is => 'rw', default => sub {{}} );
has 'features'  => ( isa => 'ArrayRef', is => 'rw', required => 1 );



#------------------------------------------------------------------------------
# Adds a feature value to the trie.
#------------------------------------------------------------------------------
sub add_value
{
    my $self = shift;
    my $pointer = shift; # hash reference
    my $value = shift;
    my $tag = shift; # tag example; only for the last feature
    if(!exists($pointer->{$value}))
    {
        # Last feature (last level of the trie) stores tag examples instead of pointers.
        if(defined($tag) && $tag ne '')
        {
            $pointer->{$value} = $tag;
        }
        else
        {
            my %new_sub_hash;
            $pointer->{$value} = \%new_sub_hash;
        }
    }
    return $pointer->{$value};
}



#------------------------------------------------------------------------------
# Advances a trie pointer.
#------------------------------------------------------------------------------
sub advance_pointer
{
    my $self = shift;
    my $pointer = shift;
    my $feature = shift;
    my $value = shift;
    if($feature =~ m/^(tagset|other)$/)
    {
        my @keys = keys(%{$pointer});
        $value = $keys[0];
    }
    else
    {
        if(ref($value) eq 'ARRAY')
        {
            $value = join('|', @{$value});
        }
        if(!exists($pointer->{$value}))
        {
            confess("Dead trie pointer.");
        }
    }
    return $pointer->{$value};
}



#------------------------------------------------------------------------------
# Returns permitted feature values in a form suitable for printing. This may be
# useful for debugging.
#------------------------------------------------------------------------------
sub as_string
{
    my $self = shift;
    my $fs = new Lingua::Interset::FeatureStructure();
    return $self->_get_permitted_combinations_as_text_recursion($fs, 0, $self->root_hash());
}



#------------------------------------------------------------------------------
# Recursive part of printing permitted feature value combinations.
#------------------------------------------------------------------------------
sub _get_permitted_combinations_as_text_recursion
{
    my $self = shift;
    my $fs0 = shift; # Lingua::Interset::FeatureStructure
    my $i = shift; # index of the next feature to process
    my $pointer = shift; # reference to the current hash in the trie
    my @features = @{$self->features()};
    return if($i>$#features);
    my $string;
    # Loop through permitted values of the next feature.
    my @values = sort(keys(%{$pointer}));
    foreach my $value (@values)
    {
        # Add the value of the next feature to the feature structure.
        my $fs1 = $fs0->duplicate();
        $fs1->set($features[$i], $value);
        # If this is the last feature, print the feature structure.
        if($i==$#features)
        {
            $string .= $fs1->as_string()."\n";
        }
        # Otherwise, go to the next feature.
        else
        {
            $string .= $self->_get_permitted_combinations_as_text_recursion($fs1, $i+1, $pointer->{$value});
        }
    }
    return $string;
}



#------------------------------------------------------------------------------
# If a feature structure is permitted, returns an example of a known tag that
# generates the same feature structure. Otherwise returns an empty string.
#------------------------------------------------------------------------------
sub get_tag_example
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my @features = @{$self->features()};
    my $pointer = $self->root_hash();
    foreach my $feature (@features)
    {
        my $value = $fs->get_joined($feature);
        # advance_pointer() will die if we supply a forbidden feature value so we must check it here.
        if(exists($pointer->{$value}) || $feature =~ m/^(tagset|other)$/)
        {
            $pointer = $self->advance_pointer($pointer, $feature, $value);
        }
        else
        {
            return "Forbidden value $value of feature $feature";
        }
    }
    # The last hash in the trie (the one for the last feature) points to examples of tags.
    # Thus if we are here, our $pointer is no longer a hash reference but a scalar string.
    return $pointer;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Trie - A trie-like structure for DZ Interset features and their values.

=head1 VERSION

version 3.011

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::EN::Penn;

  my $ts = Lingua::Interset::Tagset::EN::Penn->new();
  # Get a Lingua::Interset::Trie object $permitted and print all feature structures
  # that the tagset en::penn can generate.
  my $permitted = $ts->permitted_structures();
  print($permitted->as_string(), "----------\n");

=head1 DESCRIPTION

The C<Trie> class defines a trie-like data structure for DZ Interset features
and their values. It is an auxiliary data structure that an outside user should
not need to use directly.

It is used to describe all feature-value combinations that
are permitted under a given tagset. (Example: If the prefix already traversed
in the trie indicates that we have a noun, with subtype of proper noun, what
are the possible values of the next feature, say, gender?)

The trie assumes that features are ordered according to their priority.
However, the priorities are defined outside the trie, by default in the
FeatureStructure class, or they may be overriden in a Tagset subclass.
The trie can store features in any order.

=head1 ATTRIBUTES

=head2 features

An array reference. Lists the features in the order in which their values appear
in the trie. This may be the default order according to
C<< Lingua::Interset::FeatureStructure->priority_features() >>,
or a custom order.

=head2 root_hash

The trie structure is implemented as a tree of hashes.
The root hash corresponds to the first feature.
Its keys are values of the feature and each of them leads to a second-level hash.
All second-level hashes correspond to the second feature, their keys are values of that feature etc.
It is interpreted as a sequence of feature queries:
I<If feature F1 has value X, then if feature F2 has value Y, then...>

We need a pointer when traversing the trie,
and the pointer is always a reference to one of the hashes.
The C<root_hash> attribute is our entry pointer where we start the traversal.

=head1 METHODS

=head2 add_value()

  $trie->add_value ($pointer, $value[, $tag_example]);

Adds a feature value to the trie. It does not need to know the feature name.
It takes the feature value and the pointer to the trie level corresponding to
the feature (reference to an existing hash). If the hash already has a key
corresponding to the value, the method only advances to the sub-hash
referenced by the value, and returns the new pointer. If there is no such key,
the method first creates the new sub-hash and then advances the pointer.

For the last feature we can optionally provide an example of a tag where this
combination of feature values occurred. It may be useful for debugging, when
we see a permitted feature structure but do not understand how does it come
that it is permitted.

=head2 advance_pointer()

  $trie->advance_pointer ($pointer, $feature, $value);

Advances a trie pointer.
Normally it observes the value of the current feature;
however, the features C<tagset> and C<other> get special treatment
(any value is permitted).

=head2 as_string()

Returns permitted feature values in a form suitable for printing.
This may be useful for debugging.

=head2 get_tag_example()

  $trie->get_tag_example ($feature_structure);

Takes a L<Lingua::Interset::FeatureStructure> object.
If this is a permitted structure according to the trie,
the method returns the tag example that has been stored in the last-level hash of the trie.

Otherwise it returns an error message.
This is a debugging method and it will not throw exceptions on forbidden values.

=head1 SEE ALSO

L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
