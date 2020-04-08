package Language::FormulaEngine::Compiler;

# This is at the top of the file to make sure the eval namespace is as clean as possible
# Need a second package to avoid getting clobbered by namespace::clean
sub Language::FormulaEngine::Compiler::_CleanEval::_clean_eval {
	use strict; # these apply to the contents of the eval, too.
	use warnings;
	# Arguments are ($compiler, $perl_code)
	my $default_namespace= shift->namespace;
	eval shift;
}

use Moo;
use Carp;
use Try::Tiny;
use Sub::Util 'subname', 'set_subname';
use namespace::clean;

# ABSTRACT: Compile a parse tree into perl code
our $VERSION = '0.05'; # VERSION

*_clean_eval= *Language::FormulaEngine::Compiler::_CleanEval::_clean_eval;


has namespace => ( is => 'rw', trigger => 1 );
has variables_via_namespace => ( is => 'rw' );

has error => ( is => 'rw' );
has code_body => ( is => 'rw' );

has _perl_generator_cache => ( is => 'lazy', clearer => 1, default => sub { {} } );

sub _trigger_namespace {
	my ($self, $newval)= @_;
	$self->_clear_perl_generator_cache if $newval ne ($self->{_prev_namespace}||'');
	$self->{_prev_namespace}= $newval;
}


sub compile {
	my ($self, $parse_tree, $subname)= @_;
	my $ret;
	$self->reset;
	try {
		$self->code_body($self->perlgen($parse_tree));
		$ret= $self->generate_coderef_wrapper($self->code_body);
	}
	catch {
		chomp unless ref $_;
		$self->error($_);
	};
	return $ret;
}


sub reset {
	my $self= shift;
	$self->error(undef);
	$self->code_body(undef);
	$self;
}


sub generate_coderef_wrapper {
	my ($self, $perl, $subname)= @_;
	$self->error(undef);
	my $wrapper= '# line '.__LINE__.'
sub {
  use warnings FATAL => qw( uninitialized numeric );'
.($self->variables_via_namespace? '
  my $namespace= @_? $default_namespace->clone_and_merge(@_) : $default_namespace;
  my $vars= $namespace->variables;'
  : '
  my $namespace= $default_namespace;
  my $vars= @_ == 1 && ref $_[0] eq "HASH"? $_[0] : { @_ };'
).'
# line 0 "compiled formula"
'.$perl.'
}';
	my $ret;
	{
		local $@= undef;
		if (defined ($ret= $self->_clean_eval($wrapper))) {
			set_subname $subname, $ret if defined $subname;
		} else {
			$self->error($@);
		}
	}
	return $ret;
}


sub perlgen {
	my ($self, $node)= @_;
	if ($node->can('function_name')) {
		my $name= $node->function_name;
		my $gen= $self->_perl_generator_cache->{$name} ||= $self->_get_perl_generator($name);
		return $gen->($self->namespace, $self, $node);
	}
	elsif ($node->can('symbol_name')) {
		my $name= $node->symbol_name;
		my $x= $self->namespace->get_constant($name);
		return defined $x? $self->perlgen_literal($x) : $self->perlgen_var_access($name);
	}
	elsif ($node->can('string_value')) {
		return $self->perlgen_string_literal($node->string_value);
	}
	elsif ($node->can('number_value')) {
		return $node->number_value+0;
	}
	else {
		die "Don't know how to compile node of type '".ref($node)."'\n";
	}
}

sub _get_perl_generator {
	my ($self, $name)= @_;
	my $info= $self->namespace->get_function($name)
		or die "No such function '$name'\n";
	# If a generator is given, nothing else to do.
	return $info->{perl_generator} if $info->{perl_generator};
	
	# Else need to create a generator around a native perl function
	$info->{native}
		or die "Cannot compile function '$name'; no generator or native function given\n";
	my $fqn= subname($info->{native}) || '';
	# For security, make reasonably sure that perl will parse the subname as a function name.
	# This regex is more restrictive than perl's actual allowed identifier names.
	$fqn =~ /^[A-Za-z_][A-Za-z0-9_]*::([A-Za-z0-9_]+::)*\p{Word}+$/
		or die "Can't compile function '$name'; native function does not have a valid fully qualified name '$fqn'\n";
	# Create a generator that injects this function name
	return sub {
		$fqn . '(' . join(',', map $_[1]->perlgen($_), @{ $_[2]->parameters }) . ')'
	};
}


sub perlgen_var_access {
	my ($self, $varname)= @_;
	my $var_str= $self->perlgen_string_literal($varname);
	return $self->variables_via_namespace
		? '$namespace->get_value('.$var_str.')'
		: '$vars->{'.$var_str.'}';
}


sub perlgen_string_literal {
	my ($self, $string)= @_;
	$string =~ s/([\0-\x1F\x7f"\@\$\\])/ sprintf("\\x%02x", ord $1) /gex;
	return qq{"$string"};
}


sub perlgen_literal {
	my ($self, $string)= @_;
	no warnings 'numeric';
	return ($string+0) eq $string? $string+0 : $self->perlgen_string_literal($string);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::FormulaEngine::Compiler - Compile a parse tree into perl code

=head1 VERSION

version 0.05

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 namespace

Namespace to use for looking up functions, converting functions to perl code, and symbolic
constants.  The namespace will also be bound into the coderefs which get compiled, so any
change to the variables (not constants) of the namespace will be visible to compiled formulas.

=head2 variables_via_namespace

When compiling formulas, one option is to look up all runtime variables (passed to the coderef)
through the C</namespace> object, allowing it to do custom processing to resolve the variables.
The other option (the default of C<false>) is to put all the coderef parameters into a hashref
and directly access that hashref, which is faster and avoids needing to create temporary
namespaces.

=head2 error

After a failed call to C<compile>, this attribute holds the error message.

=head2 code_body

After compilation, this attribute holds the perl source code that was generated prior to being
wrapped with the coderef boilerplate.

=head1 METHODS

=head2 compile( $parse_tree, $subname )

Compile a parse tree, returning a coderef.  Any references to functions will be immeditely
looked up within the L</namespace>.  Any references to constants in the L</namespace> will be
inlined into the generated perl.  Any other symbol is assumed to be a variable, and will be
looked up from the L</namespace> at the time the formula is invoked.  The generated coderef
takes parameters of overrides for the set of variables in the namespace:

  $value= $compiled_sub->(%vars); # vars are optional

Because the generated coderef contains a reference to the namespace, be sure never to store
one of the coderefs into that namespace object, else you get a memory leak.

The second argument C<$subname> is optional, but provided to help encourage use of
L<Sub::Util/set_subname> for generated code.

=head2 reset

Clear any temporary results from the last compilation.  Returns C<$self>.

=head2 generate_coderef_wrapper

  my $coderef= $compiler->generate_coderef_wrapper($perl_code, $subname);

Utility method used by L</compile> that wraps a bit of perl code with the relevant boilerplate
such as merging the coderef parameters into a temporary namespace, and then evals the perl
to create the coderef.

=head2 perlgen( $parse_node )

Generate perl source code for a parse node.

=head2 perlgen_var_access

  $compiler->perlgen_var_access($varname);

Generate perl code to access a variable.  If L</variables_via_namespace> is true, this becomes
a call to C<< $namespace->get_value($varname) >>.  Else it becomes a reference to the variables
hashref C<< $vars->{$varname} >>.

=head2 perlgen_string_literal

Generate a perl string literal.  This wraps the string with double-quotes and escapes control
characters and C<["\\\@\$]> using hex-escape notation.

=head2 perlgen_literal

If the scalar can be exactly represented by a perl numeric literal, this returns that literal,
else it wraps the string with qoutes using L</perlgen_string_literal>.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
