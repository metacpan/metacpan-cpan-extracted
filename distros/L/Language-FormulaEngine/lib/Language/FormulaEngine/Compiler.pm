package Language::FormulaEngine::Compiler;

# This is at the top of the file to make sure the eval namespace is as clean as possible
# Need a second package to avoid getting clobbered by namespace::clean
sub Language::FormulaEngine::Compiler::_CleanEval::_clean_eval {
	use strict; # these apply to the contents of the eval, too.
	use warnings;
	# Arguments are ($compiler, $perl_code)
	my $default_namespace= $_[0]->namespace; # referred to by evals
	eval $_[1];
}

use Moo;
use Carp;
use Try::Tiny;
use Scalar::Util 'blessed';
use Sub::Util 'subname', 'set_subname';
use namespace::clean;

# ABSTRACT: Compile a parse tree into perl code
our $VERSION = '0.07'; # VERSION

*_clean_eval= *Language::FormulaEngine::Compiler::_CleanEval::_clean_eval;


has namespace               => ( is => 'rw', trigger => 1 );
has optimize_var_access     => ( is => 'rw', trigger => 1 );
has output_api              => ( is => 'rw', trigger => 1, default => 'function_of_vars' );
has _optimize_var_access    => ( is => 'lazy', clearer => 1 ); # holds the effective value of optimize_var_access

has variables_via_namespace => ( is => 'rw' ); # Deprecated

has error                   => ( is => 'rw' );
has code_body               => ( is => 'rw' );

has _perl_generator_cache   => ( is => 'lazy', clearer => 1, default => sub { {} } );

sub _trigger_namespace {
	my ($self, $newval)= @_;
	$self->_clear_perl_generator_cache if $newval ne ($self->{_cur_namespace}||'');
	$self->_clear_optimize_var_access;
	$self->{_cur_namespace}= $newval;
}

sub _trigger_optimize_var_access {
	shift->_clear_optimize_var_access;
}

sub _trigger_output_api {
	shift->_clear_optimize_var_access;
}

sub _build__optimize_var_access {
	my $self= shift;
	return $self->optimize_var_access if defined $self->optimize_var_access;
	return ($self->output_api =~ /^function_of_vars/)
		&& $self->namespace->can('get_value') == Language::FormulaEngine::Namespace->can('get_value');
}

sub BUILD {
	my ($self, $args)= @_;
	# Handle back-compat for initial broken version of this feature.
	# There is no longer any reason to set variables_via_namespace to true, because true is the default.
	# So if a user does that, they might be asking for the 'output_api => "function_of_namespace"'
	if (defined $self->variables_via_namespace) {
		carp "variables_via_namespace is deprecated.  See 'output_api' and 'optimize_var_access'";
		$self->output_api('function_of_namespace');
		$self->optimize_var_access(0);
	}
}


sub compile {
	my ($self, $parse_tree, $subname)= @_;
	my $ret;
	$self->reset;
	try {
		$self->code_body($self->perlgen($parse_tree));
		$ret= $self->generate_coderef_wrapper($self->code_body, $subname);
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
	my $wrapper_method= $self->can('_output_wrapper__'.$self->output_api)
		or Carp::croak("Unsupported output_api='".$self->output_api."'");
	my $code= join "\n", $self->$wrapper_method(qq{# line 0 "compiled formula"\n$perl});
	my $ret;
	{
		local $@= undef;
		if (defined ($ret= $self->_clean_eval($code))) {
			set_subname $subname, $ret if defined $subname;
		} else {
			$self->error($@);
		}
	}
	return $ret;
}

sub _output_wrapper__function_of_vars {
	my ($self, $code)= @_;
	return $self->_optimize_var_access? (
		'# line '.(__LINE__+1),
		'my $namespace= $default_namespace;',
		'sub {',
		'  use warnings FATAL => qw( uninitialized numeric );',
		'  my $vars= $namespace->variables;',
		'  $vars= { %$vars, (@_ == 1? %{$_[0]} : @_) } if @_;',
		$code,
		'}'
	) : (
		'# line '.(__LINE__+1),
		'sub {',
		'  use warnings FATAL => qw( uninitialized numeric );',
		'  my $namespace= @_ == 0? $default_namespace',
		'    : $default_namespace->clone_and_merge(variables => (@_ == 1 && ref $_[0] eq "HASH"? $_[0] : { @_ }));',
		$code,
		'}'
	)
}

sub _output_wrapper__function_of_vars_no_default {
	my ($self, $code)= @_;
	return $self->_optimize_var_access? (
		'# line '.(__LINE__+1),
		'my $namespace= $default_namespace;',
		'sub {',
		'  use warnings FATAL => qw( uninitialized numeric );',
		'  my $vars= @_ == 1? $_[0] : { @_ };',
		$code,
		'}'
	) : (
		'# line '.(__LINE__+1),
		'sub {',
		'  use warnings FATAL => qw( uninitialized numeric );',
		'  my $namespace= ref($default_namespace)->new(variables => (@_ == 1? $_[0] : { @_ }));',
		$code,
		'}'
	)
}

sub _output_wrapper__function_of_namespace {
	my ($self, $code)= @_;
	return
		'# line '.(__LINE__+1),
		'sub {',
		'  use warnings FATAL => qw( uninitialized numeric );',
		'  my $namespace= @_ == 0? $default_namespace',
		'    : @_ == 1 && Scalar::Util::blessed($_[0])? $_[0]',
		'    : $default_namespace->clone_and_merge(@_);',
		($self->_optimize_var_access? '  my $vars= $namespace->variables;' : ()),
		$code,
		'}'
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
	return $self->_optimize_var_access
		? '$vars->{'.$self->perlgen_string_literal(lc $varname).'}'
		: '$namespace->get_value('.$self->perlgen_string_literal($varname).')';
}


sub perlgen_string_literal {
	my ($self, $string)= @_;
	$string =~ s/([\0-\x1F\x7f"\@\$\%\\])/ sprintf("\\x%02x", ord $1) /gex;
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

version 0.07

=head1 DESCRIPTION

The Compiler object takes a parse tree and generates perl code from it, and also evals
that perl code into a compiled coderef.  However, most of the code generation is handled
by the L<Language::FormulaEngine::Namespace> object.  The namespace object must be
available during compilation.  In the default scenario, the namespace object will be
consulted for default constants and "global" variables, and then the generated coderef
will accept additional variables to overlay on those global variables, but the Namespace
will still get to determine how to access that pool of combined variables at execution.

For alternative strategies, see the C<output_api> attribute below.

=head1 ATTRIBUTES

=head2 namespace

Instance of L<Language::FormulaEngine::Namespace> to use for looking up functions,
converting functions to perl code, and symbolic constants.  This namespace object will
be referenced by the coderefs, and can act as a "global scope".

=head2 output_api

Determines the function signature of the coderef that will be generated.  Currently supported
values are:

=over 25

=item C<"function_of_vars">

  # generated coderef signature:
  $value = $coderef->(%vars);
  $value = $coderef->(\%vars);

The list or hashref of variables will get overlaid ontop of the set of variables of the
namespace (by creating a derived namespace), and the namespace C<get_value> method will
retrieve values from them.

=item C<"function_of_vars_no_default">

Same signature as "function_of_vars" but current C<< $namespace->variables >> are ignored
and either a new empty namespace is created each time, or (if C<optimize_var_access> is
active) no namespace will be used at all and vars will be read directly from a hashref.

=item C<"function_of_namespace">

  # generated coderef signature:
  $value= $coderef->();
  $value= $coderef->($namespace);
  $value= $coderef->(\%namespace_attributes);

This either uses the supplied namespace *instead* of the default, or merges attributes with
the default namespace via L<Language::FormulaEngine::Namespace/clone_and_merge>.

=back

=head2 optimize_var_access

By default, when a formula accesses a variable it will call L<Language::FormulaEngine::Namespace/get_value>
but for higher performance, you can have the formula directly access the variables hashref,
bypassing C<get_value>.

If this attribute is not set, the compilation will default to using the optimization if the
L</namespace> is using the default implementation of C<get_value> (i.e. has not been overridden
by a subclass) and the coderefs are a function of variables.

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
looked up from the L</namespace> at the time the formula is invoked.

See attribute C<output_api> for the signature and behavior of this coderef.

Because the generated coderef contains a reference to the namespace, be sure never to store
one of the coderefs into that namespace object, else you get a memory leak.

The second argument C<$subname> is optional, but provided to help encourage use of
L<Sub::Util/set_subname> for generated code.

=head2 reset

Clear any temporary results from the last compilation.  Returns C<$self>.

=head2 generate_coderef_wrapper

  my $coderef= $compiler->generate_coderef_wrapper($perl_code, $subname);

Utility method used by L</compile> that wraps a bit of perl code with the relevant boilerplate
according to L</output_api>, and then evals the perl to create the coderef.

On a compile failure, this returns C<undef> and puts the error message into L</error>.

=head2 perlgen

  $perl_code= $compiler->perlgen( $parse_node );

Generate perl source code for a parse node.  This is a fragment, not a whole sub.
The code should always be an expression which can be combined with other
function calls.

=head2 perlgen_var_access

  $compiler->perlgen_var_access($varname);

Generate perl code to access a variable.  Unless L</optimize_var_access> is true,
this becomes a call to C<< $namespace->get_value($varname) >>, and the namespace
decides how to interpret the variable at execution time.  If C<optimize_var_access>
is enabled, this returns a reference to the C<$vars> hashref like C<< $vars->{$varname} >>.

=head2 perlgen_string_literal

Generate a perl string literal.  This wraps the string with double-quotes and escapes control
characters and C<["\\\@\$]> using hex-escape notation.  Hex escapes are chosen over simple
backslash prefixes for extra security, in case of mistakes elsewhere in the generated code.

=head2 perlgen_literal

If the scalar can be exactly represented by a perl numeric literal, this returns that literal,
else it wraps the string with qoutes using L</perlgen_string_literal>.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
