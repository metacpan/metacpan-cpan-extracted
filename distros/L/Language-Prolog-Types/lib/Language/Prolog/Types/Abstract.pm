package Language::Prolog::Types::Abstract;

our $VERSION = '0.10';

=head1 NAME

Language::Prolog::Types::Abstract - Abstract classes for Prolog terms in Perl.

=head1 SYNOPSIS

  use Language::Prolog::Types::Abstract;
  if prolog_is_atom('hello') {
      print "'hello' is a Prolog atom\n"
  }

  ...

  etc.

=head1 ABSTRACT

Language::Prolog::Types::Abstract defines a set of abstract classes
for Prolog terms.

It also includes functions to check for Prolog types and some utility
functions to perform explicit conversion between Prolog and Perl.

=head1 DESCRIPTION

This module define abstract classes for the usual Prolog functors,
lists, variables and nil.

Atoms are not included because perl scalars do the work.

Perl C<undef> is equivalent to Prolog nil (C<[]>), although a
different representation is allowed for the Prolog term.

Perl lists can be directly used as Prolog lists. The inverse is not
always true and depends of the implementations used.

=head2 EXPORT

=over 4

=cut


use strict;
use warnings;

use Carp;

require Exporter;
our @ISA=qw(Exporter);
our @EXPORT=qw( prolog_is_term
		prolog_is_atom
		prolog_is_nil
		prolog_is_functor
		prolog_is_list
		prolog_is_list_or_nil
		prolog_is_variable
		prolog_is_var
		prolog_is_ulist
		prolog_list2perl_list );


# prolog_is functions:

# basic perl types ($ and @) are automatically coerced.

=item C<prolog_is_term($term)>

returns true if C<$term> is a valid Prolog term (actually a perl
number, string or array or any object descending from
L<Language::Prolog::Types::Term>).

=cut

sub prolog_is_term ($ ) {
    !ref($_[0])
        or ref($_[0]) eq 'ARRAY'
            or UNIVERSAL::isa('Language::Prolog::Types::Term',$_[0])
}

=item C<prolog_is_atom($term)>

returns true if C<$term> is a valid Prolog atom (actually a perl
number or string).

=cut

sub prolog_is_atom ($ ) { defined($_[0]) and !ref($_[0]) }

=item C<prolog_is_nil($term)>

returns true if C<$term> is Prolog nil value (C<[]>).

=cut

sub prolog_is_nil ($ ) {
    my $self=shift;
    !defined($self)
	or UNIVERSAL::isa($self, 'Language::Prolog::Types::Nil')
	    or (ref($self) eq 'ARRAY' and @$self==0)
}

=item C<prolog_is_functor($term)>

returns true if $term is a Prolog functor.

It should be noted that lists are equivalent to functor '.'/2 and
because of that, this function will also return true when $term is a
list.

=cut

sub prolog_is_functor ($ ) {
    my $self=shift;
    UNIVERSAL::isa($self, 'Language::Prolog::Types::Functor')
	or (ref($self) eq 'ARRAY' and @{$self}>0)
}


=item C<prolog_is_list($term)>

returns true if C<$term> is a Prolog list.

It should be noted that although Prolog nil is usually represented as
the empty list C<[]>, it is not really a Prolog list and this function
will return false for it.

=cut

sub prolog_is_list ($ ) {
    my $self=shift;
    UNIVERSAL::isa($self, 'Language::Prolog::Types::List')
        or (ref($self) eq 'ARRAY' and @$self>0);
}

=item C<prolog_is_list_or_nil($term)>

returns true if C<$term> is Prolog nil or a list.

=cut

sub prolog_is_list_or_nil ($ ) {
    my $self=shift;
    !defined($self)
	or UNIVERSAL::isa($self, 'Language::Prolog::Types::ListOrNil')
	    or ref($self) eq 'ARRAY'
}

=item C<prolog_is_variable($term)>

=item C<prolog_is_var($term)>

return true if C<$term> is a free (unbounded) Prolog variable

=cut

sub prolog_is_variable ($ ) {
    UNIVERSAL::isa(shift, 'Language::Prolog::Types::Variable');
}
*prolog_is_var=\&prolog_is_variable;


=item C<prolog_is_ulist($term)>

returns true if $term is an unfinished Prolog list, that means, one
with doesn't end in nil. i.e. difference lists.

=cut

sub prolog_is_ulist ($ ) {
    UNIVERSAL::isa(shift, 'Language::Prolog::Types::UList');
}

# util functorions:

=item C<prolog_list2perl_list($term)>

converts a Prolog list or nil to a Perl array.

=cut

sub prolog_list2perl_list {
    my $self=shift;
    return () if !defined($self);
    return @{$self} if ref($self) eq 'ARRAY';
    my @result=eval { $self->largs };
    croak "object '$self' is not a valid Prolog list" if $@;
    @result;
}

=item C<prolog_list2perl_string($list)>

Strings are usually represented in Prolog as lists of numbers. This
function do the oposite conversion, from a list of numbers to a Perl
string.

It should be noted that all the elements in the Prolog list have to be
integers in the range [0..255] or an execption will be raised.

=cut

sub prolog_list2perl_string {
    pack "C*", ( grep {
	( prolog_is_atom($_) and /^\d+$/ and $_<256 )
	    or croak "Prolog list is not a valid string"
	} (prolog_list2perl_list $_[0]) )
}


# abstract classes for Prolog types:

=back

=head2 ABSTRACT CLASSES

=head3 Language::Prolog::Types::Term

common abstract class for every Prolog term.

=cut

package Language::Prolog::Types::Term;



=head3 Language::Prolog::Types::ListOrNil

This class is used to account for the intrinsec differences between
empty lists in Perl and Prolog.

In Prolog, nil although represented as the empty list, is not really a
list.

This class provides a set of methods that apply both to lists and nil
if it is considered to be the empty list.

BTW, you should mostly ignore this class and use
L<Prolog::Language::Types::Nil> or L<Prolog::Language::Types::List>
instead.


=head4 Inherits:

=over 4

=item L<Language::Prolog::Types::Term>

=back

=head4 Methods:

=over 4

=item C<$lon-E<gt>length()>

returns the number of terms in the list. If the list is unfinished,
the tail is not counted.

=item C<$lon-E<gt>largs()>

returns the terms in the list. If the list is unfinished, the tail
is ignored.

=item C<$lon-E<gt>tail()>

returns the list tail, that will be nil if the list is finished or is nil

=item C<$lon-E<gt>larg($index)>

returns element number C<$index> on the list, if $index is negative,
the list is indexed from the end.

=back

=cut

package Language::Prolog::Types::ListOrNil;
our @ISA=qw(Language::Prolog::Types::Term);

use Carp;
sub larg      { croak "unimplemented virtual method" }
sub largs     { croak "unimplemented virtual method" }
sub length    { croak "unimplemented virtual method" }
sub tail      { croak "unimplemented virtual method" }


=head3 Language::Prolog::Types::Nil

Common abstract class for Prolog nil term representation.

=head4 Inherits

=over 4

=item L<Language::Prolog::Types::ListOrNil>

=back

=head4 Methods

This class doesn't define any method on its own.

=cut

package Language::Prolog::Types::Nil;
our @ISA=qw(Language::Prolog::Types::ListOrNil);

=head3 Language::Prolog::Types::Variable

Common abstract class for Prolog variable representation.

=head4 Inherits:

=over 4

=item L<Language::Prolog::Types::Term>

=back

=head4 Methods:

=over 4

=item C<$var-E<gt>name()>

returns the variable name.

=back

=cut

package Language::Prolog::Types::Variable;
our @ISA=qw(Language::Prolog::Types::Term);

use Carp;
sub name { croak "unimplemented virtual method" }
sub rename { croak "unimplemented virtual method" }

=head3 Language::Prolog::Types::Functor

Common abstract class for Prolog functor representations.

=head4 Inherits:

=over 4

=item L<Language::Prolog::Types::Term>

=back

=head4 Methods:

=over 4

=item C<$f-E<gt>functor()>

returns the functor name.

=item C<$f-E<gt>arity()>

returns the number of arguments of the functor.

=item C<$f-E<gt>fargs()>

returns the arguments of the functor.

=item C<$f-E<gt>farg($index)>

returns the argument of the functor in the position C<$index>, if
C<$index> is negative the arguments are indexed begining from the end.

Be aware that arguments are indexed from 0, not from 1 as in prolog.

=back

=cut

package Language::Prolog::Types::Functor;
our @ISA=qw(Language::Prolog::Types::Term);

use Carp;
sub functor { croak "unimplemented virtual method" }
sub arity   { croak "unimplemented virtual method" }
sub farg    { croak "unimplemented virtual method" }
sub fargs   { croak "unimplemented virtual method" }


=head3 Language::Prolog::Types::List

Common abstract class for Prolog list representations.

=head4 Inherits:

=over 4

=item L<Language::Prolog::Types::Functor>

A Prolog list is actually the functor '.'/2. i.e.

  [1, 4, hello, foo]

is equivalent to:

  '.'(1, '.'(4, '.'(hello, '.'(foo, []))))


=item L<Language::Prolog::Types::ListOrNil>

List methods are shared with L<Language::Prolog::Types::Nil> and this
is the reasong, to descent also from this class.

=back

=head4 Methods:

=over 4

=item C<$l-E<gt>car()>

returns the list C<car>.

=item C<$l-E<gt>cdr()>

returns the list C<cdr>.

=item C<$l-E<gt>car_cdr()>

returns both the C<car> and the C<cdr> of the list.

=back

=cut

package Language::Prolog::Types::List;
our @ISA=qw(Language::Prolog::Types::Functor
	    Language::Prolog::Types::ListOrNil);
use Carp;
sub car     { croak "unimplemented virtual method" }
sub cdr     { croak "unimplemented virtual method" }
sub car_cdr { croak "unimplemented virtual method" }

# default implementation of Functor methods for Lists
sub functor { '.' }
sub fargs { shift->car_cdr }
sub farg {
    my ($self, $index)=@_;
    return $self->car if $index==0;
    return $self->cdr if $index==1;
    croak "farg index $index out of range for '.'/2";
}


=head3 Language::Prolog::Types::UList

Common abstract class to represent unfinished lists (those whose tail
is not nil).

=head4 Inherits:

=over 4

=item L<Language::Prolog::Types::List>

=back

=head4 Methods:

None of its own.

=cut

package Language::Prolog::Types::UList;
our @ISA=qw(Language::Prolog::Types::List);
use Carp;


=head3 Language::Prolog::Types::Unknow

just in case...

=head4 Inherits:

=over 4

=item L<Language::Prolog::Types::Term>

=back

=head4 Methods:

None.

=cut


package Language::Prolog::Types::Unknow;
our @ISA=qw(Language::Prolog::Types::Term);

sub id { '*unknow*' }

=head3 Language::Prolog::Types::Opaque

This class should be only used by Prolog <-> Perl interface authors.

Usually Perl objects are converted to Prolog structures when passed to
a Prolog implementation. This class defines a proxy that stops the
conversion to happen and just pass a reference to the Perl object.

Opaque objects should not be returned from Prolog interfaces, they
should only be used to indicate to the Prolog implementations to not
convert Perl data to Prolog. When returning from Prolog the original
object should be directly returned to improve usability.

It should be noted that not all prolog implementations would support
this type.


=head4 Inherits:

=over 4

=item L<Language::Prolog::Types::Term>

=back

=head4 Methods:

=over 4

=item C<$this-E<gt>opaque_reference>

returns the object that it shields from prolog

=item C<$this->E<gt>opaque_comment>

returns comment string that will show in Prolog representation

=item C<$this->E<gt>opaque_class>

returns object class as should been seen from Prolog side

=back

=cut

package Language::Prolog::Types::Opaque;
our @ISA=qw(Language::Prolog::Types::Term);
use Carp;

sub opaque_reference { croak "unimplemented virtual method" }

sub opaque_comment { return '-' }

sub opaque_class { return ref shift }


=head3 Language::Prolog::Types::Opaque::Auto

Not really an abstract class but a simple implementation to be used as
a base class to provide automatic opacity to objects.

So, objects of any class that has it as an ancestor will be passed to
prolog as a reference.

=cut


package Language::Prolog::Types::Opaque::Auto;
our @ISA=qw(Language::Prolog::Types::Opaque);

sub opaque_reference { return shift }


1; # module ok


=head1 SEE ALSO

L<Language::Prolog::Types>.

L<Language::Prolog::Types::Internal> contains an actual implementation
for the classes defined in this module.

Any good Prolog book will also help :-)

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2007 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
