package Language::FormulaEngine;
use Moo;
use Carp;
use Try::Tiny;
use Module::Runtime 'require_module';

# ABSTRACT: Parser/Interpreter/Compiler for simple spreadsheet formula language
our $VERSION = '0.04'; # VERSION


has parser => (
	is => 'lazy',
	builder => sub {},
	coerce => sub { _coerce_instance($_[0], 'parse', 'Language::FormulaEngine::Parser') }
);
has namespace => (
	is => 'lazy',
	builder => sub {},
	coerce => sub { _coerce_instance($_[0], 'get_function', 'Language::FormulaEngine::Namespace::Default') },
	trigger => sub { my ($self, $val)= @_; $self->compiler->namespace($val) },
);
has compiler => (
	is => 'lazy',
	builder => sub {},
	coerce => sub { _coerce_instance($_[0], 'compile', 'Language::FormulaEngine::Compiler') }
);

sub BUILD {
	my $self= shift;
	$self->compiler->namespace($self->namespace);
}

sub _coerce_instance {
	my ($thing, $req_method, $default_class)= @_;
	return $thing if ref $thing and ref($thing)->can($req_method);
	
	my $class= !(defined $thing || ref $thing)? $default_class
		: ($req_method eq 'get_function' && $thing =~ /^[0-9]+$/)? "Language::FormulaEngine::Namespace::Default::V$thing"
		: $thing;
	require_module($class)
		unless $class->can('new');
	
	my @args= !ref $thing? ()
		: (ref $thing eq 'ARRAY')? @$thing
		: $thing;
	return $class->new(@args);
}


sub evaluate {
	my ($self, $text, $vars)= @_;
	$self->parser->parse($text)
		or die $self->parser->error;
	my $ns= $self->namespace;
	$ns= $ns->clone_and_merge(variables => $vars) if $vars && %$vars;
	return $self->parser->parse_tree->evaluate($ns);
}


sub compile {
	my ($self, $text)= @_;
	$self->parser->parse($text)
		or die $self->parser->error;
	$self->compiler->namespace($self->namespace);
	$self->compiler->compile($self->parser->parse_tree)
		or die $self->compiler->error;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::FormulaEngine - Parser/Interpreter/Compiler for simple spreadsheet formula language

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  my $vars= { foo => 1, bar => 3.14159265358979, baz => 42 };
  
  my $engine= Language::FormulaEngine->new();
  $engine->evaluate( 'if(foo, round(bar, 3), baz*100)', $vars );
  
  # or for more speed on repeat evaluations
  my $formula= $engine->compile( 'if(foo, round(bar, 3), baz*100)' );
  print $formula->($vars);
  
  
  package MyNamespace {
    use Moo;
    extends 'Language::FormulaEngine::Namespace::Default';
    sub fn_customfunc { print "arguments are ".join(', ', @_)."\n"; }
  };
  my $engine= Language::FormulaEngine->new(namespace => MyNamespace->new);
  my $formula= $engine->compile( 'CustomFunc(baz,2,3)' );
  $formula->($vars); # prints "arguments are 42, 2, 3\n"

=head1 DESCRIPTION

This set of modules implement a parser, evaluator, and optional code generator for a simple
expression language similar to those used in spreadsheets.
The intent of this module is to help you add customizable behavior to your applications that an
"office power-user" can quickly learn and use, while also not opening up security holes in your
application.

In a typical business application, there will always be another few use cases that the customer
didn't know about or think to tell you about, and adding support for these use cases can result
in a never-ending expansion of options and chekboxes and dropdowns, and a lot of time spent
deciding the logical way for them to all interact.
One way to solve this is to provide some scripting support for the customer to use.  However,
you want to make the language easy to learn, "nerfed" enough for them to use safely, and
prevent security vulnerabilities.  The challenge is finding a language that they find familiar,
that is easy to write correct programs with, and that dosn't expose any peice of the system
that you didn't intend to expose.  I chose "spreadsheet formula language" for a project back in
2012 and it worked out really well, so I decided to give it a makeover and publish it.

The default syntax is pure-functional, in that each operation has exactly one return value, and
cannot modify variables; in fact none of the default functions have any side-effects.  There is
no assignment, looping, or nested data structures.  The language does have a bit of a Perl twist
to it's semantics, like throwing exceptions rather than returning C<< #VALUE! >>, fluidly
interpreting values as strings or integers, and using L<DateTime> instead of days-since-1900
numbers for dates, but most users probably won't mind.  And, all these decisions are fairly
easy to change with a subclass.
(but if you want big changes, you should L<review your options|/"SEE ALSO"> to make sure you're
starting with the right module.)

The language is written with security in mind, and (until you start making changes)
should be safe for most uses, since the functional design promotes O(1) complexity
and shouldn't have side effects on the data structures you expose to the user.
The optional L</compile> method does use C<eval> though, so you should do an audit for
yourself if you plan to use it where security is a concern.

B<Features:>

=over

=item *

Standard design with scanner/parser, syntax tree, namespaces, and compiler.

=item *

Can compile to perl coderefs for fast repeated execution

=item *

Provides metadata about what it compiled

=item *

Designed for extensibility

=item *

Light-weight, few dependencies, clean code

=item *

Recursive-descent parse, which is easier to work with and gives helpful error messages,
though could get a bit slow if you extend the grammar too much.
(for simple grammars like this, it's pretty fast)

=back

=head1 ATTRIBUTES

=head2 parser

A parser for the language.  Responsible for tokenizing the input and building the
parse tree.

Defaults to an instance of L<Language::FormulaEngine::Parser>. You can initialize this
attribute with an object instance, a class name, or arguments for the default parser.

=head2 namespace

A namespace for looking up functions or constants.  Also determines some aspects of how the
language works, and responsible for providing the perl code when compiling expressions.

Defaults to an instance of L<Language::FormulaEngine::Namespace::Default>.
You can initialize this with an object instance, class name, version number for the default
namespace, or hashref of arguments for the constructor.

=head2 compiler

A compiler for the parse tree.  Responsible for generating Perl coderefs, though the Namespace
does most of the perl code generation.

Defaults to an instance of L<Language::FormulaEngine::Compiler>.
You can initialize this attribute with a class instance, a class name, or arguments for the
default compiler.

=head1 METHODS

=head2 evaluate

  my $value= $fe->evaluate( $formula_text, \%variables );

This method creates a new namespace from the default plus the supplied variables, parses the
formula, then evaluates it in a recursive interpreted manner, returning the result. Exceptions
may be thrown during parsing or execution.

=head2 compile

  my $coderef= $fe->compile( $formula_text );

Parses and then compiles the C<$formula_text>, returning a coderef.  Exceptions may be thrown
during parsing or execution.

=head1 CUSTOMIZING THE LANGUAGE

The module is called "FormulaEngine" in part because it is designed to be customized.
The functions are easy to extend, the variables are somewhat easy to extend, the compilation
can be extended after a little study of the API, and the grammar itself can be extended with
some effort.

If you are trying to addd I<lots> of functionality, you might be starting with the wrong module.
See the notes in the L</"SEE ALSO"> section.

=head2 Adding Functions

The easiest thing to extend is the namespace of available functions.  Just subclass
L<Language::FormulaEngine::Namespace> and add the functions you want starting with the prefix
C<fn_>.

=head2 Complex Variables

The default implementation of Namespace requires all variables to be stored in a single hashref.
This default is safe and fast.  If you want to traverse nested data structures or call methods,
you also need to subclass L<Language::FormulaEngine::Namespace/get_value>.

=head2 Changing Semantics

The namespace is also in control of the behavior of the functions and operators (which are
themselves just functions).  It controls both the way they are evaluated and the perl code they
generate if compiled.

=head2 Adding New Operators

If you want to make small changes to the grammar, such as adding new prefix/suffix/infix
operators, this can be accomplished fairly easily by subclassing the Parser.  The parser just
returns trees of functions, and if you look at the pattern used in the recursive descent
C<parse_*> methods it should be easy to add some new ones.

=head2 Bigger Grammar Changes

Any customization involving bigger changes to the grammar, like adding assignments or multi-
statement blocks or map/reduce, would require a bigger rewrite.  Consider starting with
a different more powerful parsing system for that.

=head1 SEE ALSO

=over

=item L<Language::Expr>

A bigger more featureful expression language; perl-like syntax and data structures.
Also much more complicated and harder to customize.
Can also compile to Javascript!

=item L<Math::Expression>

General-purpose language, including variable assignment and loops, arrays,
and with full attention to security.  However, grammar is not customizable at all,
and math-centric.

=item L<Math::Expression::Evaluator>

Very similar to this module, but no string support and not very customizable.
Supports assignments, and compilation.

=item L<Math::Expr>

Similar expression parser, but without string support.
Supports arbitrary customization of operators.
Not suitable for un-trusted strings, according to BUGS documentation.

=back

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
