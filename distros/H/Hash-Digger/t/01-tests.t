use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Hash::Digger qw(dig diggable exhume);
use Test::More tests => 19;
use Test::Exception;

my $hash;
my $org_hash;

$hash->{foo} = 'bar';
$org_hash->{foo} = 'bar';

is dig($hash, qw(foo)), 'bar'
,'Can dig simple value';
is_deeply($hash, $org_hash, 'no autovivification');

is dig($hash, qw(bar)), undef
,'gets empty for undefined value';
is_deeply($hash, $org_hash, 'no autovivification');

$hash->{foo} = {};
$hash->{foo}{bar1}{bar2}{bar3}{bar4} = 'bar5';
$org_hash->{foo} = {};
$org_hash->{foo}{bar1}{bar2}{bar3}{bar4} = 'bar5';

is dig($hash, qw(foo bar1 bar2 bar3 bar4)), 'bar5'
,'digs long hashes';
is_deeply($hash, $org_hash, 'no autovivification');

is dig($hash, qw(foo bar10 bar20 bar30 bar40 bar50)), undef
,'gets empty for undefined long hash value';
is_deeply($hash, $org_hash, 'no autovivification');

throws_ok { dig(undef) } qr/undefined/,
'dies on undefined root node';

throws_ok { dig(1) } qr/reference/,
'dies if not hash reference on root node';

throws_ok { dig($hash) } qr/path/,
'dies if nothing to dig';

is exhume('xyz', $hash, qw(foo barX barY barZ)), 'xyz'
,'gets default value';
is_deeply($hash, $org_hash, 'no autovivification');

ok !diggable($hash, qw(foo barX barY barZ))
,'checks diggable';
is_deeply($hash, $org_hash, 'no autovivification');

ok !diggable($hash, qw(foo barX barY))
,'checks diggable previous path';
is_deeply($hash, $org_hash, 'no autovivification');

ok diggable($hash, qw(foo bar1 bar2))
,'checks diggable path';
is_deeply($hash, $org_hash, 'no autovivification');
