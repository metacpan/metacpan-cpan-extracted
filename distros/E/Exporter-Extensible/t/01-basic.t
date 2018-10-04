#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok( 'Exporter::Extensible' ) or BAIL_OUT;

ok( eval q|
	package Example;
	$INC{'Example.pm'}=1;

	use Exporter::Extensible -exporter_setup => 0;
	our %EXPORT_TAGS= ( default => ['bar'] );
	sub foo :Export {}
	sub bar :Export {}
|, 'declare Example' ) or diag $@;

ok( eval q|
	package Example::Derived;
	$INC{'Example/Derived.pm'}=1;

	use Example -exporter_setup => 0;
	our %EXPORT_TAGS= ( default => ['foo'] );
	sub foo :Export {}
|, 'declare Example::Derived' ) or diag $@;

ok( !exists &foo, 'foo not imported yet' );
Example->import('foo');
ok( exists &foo, 'foo imported' );
is( \&foo, \&Example::foo, 'from package Example' );

undef *foo;

Example::Derived->import('foo');
is( \&foo, \&Example::Derived::foo, 'now from package Example::Derived' );

Example::Derived->import('bar');
is( \&bar, \&Example::bar, 'Example::Derived inherits parent\'s "bar"' );

Example::Derived->import_into('Test::_Ns1'); # invole :default
no strict 'refs';
is_deeply([ eval 'no strict "refs"; sort keys %{"Test::_Ns1::"};' ], ['bar','foo'], 'Export :default tag when no args' );

done_testing;
