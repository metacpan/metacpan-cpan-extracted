# NAME

Genealogy::Ahnentafel - Handle Ahnentafel numbers in Perl.

# SYNOPSIS

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

# DESCRIPTION

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

# FUNCTIONS

This module exports one function.

## ahnen($positive\_integer)

This function takes a positive integer and returns a Genealogy::Ahnentafel
object for that integer. If you pass it something that isn't a positive
integer the function will throw an exception.

This is just a short-cut for

    Genealogy::Ahnentafel->new({ ahnentafel => $positive_integer })

# CLASS ATTRIBUTES

The module provides two class attributes. These define strings that are
used in the output of various methods in the class. They are provided to
make it easier to subclass this class to support internationalisation.

## genders

This is a reference to an array that contains two strings that represent
the genders male and female. By default, they are the strings "Male" and
"Female".

## parent\_names

This is a reference to an array that contains two strings that represent
the parent of the two genders. By default, they are the strings "Father"
and "Mother".

Note that these strings are also used to build more complex relationship
names like "Grandfather" and "Great Grandmother".

# OBJECT ATTRIBUTES

Objects of this class have the following attributes. Most them are
lazily generated from the Ahnentafel number.

## ahnentafel

The positive integer that was used to create this object.

    say ahnen(123)->ahnentafel; # 123

## gender

The gender of the person represented by this object. This returns "Unknown"
for person 1 (as the person at the root of the tree can be of either gender).
Other than that people with an even Ahnentafel number are men and people with
an odd Ahnentafel are women.

## gender\_description

(I'm not convinced by this name. I'll almost certainly change it at some
point.)

The base word that is used for people of this gender. It is "Person" for
person 1 (as we don't know their gender) and either "Father" or "Mother"
as appropriate for everyone else.

## generation

The number of the generation that this person is in. Person 1 is in
generation 1. People 2 and 3 (the parents) are in generation 2. People
4 to 7 (the grandparents) are in generation 3. And so on.

## description

A description of the relationship between the root person and the current
person. For person 1, it is "Person". For people 2 and 3 it is "Father"
or "Mother". For people in generation 3, it is "Grandfather" or
"Grandmother". After that we prepend the appropriate number of repetitions
of "Great" - "Great Grandmother", "Great Great Grandfather", etc.

## ancestry

An array of Genealogy::Ahnentafel objects representing all of the people
between (and including) the root person and the current person.

## ancestry\_string

A string representation of ancestry.

## father

A Genealogy::Ahnentafel object representing the father of the current
person.

## mother

A Genealogy::Ahnentafel object representing the mother of the current
person.

## AUTHOR

Dave Cross <dave@perlhacks.com>

## COPYRIGHT AND LICENCE

Copyright (c) 2016, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
