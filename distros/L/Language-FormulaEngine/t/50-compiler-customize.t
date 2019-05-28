#! /usr/bin/env perl
use Test2::V0;
use Try::Tiny;
use Language::FormulaEngine;

my $vars= { baz => 42 };
{
	package MyContext;
	use Moo;
	extends 'Language::FormulaEngine::Namespace';
	sub fn_customfunc { return "arguments are ".join(', ', @_)."\n"; }
};
my $engine= Language::FormulaEngine->new(namespace => MyContext->new);
my $formula= $engine->compile( 'CustomFunc(baz,2,3)' );
is( $formula->($vars), "arguments are 42, 2, 3\n", 'correct result' );

done_testing;
