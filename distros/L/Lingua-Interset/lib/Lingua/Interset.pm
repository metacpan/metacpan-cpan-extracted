# ABSTRACT: DZ Interset is a universal morphosyntactic feature set to which all tagsets of all corpora/languages can be mapped.
# Copyright © 2007-2014 Univerzita Karlova v Praze / Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset;
use strict;
use warnings;
our $VERSION = '3.012';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose 2;
use MooseX::SemiAffordanceAccessor; # attribute x is written using set_x($value) and read using x()
# Allow the user to import the core functions into their namespace by stating
# use Lingua::Interset qw(decode encode list);
use Exporter::Easy ( OK => [ 'decode', 'encode', 'encode_strict', 'list', 'find_drivers', 'find_tagsets', 'hash_drivers', 'get_driver_object' ] );



###############################################################################
# DRIVER FUNCTIONS WITH PARAMETERIZED DRIVERS
###############################################################################



# Static reference to the list of all installed tagset drivers.
# The list will be built lazily, see find_drivers().
my $driver_list = undef;
my $driver_hash = undef; # indexed by tagset id



#------------------------------------------------------------------------------
# Decodes a tag using a particular driver.
#------------------------------------------------------------------------------
sub decode
{
    my $tagset = shift; # e.g. "cs::pdt"
    my $driver = get_driver_object($tagset);
    return $driver->decode(@_);
}



#------------------------------------------------------------------------------
# Encodes a tag using a particular driver.
#------------------------------------------------------------------------------
sub encode
{
    my $tagset = shift; # e.g. "cs::pdt"
    my $driver = get_driver_object($tagset);
    return $driver->encode(@_);
}



#------------------------------------------------------------------------------
# Encodes a tag using a particular driver and strict encoding (only known
# tags).
#------------------------------------------------------------------------------
sub encode_strict
{
    my $tagset = shift; # e.g. "cs::pdt"
    my $driver = get_driver_object($tagset);
    return $driver->encode_strict(@_);
}



#------------------------------------------------------------------------------
# Lists all tags of a tag set.
#------------------------------------------------------------------------------
sub list
{
    my $tagset = shift; # e.g. "cs::pdt"
    my $driver = get_driver_object($tagset);
    return $driver->list(@_);
}



#------------------------------------------------------------------------------
# Creates and returns a tagset driver object for a given tagset.
#------------------------------------------------------------------------------
sub get_driver_object
{
    my $tagset = shift; # e.g. "cs::pdt"
    my $driver_hash = get_driver_hash();
    if(!exists($driver_hash->{$tagset}))
    {
        confess("Unknown tagset driver '$tagset'");
    }
    # We will cache the driver objects for tagsets. We do not want to construct them again and again.
    if(!defined($driver_hash->{$tagset}{driver}))
    {
        my $package = $driver_hash->{$tagset}{package};
        my $eval;
        if($driver_hash->{$tagset}{old})
        {
            $eval = <<_end_of_old_eval_
            {
                use ${package};
                use Lingua::Interset::OldTagsetDriver;
                my \$object = Lingua::Interset::OldTagsetDriver->new(driver => '${tagset}');
                return \$object;
            }
_end_of_old_eval_
            ;
        }
        else # new driver
        {
            $eval = <<_end_of_eval_
            {
                use ${package};
                my \$object = ${package}->new();
                return \$object;
            }
_end_of_eval_
            ;
        }
        ###!!! Perlcritic suggests that the following line be
        ###!!! my $object = eval { $eval };
        ###!!! so that it is not compiled every time it is called.
        ###!!! But the suggested version does not work on Windows!
        my $object = eval $eval; ## no critic
        if($@)
        {
            confess("$@\nEval failed");
        }
        $driver_hash->{$tagset}{driver} = $object;
    }
    my $object = $driver_hash->{$tagset}{driver};
    if(!defined($object) || ref($object) !~ m/^Lingua::Interset::/)
    {
        confess("Did not succeed in creating driver object for '$tagset' (".ref($object)."/$object)");
    }
    return $object;
}



#------------------------------------------------------------------------------
# Tries to enumerate existing tagset drivers. Searches for relevant folders in
# @INC paths.
#------------------------------------------------------------------------------
sub find_drivers
{
    if(!defined($driver_list))
    {
        $driver_list = _find_drivers();
    }
    return $driver_list;
}
sub _find_drivers
{
    my @drivers;
    foreach my $path (@INC)
    {
        # Old drivers (Interset 1.0) are in the "tagset" folder.
        # We will continue using them until all have been ported to Interset 2.0.
        my $tpath = "$path/tagset";
        if(-d $tpath)
        {
            opendir(DIR, $tpath) or confess("Cannot read folder $tpath: $!\n");
            my @subdirs = readdir(DIR);
            closedir(DIR);
            foreach my $sd (@subdirs)
            {
                my $sdpath = "$tpath/$sd";
                if(-d $sdpath && $sd !~ m/^\.\.?$/)
                {
                    # It is possible that a subfolder of $PERLLIB is not readable.
                    # We cannot complain about it. We will just silently proceed to the next available folder.
                    opendir(DIR, $sdpath) or next;
                    my @files = readdir(DIR);
                    closedir(DIR);
                    foreach my $file (@files)
                    {
                        my $fpath = "$sdpath/$file";
                        my $driver = $file;
                        if(-f $fpath && $driver =~ s/\.pm$//)
                        {
                            $driver = $sd."::".$driver;
                            my %record =
                            (
                                'old'     => 1,
                                'tagset'  => $driver,
                                'package' => "tagset::$driver",
                                'path'    => $fpath
                            );
                            push(@drivers, \%record);
                        }
                    }
                }
            }
        }
        # New drivers (Interset 2.0) are in the "Lingua/Interset" folder.
        # Not everything in this folder is a driver! But subfolders lead to drivers, the additional stuff are files, not folders.
        my $lipath = "$path/Lingua/Interset/Tagset";
        if(-d $lipath)
        {
            opendir(DIR, $lipath) or confess("Cannot read folder $lipath: $!\n");
            my @subdirs = readdir(DIR);
            closedir(DIR);
            foreach my $sd (@subdirs)
            {
                my $sdpath = "$lipath/$sd";
                if(-d $sdpath && $sd !~ m/^\.\.?$/)
                {
                    # It is possible that a subfolder of $PERLLIB is not readable.
                    # We cannot complain about it. We will just silently proceed to the next available folder.
                    opendir(DIR, $sdpath) or next;
                    my @files = readdir(DIR);
                    closedir(DIR);
                    foreach my $file (@files)
                    {
                        my $fpath = "$sdpath/$file";
                        my $driver = $file;
                        if(-f $fpath && $driver =~ s/\.pm$//)
                        {
                            my $driver_uppercased = $sd.'::'.$driver;
                            my $driver_lowercased = lc($driver_uppercased);
                            my %record =
                            (
                                'old'     => 0,
                                'tagset'  => $driver_lowercased,
                                'package' => "Lingua::Interset::Tagset::$driver_uppercased",
                                'path'    => $fpath
                            );
                            push(@drivers, \%record);
                        }
                    }
                }
            }
        }
    }
    @drivers = sort {$a->{tagset} cmp $b->{tagset}} (@drivers);
    return \@drivers;
}



#------------------------------------------------------------------------------
# Returns the set of all known tagset drivers indexed by tagset id. If there
# are two drivers installed for the same tagset, it is not defined which one
# will be returned (and something is definitely wrong if they are not
# identical implementations). Exception: Interset 2.0 drivers are prefered over
# the old ones.
#
# For backward compatibility, this function is also available under its older
# name, get_driver_hash(). I later decided that I wanted to call it
# hash_drivers(). It is available for import as hash_drivers().
#------------------------------------------------------------------------------
sub hash_drivers
{
    return get_driver_hash();
}
sub get_driver_hash
{
    if(!defined($driver_hash))
    {
        my $driver_list = find_drivers();
        # Index the drivers by tagset id.
        my %hash;
        foreach my $driver (@{$driver_list})
        {
            # It is possible (though not exactly desirable) that there are several drivers installed for the same tagset.
            if(exists($hash{$driver->{tagset}}))
            {
                # If the previously encountered driver is old and this one is new, prefer the new one.
                # Otherwise (both are old or both are new) just hope that the two installed modules are identical.
                if($hash{$driver->{tagset}}{old} && !$driver->{old})
                {
                    $hash{$driver->{tagset}} = $driver;
                }
            }
            else # this is the first driver found for this tagset
            {
                $hash{$driver->{tagset}} = $driver;
            }
        }
        $driver_hash = \%hash;
    }
    return $driver_hash;
}



#------------------------------------------------------------------------------
# Tries to enumerate known tagsets (for which there is at least one driver).
# This function uses find_drivers() but it returns a list of tagset ids
# available for the user to ask for creating a driver object.
#------------------------------------------------------------------------------
sub find_tagsets
{
    my $hash = get_driver_hash();
    my @tagsets = sort(keys(%{$hash}));
    return @tagsets;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset - DZ Interset is a universal morphosyntactic feature set to which all tagsets of all corpora/languages can be mapped.

=head1 VERSION

version 3.012

=head1 SYNOPSIS

  use Lingua::Interset qw(decode encode);

  my $tag1 = 'NN'; # in the English Penn Treebank, "NN" means "noun"
  my $feature_structure = decode('en::penn', $tag1);
  print($feature_structure->as_string(), "\n");
  $feature_structure->set_number('plur');
  my $tag2 = encode('en::penn', $feature_structure);
  print("$tag2\n");

=head1 DESCRIPTION

DZ Interset is a universal framework for reading, writing, converting and
interpreting part-of-speech and morphosyntactic tags from multiple tagsets
of many different natural languages.

Individual tagsets are mapped to the Interset using specialized modules
called I<tagset drivers>. Every driver must implement three methods:
C<decode>, C<encode> and C<list>.

The main module, C<Lingua::Interset>, provides parameterized access to the
drivers and their methods. Instead of having to C<use> particular modules
(which would mean you know in advance what tagsets your program will be
working with) you just specify the tagset giving its I<identifier> as a parameter.
Tagset ids are derived from Perl package names but they are always all-lowercase.
Most tagsets are taylored for one language and their id has two components (separated by C<::>):
the ISO 639 code of the language, and a part to distinguish various tagsets for the language.
This second component may be some sort of abbreviated name of the corpus where the tagset is used,
for example.

More information is given at the DZ Interset project page,
L<https://wiki.ufal.ms.mff.cuni.cz/user:zeman:interset>.

=head1 FUNCTIONS

=head2 decode()

  my $fs  = decode ('en::penn', 'NNS');

A generic interface to the C<decode()> method of L<Lingua::Interset::Tagset>.
Takes tagset id and a tag in that tagset. Returns a L<Lingua::Interset::FeatureStructure> object
with corresponding feature values set.

=head2 encode()

  my $fs  = decode ('en::penn', 'NNS');
  my $tag = encode ('en::conll', $fs);

A generic interface to the C<encode()> method of L<Lingua::Interset::Tagset>.
Takes tagset id and a L<Lingua::Interset::FeatureStructure> object.
Returns the tag in the given tagset that corresponds to the feature values.
Note that some features may be ignored because they cannot be represented
in the given tagset.

=head2 encode_strict()

  my $fs  = decode ('en::penn', 'NNS');
  my $tag = encode_strict ('en::conll', $fs);

A generic interface to the C<encode_strict()> method of L<Lingua::Interset::Tagset>.
Takes tagset id and a feature structure (L<Lingua::Interset::FeatureStructure>).
Returns a tag of the identified tagset that matches the contents of the feature
structure.

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

=head2 list()

  my $list_of_tags = list ('en::penn');

A generic interface to the C<list()> method of L<Lingua::Interset::Tagset>.
Takes tagset id and returns the reference to the list of all known tags of that tagset.
This is not directly needed to decode, encode or convert tags but it is very useful
for testing and advanced operations over the tagset.
Note however that many tagset drivers contain only an approximate list,
created by collecting tag occurrences in some corpus.

=head2 get_driver_object()

  my $driver = get_driver_object ('en::penn');

A generic accessor to installed Interset drivers of tagsets.
Takes tagset id and returns a L<Lingua::Interset::Tagset> object.

The objects are cached and if you call this function several times for the same
tagset, you will always get the reference to the same object. Tagset objects
do not have variable state, so it probably does not make sense to have several
different driver objects for the same tagset. If you want to get a different
object, you must call C<new()>, e.g. C<< Lingua::Interset::Tagset::EN::Penn->new() >>.

=head2 find_drivers()

  my $list_of_drivers = find_drivers ();

This function searches relevant folders in C<@INC> for installed Interset
drivers for tagsets.
It looks both for the new Interset 2 drivers (e.g. C<Lingua::Interset::Tagset::EN::Penn>)
and for the old Interset 1 drivers (e.g. C<tagset::en::penn>).
It returns a reference to an array of hash references.
Every hash in the list contains the following fields
(here with example values):

  my %record =
  (
      'old'     => 1, # 1 or 0 ... old or new driver?
      'tagset'  => 'en::penn', # tagset id
      'package' => 'Lingua::Interset::Tagset::EN::Penn', # this is what you 'use' or 'require' in your code
      'path'    => '/home/zeman/perl5/lib/Lingua/Interset/Tagset/EN/Penn.pm' # path where it is installed
  );

Note that you may find more than one package for the same tagset id.
This function will list all of them.
When you ask Interset to do something with a tagset (e.g. C<decode ('en::penn', $tag)>),
Interset will select one of the available packages for you.
It will prefer new drivers over the old ones.
If you have two old or two new drivers, their priority will be decided by Perl
and it should correspond to the order of your C<$PERL5LIB> environment variable.
To avoid confusion, it is recommended that you have each package installed only once.

=head2 hash_drivers()

  my $hash_of_drivers = hash_drivers ();

Returns the set of all known tagset drivers indexed by tagset id. The elements
are hashes themselves, with the same record structure as returned by
C<find_drivers()>. Unlike C<find_drivers()>, here the records are organized
in a hash instead of a list, and only one driver per tagset is present.
If there are two drivers installed for the same tagset, the one that appears
earlier in C<@INC> (or in the C<PERL5LIB> environment variable) is returned.
Exception: Interset 2.0 and newer drivers are prefered over the old ones.

=head2 find_tagsets()

  my @list_of_tagset_ids = find_tagsets ();

This function uses find_drivers() and further processes its output. It returns
the list of tagset ids for which there is a driver installed. The user can then
call the C<get_driver_object()> method on these ids.

=head1 SEE ALSO

L<Lingua::Interset::FeatureStructure>,
L<Lingua::Interset::Tagset>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
