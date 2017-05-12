#!perl

use Test::More tests => 10;

use_ok('Log::Saftpresse::Counters');

my $c = Log::Saftpresse::Counters->new;
isa_ok($c, 'Log::Saftpresse::Counters');

# update counter
$c->incr_one('smtp', 'connections');
cmp_ok( $c->counters->{'smtp'}->{'connections'}, '==', 1, 'smtp/connections must be 1');

# update existing counter
$c->incr_one('smtp', 'connections');
cmp_ok( $c->counters->{'smtp'}->{'connections'}, '==', 2, 'smtp/connections must be 2');

# update existing counter with value 10
$c->incr('smtp', 'connections', 10);
cmp_ok( $c->counters->{'smtp'}->{'connections'}, '==', 12, 'smtp/connections must be 12');

# check get method
cmp_ok( $c->get('smtp', 'connections'), '==', 12, '->get_counter must also return 12' );

ok( ! defined $c->get('smtp', 'bla'), 'non existing key must be undef' );
ok( ! defined $c->get('smtp'), 'must return undef if key is a hash element' );

cmp_ok( ref($c->get_node('smtp')), 'eq', 'HASH', 'must get_node return a HASH reference' );
cmp_ok( $c->get_node('smtp', 'connections'), '==', 12, 'must get_node return the value' );

