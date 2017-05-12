#!perl

use Test::More tests => 7;
use Test::Exception;
use Error;

use Games::EveOnline::EveCentral::Request::Route;

my $o = Games::EveOnline::EveCentral::Request::Route->new(
  from_system => 'Jita',
  to_system => 'Amarr'
);
isa_ok($o, 'Games::EveOnline::EveCentral::Request::Route');
is($o->request->method, 'GET');

my $expected_path = 'route/from/Jita/to/Amarr';
is($o->_path, $expected_path);

$o = Games::EveOnline::EveCentral::Request::Route->new(
  from_system => 30000142,
  to_system => 30002187
);
isa_ok($o, 'Games::EveOnline::EveCentral::Request::Route');
$expected_path = 'route/from/30000142/to/30002187';
is($o->_path, $expected_path);

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::Route->new(
      from_system => 'Jita'
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::Route->new(
      to_system => 'Amarr'
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';
