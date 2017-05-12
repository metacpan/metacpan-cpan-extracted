package Language::Prolog::Types::Factory;

our $VERSION = '0.09';

use strict;
use warnings;

use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( prolog_list
		  prolog_ulist
		  prolog_functor
		  prolog_variable
		  prolog_variables
		  prolog_var
		  prolog_nil
		  prolog_atom
		  prolog_string
		  prolog_chain
		  prolog_opaque
		);

use Language::Prolog::Types::Abstract;

my $factory;

# ctors:
sub prolog_list {
    @_<1
	? $factory->new_nil
	    : $factory->new_list(@_);
}

sub prolog_ulist {
    if (@_<2) {
	return $_[0] if @_==1;
	croak "prolog_ulist requires 1 or more arguments";
    }
    my $tail=pop @_;
    # expand tail when it is some kind of list:
    if(prolog_is_list_or_nil($tail)) {
	prolog_is_nil($tail)
	    and return $factory->new_list(@_);
	prolog_is_ulist($tail)
	    and return prolog_ulist( @_, $tail->largs, $tail->tail);
	return prolog_list( @_,
			    prolog_list2perl_list($tail))
    }
    $factory->new_ulist(@_, $tail)
}

sub prolog_functor ($@ ) {
    prolog_is_atom($_[0]) or
	croak "funtor name '$_[0]' is not an atom";
    # functor without args is actually an atom
    @_>1 or return $_[0];
    # '.'/2 is promoted to list:
    return prolog_ulist($_[1], $_[2])
	if ($_[0] eq '.' and @_==3);
    $factory->new_functor(@_)
}

sub prolog_variable ($ ) { $factory->new_variable(@_) }

sub prolog_variables { map { prolog_variable $_ } @_ }

sub prolog_nil () { $factory->new_nil }

sub prolog_atom ($ ) { "$_[0]" }

sub prolog_string ($ ) { prolog_list(unpack('C*', $_[0])) }

sub prolog_opaque ($ ) { $factory->new_opaque(@_) }

sub prolog_chain {
    my $functor=shift;
    if (@_<=1) {
	return $_[0] if @_;
	return ();
    }
    my $first=shift;
    prolog_functor($functor, $first, prolog_chain($functor, @_))
}

*prolog_var=\&prolog_variable;


sub factory () { $factory }
sub set_factory { $factory=$_[0] }


1;
__END__

=head1 NAME

Language::Prolog::Types::Factory - Perl extension to construct Prolog types

=head1 SYNOPSIS

  use Language::Prolog::Types::Factory;
  print prolog_functor("hello",2,3,4);
  print prolog_list(3,4,5);

  etc.

=head1 ABSTRACT

Factory module for Prolog terms.

Implements a pluggable interface that lets the constructor functions
be changed to use different implementations for the actual prolog
terms.

This module should be rarely used, only when interfacing Perl with a
different Prolog system if the default representations for Prolog
terms are not adecuate.


=head1 DESCRIPTION

This module implements a set of constructor functions for Prolog terms.

Internally the module use a factory object implementing C<new_nil>,
C<new_list>, C<new_ulist>, C<new_functor> and C<new_variable>. Look at
L<Language::Prolog::Types::Internal> for a real implementation of the
factory interface.

There is also some intelligency added to the consructors to
automatically promote types to others more adecuate. i.e. a '.'/2
functor to a list or [] to nil.

Constructor functions are reexported from L<Language::Prolog::Types>
and you should use that module instead of this one.

=head2 EXPORT

=over 4

=item prolog_nil()

returns nil term.

=item prolog_list(@terms)

returns a prolog list containing terms <@terms>.

=item prolog_ulist(@terms, $tail)

returns an unfinished list with terms C<@terms> and tail C<$tail>.

=item prolog_functor($name, @terms)

returns a functor with name C<$name> and arguments C<@terms>.

=item prolog_variable($name)
=item prolog_var($name)

return a new varaible with name C<$name>


=item prolog_atom($atom)

Is not a contructor but converts any perl construct C<$atom> to an atom.

=item prolog_string($string)

returns a prolog list formed by the ASCII values of C<$string>.


=back


=head1 SEE ALSO

L<Language::Prolog::Types>, L<Language::Prolog::Types::Internal> and
L<Language::Prolog::Types::Abstract>.

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
