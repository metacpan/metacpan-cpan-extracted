#!perl

use Test::More tests => 18;
use Test::Exception;
use Error;

use Games::EveOnline::EveCentral::Request::MarketStat;

my $o = Games::EveOnline::EveCentral::Request::MarketStat->new(
  type_id => 34,
);
isa_ok($o, 'Games::EveOnline::EveCentral::Request::MarketStat');
is($o->type_id, 34);
is($o->hours, 24);
is($o->min_q, 1);
is($o->regions, -1);
is($o->system, -1);

my $expected_path = 'marketstat?typeid=34&hours=24&minQ=1';
is($o->_path, $expected_path);

is($o->request->method, 'GET');

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::MarketStat->new(
      hours => 1,
      min_q => 10,
      system => 30000142,
      regions => 10000002,
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

$o = Games::EveOnline::EveCentral::Request::MarketStat->new(
  type_id => 34,
  hours => 1,
  min_q => 10,
  system => 30000142,
  regions => 10000002,
);
is($o->hours, 1);
is($o->min_q, 10);
is($o->system, 30000142);
is($o->regions, 10000002);
$expected_path = 'marketstat?typeid=34&hours=1&minQ=10&usesystem=30000142&regionlimit=10000002';
is($o->_path, $expected_path);

my $regions = [10000002, 10000003];
$o = Games::EveOnline::EveCentral::Request::MarketStat->new(
  type_id => 34,
  regions => $regions,
);
is($o->regions, $regions);
$expected_path = 'marketstat?typeid=34&hours=24&minQ=1&regionlimit=10000002&regionlimit=10000003';
is($o->_path, $expected_path);

my $type_ids = [34, 35];
$o = Games::EveOnline::EveCentral::Request::MarketStat->new(
  type_id => $type_ids,
);
is($o->type_id, $type_ids);
$expected_path = 'marketstat?typeid=34&typeid=35&hours=24&minQ=1';
is($o->_path, $expected_path);
