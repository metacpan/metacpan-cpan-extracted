#! /usr/bin/env perl
use Test2::V0;
use Try::Tiny;
use Language::FormulaEngine;

#-----------------------------------------------------------------------------
# Example of compiling with a custom namespace
{
	package MyContext;
	use Moo;
	extends 'Language::FormulaEngine::Namespace';
	sub fn_customfunc { return "arguments are ".join(', ', @_)."\n"; }
};
subtest custom_namespace_function => sub {
	my $engine= Language::FormulaEngine->new(namespace => MyContext->new);
	my $formula= $engine->compile( 'CustomFunc(baz,2,3)' );
	is( $formula->({ baz => 42 }), "arguments are 42, 2, 3\n", 'correct result' );
};

#-----------------------------------------------------------------------------
# Example of compiling with overridden get_value
#
{
	package MyContext2;
	use Moo;
	extends 'Language::FormulaEngine::Namespace';
	sub fn_customfunc { return "arguments are ".join(', ', @_)."\n"; }
	sub get_value { return 1 + shift->next::method(@_); }
};
subtest custom_namespace_get_var => sub {
	my $engine= Language::FormulaEngine->new(
		namespace => { CLASS => 'MyContext2' },
	);
	my $formula= $engine->compile( 'CustomFunc(baz,2,3)' );
	is( $formula->({ baz => 42 }), "arguments are 43, 2, 3\n", 'correct result' )
		or diag 'code_body = '.$engine->compiler->code_body;
};

#-----------------------------------------------------------------------------
# Example of compiling with overridden get_value using deprecated
# variables_via_namespace compile option.
#
subtest deprecated_variables_via_namespace => sub {
	my $engine= do {
		local $SIG{__WARN__}= sub {}; # suppress the warning about variables_via_namespace being depricated
		Language::FormulaEngine->new(
			namespace => { CLASS => 'MyContext2' },
			compiler => { variables_via_namespace => 1 }
		);
	};
	my $formula= $engine->compile( 'CustomFunc(baz,2,3)' );
	is( $formula->(variables => { baz => 42 }), "arguments are 43, 2, 3\n", 'correct result' )
		or diag 'code_body = '.$engine->compiler->code_body;
};

#-----------------------------------------------------------------------------
# Check whether any of the above tests left behind any FormulaEngine objects
#
subtest leak_check => sub {
	skip_all "Devel::Gladiator is not available"
		unless eval { require Devel::Gladiator; };
	my $current_arena= Devel::Gladiator::walk_arena();
	my @leaked_objects= grep ref($_) =~ /^Language::FormulaEngine/, @$current_arena;
	# Note: checking for leftover FormulaEngine objects also effectively checks for leftover
	# compiled formulas, because a compiled formula holds a reference to the Namespace
	ok( 0 == @leaked_objects, 'all formula engine objects cleaned up' )
		or diag @leaked_objects;
	@$current_arena= ();
};

done_testing;
