#!/usr/bin/perl -w

# Test File::Tasks::Provider

use strict;

# Execute the tests
use Test::More tests => 13;
use File::Tasks;





#####################################################################
# Basic Errors

my $P = 'File::Tasks::Provider';
is( $P->compatible,        '', '->compatible returns undef for no arguments' );
is( $P->compatible(undef), '', '->compatible(undef) returns undef' );
is( $P->compatible(''),    '', "->compatible('') return undef" );





#####################################################################
# Various scalars and the like

# Basic scalar
       is( $P->compatible('foo'), 1, '->compatible(string) returns true' );
is_deeply( $P->content('foo'), \"foo", '->content(string) return correctly' );

# SCALAR reference
       is( $P->compatible(\"foo"), 1, '->compatible(SCALAR) returns true' );
is_deeply( $P->content(\"foo"), \"foo", '->content(SCALAR) returns correctly' );

# ARRAY reference without newlines
my $array = [ 'foo', 'bar' ];
       is( $P->compatible($array), 1, '->compatible(ARRAY) returns true' );
is_deeply( $P->content($array), \"foo\nbar\n", '->content(ARRAY) returns correctly' );

# ARRAY reference with newlines
$array = [ "foo\n", "bar\n" ];
       is( $P->compatible($array), 1, '->compatible(ARRAY) returns true' );
is_deeply( $P->content($array), \"foo\nbar\n", '->content(ARRAY) returns correctly' );

# HASH reference fails
my $hash = { foo => 'bar' };
is( $P->compatible($hash), '', '->compatible(HASH) returns undef' );

SKIP: {
	eval { require Archive::Builder };
	skip 'Archive::Builder is not installed', 1 if $@;

	# Create a basic Archive::Builder
	my $Builder = Archive::Builder->new;
	isa_ok( $Builder, 'Archive::Builder' );
}

exit(0);
