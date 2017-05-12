#!perl -T

use Test::More tests => 1;
{{
	$name = join('::', split(/-/, $dist->name));
	'';
}}
BEGIN {
	use_ok( '{{$name}}' ) || print "Bail out!\n";
}

diag( "Testing {{$name}} ${{$name}}::VERSION, Perl $], $^X" );
