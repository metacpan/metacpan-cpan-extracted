#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
#use Unknown::Values;

{
	package GIDTest::Class;
	use GID::Class;

	has last_index => ( is => 'rw' );

	sub test_last_index {
		return last_index { $_ eq 1 } ( 1,1,1,1 );
	}
}

{
	package GIDTest::Class2;
	use GID::Class;
	extends 'GIDTest::Class';

	has readonly => ( is => 'ro' );
	has after => ( is => 'ro' );
#	has unknown => ( is => 'ro', default => sub { unknown } );
}

my $t = GIDTest::Class->new( last_index => 1 );

is($t->last_index,1,'last_index is set proper via constructor');
isa_ok($t,'GID::Object');
isa_ok($t,'Moo::Object');
$t->last_index(2);
is($t->last_index,2,'last_index is changed proper');
is($t->test_last_index,3,'gid last_index still works fine');

my $t2 = GIDTest::Class2->new( readonly => 2, after => 3 );

is($t2->readonly,2,'readonly is set via constructor');
is($t2->after,3,'after is set via constructor');
#ok(is_unknown($t2->unknown),'Checking the unknown value');
isa_ok($t2,'GIDTest::Class');
isa_ok($t2,'GID::Object');
isa_ok($t2,'Moo::Object');

eval {
	$t2->readonly(1);
};

my $error = $@;

if ($error =~ m/^Usage/) {
	like($@,qr/Usage: GIDTest::Class2::readonly\(self\)/,'Failing on readonly overriding (via XS)');
} else {
	like($@,qr/readonly is a read\-only accessor/,'Failing on readonly overriding');
}

done_testing;
