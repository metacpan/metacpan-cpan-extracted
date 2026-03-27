use 5.008003;
use strict;
use warnings;
use Test::More tests => 5;
use Horus qw(:all);

# Same UUID compares equal
my $uuid = uuid_v4();
is(uuid_cmp($uuid, $uuid), 0, 'same UUID compares equal');

# NIL < any v4
my $nil = uuid_nil();
is(uuid_cmp($nil, $uuid), -1, 'nil < v4');
is(uuid_cmp($uuid, $nil), 1, 'v4 > nil');

# MAX > any v4
my $max = uuid_max();
is(uuid_cmp($max, $uuid), 1, 'max > v4');
is(uuid_cmp($uuid, $max), -1, 'v4 < max');
