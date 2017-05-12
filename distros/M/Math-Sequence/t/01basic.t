use strict;
use warnings;

use Test::More tests => 1 + 6 + 10*4 + 10*4 + 12;


use_ok('Math::Sequence');

my $cached = Math::Sequence->new('x+1', 0);
isa_ok($cached, 'Math::Sequence');

$cached = Math::Sequence->new('x+1', 0, 'x');
isa_ok($cached, 'Math::Sequence');

my $ncache = Math::Sequence->new('y+1', 0, 'y');
isa_ok($ncache, 'Math::Sequence');

$ncache = Math::Sequence->new('y+1', 0);
isa_ok($ncache, 'Math::Sequence');

ok($cached->cached() == 1, 'sequence cached by default');
$ncache->cached(0);
ok($ncache->cached() == 0, 'sequence not cached after change');

foreach (0..9) {
	ok($cached->current_index() == $_,
		'Testing current_index() of cached object.');
	ok($ncache->current_index() == $_,
		'Testing current_index() of uncached object.');
	ok($cached->next()->value() == $_,
		'Testing next() of cached object.');
	ok($ncache->next()->value() == $_,
		'Testing next() of uncached object.');
}

$Math::Sequence::warnings = $Math::Sequence::warnings = 0;
foreach (reverse 0..9) {
	ok($cached->back()->value() == $_,
		'Testing back() of cached object.');
	ok($ncache->back()->value() == $_,
		'Testing back() of uncached object.');
	ok($cached->current_index() == $_,
		'Testing current_index() of cached object after back().');
	ok($ncache->current_index() == $_,
		'Testing current_index() of uncached object after back().');
}

ok($cached->current_index(8) == 8,
	'Testing setting current_index() on cached object.');
ok($ncache->current_index(8) == 8,
	'Testing setting current_index() on cached object.');

ok($cached->at_index(5)->value() == 5,
	'Testing at_index() (below current index) on cached object.');
ok($ncache->at_index(5)->value() == 5,
	'Testing at_index() (below current index) on uncached object.');

ok($cached->at_index(9)->value() == 9,
	'Testing at_index() (above current index but cached) on cached object.');
ok($ncache->at_index(9)->value() == 9,
	'Testing at_index() (above current index) on uncached object.');

ok($cached->at_index(12)->value() == 12,
	'Testing at_index() (above current index) on cached object.');
ok($ncache->at_index(12)->value() == 12,
	'Testing at_index() (above current index) on uncached object.');

ok(!defined($cached->at_index(-1)),
	'Testing at_index() with invalid index on cached object.');
ok(!defined($ncache->at_index(-1)),
	'Testing at_index() with invalid index on uncached object.');

ok(!defined($cached->current_index(-1)),
	'Testing current_index() with invalid index on cached object.');
ok(!defined($ncache->current_index(-1)),
	'Testing current_index() with invalid index on uncached object.');

