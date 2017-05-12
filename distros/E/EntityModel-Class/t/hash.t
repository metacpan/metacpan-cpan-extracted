use strict;
use warnings;
use 5.10.0;
use FindBin;
use lib "$FindBin::Bin/..";

use Test::More tests => 18;
use Test::Deep;
use EntityModel::Hash;

my %data = (
	first	=> 1,
	second	=> 2,
	third	=> 3,
);

ok(my $h = new EntityModel::Hash::(\%data), 'create from hash');
is($h->get('first'), 1, 'first value correct');
is($h->get('second'), 2, 'second value correct');
is($h->get('third'), 3, 'third value correct');
is($h->count, 3, 'count is correct');
cmp_deeply([ sort { $a <=> $b } $h->list ], [ 1,2,3 ], 'list is correct');
cmp_deeply($h->hashref, \%data, 'hashref matches original');
ok($h->exists('first'), 'exists matches valid key');
ok(!$h->exists('invalid'), 'exists does not match invalid key');
ok($h->set('second', '9'), 'change a value');
is($data{second}, 9, 'value updated correctly');
cmp_deeply($h->hashref, \%data, 'hashref matches original');
cmp_deeply([ sort $h->keys ], [ qw(first second third) ], 'keys are correct');

ok($h->count, 'has entries before clear');
ok($h->clear, 'clear hash');
ok(!$h->count, 'clear hash');
ok($h->set({ x => 1, y => 2 }), 'set two values via hashref');
is($h->count, 2, 'have two entries now');
