# ABSTRACT: The root class for all physical tagsets covered by DZ Interset 2.0.
# Copyright © 2012, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset;
use strict;
use warnings;
our $VERSION = '3.006';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
use MooseX::SemiAffordanceAccessor; # attribute x is written using set_x($value) and read using x()
use Lingua::Interset::FeatureStructure;
use Lingua::Interset::Trie;
use Lingua::Interset::Atom;
use Lingua::Interset::SimpleAtom;



has 'permitted_structures' => ( isa => 'Lingua::Interset::Trie', is => 'ro', builder => '_build_permitted_structures', lazy => 1 );
has 'permitted_values' => ( isa => 'HashRef', is => 'ro', builder => '_build_permitted_values', lazy => 1 );



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    confess("The get_tagset_id() method has not been redefined in a class derived from Lingua::Interset::Tagset");
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    confess('Not implemented. A derived class must provide implementation of the decode() method');
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    confess('Not implemented. A derived class must provide implementation of the encode() method');
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
# Unlike encode(), this method ensures that the result is a known tag of the
# target tagset. Positional tagsets allow in principle encoding feature-value
# combination that never occur in the original corpus but may make sense when
# converted from another tagset. Strict encoding can block this if desired.
# Note however, that using strict encoding may result in unnecessary loss or
# bias of information. For example, Interset says that it's the third person
# but strict encoding may realize that only first or second persons occur with
# the combination of values that have been processed before: then you will get
# the first person on the output!
#------------------------------------------------------------------------------
sub encode_strict
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    confess('Undefined Interset feature structure') if(!defined($fs));
    # We are going to damage the feature structure so we should make its copy first.
    # The caller may still need the original structure!
    my $fs1 = $fs->duplicate();
    my $permitted = $self->permitted_structures();
    $fs1->enforce_permitted_values($permitted);
    return $self->encode($fs1);
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    confess('Not implemented. A derived class must provide implementation of the list() method');
}



#------------------------------------------------------------------------------
# Creates an atomic driver and returns it. Derived classes may want to use
# atoms to define decoding and encoding of individual surface features.
#------------------------------------------------------------------------------
sub create_atom
{
    my $self = shift;
    my @parameters = (@_, 'tagset' => $self->get_tagset_id());
    my $atom = Lingua::Interset::Atom->new(@parameters);
    return $atom;
}



#------------------------------------------------------------------------------
# Creates a simple atomic driver and returns it. Derived classes may want to use
# atoms to define decoding and encoding of individual surface features.
#------------------------------------------------------------------------------
sub create_simple_atom
{
    my $self = shift;
    my @parameters = (@_, 'tagset' => $self->get_tagset_id());
    my $atom = Lingua::Interset::SimpleAtom->new(@parameters);
    return $atom;
}



#------------------------------------------------------------------------------
# Creates and returns an atomic driver with an empty encoding map and a huge
# decoding map that is a merger of decoding maps from other atomic drivers.
# Derived classes may want to use atoms to define decoding and encoding of
# individual surface features. If the feature values appear without feature
# names in the tags, we may need a huge decoding map for all the features, and
# many small encoding maps for individual features. It is advantageous to
# define the small atoms (both for decoding and encoding) and then merge them
# automatically and get the big decoding map.
#------------------------------------------------------------------------------
sub create_merged_atom
{
    my $self = shift;
    my @parameters = @_;
    my %parameters = @parameters;
    confess("The 'atoms' parameter is required") unless(defined($parameters{atoms}));
    unless(defined($parameters{surfeature}))
    {
        $parameters{surfeature} = 'feature';
    }
    unless(defined($parameters{decode_map}))
    {
        $parameters{decode_map} = {};
    }
    unless(defined($parameters{encode_map}))
    {
        # The encoding map cannot be empty even if we are not going to use it.
        $parameters{encode_map} = { 'pos' => {} };
    }
    my $atom = $self->create_atom(%parameters);
    if(defined($parameters{atoms}))
    {
        $atom->merge_atoms(@{$parameters{atoms}});
    }
    return $atom;
}



###############################################################################
# COLLECTING PERMITTED FEATURE VALUES OF A TAGSET
###############################################################################



#------------------------------------------------------------------------------
# Filters a list of tags so that the resulting list contains only tags that
# can result from conversion from a different tagset. These tags do not depend
# on the 'other' feature. It is not to say that decoding them necessarily
# leaves the feature empty. However, these tags are default with respect to the
# feature, so if the feature is not available, encoder picks the default tag.
#
# Note that it is not guaranteed that the resulting list is a subset of the
# original list. It is possible, though undesirable, that decode -> strip other
# -> encode creates an unknown tag.
#------------------------------------------------------------------------------
sub list_other_resistant_tags
{
    my $self = shift;
    my $list0 = shift; # reference to array
    my $decode = shift; # reference to driver-specific decoding function
    my $encode = shift; # reference to driver-specific encoding function
    my %result;
    foreach my $tag0 (@{$list0})
    {
        my $fs = $self->decode($tag0);
        $fs->set_other('');
        my $tag1 = $self->encode($fs);
        $result{$tag1}++;
    }
    my @list1 = sort(keys(%result));
    return \@list1;
}



#------------------------------------------------------------------------------
# Creates the trie description of all permitted feature structures (Lingua::
# Interset::Trie) and returns a reference to it. The trie is constructed lazily
# on the first demand. The builder reads the list of known tags, decodes each
# tag, converts all array values to scalars (by sorting and joining them) and
# remembers permitted feature structures in the trie.
#------------------------------------------------------------------------------
sub _build_permitted_structures
{
    my $self = shift;
    my $no_other = shift; ###!!!
    # This is a lazy attribute and the builder can be called anytime, even
    # from map() or grep(). Avoid damaging the caller's $_!
    local $_;
    my $list = $self->list();
    # Make sure that the list of possible tags is not empty.
    # If it is, the driver's list() function is probably not implemented.
    unless(scalar(@{$list}))
    {
        confess('Cannot figure out the permitted values because the list of possible tags is empty');
    }
    my @features = Lingua::Interset::FeatureStructure::priority_features();
    my $trie = Lingua::Interset::Trie->new('features' => \@features);
    foreach my $tag (@{$list})
    {
        my $fs = $self->decode($tag);
        # If required, skip tags that set the 'other' feature.
        ###!!! Alternatively, we need not skip the tag.
        ###!!! Instead, strip the 'other' information, make sure that we have a valid tag (by encoding and decoding once more),
        ###!!! then add feature values to the tree.
        next if($no_other && $fs->other());
        # Loop over known features (in the order of feature priority).
        my $pointer = $trie->root_hash();
        foreach my $f (@features)
        {
            # Make sure the value is not an array.
            my $v = $fs->get_joined($f);
            # Supply tag only if this is the last feature in the list.
            my $t = $f eq $features[$#features] ? $tag : undef;
            $pointer = $trie->add_value($pointer, $v, $t);
        }
    }
    return $trie;
}



#------------------------------------------------------------------------------
# Creates a hash of permitted feature values for this tagset:
# ($hash{$feature}{$value} != 0) => tagset permits $value of $feature
# Note that a value that is permitted in one context may not be permitted in
# another. Unlike in permitted_structures, this hash just ignores context.
# The builder reads a list of tags, decodes each tag and remembers occurrences
# of feature values in the hash. It returns a reference to the hash.
#------------------------------------------------------------------------------
sub _build_permitted_values
{
    my $self = shift;
    # This is a lazy attribute and the builder can be called anytime, even
    # from map() or grep(). Avoid damaging the caller's $_!
    local $_;
    my $list = $self->list();
    # Make sure that the list of possible tags is not empty.
    # If it is, probably the driver's list() function is not implemented.
    unless(defined($list) && scalar(@{$list}))
    {
        confess('Cannot figure out the permitted values because the list of possible tags is empty');
    }
    my @features = Lingua::Interset::FeatureStructure::priority_features();
    my %values;
    foreach my $tag (@{$list})
    {
        my $fs = $self->decode($tag);
        foreach my $f (@features)
        {
            # Make sure the value is always a list of values.
            my @v = $fs->get_list($f);
            foreach my $v (@v)
            {
                $values{$f}{$v}++;
            }
        }
    }
    return \%values;
}



###############################################################################
# TESTING AND DEBUGGING THE DRIVER
###############################################################################



#------------------------------------------------------------------------------
# Tells whether a tag is known to this tagset driver in the sense that it is
# returned by the list() method. Being an unknown tag does not mean that it
# cannot be decoded!
#------------------------------------------------------------------------------
sub is_known_tag
{
    my $self = shift;
    my $tag = shift;
    ###!!! This test would be faster if we had a hash of known tags.
    ###!!! (It will only matter for large tagsets if they are queried many times.)
    ###!!! We could create a hash when this method is invoked the first time.
    ###!!! Then we would keep it as a cache.
    my $list = $self->list();
    my $ok = grep {$_ eq $tag} (@{$list});
    return $ok;
}



#------------------------------------------------------------------------------
# Tests processing a particular tag (presumably a known one, from the list()
# method). Checks that decoding the tag sets only known features and values
# and that no information gets lost when we encode the feature structure again.
#------------------------------------------------------------------------------
sub test_tag
{
    my $self = shift;
    my $tag = shift;
    # Optional reference to the variable where we count tags that set 'other'.
    my $n_other = shift;
    # Optional reference to the hash where we collect tags that survive removing the value of 'other'.
    my $other_survivors = shift;
    my @errors;
    my $n_errors = 0;
    # Decode the tag and create the Interset feature structure.
    my $f = $self->decode($tag);
    my $sfs = $f->as_string();
    if($f->other() ne '')
    {
        ${$n_other}++;
        # Non-empty other should be always accompanied by a non-empty tagset.
        # (Actually we expect tagset to be never empty. But it is really needed only if the other feature is set.)
        if($f->tagset() eq '')
        {
            my $message = "Error: nonempty other without specifying the source tagset\n";
            $message .= " src = \"$tag\"\n";
            $message .= " sfs = $sfs\n";
            push(@errors, $message);
            $n_errors++;
        }
    }
    # Test that encode(decode(tag))=tag (reproducibility).
    my $tag1 = $self->encode($f);
    if($tag1 ne $tag)
    {
        my $message = "Error: encode(decode(x)) != x\n";
        $message .= " src = \"$tag\"\n";
        $message .= " tgt = \"$tag1\"\n";
        $message .= " sfs = $sfs\n";
        push(@errors, $message);
        $n_errors++;
    }
    # Decoding a tag, removing information stored in the 'other' feature and
    # encoding should render a known tag (a default one if the original tag cannot
    # be completely restored because of the missing information). This is important
    # for figuring out the permitted feature combinations when converting from a
    # different tagset.
    $f->set_tagset('');
    $f->set_other('');
    my $tag2 = $self->encode($f);
    # Is the resulting tag known?
    if(!$self->is_known_tag($tag2))
    {
        my $sfs2 = $f->as_string();
        my $message = "Error: encode(decode(x)-other) gives an unknown tag\n";
        $message .= " src = \"$tag\"\n";
        $message .= " tgt = \"$tag2\"\n";
        $message .= " sfo = $sfs\n";
        $message .= " sfs = $sfs2\n";
        push(@errors, $message);
        $n_errors++;
    }
    elsif(defined($other_survivors))
    {
        $other_survivors->{$tag2}++;
    }
    return @errors;
}



#------------------------------------------------------------------------------
# Takes all tags in the tagset and tests their processing by the driver.
# Returns a list of printable error messages. An empty list means the test was
# passed successfully.
#------------------------------------------------------------------------------
sub test
{
    my $self = shift;
    my $list = $self->list();
    my @errors;
    foreach my $tag (@{$list})
    {
        my @tag_errors = $self->test_tag($tag);
        push(@errors, @tag_errors) if(@tag_errors);
    }
    return @errors;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset - The root class for all physical tagsets covered by DZ Interset 2.0.

=head1 VERSION

version 3.006

=head1 SYNOPSIS

  package Lingua::Interset::MY::Tagset;
  use Moose;
  extends 'Lingua::Interset::Tagset';
  use Lingua::Interset::FeatureStructure;

  sub decode
  {
      my $self = shift;
      my $tag = shift;
      my $fs = Lingua::Interset::FeatureStructure->new();
      ...
      return $fs;
  }

  sub encode
  {
      my $self = shift;
      my $fs = shift; # Lingua::Interset::FeatureStructure
      my $tag;
      ...
      return $tag;
  }

  sub list
  {
      my $self = shift;
      return ['NOUN', 'VERB', 'OTHER'];
  }

  1;

=head1 DESCRIPTION

DZ Interset is a universal framework for reading, writing, converting and
interpreting part-of-speech and morphosyntactic tags from multiple tagsets
of many different natural languages.

The C<Tagset> class is the inheritance root for all classes describing
physical tagsets (sets of strings of characters). It defines decoding of tags, encoding
and list of known tags.

=head1 ATTRIBUTES

=head2 permitted_structures

A L<Lingua::Interset::Trie> object that represents all feature structures
permitted by this tagset. These are structures that result from decoding
one of the I<known tags> returned by the C<list()> method.

This data structure is used to implement strict encoding (see the C<encode_strict()> method).

=head2 permitted_values

Reference to a hash that contains all feature values set by the C<decode()> method
for at least one of the I<known tags>.
If the tagset permits C<$value> of C<$feature>, then

  $driver->permitted_values->{$feature}{$value} != 0

Note that a value that is permitted in one context may not be permitted in
another.
(For example, I<plural number> could be allowed for a I<noun> but not for an I<adverb>.)
Unlike in C<permitted_structures>, this hash just ignores context.

=head1 METHODS

=head2 get_tagset_id()

Returns the tagset id that should be set as the value of the 'tagset' feature
during decoding. Every derived class must implement this method, even though
the derived class is also responsible for setting the value in its C<decode()>
method.

The ID should correspond to the last two parts in package name, lowercased.
Specifically, it should be the ISO 639-2 language, followed by C<::>
and a language-specific tagset ID. Example: C<cs::multext>.

=head2 decode()

  my $fs  = $driver->decode ($tag);

Takes a tag (string) and returns a L<Lingua::Interset::FeatureStructure> object
with corresponding feature values set.

Every derived class must implement this method.
The C<Tagset> class contains an empty implementation,
which will throw an exception if inherited and called.

=head2 encode()

  my $tag = $driver->encode ($fs);

Takes a L<Lingua::Interset::FeatureStructure> object and
returns the tag (string) in the given tagset that corresponds to the feature values.
Note that some features may be ignored because they cannot be represented
in the given tagset.

Every derived class must implement this method.
The C<Tagset> class contains an empty implementation,
which will throw an exception if inherited and called.

=head2 encode_strict()

  my $tag = $driver->encode_strict ($fs);

Takes a feature structure (L<Lingua::Interset::FeatureStructure>) and
returns a tag that matches the contents of the feature structure.

Unlike C<encode()>, C<encode_strict()> always returns a I<known tag>, i.e.
one that is returned by the C<list()> method of the Tagset object. Many tagsets
consist of I<structured> tags, i.e. they can be defined as a compact representation
of a feature structure (a set of attribute-value pairs). It is in principle possible
to encode such combinations of features and values that did not appear in the original
tagset. For example, a tagset for Czech is unlikely to contain a tag saying that
a word is preposition and at the same time setting non-empty value for gender.
Yet it is possible to create such a tag because the tagset encodes part of speech
and gender independently.

If this is undesirable behavior, the application should call C<encode_strict()>
instead of C<encode()>. Then it will be guaranteed that the resulting tag is one
of those returned by C<list()>. Nevertheless, think twice whether you really need
the guarantee, as it does not come for free. The necessity to replace forbidden
feature values by permitted ones may sometimes lead to surprising or confusing
results.

This method is implemented directly within the C<Tagset> class,
relying on custom implementations of C<list()>, C<decode()> and C<encode()>.

=head2 list()

  my $list_of_tags = $driver->list();

Returns the reference to the list of all known tags in this particular tagset.
This is not directly needed to decode, encode or convert tags but it is very useful
for testing and advanced operations over the tagset.
Note however that many tagset drivers contain only an approximate list,
created by collecting tag occurrences in some corpus.

Every derived class must implement this method.
The C<Tagset> class contains an empty implementation,
which will throw an exception if inherited and called.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::FeatureStructure>,
L<Lingua::Interset::Trie>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
