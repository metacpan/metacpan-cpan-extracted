# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mcache.t'

#########################

use Mcache;
use Test::More tests => 2;

my $cache = Mcache->new();
$cache->add("string 10",1);
my $k1 = $cache->add("string 20",1);
my $k2 = $cache->add("string 30",1);
$cache->add("string 40",1);
my $sel1 = $cache->count(1);
$cache->del(1,"$k1");
$cache->del(1,"$k2");
my $sel2 = $cache->count(1);

ok ( $sel1 == 4 );
ok ( $sel2 == 2 );

#########################

