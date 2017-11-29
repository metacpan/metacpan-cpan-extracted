# ABSTRACT: A temporary envelope that provides access to the old (Interset 1.0) drivers from Interset 2.0.
# Once all the old drivers are ported to Interset 2.0, this module will be removed.
# Copyright © 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::OldTagsetDriver;
use strict;
use warnings;
our $VERSION = '3.010';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
use Lingua::Interset;
use Lingua::Interset::FeatureStructure;
extends 'Lingua::Interset::Tagset';



has 'driver' => ( isa => 'Str', is => 'ro', required => 1 ); # e.g. 'cs::pdt'; not 'tagset::cs::pdt' (the 'tagset' part will be inserted automatically)
# The following attributes are required but they will be automatically derived from 'driver' in BUILDARGS() below.
has 'decode_function' => ( isa => 'CodeRef', is => 'ro', required => 1 );
has 'encode_function' => ( isa => 'CodeRef', is => 'ro', required => 1 );
has 'list_function'   => ( isa => 'CodeRef', is => 'ro', required => 1 );



#------------------------------------------------------------------------------
# This block will be called before object construction. It will take the driver
# attribute from the user and use it to get the three function attributes. Then
# it will pass all the attributes to the constructor.
#------------------------------------------------------------------------------
around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;
    # Call the default BUILDARGS in Moose::Object. It will take care of distinguishing between a hash reference and a plain hash.
    my $attr = $class->$orig(@_);
    if($attr->{driver})
    {
        my $driver_hash = Lingua::Interset::get_driver_hash();
        if(!exists($driver_hash->{$attr->{driver}}))
        {
            confess("Unknown tagset driver '$attr->{driver}'");
        }
        if(!$driver_hash->{$attr->{driver}}{old})
        {
            confess("OldTagsetDriver can be used only for old drivers but '$attr->{driver}' is new");
        }
        my $package = $driver_hash->{$attr->{driver}}{package};
        my $eval = <<_end_of_eval_
        {
            use ${package};
            my \$decode = \\&${package}::decode;
            my \$encode = \\&${package}::encode;
            my \$list = \\&${package}::list;
            return (\$decode, \$encode, \$list);
        }
_end_of_eval_
        ;
        ###!!! Perlcritic suggests that the following line be
        ###!!! my ($decode, $encode, $list) = eval { $eval };
        ###!!! so that it is not compiled every time it is called.
        ###!!! But the suggested version does not work on Windows!
        my ($decode, $encode, $list) = eval $eval; ## no critic
        if($@)
        {
            confess("$@\nEval failed");
        }
        # Now add the references to the driver functions to the attribute hash.
        $attr->{decode_function} = $decode;
        $attr->{encode_function} = $encode;
        $attr->{list_function} = $list;
    }
    return $attr;
};



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = Lingua::Interset::FeatureStructure->new();
    my $fs_hash = &{$self->decode_function()}($tag);
    translate($fs_hash, 12);
    $fs->set_hash($fs_hash);
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $fs_hash = $fs->get_hash();
    translate($fs_hash, 21);
    # Call non-strict ("1") encoding of the old driver. We use a different method ("encode_strict") for strict encoding now.
    my $tag = &{$self->encode_function()}($fs_hash, 1);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    return &{$self->list_function()}();
}



#------------------------------------------------------------------------------
# Some features and values changed between Interset 1.0 and 2.0. The feature
# space has been changing during whole history of Interset and tagset drivers
# had to be adjusted to each change; however, we are not going to adapt old
# drivers to features new in 2.0 (instead, the whole drivers should be ported).
# We must thus translate the changed features while this temporary envelope to
# old drivers is used.
#------------------------------------------------------------------------------
sub translate
{
    my $hash = shift; # hash reference, not Lingua::Interset::FeatureStructure
    my $direction = shift; # 12 or 21 ... from version 1 to 2 or from 2 to 1
    if($direction != 12 && $direction != 21)
    {
        confess("Direction is neither 12 nor 21");
    }
    my @translations =
    (
        ['subpos', 'prop' => 'nountype', 'prop'],
        ['subpos', 'det' => 'adjtype', 'det'],
        ['subpos', 'coor' => 'conjtype', 'coor'],
        ['subpos', 'sub' => 'conjtype', 'sub'],
    );
    foreach my $feature (keys(%{$hash}))
    {
        foreach my $translation (@translations)
        {
            my ($sf, $sv, $tf, $tv);
            if($direction==12)
            {
                ($sf, $sv, $tf, $tv) = @{$translation};
            }
            elsif($direction==21)
            {
                ($tf, $tv, $sf, $sv) = @{$translation};
            }
            # Translate.
            if(defined($hash->{$sf}) && $hash->{$sf} eq $sv)
            {
                delete($hash->{$sf});
                $hash->{$tf} = $tv;
            }
        }
    }
    return $hash;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::OldTagsetDriver - A temporary envelope that provides access to the old (Interset 1.0) drivers from Interset 2.0.

=head1 VERSION

version 3.010

=head1 SYNOPSIS

  # (No need to
  #     use tagset::en::conll;
  # here. It will be taken care of within OldTagsetDriver.)
  use Lingua::Interset::OldTagsetDriver;
  my $driver = Lingua::Interset::OldTagsetDriver->new(driver => 'en::conll');
  my $fs = $driver->decode("NN\tNN\t_");

=head1 DESCRIPTION

Provides object envelope for an old, non-object-oriented driver from Interset 1.0.
This makes the old drivers at least partially usable until they are fully ported to Interset 2.0.
Note however that the old drivers use Interset features and/or values that have been changed in the new version.

=head1 METHODS

=head2 decode()

  my $fs  = $driver->decode ($tag);

Takes a tag (string) and returns a L<Lingua::Interset::FeatureStructure> object
with corresponding feature values set.

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
