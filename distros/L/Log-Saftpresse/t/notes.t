#!perl

use Test::More tests => 19;

use_ok('Log::Saftpresse::Notes');

my $n = Log::Saftpresse::Notes->new;
isa_ok($n, 'Log::Saftpresse::Notes');

cmp_ok( $n->size, '==', 0, 'initial size must be 0' );
cmp_ok( $n->is_full, '==', 0, 'initial must be not full' );

$n->set('test' => 'testvalue');
cmp_ok( $n->get('test'), 'eq', 'testvalue', 'must be able to retrieve test entry');

cmp_ok( $n->size, '==', 1, 'new size must be 1' );

$n->remove('test');
ok( ! defined $n->get('test'), 'value must be undefined');
cmp_ok( $n->size, '==', 0, 'new size must be 0' );

$n->set('test1' => 'testvalue');
$n->set('test2' => 'testvalue');
$n->set('test3' => 'testvalue');
cmp_ok( $n->size, '==', 3, 'new size must be 3' );

$n->reset;
cmp_ok( $n->size, '==', 0, 'new size must be 0' );
ok( ! defined $n->get('test1'), 'value must be undefined');
ok( ! defined $n->get('test2'), 'value must be undefined');
ok( ! defined $n->get('test3'), 'value must be undefined');

my $max = $n->max_entries;
my $num = $max - 1;
for my $i ( 1..$num ) {
	$n->set( "test$i" => 'testvalue' );
}
cmp_ok( $n->size, '==', $num, "new size must be $num" );
cmp_ok( $n->is_full, '==', 0, 'initial must be not full' );

# now we reached the watermark
$n->set('more1' => 'testvalue');
cmp_ok( $n->size, '==', $max, "new size must be $max" );
cmp_ok( $n->is_full, '==', 1, 'initial must be full' );

# test overflow
for my $i ( 1..10 ) {
	$n->set( "more$i" => 'testvalue' );
}
cmp_ok( $n->size, '==', $max, "new size must be $max" );
cmp_ok( $n->is_full, '==', 1, 'initial must be full' );

