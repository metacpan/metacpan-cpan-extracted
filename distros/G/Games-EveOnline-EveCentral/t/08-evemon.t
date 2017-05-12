#!perl

use Test::More tests => 3;
use Test::Exception;
use Error;

use Games::EveOnline::EveCentral::Request::EVEMon;

my $o = Games::EveOnline::EveCentral::Request::EVEMon->new;
isa_ok($o, 'Games::EveOnline::EveCentral::Request::EVEMon');

is($o->request->method, 'GET');

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::EVEMon->new(type_id => 34);
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';
