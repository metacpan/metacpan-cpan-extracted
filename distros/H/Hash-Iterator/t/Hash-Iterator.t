# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Hash-Iterator.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More;
use Hash::Iterator;

my %hash = (
	a => 'one', b => 'two', c => 'three',
	array => [ qw(one two three) ],
	hash => { d => 'four', e => 'five', f => 'six' },
);

BEGIN {
	require_ok('Hash::Iterator');
}

my $Iterator = Hash::Iterator->new( %hash );

my $count = 0;
while ($Iterator->next) {
	is( $Iterator->{CurrentState}, $count++, "CurrentState: $count" );

	if ( $Iterator->is_ref('HASH') ){
		isa_ok( $Iterator->peek_value, 'HASH', "HASH $count" );
	}
	elsif ( $Iterator->is_ref('ARRAY') ) {
		isa_ok( $Iterator->peek_value, 'ARRAY' ,"ARRAY $count" );
	}
	else {
		is( $Iterator->peek_value, $hash{$Iterator->peek_key} , "peek_value: $hash{$Iterator->peek_key}" );
	}
}

$Iterator = Hash::Iterator->new( a => 1 );
$Iterator->next;
is( $Iterator->peek_key, 'a', 'peek_key' );
is( $Iterator->peek_value, '1', 'peek_value' );

$Iterator = Hash::Iterator->new( hash => { a => 1, b => 2 } );
$Iterator->next;
is( $Iterator->peek_key, 'hash', 'peek_key' );
isa_ok( $Iterator->peek_value, 'HASH', 'isa_ok HASH' );
ok( $Iterator->is_ref('HASH'), 'is_ref hash' );

$Iterator = Hash::Iterator->new( array => [ qw(a b c d) ] );
$Iterator->next;
is( $Iterator->peek_key, 'array', 'peek_key' );
isa_ok( $Iterator->peek_value, 'ARRAY', 'isa_ok HASH' );
ok( $Iterator->is_ref('ARRAY'), 'is_ref array' );

$Iterator = Hash::Iterator->new( a => 1, b => 2 );
$Iterator->next;
is( $Iterator->{CurrentState}, 0, 'next CurrentState' );
is( $Iterator->{PreviousState}, -1, 'next PreviousState' );
$Iterator->next;
is( $Iterator->{CurrentState}, 1, 'next iter CurrentState' );
is( $Iterator->{PreviousState}, 0, 'next iter PreviousState' );
$Iterator->previous;
is( $Iterator->{CurrentState}, 0, 'previous CurrentState' );
is( $Iterator->{PreviousState}, -1, 'previous PreviousState' );

eval {
	$Iterator = Hash::Iterator->new( a => 1);
	$Iterator->previous
		or die "Error previous";
};
pass("$@") if $@;

$Iterator = Hash::Iterator->new( a => 1, a => 2 );
$Iterator->next;
$Iterator->next;
eval {
	$Iterator->next
		or die 'Error';
};
pass( "$@" ) if $@;

eval {
	Hash::Iterator->new->next;
};

done_testing;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

