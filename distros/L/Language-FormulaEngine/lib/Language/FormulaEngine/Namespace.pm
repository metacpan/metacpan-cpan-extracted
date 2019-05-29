package Language::FormulaEngine::Namespace;
use Moo;
use Carp;
use Try::Tiny;
use Language::FormulaEngine::Error ':all';
use namespace::clean;

# ABSTRACT: Object holding function and variable names
our $VERSION = '0.03'; # VERSION


has variables            => ( is => 'rw', default => sub { +{} } );
has constants            => ( is => 'rw', default => sub { +{} } );
has die_on_unknown_value => ( is => 'rw' );


sub clone {
	my $self= shift;
	my %attrs= @_==1 && ref $_[0] eq 'HASH'? %{$_[0]} : @_;
	$attrs{variables} ||= { %{ $self->variables } };
	$attrs{constants} ||= { %{ $self->constants } };
	$self->new( %$self, %attrs );
}

sub clone_and_merge {
	my $self= shift;
	my %attrs= @_==1 && ref $_[0] eq 'HASH'? %{$_[0]} : @_;
	$attrs{variables}= { %{ $self->variables }, %{ $attrs{variables}||{} } };
	$attrs{constants}= { %{ $self->constants }, %{ $attrs{constants}||{} } };
	$self->new( %$self, %attrs );
}


sub get_constant {
	my ($self, $name)= @_;
	$name= lc $name;
	$self->{constants}{$name};
}

sub get_value {
	my ($self, $name)= @_;
	$name= lc $name;
	exists $self->{variables}{$name}? $self->{variables}{$name}
	: exists $self->{constants}{$name}? $self->{constants}{$name}
	: !$self->die_on_unknown_value? undef
	: die ErrREF("Unknown variable or constant '$_[1]'");
}

sub get_function {
	my ($self, $name)= @_;
	$name= lc $name;
	my $info= $self->{_function_cache}{$name} ||= do {
		my $fn= $self->can("fn_$name");
		my $ev= $self->can("nodeval_$name");
		my $pl= $self->can("perlgen_$name");
		$fn || $ev || $pl? {
			($fn? ( native => $fn ) : ()),
			($ev? ( evaluator => $ev ) : ()),
			($pl? ( perl_generator => $pl ) : ())
		} : 1;
	};
	return ref $info? $info : undef;
}


sub evaluate_call {
	my ($self, $call)= @_;
	my $name= $call->function_name;
	my $info= $self->get_function($name)
		or die ErrNAME("Unknown function '$name'");
	# If the namespace supplies a special evaluator method, use that
	if (my $eval= $info->{evaluator}) {
		return $self->$eval($call);
	}
	# Else if the namespace supplies a native plain-old-function, convert the parameters
	# from parse nodes to plain values and then call the function.
	elsif (my $fn= $info->{native}) {
		# The function might be a perl builtin, so need to activate the same
		# warning flags that would be used by the compiled version.
		use warnings FATAL => 'numeric', 'uninitialized';
		my @args= map $_->evaluate($self), @{ $call->parameters };
		return $fn->(@args);
	}
	# Else the definition of the function is incomplete.
	die ErrNAME("Incomplete function '$name' cannot be evaluated");
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::FormulaEngine::Namespace - Object holding function and variable names

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  my $ns= Language::FormulaEngine::Namespace->new( values => \%val_by_name );

=head1 DESCRIPTION

A FormulaEngine Namespace is an object that provides a set of functions and named values.
It can also affect language semantics through it's implementation of those functions.

The default implementation provides all functions of its own namespace which begin with
the prefix "fn_" or "eval_", and provides them case-insensitive.  Named values are provided
from hashrefs of L</constants> and L</variables>, also case-insensitive.

You can subclass this (or just write a class with the same interface) to provide more advanced
lookup for the functions or values.

=head1 ATTRIBUTES

=head2 variables

A hashref of C<< name => value >> which formulas may reference.  The keys should be lowercase,
and incoming variable requests will be converted to lowercase before checking this hash.
Variables will not be "compiled" into perl coderefs, and will be looked up from the namespace
every time a formula is evaluated.

=head2 constants

Same as L</variables>, but these may be compiled into coderefs.

=head2 die_on_unknown_value

Controls behavior of L</get_value>.  If false (the default) unknown symbol names will resolve
as perl C<undef> values.  If true, unknown symbol names will throw an
L<ErrREF exception|Language::FormulaEngine::Error/ErrREF>.

=head1 METHODS

=head2 clone

  my $ns2= $ns1->clone(variables => \%different_vars);

Return a copy of the namespace, optionally with some attributes overridden.

=head2 clone_and_merge

  my $ns2= $ns1->clone_and_merge(variables => \%override_some_vars);

Return a copy of the namespace, with any new attributes merged into the existing ones.

=head2 get_constant

  my $val= $ns->get_constant( $symbolic_name );

Mehod to check for availability of a named constant, before assuming that a name is a variable.
This never throws an exception; it returns C<undef> if no constant exists by that name.

=head2 get_value

  my $val= $ns->get_value( $symbolic_name );

Lowercases C<$symbolic_name> and then looks in C<variables> or C<constants>.  May die depending
on setting of L</die_on_unknown_value>.

=head2 get_function

  $ns->get_function( $symbolic_name );
  
  # Returns:
  # {
  #   native         => $coderef,
  #   evaluator      => $method,
  #   perl_generator => $method,
  # }

If a function by this name is available in the namespace, ths method returns a hashref of
information about it.  It may include some or all of the following:

=over

=item native

A native perl implementation of this function.  Speficially, a non-method plain old function
that takes a list of values (not parse nodes) and returns the computed value.

Note that if C<< Sub::Util::subname($native) >> returns a name with colons in it, the compiler
will assume it is safe to inline this function name into the generated perl code.  (but this
only happens if C<perl_generator> was not available)

=item evaluator

A coderef or method name which will be called on the namespace to evaluate a parse tree for
this function.

  $value= $namespace->$evaluator( $parse_node );

=item perl_generator

A coderef or method name which will be called on the namespace to convert a parse tree into
perl source code.

  $perl= $namespace->$generator( $compiler, $parse_node );

=back

The default implementation lowercases the C<$symbolic_name> and then checks for three method
names: C<< $self->can("fn_$name") >>, C<< $self->can("nodeval_$name") >> and
C<< $self->can("perlgen_$name") >>.

=head2 evaluate_call

  my $value= $namespace->evaluate_call( $Call_parse_node );

Evaluate a function call, passing it either to a specialized evaluator or performing a more
generic evaluation of the arguments followed by calling a native perl function.

=head1 FUNCTION LIBRARY

Theis base Namespace class does not contain any user-visible functions; those are found within
the sub-classes such L<Language::FormulaEngine::Namespace::Default>.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
