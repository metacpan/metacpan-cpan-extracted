use Test::More tests => 2;
{{
	$name = join('::', split(/-/, $dist->name));
	'';
}}
BEGIN {
	use strict;
	$^W = 1;
	$| = 1;

    ok(($] > 5.008000), 'Perl version acceptable') or BAIL_OUT ('Perl version unacceptably old.');
    use_ok( '{{$name}}' );
    diag( "Testing {{$name}} ${{$name}}::VERSION" );
}

