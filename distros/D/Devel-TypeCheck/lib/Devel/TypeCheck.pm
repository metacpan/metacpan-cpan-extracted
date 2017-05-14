package Devel::TypeCheck;

use warnings;
use strict;

=head1 NAME

Devel::TypeCheck - Identify type-unsafe usage in Perl programs

=head1 VERSION

Version 1.2.2

=cut

our $VERSION = '1.2.2';

=head1 SYNOPSIS

This file exists as a placeholder for the documentation.  To use,
invoke the B::TypeCheck module as one normally would with any other
compiler back-end module:

	perl -MO=TypeCheck[,OPTION][,I<subroutine> ...] I<SCRIPTNAME>

Alternatively, in line Perl:

	use O ("TypeCheck", OPTION, I<subroutine>)

=head1 OPTIONS

=over 4

=item B<-verbose>

Print out the relevant parts of the opcode tree along with their
inferred types.  This can be useful for identifying where a
type-inconsistant usage is in your program, and for debugging
TypeCheck itself.

=item B<-ugly>

When printing out types, use the older type language instead of
human-readable names.  This mode is best used for debugging the type
inference system.

=item B<-continue>

Continue on to the next function if the current function fails to
type-check.  Useful for type-checking large numbers of functions (for
instance, with the -all option).

=item B<-main>

Type check the main body of the Perl program in question.

=item B<-module I<module name>>

Type check all functions in the named module.  This does not cause
TypeCheck to recurse to sub-modules in the name space.

=item B<-all>

Type check all functions, including normally included ones, such as
IO::Handle.

=item B<I<subroutine>>

Type check a specific subroutine.  In this release, TypeCheck does not
do generalized interprocedural analysis.  However, it does keep track
of types for global variables.

=back

=head1 EXAMPLES

Here is an example program that treats $foo in a type-consistent manner:

 # pass
 if (int(rand(2)) % 2) {
     $foo = 1;
 } else {
     $foo = 2;
 }

When we run the TypeChecker against this program, we get the following
output:

 Defaulting to -main
 Type checking CVs:
   main::MAIN
   Pad Table Types:
   Name                Type
   ----------------------------------------

   Result type of main::MAIN is undefined
   Return type of main::MAIN is undefined

 Global Symbol Table Types:
 Name                Type
 ------------------------------------------------------------------------------
 foo                 GLOB of (...; NUMBER of INTEGER; TUPLE of (); RECORD of {})
 Total opcodes processed: 24
 - syntax OK

The indented stanza indicates that there are no named local variables in MAIN.

The stanza at the bottom shows that we have a global variable named
foo of the GLOB type that contains an integer in its scalar value
element.

Here is another that does not:

 # fail
 if (int(rand(2)) % 2) {
     $foo = 1;
 } else {
     $foo = \1;
 }

We get the following when we run TypeChecker against the example:

 Defaulting to -main
 Type checking CVs:
   main::MAIN
 TYPE ERROR: Could not unify REFERENCE to NUMBER of INTEGER and NUMBER of INTEGER at line 5, file -
 CHECK failed--call queue aborted.

This means that the type inference algorithm was not able to unify a
reference to an integer type with an integer type.  To get a better
idea about how this works, we will look at the verbose output (with
lines numbered and extraneous lines removed for clarity):

    25                  S:leave {
    26                      S:enter {
    27                      } = void
    28                      S:nextstate {
    29                        line 3, file /tmp/fail.pl
    30                      } = void
    31                      S:sassign {
    32                          S:const {
    33                          } = NUMBER of INTEGER
    34                          S:null {
    35                              S:gvsv {
    36                              } = TYPE VARIABLE f
    37                          } = TYPE VARIABLE f
    38                        unify(NUMBER of INTEGER, TYPE VARIABLE f) = NUMBER of INTEGER
    39                      } = NUMBER of INTEGER
    40                  } = void
    41                  S:leave {
    42                      S:enter {
    43                      } = void
    44                      S:nextstate {
    45                        line 5, file /tmp/fail.pl
    46                      } = void
    47                      S:sassign {
    48                          S:const {
    49                          } = REFERENCE to NUMBER of INTEGER
    50                          S:null {
    51                              S:gvsv {
    52                              } = NUMBER of INTEGER
    53                          } = NUMBER of INTEGER
    54                        unify(REFERENCE to NUMBER of INTEGER, NUMBER of INTEGER) = FAIL
    55  TYPE ERROR: Could not unify REFERENCE to NUMBER of INTEGER and NUMBER of INTEGER at line 5, file /tmp/fail.pl
    56  CHECK failed--call queue aborted.

Lines 31-39 represent the assignment that constitutes the first branch
of the if statement.  Here, an integer constant (lines 31-32) is
assigned to the variable represented by the gvsv operator (lines
35-36).  The variable is brand new, so it is instantiated with a brand
new unspecified scalar value type (TYPE VARIABLE f).  This is unified
with the constant (line 38), binding the type variable "f" with the
concrete type NUMBER of INTEGER.

Lines 47-53 represent the assignment that consitutes the second branch
of the if statement.  Like the last assignment, we generate a type for
our constant.  Here, the type is a reference to an integer (lines
47-48).  Since we have already inferred an integer type for the C<<
$foo >> variable, that is what we get when we access it with the gvsv
operator (lines 51-52).  When we try to assign the constant to the
variable, we get a failure in the unification since the types do not
match and there is no free type variable to unify type components
with.

=head1 NOTES

In the REFERENCES section, we cite a paper by the author that is
suggested reading for understanding the type system in-depth.
Briefly, we use a simplified model of the Perl type system based on
the information available at compile time.  A type in this system
represents a string accepted by our type language.  This language
models ambiguity in inferred types by allowing type variables to be
introduced in specific places.  The type system has changed since that
paper was written to better accomodate aggregate types, and allow for
the representation of a non-reference (but otherwise undistinguished)
scalar value.

The type language now looks more like this, where a "t" is the start
of the language, and "a" represents a type variable:

 t ::= M m | a
 m ::= H h | K k | O o | X x | CV | IO
 h ::= H:(..., M K k, M O o, M X x)
 k ::= P t | Y y | a
 y ::= PV | N n | a
 n ::= IV | DV | a
 o ::= (t, ...) | (q)
 q ::= t | t, q
 x ::= {* => t} | {r}
 r ::= "IDENTIFIER" => t | "IDENTIFIER" => t, r

The additions are for Upsilon (Y), which allows for ambiguity about
whether a type is a string or a number without allowing it to be a
reference, and for Omicron (O) and Chi (X), which model arrays and
hashes, respectively.

With this type language, we model types for individual values as a
data structure type, and type unification is done structurally.
Furthermore, we model aggregate data structures with a subtyping
relationship.  For brevity, we will explain only the functioning of
array types.  Hash types work analogously.

Arrays are used in essentially two different ways.  First, they can be
used as tuples, where members at specific indices have specific
meanings and potentially heterogeneous types.  An example of this
would be the return value of the C<< getgrent >> function, which
consists of both strings and integers.  Second, they can be used as
lists of indeterminate length.  To support typing arrays, we introduce
a subtyping relationship between tuples and lists by making tuples a
subtype of lists.  Inference can go from a specific type with a tuple
to a more general type with a list, but it will not run the other way.
Unification between a tuple and a list works by unifying all elements
in the tuple with the homogeneous type of the list.  Thus, a
programmer can treat an array as a tuple in one part of the code and a
list in the other as long as every member of the tuple can be unified
with the type of every possible element in a list.

=head1 TODO

Release 1.0 is a fully functional release.  However, there are several
things that need to be done before Devel::TypeCheck can be given a 2.0
release.

=over 4

=item Subtyping Relationships

Subtyping relationships are very important in the model of the type
system that we are using.  An ad-hoc sub-typing relationship is used
explicitly for typing aggregate data types.  Furthermore, the
relationships between the other types can be seen as a subtyping
system.  For instance, we can envision an infinite lattice (due to
glob and reference types) with the most general type at the top and
more specific types (subtypes) down toward the bottom, which is no
type (and is the result of a unify operation which acts as a meet
operation between unrelated types).  A generalized way to reflect this
would make the code cleaner and easier to read.  Furthermore, it would
support the next two important features.  This would involve an
extensive refactoring or rewrite of the type system and the type
inference algorithm.

=item Objects

With a generalized system for subtyping relationships, objects can be
easily supported by determining lattice that reflects the inheritance
hierarchy and adding code to identify the type of a given
instantiation.  With a generalized subtyping model, there should be
few other changes necessary.

=item Type Qualifiers

Type qualifiers can be used to describe ephemeral qualities of the
data manipulated in the program.  For instance, Perl already has a
type qualifier system with subtypes, that works at run-time: Taint
mode.  Generic type qualifiers could model type qualifiers at compile
time, like Taint (but without it's precision) or many other properties
that can be modelled with type qualifiers.  Along with a generic
subtyping system, implementing type qualifiers would require a way to
describe a qualifier lattice and a way to annotate code.  It is
unknown to the author whether the current annotation system is
sufficient.  See CQual for more information about an existing system
that implements Type Qualifiers in a practical way:

 http://www.cs.umd.edu/~jfoster/cqual/

=item Interprocedural Analysis

The type analysis needs interprocedural analysis to be truly useful.
This may or may not have to support type polymorphism.

=item Test Harness

It would be nice to have a way to automatically generate TypeCheck
tests for modules.

=back

=head1 REFERENCES

The author has written a paper explaining the need, operation,
results, and future direction for this project.  It is available at the
following URL:

  http://www.umiacs.umd.edu/~bargle/project2.pdf

This is suggested reading for this release.  In future releases, we
hope to have a proper manual.

=head1 AUTHOR

Gary Jackson, C<< <bargle at umiacs.umd.edu> >>

=head1 BUGS

This version is specific to Perl 5.8.1.  It may work with other
versions that have the same opcode list and structure, but this is
entirely untested.  It definitely will not work if those parameters
change.

Please report any bugs or feature requests to
C<bug-devel-typecheck at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-TypeCheck>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Gary Jackson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Devel::TypeCheck
