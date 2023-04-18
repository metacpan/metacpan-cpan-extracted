package Language::FormulaEngine::Namespace;
use Moo;
use Carp;
use Try::Tiny;
require MRO::Compat if $] lt '5.009005';
use Language::FormulaEngine::Error ':all';
use namespace::clean;

# ABSTRACT: Object holding function and variable names
our $VERSION = '0.07'; # VERSION


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

# potentially hot method
sub clone_and_merge {
	my $self= shift;
	my %attrs= @_==1 && ref $_[0] eq 'HASH'? %{$_[0]} : @_;
	$attrs{variables}= { %{ $self->variables }, ($attrs{variables}? %{ $attrs{variables} } : () ) };
	$attrs{constants}= { %{ $self->constants }, ($attrs{constants}? %{ $attrs{constants} } : () ) };
	$self->new( %$self, %attrs );
}


sub get_constant {
	my ($self, $name)= @_;
	$name= lc $name;
	$self->constants->{$name};
}

sub get_value {
	my ($self, $name)= @_;
	$name= lc $name;
	my $set= $self->variables;
	return $set->{$name} if exists $set->{$name};
	$set= $self->constants;
	return $set->{$name} if exists $set->{$name};
	die ErrREF("Unknown variable or constant '$_[1]'")
		if $self->die_on_unknown_value;
	return undef;
}

our %is_pure_function;
sub FETCH_CODE_ATTRIBUTES {
	my ($class, $ref)= @_;
	return $class->maybe::mext::method($ref), ($is_pure_function{$ref}? ('Pure') : ());
}
sub MODIFY_CODE_ATTRIBUTES {
	my ($class, $ref, @attr)= @_;
	my $n= @attr;
	@attr= grep $_ ne 'Pure', @attr;
	$is_pure_function{$ref}= 1 if $n > @attr;
	$class->maybe::next::method($ref, @attr);
}

sub get_function {
	my ($self, $name)= @_;
	$name= lc $name;
	# The value 0E0 is a placeholder for "no such function"
	my $info= $self->{_function_cache}{$name} ||= do {
		my %tmp= $self->_collect_function_info($name);
		keys %tmp? \%tmp : '0E0';
	};
	return ref $info? $info : undef;
}

sub _collect_function_info {
	my ($self, $name)= @_;
	my $fn= $self->can("fn_$name");
	my $sm= $self->can("simplify_$name");
	my $ev= $self->can("nodeval_$name");
	my $pure= $fn? $is_pure_function{$fn}
		: $ev? $is_pure_function{$ev}
		: 0;
	my $pl= $self->can("perlgen_$name");
	return
		($pure? ( is_pure_function => $pure ) : ()),
		($fn? ( native => $fn ) : ()),
		($sm? ( simplify => $sm ) : ()),
		($ev? ( evaluator => $ev ) : ()),
		($pl? ( perl_generator => $pl ) : ()),
		$self->maybe::next::method($name);
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


sub simplify_call {
	my ($self, $call)= @_;
	my ($same, $const)= (1,1);
	my @s_params= @{ $call->parameters };
	for (@s_params) {
		my $s= $_->simplify($self);
		$same &&= ($s == $_);
		$const &&= $s->is_constant;
		$_= $s;
	}
	$call= Language::FormulaEngine::Parser::Node::Call->new($call->function_name, \@s_params)
		unless $same;
	if (my $info= $self->get_function($call->function_name)) {
		if (my $method= $info->{simplify}) {
			return $self->$method($call);
		}
		# Are they all constants being passed to a pure function?
		elsif ($const && $info->{is_pure_function}) {
			my $val= $self->evaluate_call($call);
			return !defined $val? $call : $self->_parse_node_for_value($val);
		}
	}
	return $call;
}

sub simplify_symref {
	my ($self, $symref)= @_;
	local $self->{die_on_unknown_value}= 0;
	my $val= $self->get_value($symref->symbol_name);
	return !defined $val? $symref : $self->_parse_node_for_value($val);
}
sub _parse_node_for_value {
	my ($self, $val)= @_;
	# Take a guess at whether this should be a number or string...
	if (Scalar::Util::looks_like_number($val) && 0+$val eq $val) {
		return Language::FormulaEngine::Parser::Node::Number->new($val);
	} else {
		return Language::FormulaEngine::Parser::Node::String->new($val);
	}
}


sub find_methods {
	my ($self, $pattern)= @_;
	my $todo= mro::get_linear_isa(ref $self || $self);
	my (%seen, @ret);
	for my $pkg (@$todo) {
		my $stash= do { no strict 'refs'; \%{$pkg.'::'} };
		push @ret, grep +($_ =~ $pattern and defined $stash->{$_}{CODE} and !$seen{$_}++), keys %$stash;
	}
	\@ret;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::FormulaEngine::Namespace - Object holding function and variable names

=head1 VERSION

version 0.07

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

=head2 simplify_call

  $new_tree= $namespace->simplify_call( $parse_tree );

Create a simplified formula by reducing variables and evaluating
functions down to constants.  If all variables required by the
formula are defined, and true functions without side effects, this
will return a single parse node which is a constant the same as
evaluate() would return.

=head2 simplify_symref

  $parse_node= $namespace->simplify_symref( $parse_node );

This is a helper for the "simplify" mechanism that returns a parse
node holding the constant value of C<< $self->get_value($name) >>
if the value is defined, else passes-through the same parse node.

=head2 find_methods

Find methods on this object that match a regex.

  my $method_name_arrayref= $ns->find_methods(qr/^fn_/);

=head1 FUNCTION LIBRARY

Theis base Namespace class does not contain any user-visible functions; those are found within
the sub-classes such L<Language::FormulaEngine::Namespace::Default>.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
