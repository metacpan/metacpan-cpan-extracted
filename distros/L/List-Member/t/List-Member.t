use strict;
use warnings;

use Test::More tests => 7;
use lib "../lib";

use_ok( 'List::Member' => '0.044');

my $target = 'bar';
my @look_in = ('foo','baz','bar','etc',0);

ok( member('foo',@look_in) +1, 'scalar +1');

ok( member('foo',@look_in) >= 0, 'scalar >= 0');

ok( member('tikkumolam',@look_in) eq nota_member(), 'nota_member');

ok( defined(member('foo',@look_in)), 'defined');

ok( member('0',@look_in) +1, '0 +1');

ok( member(qr/oo$/,@look_in) +1, 're +1');

