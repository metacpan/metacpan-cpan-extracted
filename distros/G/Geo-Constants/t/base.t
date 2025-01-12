#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 14;
use_ok('Geo::Constants');

{
  my $o = Geo::Constants->new();
  isa_ok($o, 'Geo::Constants');
  can_ok($o, 'PI');
  can_ok($o, 'DEG');
  can_ok($o, 'RAD');
  can_ok($o, 'KNOTS');

  is($o->PI   , 4*atan2(1,1)      , '->PI'    );
  is($o->DEG  , 180/(4*atan2(1,1)), '->DEG'   );
  is($o->RAD  , 4*atan2(1,1)/180  , '->RAD'   );
  is($o->KNOTS, 1852/3600         , '->KNOTS' );
}

{
  use Geo::Constants qw{PI DEG RAD KNOTS};
  is(PI()   , 4*atan2(1,1)      , 'exported PI()'    );
  is(DEG()  , 180/(4*atan2(1,1)), 'exported DEG()'   );
  is(RAD()  , 4*atan2(1,1)/180  , 'exported RAD()'   );
  is(KNOTS(), 1852/3600         , 'exported KNOTS()' );
}
