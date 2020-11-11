package Genealogy::Ahnentafel;

=head1 NAME

Genealogy::Ahnentafel - Handle Ahnentafel numbers in Perl.

=head1 SYNOPSIS

   use Genealogy::Ahnentafel;

   my $ahnen = ahnen(1);
   say $ahnen->gen;         # 1
   say $ahnen->gender;      # Unknown
   say $ahnen->description; # Person

   my $ahnen = ahnen(2);
   say $ahnen->gen;         # 2
   say $ahnen->gender;      # Male
   say $ahnen->description; # Father

   my $ahnen = ahnen(5);
   say $ahnen->gen;         # 3
   say $ahnen->gender;      # Female
   say $ahnen->description; # Grandmother

=head1 DESCRIPTION

Geologists often use Ahnentafel (from the German for "ancestor table")
numbers to identify the direct ancestors of a person. The original
person of interest is given the number 1, their father and mother are
2 and 3, their paternal grandparents are 4 and 5, their maternal
grandparents are 6 and 7 and the list goes on.

This class gives you a way to deal with these numbers in Perl.

Ahnentafel numbers have some interesting properties. For example, with
the exception of the first person in the list (who can, obviously, be
of either sex) all of the men have Ahnentafel numbers which are even
and the women have Ahnentafel numbers which are even. You can calculate
the number of the father of any person on the list simply by doubling
the number of the child. You can get the number of their mother by
doubling the child's number and adding one.

=cut

use strict;
use warnings;

our $VERSION = '1.0.2';

require Exporter;
our @ISA = qw[Exporter];
our @EXPORT = qw[ahnen];

use Carp;

use Moo;
use MooX::ClassAttribute;
use Types::Standard qw( Str Int ArrayRef Bool );
use Type::Utils qw( declare as where inline_as coerce from );

my $PositiveInt = declare
  as        Int,
  where     {  $_ > 0  },
  inline_as { "defined $_ and $_ =~ /^[0-9]+\$/ and $_ > 0" };

use overload
  '""' => sub { $_[0]->ahnentafel },
  fallback => 1;

=head1 FUNCTIONS

This module exports one function.

=head2 ahnen($positive_integer)

This function takes a positive integer and returns a Genealogy::Ahnentafel
object for that integer. If you pass it something that isn't a positive
integer the function will throw an exception.

This is just a short-cut for

  Genealogy::Ahnentafel->new({ ahnentafel => $positive_integer })

=cut

sub ahnen {
  return Genealogy::Ahnentafel->new({ ahnentafel => $_[0] });
}

=head1 CLASS ATTRIBUTES

The module provides two class attributes. These define strings that are
used in the output of various methods in the class. They are provided to
make it easier to subclass this class to support internationalisation.

=head2 genders

This is a reference to an array that contains two strings that represent
the genders male and female. By default, they are the strings "Male" and
"Female".

=cut

class_has genders => (
  is      => 'lazy',
  isa     => ArrayRef[Str],
);

sub _build_genders {
  return [ qw[Male Female] ];
}

=head2 parent_names

This is a reference to an array that contains two strings that represent
the parent of the two genders. By default, they are the strings "Father"
and "Mother".

Note that these strings are also used to build more complex relationship
names like "Grandfather" and "Great Grandmother".

=cut

class_has parent_names => (
  is      => 'lazy',
  isa     => ArrayRef[Str],
);

sub _build_parent_names {
  return [ qw[Father Mother] ];
}

=head1 OBJECT ATTRIBUTES

Objects of this class have the following attributes. Most them are
lazily generated from the Ahnentafel number.

=head2 ahnentafel

The positive integer that was used to create this object.

  say ahnen(123)->ahnentafel; # 123

=cut

has ahnentafel => (
  is       => 'ro',
  isa      => $PositiveInt,
  required => 1,
);

=head2 gender

The gender of the person represented by this object. This returns "Unknown"
for person 1 (as the person at the root of the tree can be of either gender).
Other than that people with an even Ahnentafel number are men and people with
an odd Ahnentafel are women.

=cut

has gender => (
  is      => 'lazy',
  isa     => Str,
);

sub _build_gender {
  my $ahnen = $_[0]->ahnentafel;
  return 'Unknown' if $ahnen == 1;
  return $_[0]->genders->[ $ahnen % 2 ];
}

=head2 gender_description

(I'm not convinced by this name. I'll almost certainly change it at some
point.)

The base word that is used for people of this gender. It is "Person" for
person 1 (as we don't know their gender) and either "Father" or "Mother"
as appropriate for everyone else.

=cut

has gender_description => (
  is      => 'lazy',
  isa     => Str,
);

sub _build_gender_description {
  my $ahnen = $_[0]->ahnentafel;
  return 'Person' if $ahnen == 1;
  return $_[0]->parent_names->[ $ahnen % 2 ];
}

=head2 generation

The number of the generation that this person is in. Person 1 is in
generation 1. People 2 and 3 (the parents) are in generation 2. People
4 to 7 (the grandparents) are in generation 3. And so on.

=cut

has generation => (
  is      => 'lazy',
  isa     => $PositiveInt,
);

sub _build_generation {
  my $ahnen = $_[0]->ahnentafel;
  return int log( $ahnen ) / log(2) + 1;
}

=head2 description

A description of the relationship between the root person and the current
person. For person 1, it is "Person". For people 2 and 3 it is "Father"
or "Mother". For people in generation 3, it is "Grandfather" or
"Grandmother". After that we prepend the appropriate number of repetitions
of "Great" - "Great Grandmother", "Great Great Grandfather", etc.

=cut

has description => (
  is      => 'lazy',
  isa     => Str,
);

sub _build_description {
  my $ahnen = $_[0]->ahnentafel;

  my $generation = $_[0]->generation();

  return 'Person' if $generation == 1;

  my $root = $_[0]->gender_description;
  return $root    if $generation == 2;
  $root = "Grand\L$root";
  return $root    if $generation == 3;
  my $greats = $generation - 3;
  return ('Great ' x $greats) . $root;
}

=head2 ancestry

An array of Genealogy::Ahnentafel objects representing all of the people
between (and including) the root person and the current person.

=cut

has ancestry => (
  is      => 'lazy',
  isa     => ArrayRef,
);

sub _build_ancestry {
  my @ancestry;
  my $curr = $_[0]->ahnentafel;

  while ($curr) {
    unshift @ancestry, ahnen($curr);
    $curr = int($curr / 2);
  }

  return \@ancestry;
}

=head2 ancestry_string

A string representation of ancestry.

=cut

has ancestry_string => (
  is      => 'lazy',
  isa     => Str,
);

sub _build_ancestry_string {
  return join ', ', map { $_->description } @{ $_[0]->ancestry };
}

=head2 father

A Genealogy::Ahnentafel object representing the father of the current
person.

=cut

has father => (
  is      => 'lazy',
);

sub _build_father {
  return ahnen($_[0]->ahnentafel * 2);
}

=head2 mother

A Genealogy::Ahnentafel object representing the mother of the current
person.

=cut

has mother => (
  is      => 'lazy',
);

sub _build_mother {
  return ahnen($_[0]->ahnentafel * 2 + 1);
}

=head2 first_in_generation

The lowest Ahnentafel number that appears in the current generation.

=cut

has first_in_generation => (
  is      => 'lazy',
  isa     => Int,
);

sub _build_first_in_generation {
  return 2 ** ($_[0]->generation - 1);
}

=head2 is_first_in_generation

Is this the first Ahnentafel number in the current generation?

=cut

has is_first_in_generation => (
  is      => 'lazy',
  isa     => Bool,
);

sub _build_is_first_in_generation {
  return $_[0]->first_in_generation == $_[0]->ahnentafel;
}

=head2 last_in_generation

The highest Ahnentafel number that appears in the current generation.

=cut

has last_in_generation => (
  is      => 'lazy',
  isa     => Int,
);

sub _build_last_in_generation {
  return 2 ** $_[0]->generation - 1;
}

=head2 is_last_in_generation

Is this the last Ahnentafel number in the current generation?

=cut

has is_last_in_generation => (
  is      => 'lazy',
  isa     => Bool,
);

sub _build_is_last_in_generation {
  return $_[0]->last_in_generation == $_[0]->ahnentafel;
}

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2016, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
