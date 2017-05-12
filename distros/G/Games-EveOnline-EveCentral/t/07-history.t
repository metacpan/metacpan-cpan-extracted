#!perl

use Test::More tests => 14;
use Test::Exception;
use Error;

use Games::EveOnline::EveCentral::Request::History;

my $o = Games::EveOnline::EveCentral::Request::History->new(
  type_id => 34,
  bid => 'buy'
);
isa_ok($o, 'Games::EveOnline::EveCentral::Request::History');
is($o->request->method, 'GET');

$o = Games::EveOnline::EveCentral::Request::History->new(
  type_id => 34,
  bid => 'sell'
);
isa_ok($o, 'Games::EveOnline::EveCentral::Request::History');

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::History->new(
      bid => 'buy'
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::History->new(
      type_id => 34
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::History->new(
      type_id => [34, 35],
      bid => 'buy'
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::History->new(
      type_id => 34,
      bid => 'borrow'
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

$o = Games::EveOnline::EveCentral::Request::History->new(
  type_id => 34,
  bid => 'buy',
  location_type => 'system',
  location => 'Jita'
);
isa_ok($o, 'Games::EveOnline::EveCentral::Request::History');

$o = Games::EveOnline::EveCentral::Request::History->new(
  type_id => 34,
  bid => 'buy',
  location_type => 'region',
  location => 'The Forge'
);
isa_ok($o, 'Games::EveOnline::EveCentral::Request::History');

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::History->new(
      type_id => 34,
      location_type => 'station',
      location => 'Jita IV-4 - Caldari Navy Assembly Plant',
      bid => 'buy'
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::History->new(
      type_id => 34,
      location_type => 'system',
      bid => 'buy'
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

$o = Games::EveOnline::EveCentral::Request::History->new(
  type_id => 34,
  location_type => 'system',
  location => 'Jita',
  bid => 'buy'
);
my $expected_path = 'history/for/type/34/system/Jita/bid/1';
is($o->_path, $expected_path);

$o = Games::EveOnline::EveCentral::Request::History->new(
  type_id => 34,
  location_type => 'region',
  location => 'The Forge',
  bid => 'sell'
);
$expected_path = 'history/for/type/34/region/The Forge/bid/0';
is($o->_path, $expected_path);

$o = Games::EveOnline::EveCentral::Request::History->new(
  type_id => 34,
  bid => 'sell'
);
$expected_path = 'history/for/type/34/bid/0';
is($o->_path, $expected_path);
