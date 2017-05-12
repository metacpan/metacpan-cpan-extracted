package Language::Prolog::Types;

our $VERSION = '0.10';

use strict;
use warnings;

use Carp;

require Exporter;
our @ISA=qw(Exporter);
our %EXPORT_TAGS = ( is => [qw( prolog_is_term
				prolog_is_atom
				prolog_is_nil
				prolog_is_list
				prolog_is_list_or_nil
				prolog_is_functor
				prolog_is_variable
				prolog_is_var
				prolog_is_ulist
				prolog_is_string )],
		     ctors => [qw( prolog_list
				   prolog_ulist
				   prolog_functor
				   prolog_variable
				   prolog_variables
				   prolog_var
				   prolog_vars
				   prolog_atom
				   prolog_nil
				   prolog_string
				   prolog_chain
				   prolog_opaque )],
		     util => [qw( prolog_list2perl_list
				  prolog_list2perl_string )],
		     short => [qw( isL
				   isUL
				   isF
				   isV
				   isA
				   isN
				   isS
				   L
				   UL
				   F
				   V
				   Vs
				   A
				   N
				   S
				   C )] );

our @EXPORT_OK=map { @{$EXPORT_TAGS{$_}} } keys(%EXPORT_TAGS);
our @EXPORT=();

use Language::Prolog::Types::Internal;

# ctors come from ...::Types::Factory:
use Language::Prolog::Types::Factory;

# sets default factory to ...::Types::Internal one
Language::Prolog::Types::Factory::set_factory
    Language::Prolog::Types::Internal->new_factory();

# prolog_is_* functions come from ...::Types::Abstract:
use Language::Prolog::Types::Abstract;



# short aliases for constructors
*L=\&prolog_list;
*UL=\&prolog_ulist;
*F=\&prolog_functor;
*V=\&prolog_variable;
*Vs=\&prolog_variables;
*A=\&prolog_atom;
*N=\&prolog_nil;
*S=\&prolog_string;
*C=\&prolog_chain;

# short aliases for is* functions
*isL=\&prolog_is_list;
*isUL=\&prolog_is_ulist;
*isF=\&prolog_is_functor;
*isV=\&prolog_is_variable;
*isA=\&prolog_is_atom;
*isN=\&prolog_is_nil;
*isS=\&prolog_is_string;


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Language::Prolog::Types - Prolog types in Perl.

=head1 SYNOPSIS

  use Language::Prolog::Types::overload;

  use Language::Prolog::Types qw(:ctors);

  $atom=prolog_atom('foo');
  $list=prolog_list(1,2,3,4,5);
  $functor=prolog_functor('foo',1,2,3,'bar');
  $nil=prolog_nil;


  use Language::Prolog::Types qw(:is);

  print "$atom is an atom\n" if prolog_is_atom($atom);
  print "$list is a list\n" if prolog_is_list($list);
  print "$nil is nil\n" if prolog_is_nil($nil);


  use Language::Prolog::Types qw(:short);

  $atom=A('foo');
  $list=L(1,2,3,4);
  $functor=F('foo',1,2,3,'bar')

  print "$atom is an atom\n" if isA($atom);
  print "$list is a list\n" if isL($list);
  print "$nil is nil\n" if isN($nil);



=head1 ABSTRACT

Language::Prolog::Types is a set of modules implementing Prolog types
in Perl.

=head1 DESCRIPTION

This module exports subroutines to create Prolog terms in Perl, to
test term types and also some utility functions to convert data
between Prolog and Perl explicitly.

You will see that there is not any kind of constructor for Prolog
atoms, this is because Perl scalars (numbers or strings) are directly
used as Prolog atoms.

You can also use Perl list references as Prolog lists, and Perl
C<undef> as Prolog nil (C<[]>).

=head2 EXPORT_TAGS

Subroutines are grouped in three tags:

=over 4

=item C<:is>

Subroutines to test typing of terms.

=over 4

=item C<prolog_is_atom($term)>

true if C<$term> is a valid Prolog atom (Perl number or string).

=item C<prolog_is_nil($term)>

true if C<$term> is Prolog nil C<[]>. Perl undef is equivalent to
Prolog nil.

=item C<prolog_is_list($term)>

true if C<$term> is Prolog list.

It should be noted that Prolog nil although represented with the empty
list C<[]> is not a list.

=item C<prolog_is_list_or_nil($term)>

true if C<$term> is a Prolog list or nil.

=item C<prolog_is_functor($term)>

true if C<$term> is a Prolog functor.

It should be noted that list are formed with the functor '.'/2.

=item C<prolog_is_variable($term)>

=item C<prolog_is_var($term)>

true if C<$term> is a Prolog variable.

=item C<prolog_is_ulist($term)>

true if C<$term> is a Prolog unfinished list (those whose tail is not
nil).

=item C<prolog_is_string($term)>

true if C<$term> can be converted to a string, a list whose elements
are integers in the range [0..255].

=back

=item C<:ctors>

Subruotines to create new Prolog terms.

=over 4

=item C<prolog_list(@terms)>

returns a new prolog list with elements C<@terms>.

=item C<prolog_ulist(@terms, $tail)>

returns a new prolog unfineshed list with elements C<@terms> and tail
C<$tail>.

=item C<prolog_functor($name, @args)>

returns a new prolog functor which name C<$name> and arguments
C<@args>.

=item C<prolog_variable($name)>

=item C<prolog_var($name)>

returns a new prolog variable with name C<$name>.

=item C<prolog_atom($atom)>

As normal Perl strings and numbers are used to represent Prolog atoms
this function only ensures that its argument is properly converted to
a string.

=item C<prolog_nil()>

returns Prolog nil (C<[]>).

=item C<prolog_string($string)>

returns Prolog string, that is a list with the ASCII codes of
C<$string>.

=item C<prolog_chain($ftr, $term1, $term2, ..., $termn, $termo)>

creates prolog structure

  $ftr($term1,
       $ftr($term2,
            $ftr($term3,
                 $ftr(...
                          $ftr($termn, $termo) ... ))))

it should be noted that

  prolog_chain($ftr, $term)

returns

  $term

=item C<prolog_opaque($object)>

creates a proxy opaque object to tell Perl to pass the object to
Prolog as an opaque reference that can not be directly used from Prolog
but just passed back to Perl in callbacks.

=back

=item C<:util>

Subroutines to convert Prolog data to Perl.

=over 4

=item C<prolog_list2perl_list($term)>

converts a Prolog_list to a Perl array acounting for all the different
possibilities of Prolog list representations.

=item C<prolog_list2perl_string($term)>

converts a Prolog list to a Perl string. All the elements in the list
have to be integers in the range [0..255] or an exception will be
raised. 

=back

=item C<:short>

For the lazy programmer, C<:short> includes a set of abreviations for
the C<:is> and C<:ctors> groups:

=over 4

=item C<isL($term)>

=item C<isUL($term)>

=item C<isF($term)>

=item C<isV($term)>

=item C<isA($term)>

=item C<isN($term)>

=item C<isS($term)>

=item C<L(@terms)>

=item C<UL(@terms, $tail)>

=item C<F($name, @args)>

=item C<V($name)>

=item C<A($atom)>

=item C<N()>

=item C<S($string)>

=item C<C($term1, $term2, ..., $termn, $termo)>

=back

=back


=head1 SEE ALSO

L<Language::Prolog::Types::overload>

L<Language::Prolog::Sugar>

L<Language::XSB>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2005, 2007 by Salvador FandiE<ntilde>o
E<lt>sfandino@yahoo.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

