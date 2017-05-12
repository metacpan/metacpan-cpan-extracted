#!/usr/bin/perl

use strict;
use Math::BaseCalc;
use warnings;
use Test::More;

plan tests => 7;

{
  # Create a base 30 BaseCalc object, then downshift it to base 27.
  my $x = Math::BaseCalc->new(digits=>['0'..'7']);
  is($x->to_base(76), '114');

  # $x->digits(['0', 'a'..'z']) -- using digits(), change to base 27: 0 plus a to z
  $x->digits(['0', 'a'..'z']);
  is($x->to_base(7648),    'jmg');
  is($x->from_base('jmg'), 7648);
  is($x->from_base('114'), undef); # Should be undef due to digits not in base string
}

{
  # This time create a base 27 BaseCalc object and do not change the digits and base.

  my $x = Math::BaseCalc->new(digits=>['0', 'a'..'z']);
  is($x->to_base(7648),    'jmg');
  is($x->from_base('jmg'), 7648);
  is($x->from_base('114'), undef); # Should be undef due to digits not in base string
}
