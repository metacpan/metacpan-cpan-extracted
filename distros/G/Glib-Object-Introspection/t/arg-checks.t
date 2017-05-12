#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;

plan tests => 8;

{
  is (Regress::test_int8 (-127), -127);
  isa_ok (Regress::TestObj->constructor, 'Regress::TestObj');
}

{
  is (eval { Regress::test_int8 () }, undef);
  like ($@, qr/too few/);

  is (eval { Regress::TestObj::constructor }, undef);
  like ($@, qr/too few/);
}

{
  local $SIG{__WARN__} = sub { like ($_[0], qr/too many/) };
  is (Regress::test_int8 (127, 'bla'), 127);
}
