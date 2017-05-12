use strict;
use Heap::Fibonacci::Fast;
use List::Util qw(min);

my $count = 100;
use Test::More tests => (3 + 10 * (11 + 2*100 + 2*100/2 + 3*100/2 + 2*100/2));

my $t = Heap::Fibonacci::Fast->new('min');

=plan
test plan is:
	insert $count, bulk	#step 0

	insert $count, by single	#step 1
	delete at random $count / 2	#step 2
	peek by single $count / 2 top items	#step 3
	insert $count * 2, bulk 	#step 4
	delete at random $count / 2	#step 5
	peek $count / 2 using upto() #step 7
	goto step 1
=cut

my @all = map { 200 + int(rand() * 10000 * $count) } (1..$count);
my $elems = 0;

$t->key_insert(map {$_, $_} @all);
$elems += $count;

my $min = min @all;
is($t->top(), $min);
is($t->top_key(), $min);
is($t->count(), $elems);

@all = sort { $a <=> $b } @all;

for my $n (1..10){
	my @add = map { ((-1)**$n) * 300 + int(rand() * 4000 * $count) } (1..$count);
	my @added = ();

	$min = $all[0];
	foreach (@add){
		push @added, $t->key_insert($_, $_);
		$elems++;
		$min = min($min, $_);

		is($t->top(), $min);
		is($t->top_key(), $min);
	}
	is($t->count(), $elems);

	foreach (1..$count/2){
		my $ind = int(rand() * scalar @add);
		$t->remove($added[$ind]);
		$elems--;

		splice @add, $ind, 1;
		splice @added, $ind, 1;

		$min = min($all[0], @add);

		is($t->top(), $min);
		is($t->top_key(), $min);
	}
	is($t->count(), $elems);
	@all = sort { $a <=> $b } @all, @add;

	foreach (1..$count/2){
		is($t->extract_top(), $all[0]);
		$elems--;

		shift @all;
		is($t->top(), $all[0]);
		is($t->top_key(), $all[0]);
	}
	is($t->count(), $elems);

	@add = map { int(rand() * 100 * $count) } (1..$count);
	@added = $t->key_insert(map {$_, $_} @add);
	$elems += $count;
	$min = min($all[0], @add);

	is($t->count(), $elems);
	is($t->top(), $min);
	is($t->top_key(), $min);

	foreach (1..$count/2){
		my $ind = int(rand() * scalar @add);
		$t->remove($added[$ind]);
		$elems--;

		splice @add, $ind, 1;
		splice @added, $ind, 1;

		$min = min($all[0], @add);

		is($t->top(), $min);
		is($t->top_key(), $min);
	}
	is($t->count(), $elems);
	@all = sort { $a <=> $b } @all, @add;

	my $ind = $count/2;
	$ind++ while $all[$ind] == $all[$ind + 1];
	my @totest = $t->extract_upto($all[$ind]);
	is_deeply(\@totest, [splice @all, 0, $ind + 1]);

	$elems -= $ind + 1;
	is($t->count(), $elems);
	is($t->top(), $all[0]);
	is($t->top_key(), $all[0]);
}
