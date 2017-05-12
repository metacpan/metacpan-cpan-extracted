#!perl

use Test::More tests => 19;
use Test::Exception;
use Error;

use Games::EveOnline::EveCentral::Request::QuickLookPath;

my $o = Games::EveOnline::EveCentral::Request::QuickLookPath->new(
  type_id => 34,
  from_system => 'Jita',
  to_system => 'Amarr'
);

isa_ok($o, 'Games::EveOnline::EveCentral::Request::QuickLookPath');
is($o->type_id, 34);
is($o->hours, 360);
is($o->min_q, 1);
is($o->from_system, 'Jita');
is($o->to_system, 'Amarr');

my $expected_path = 'quicklook/onpath/from/Jita/to/Amarr/fortype/34';
is($o->_path, $expected_path);

my $expected_content = [qw(sethours 360 setminQ 1)];
is_deeply($o->_content, $expected_content);

my $req = $o->request;
is($req->method, 'POST');

$o = Games::EveOnline::EveCentral::Request::QuickLookPath->new(
  type_id => 34,
  from_system => 30000142,
  to_system => 30002187
);
is($o->from_system, 30000142);
is($o->to_system, 30002187);

$expected_path = 'quicklook/onpath/from/30000142/to/30002187/fortype/34';
is($o->_path, $expected_path);

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::QuickLook->new(
      type_id => [34, 35],
      from_system => 'Jita',
      to_system => 'Amarr'
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::QuickLook->new(
      from_system => 'Jita',
      to_system => 'Amarr'
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::QuickLook->new(
      type_id => 34,
      to_system => 'Amarr'
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

throws_ok {
  eval {
    $o = Games::EveOnline::EveCentral::Request::QuickLook->new(
      type_id => 34,
      from_system => 'Jita'
    );
  };
  throw Error::Simple($!) if $@;
} 'Error::Simple';

$o = Games::EveOnline::EveCentral::Request::QuickLookPath->new(
  type_id => 34,
  from_system => 'Jita',
  to_system => 'Amarr',
  hours => 37,
  min_q => 10
);
is($o->hours, 37);
is($o->min_q, 10);

my $expected_content = [qw(sethours 37 setminQ 10)];
is_deeply($o->_content, $expected_content);
