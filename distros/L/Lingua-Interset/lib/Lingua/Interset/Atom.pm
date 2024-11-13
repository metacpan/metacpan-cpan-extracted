# ABSTRACT: Atomic driver for a surface feature.
# Copyright © 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Atom;
use strict;
use warnings;
our $VERSION = '3.016';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
use MooseX::SemiAffordanceAccessor; # attribute x is written using set_x($value) and read using x()
use Lingua::Interset;
use Lingua::Interset::FeatureStructure qw(feature_valid);
extends 'Lingua::Interset::Tagset';



has 'surfeature' => ( isa => 'Str', is => 'ro', required => 1, documentation => 'Name of the surface feature the atom describes.' );
# Example of a decoding map:
# { 'M' => ['gender' => 'masc', 'animateness' => 'anim'],
#   'I' => ['gender' => 'masc', 'animateness' => 'inan'],
#   'F' => ['gender' => 'fem'],
#   'N' => ['gender' => 'neut'] }
has 'decode_map' => ( isa => 'HashRef', is => 'ro', required => 1 );
# Example of an encoding map:
# The top-level hash must have just one key, a name of a known feature (it is a hash for cosmetic reasons).
# '@' denotes the default and will be translated to an else block
# { 'gender' => { 'masc' => { 'animateness' => { 'inan' => 'I',
#                                                '@'    => 'M' }},
#                 'fem'  => 'F',
#                 '@'    => 'N' }}
has 'encode_map' => ( isa => 'HashRef', is => 'ro', required => 1 );
# Atoms are typically used as micro drivers for individual features within drivers for structured tagsets.
# If this is the case, the atom may need to be able to identify the tagset it works for, in order to be able to interpret values of the 'other' feature.
has 'tagset' => ( isa => 'Str', is => 'ro', 'default' => '', documentation => 'Identifier of tagset that this atom is part of. Used when querying the other feature.' );



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = Lingua::Interset::FeatureStructure->new();
    my $map = $self->decode_map();
    $tag = '' if(!defined($tag));
    my $assignments = $map->{$tag};
    if($assignments)
    {
        $fs->add(@{$assignments});
    }
    return $fs;
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and adds the feature values to an existing
# feature structure.
#------------------------------------------------------------------------------
sub decode_and_merge_hard
{
    my $self = shift;
    my $tag = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $fs1 = $self->decode($tag);
    my $hash = $fs1->get_hash();
    # Special behavior is defined if the 'other' feature in both hashes is a hash of subfeatures.
    _merge_other_subhashes($fs->other(), $hash->{other}, $hash);
    $fs->merge_hash_hard($hash);
    return $fs;
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and adds the feature values to an existing
# feature structure.
#------------------------------------------------------------------------------
sub decode_and_merge_soft
{
    my $self = shift;
    my $tag = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $fs1 = $self->decode($tag);
    my $hash = $fs1->get_hash();
    # Special behavior is defined if the 'other' feature in both hashes is a hash of subfeatures.
    _merge_other_subhashes($fs->other(), $hash->{other}, $hash);
    $fs->merge_hash_soft($hash);
    return $fs;
}



#------------------------------------------------------------------------------
# Special merging of the 'other' feature in the case that it is a sub-hash of
# subfeatures.
#------------------------------------------------------------------------------
sub _merge_other_subhashes
{
    my $tgt_other = shift;
    my $src_other = shift;
    my $src_fs_hash = shift; # we will remove other from here after processing its contents
    if(ref($src_other) eq 'HASH' && ref($tgt_other) eq 'HASH')
    {
        my @keys = keys(%{$src_other});
        foreach my $key (@keys)
        {
            # The value is probably a plain scalar but it is not guaranteed, so we must create a deep copy.
            $tgt_other->{$key} = Lingua::Interset::FeatureStructure::_duplicate_recursive($src_other->{$key});
        }
        delete($src_fs_hash->{other});
    }
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $map = $self->encode_map();
    return $self->_encoding_step($map, $fs);
}



#------------------------------------------------------------------------------
# A recursive static function that takes encoding map (hash reference with one
# feature name as the only key) and returns surface tag (string).
#------------------------------------------------------------------------------
sub _encoding_step
{
    my $self = shift;
    my $map = shift; # reference to hash with only one key
    my $fs = shift; # Lingua::Interset::FeatureStructure
    # Example of an encoding map:
    # The top-level hash must have just one key, a name of a known feature (it is a hash for cosmetic reasons).
    # '@' denotes the default and will be translated to an else block
    # { 'gender' => { 'masc' => { 'animateness' => { 'inan' => 'I',
    #                                                '@'    => 'M' }},
    #                 'fem'  => 'F',
    #                 '@'    => 'N' }}
    my @keys = keys(%{$map});
    if(scalar(@keys)==1)
    {
        my $feature = $keys[0];
        my $value;
        if($feature eq 'other')
        {
            my $tagset = $self->tagset();
            if($tagset eq '')
            {
                my $surfeature = $self->surfeature();
                confess("Encoding map (surface feature = '$surfeature') refers to 'other' but the 'tagset' attribute of the atom is empty");
            }
            $value = $fs->get_other_for_tagset($tagset);
        }
        elsif($feature =~ m-^other/(.+)$-)
        {
            my $subfeature = $1;
            my $tagset = $self->tagset();
            if($tagset eq '')
            {
                my $surfeature = $self->surfeature();
                confess("Encoding map (surface feature = '$surfeature') refers to 'other' but the 'tagset' attribute of the atom is empty");
            }
            $value = $fs->get_other_subfeature($tagset, $subfeature);
        }
        elsif(feature_valid($feature))
        {
            $value = $fs->get_joined($feature);
        }
        else
        {
            confess("Unknown feature '$feature'");
        }
        my $valuehash = $map->{$feature};
        my $target = _get_decision_for_value($value, $valuehash); # output string or next-level map
        if(ref($target) eq 'HASH')
        {
            return $self->_encoding_step($target, $fs);
        }
        else
        {
            return $target;
        }
    }
    else
    {
        # Tagset drivers normally do not throw exceptions but if we are here it means we have badly designed code, not input data.
        confess("The feature-level hash in encoding map must have just one key (feature name); instead, we have ".scalar(@keys).": ".join(', ', @keys));
    }
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my %tagset;
    # Collect tags that we are prepared to decode.
    my $dmap = $self->decode_map();
    foreach my $tag (keys(%{$dmap}))
    {
        $tagset{$tag}++;
    }
    # Collect tags reachable through our encoding map.
    # There should not really be any additional tags not known from $dmap.
    # But as a sanity check, we will scan them anyway.
    my $emap = $self->encode_map();
    $self->_list_step($emap, \%tagset);
    my @list = sort(keys(%tagset));
    return \@list;
}



#------------------------------------------------------------------------------
# A recursive static function that takes encoding map (hash reference with one
# feature name as the only key) and a reference to a hash where we collect
# results. It adds all tags reachable via the map to the collection.
#------------------------------------------------------------------------------
sub _list_step
{
    my $self = shift;
    my $map = shift; # reference to hash with only one key
    my $tagset = shift; # reference to hash where we collect surface tags
    # Example of an encoding map:
    # The top-level hash must have just one key, a name of a known feature (it is a hash for cosmetic reasons).
    # '@' denotes the default and will be translated to an else block
    # { 'gender' => { 'masc' => { 'animateness' => { 'inan' => 'I',
    #                                                '@'    => 'M' }},
    #                 'fem'  => 'F',
    #                 '@'    => 'N' }}
    my @keys = keys(%{$map});
    if(scalar(@keys)==1)
    {
        my $feature = $keys[0];
        my $valuehash = $map->{$feature};
        my @values = keys(%{$valuehash});
        foreach my $value (@values)
        {
            my $target = $valuehash->{$value};
            if(ref($target) eq 'HASH')
            {
                $self->_list_step($target, $tagset);
            }
            else
            {
                $tagset->{$target}++;
            }
        }
    }
    else
    {
        # Tagset drivers normally do not throw exceptions but if we are here it means we have badly designed code, not input data.
        confess("The feature-level hash in encoding map must have just one key (feature name); instead, we have ".scalar(@keys).": ".join(', ', @keys));
    }
}



#------------------------------------------------------------------------------
# Takes references to two one-dimensional arrays and returns their intersection
# as a list. If an element occurs more than once in one of the arrays, it will
# occur at most once in the result.
#------------------------------------------------------------------------------
sub intersection
{
    my $a = shift;
    my $b = shift;
    if(ref($a) ne 'ARRAY' || ref($b) ne 'ARRAY')
    {
        confess("Expected two array references as parameters");
    }
    my %bmap;
    foreach my $belement (@{$b})
    {
        $bmap{$belement}++;
    }
    my @intersection;
    my %imap;
    foreach my $aelement (@{$a})
    {
        if(exists($bmap{$aelement}) && !exists($imap{$aelement}))
        {
            push(@intersection, $aelement);
            $imap{$aelement}++;
        }
    }
    return @intersection;
}



#------------------------------------------------------------------------------
# Takes a feature value and a hash indexed by feature values. A value can be a
# list of values separated by vertical bars (e.g. 'masc|fem'). The function
# first tries to find an exact match. If it fails, it takes all hash keys,
# tries to interpret them as lists and find the value in the list (or, if the
# value sought for is also a list, to find the largest intersection of the
# lists). If it still fails, it looks for the hash key '@', which means
# "everything else".
#------------------------------------------------------------------------------
sub _get_decision_for_value
{
    my $value = shift;
    my $valuehash = shift;
    if(exists($valuehash->{$value}))
    {
        return $valuehash->{$value};
    }
    else
    {
        # The sought value could be a list of values.
        # One or more of the hash keys could also be lists of values.
        # If there are multiple matching answers and we must select one, we still want the atom to behave deterministically.
        # Hence we sort the keys (otherwise their order is really random).
        my @keys = sort(keys(%{$valuehash}));
        my $maxn = 0;
        my $maxkey;
        foreach my $key (@keys)
        {
            my @a = split(/\|/, $value);
            my @b = split(/\|/, $key);
            my @i = intersection(\@a, \@b);
            my $n = scalar(@i);
            if($n>$maxn)
            {
                $maxn = $n;
                $maxkey = $key;
            }
        }
        # Did we find anything?
        if(defined($maxkey))
        {
            return $valuehash->{$maxkey};
        }
        # Do we at least have a default decision?
        elsif(exists($valuehash->{'@'}))
        {
            return $valuehash->{'@'};
        }
    }
}



#------------------------------------------------------------------------------
# Takes references to one or more other atoms and merges (adds) their decoding
# maps to our decoding map. Ordering of the atoms matters: if several atoms
# define decoding of the same feature, the first definition will be used and
# the others will be ignored. The atom $self comes first.
#------------------------------------------------------------------------------
sub merge_atoms
{
    my $self = shift;
    my @atoms = @_;
    my $dmap = $self->decode_map();
    foreach my $atom (@atoms)
    {
        my $admap = $atom->decode_map();
        foreach my $key (keys(%{$admap}))
        {
            unless(defined($dmap->{$key}))
            {
                $dmap->{$key} = $admap->{$key};
            }
        }
    }
    return $dmap;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Atom - Atomic driver for a surface feature.

=head1 VERSION

version 3.016

=head1 SYNOPSIS

  use Lingua::Interset::Atom;

  my $atom = Lingua::Interset::Atom->new
  (
      'surfeature'    => 'gender',
      'decode_map' =>

          { 'M' => ['gender' => 'masc', 'animateness' => 'anim'],
            'I' => ['gender' => 'masc', 'animateness' => 'inan'],
            'F' => ['gender' => 'fem'],
            'N' => ['gender' => 'neut'] },

      'encode_map' =>

          { 'gender' => { 'masc' => { 'animateness' => { 'inan' => 'I',
                                                         '@'    => 'M' }},
                          'fem'  => 'F',
                          '@'    => 'N' }}
  );

=head1 DESCRIPTION

Atom is a special case of a tagset driver.
As the name suggests, the surface tags are considered atomic, i.e. indivisible.
It provides environment for easy mapping between surface strings and Interset features.

While Atom can be used to implement drivers of tagsets whose tags are not structured
(such as en::penn or sv::mamba), they should also provide means of defining
“sub-drivers” for individual surface features within drivers of complex tagsets.
For example, the Czech tags in the Prague Dependency Treebank are always strings
of 15 characters where the I<i>-th position in the string encodes the I<i>-th surface feature
(which may or may not directly correspond to a feature in Interset).
A driver for the PDT tagset could internally construct atomic drivers for PDT
gender, number, case etc.

=head1 ATTRIBUTES

=head2 surfeature

Name of the surface feature the atom describes.
If the atom describes a whole tagset, the tagset id could be stored here.
The surface features may be structured differently from Interset,
e.g. there might be an I<agreement> feature, which would map to the Interset features of
C<person> and C<number>.

=head2 decode_map

A compact description of mapping from the surface tags to the Interset feature values.
It is a hash reference.
Hash keys are surface tags.
Hash values are references to arrays of assignments.
The arrays must have even number of elements and every pair of elements is a feature-value pair.

Example:

  { 'M' => ['gender' => 'masc', 'animateness' => 'anim'],
    'I' => ['gender' => 'masc', 'animateness' => 'inan'],
    'F' => ['gender' => 'fem'],
    'N' => ['gender' => 'neut'] }

Vertical bars may be used to separate multiple values of one feature.
The C<other> feature can have a structured value, so you can use standard Perl syntax to describe hash and/or array references.

  { 'name_of_dog' => [ 'pos' => 'noun', 'nountype' => 'prop', 'other' => { 'named_entity_type' => 'dog' } ],
    'wh_word'     => [ 'pos' => 'noun|adj|adv', 'prontype' => 'int|rel' ] }

=head2 encode_map

A compact description of mapping from the Interset feature structure to the surface tags.
It is a hash reference, possibly with nested hashes.
The top-level hash must always have just one key, which is a name of an Interset feature.
(It could be encoded without the hash but I believe that the whole map looks better this way.)

The top-level key leads to a second-level hash, which is indexed by the values of the feature.
It is not necessary that all possible values are listed.
A special value C<@>, if present, means “everything else”.
It is recommended to always mark the default value using C<@>.
Even if we list all currently known values of the feature, new values may be introduced to Interset in future
and we do not want to have to get back to all tagsets and update their encoding maps.
(On the other hand, if there are values that the C<decode()> method of the current atom
does not generate but we still have a preferred output for them, the preference must
be made explicit. For instance, if the language does not have the pluperfect tense,
it may still define that it be encoded the same way as the past tense.)

A feature may have a I<multi-value> (several values joined and separated by vertical
bars). A value (multi- or not) is always first sought using the exact match. If the
search fails, both the current feature value and the keys of the value hash are treated
as lists of values and their largest intersection is sought for. If no overlap is found,
the default C<@> decision is taken.

Example:

  { 'gender' => { 'masc'      => { 'animateness' => { 'inan' => 'I',
                                                      '@'    => 'M' }},
                  'fem|masc'  => 'T',
                  'fem'       => 'F',
                  '@'         => 'N' }}

The C<other> feature, if queried by the map, receives special treatment.
First, the C<tagset> attribute must be filled in and its value is checked against the C<tagset> feature.
The value is only processed if the tagset ids match (otherwise an empty value is assumed).
String values and array values (given as vertical-bar-separated strings) are processed
similarly to normal features.
In addition, it is possible to have a hash of subfeatures stored in C<other>,
and to query them as 'other/subfeature'.

Example:

  { 'other/subfeature1' => { 'x' => 'X',
                             'y' => 'Y',
                             '@' => { 'other/subfeature2' => { '1' => 'S',
                                                               '@' => '' }}}}

The corresponding C<decode_map> would be in this case:

  {
      'X' => ['other' => {'subfeature1' => 'x'}],
      'Y' => ['other' => {'subfeature1' => 'y'}],
      'S' => ['other' => {'subfeature2' => '1'}]
  }

Note that in general it is not possible to automatically derive the C<encode_map> from the C<decode_map>
or vice versa. However, there are simple instances of atoms where this is possible.

=head2 tagset

Optional identifier of the tagset that this atom is part of.
It is required when the encoding map queries values of the C<other> feature
(to check against the C<tagset> feature that the values come from the same tagset).
Default is empty string.

=head1 METHODS

=head2 decode()

  my $fs  = $driver->decode ($tag);

Takes a tag (string) and returns a L<Lingua::Interset::FeatureStructure> object
with corresponding feature values set.

=head2 decode_and_merge_hard()

  my $fs  = $driver1->decode ($tag1);
  $driver2->decode_and_merge_hard ($tag2, $fs);

Takes a tag (string) and a L<Lingua::Interset::FeatureStructure> object.
Adds the feature values corresponding to the tag to the existing feature structure.
Replaces previous values in case of conflict.

=head2 decode_and_merge_soft()

  my $fs  = $driver1->decode ($tag1);
  $driver2->decode_and_merge_soft ($tag2, $fs);

Takes a tag (string) and a L<Lingua::Interset::FeatureStructure> object.
Adds the feature values corresponding to the tag to the existing feature structure.
Merges lists of values in case a feature had already a value set.

=head2 encode()

  my $tag = $driver->encode ($fs);

Takes a L<Lingua::Interset::FeatureStructure> object and
returns the tag (string) in the given tagset that corresponds to the feature values.
Note that some features may be ignored because they cannot be represented
in the given tagset.

=head2 list()

  my $list_of_tags = $driver->list();

Returns the reference to the list of all known tags in this particular tagset.
This is not directly needed to decode, encode or convert tags but it is very useful
for testing and advanced operations over the tagset.
Note however that many tagset drivers contain only an approximate list,
created by collecting tag occurrences in some corpus.

=head2 merge_atoms()

  $atom0->merge($atom1, $atom2, ..., $atomN);

Takes references to one or more other atoms and merges (adds) their decoding
maps to our decoding map. Ordering of the atoms matters: if several atoms
define decoding of the same feature, the first definition will be used and
the others will be ignored. The atom C<$self> comes first.

Note that the I<encoding> map will I<not change>.
This method is useful for tagsets where feature values appear without naming
the feature. For example, instead of

  gender=masc|number=sing|case=nom

the tag only contains

  masc|sing|nom

Such tagsets require asymmetric processing.
There is one big atom that decodes any feature value regardless of which
feature it belongs to. But it does not encode anything.
Then there are many small atoms for individual features.
We cannot use them for decoding because we do not know which atom to pick
until we have decoded the value. But we will use them for encoding because
we know which features and in what order we want to encode for a particular
part of speech.

We could define both the big decoding atom and the small encoding atoms
manually. There is a drawback to it: we would be describing each feature twice
at two different places in the source code. The C<merge_atoms()> method gives
us a better way: we will define the small atoms (both for decoding and
encoding) and then create the big decoding atom by merging the small ones:

  # This code goes in a tagset driver, e.g. Lingua::Interset::Tagset::CS::Mytagset,
  # in a function that builds all necessary atoms, e.g. sub _create_atoms.
  my %atoms;
  $atoms{genderanim} = $self->create_atom
  (
      'surfeature' => 'genderanim',
      'decode_map' =>
      {
          'ma' => ['gender' => 'masc', 'animateness' => 'anim'],
          'mi' => ['gender' => 'masc', 'animateness' => 'inan'],
          'f'  => ['gender' => 'fem'],
          'n'  => ['gender' => 'neut']
      },
      'encode_map' =>
      {
          'gender' => { 'masc' => { 'animateness' => { 'inan' => 'mi',
                                                       '@'    => 'ma' }},
                        'fem'  => 'f',
                        '@'    => 'n' }
      }
  );
  $atoms{number} = $self->create_simple_atom
  (
      'intfeature' => 'number',
      'simple_decode_map' =>
      {
          'sg' => 'sing',
          'pl' => 'plur'
      }
  );
  $atoms{feature} = $self->create_atom
  (
      'surfeature' => 'feature',
      'decode_map' => {},
      'encode_map' => { 'pos' => {} } # The encoding map cannot be empty even if we are not going to use it.
  );
  $atoms{feature}->merge_atoms($atoms{genderanim}, $atoms{number});

=head1 SEE ALSO

L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
