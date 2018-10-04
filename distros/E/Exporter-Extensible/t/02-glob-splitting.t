#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok( 'Exporter::Extensible' ) or BAIL_OUT;

ok( eval q|
	package Example;
	$INC{'Example.pm'}=1;

	use Exporter::Extensible -exporter_setup => 0;
	sub foo :Export {}
	our $foo= 42;
	our @foo= ( 1, 2, 3 );
	our %foo= ( a => 1 );
	our $bar= 100;
	our @bar= ( 100, 100 );
	our %bar= ( a => 100 );
	sub bar { 100 }
	__PACKAGE__->exporter_register_symbol('$foo', \$foo);
	__PACKAGE__->exporter_register_symbol('%foo', \%foo);
	__PACKAGE__->exporter_register_symbol('@foo', \@foo);
	__PACKAGE__->exporter_register_symbol('*bar', \*bar);
	1;
|, 'declare Example' ) or diag $@;

sub same_scalar {
	my $name= shift;
	no strict 'refs';
	defined ${"CleanNamespace::$name"}
		and ++${"Example::$name"} == ${"CleanNamespace::$name"};
}
sub same_hash {
	my $name= shift;
	no strict 'refs';
	defined ${"CleanNamespace::"}{$name}
		and defined *{"CleanNamespace::$name"}{HASH}
		and defined ${"CleanNamespace::$name"}{a}
		and ++${"Example::$name"}{a} == ${"CleanNamespace::$name"}{a};
}
sub same_array {
	my $name= shift;
	no strict 'refs';
	defined ${"CleanNamespace::"}{$name}
		and defined *{"CleanNamespace::$name"}{ARRAY}
		and @{"CleanNamespace::$name"}
		and ++${"Example::$name"}[0] == ${"CleanNamespace::$name"}[0];
}
sub same_sub {
	my $name= shift;
	no strict 'refs';
	CleanNamespace->can($name)
		and CleanNamespace->can($name) == Example->can($name);
}

ok( !same_sub('foo'),    'foo not imported' );
ok( !same_scalar('foo'), '$foo not imported' );
ok( !same_array('foo'),  '@foo not imported' );
ok( !same_hash('foo'),   '%foo not imported' );

package CleanNamespace;
Example->import('foo');

package main;
ok( same_sub('foo'),     'foo imported' );
ok( !same_scalar('foo'), '$foo not imported' );
ok( !same_array('foo'),  '@foo not imported' );
ok( !same_hash('foo'),   '%foo not imported' );

package CleanNamespace;
Example->import('$foo');

package main;
ok( same_sub('foo'),     'foo imported' );
ok( same_scalar('foo'),  '$foo imported' );
ok( !same_array('foo'),  '@foo not imported' );
ok( !same_hash('foo'),   '%foo not imported' );

package CleanNamespace;
Example->import('@foo');

package main;
ok( same_sub('foo'),     'foo imported' );
ok( same_scalar('foo'),  '$foo imported' );
ok( same_array('foo'),   '@foo imported' );
ok( !same_hash('foo'),   '%foo not imported' );

package CleanNamespace;
Example->import('%foo');

package main;
ok( same_sub('foo'),     'foo imported' );
ok( same_scalar('foo'),  '$foo imported' );
ok( same_array('foo'),   '@foo imported' );
ok( same_hash('foo'),    '%foo imported' );

package CleanNamespace;
Example->import('*bar');

package main;
ok( same_sub('bar'),     '&bar imported' );
ok( same_scalar('bar'),  '$bar imported' );
ok( same_array('bar'),   '@bar imported' );
ok( same_hash('bar'),    '%bar imported' );
# need eval here or the glob will get vivified before running ->import(*bar)
eval q{
	local $Example::bar= 5;
	is( $CleanNamespace::bar, 5, 'local on *bar{SCALAR} works' );
	1;
} or die $@;
# need eval here or the glob will get vivified before running ->import(*bar)
eval q{
	local $CleanNamespace::bar= 6;
	is( $Example::bar, 6, 'and in reverse' );
	1;
} or die $@;

note "--- Now, try un-import ---";

package CleanNamespace;
Example->unimport('$foo');

package main;
ok( !same_scalar('foo'), '$foo no longer imported' );
ok( same_sub('foo'),     '&foo imported' );
ok( same_array('foo'),   '@foo imported' );
ok( same_hash('foo'),    '%foo imported' );

package CleanNamespace;
Example->unimport('@foo');

package main;
ok( !same_scalar('foo'), '$foo no longer imported' );
ok( !same_array('foo'),  '@foo no longer imported' );
ok( same_sub('foo'),     '&foo imported' );
ok( same_hash('foo'),    '%foo imported' );

package CleanNamespace;
Example->unimport('%foo');

package main;
ok( !same_scalar('foo'), '$foo no longer imported' );
ok( !same_array('foo'),  '@foo no longer imported' );
ok( !same_hash('foo'),   '%foo no longer imported' );
ok( same_sub('foo'),     '&foo imported' );

package CleanNamespace;
Example->unimport('foo');

package main;
ok( !same_scalar('foo'), '$foo no longer imported' );
ok( !same_array('foo'),  '@foo no longer imported' );
ok( !same_hash('foo'),   '%foo no longer imported' );
ok( !same_sub('foo'),    '&foo no longer imported' );

package CleanNamespace;
Example->unimport('*bar');

package main;
ok( !same_sub('bar'),     '&bar no longer imported' );
ok( !same_scalar('bar'),  '$bar no longer imported' );
ok( !same_array('bar'),   '@bar no longer imported' );
ok( !same_hash('bar'),    '%bar no longer imported' );

done_testing;
