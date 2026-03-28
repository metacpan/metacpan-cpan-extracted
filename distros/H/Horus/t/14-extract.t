use 5.008003;
use strict;
use warnings;
use Test::More tests => 9;
use Horus qw(:all);

# uuid_version for each type
is(uuid_version(uuid_v1()), 1, 'version of v1');
is(uuid_version(uuid_v3(UUID_NS_DNS(), 'test')), 3, 'version of v3');
is(uuid_version(uuid_v4()), 4, 'version of v4');
is(uuid_version(uuid_v5(UUID_NS_DNS(), 'test')), 5, 'version of v5');
is(uuid_version(uuid_v6()), 6, 'version of v6');
is(uuid_version(uuid_v7()), 7, 'version of v7');

# uuid_time returns 0 for non-time-based versions
is(uuid_time(uuid_v4()), 0, 'uuid_time returns 0 for v4');

# uuid_time returns meaningful values for time-based versions
my $v1_time = uuid_time(uuid_v1());
ok(abs($v1_time - time()) < 5, 'v1 time is close to now');

my $v7_time = uuid_time(uuid_v7());
ok(abs($v7_time - time()) < 5, 'v7 time is close to now');
