#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;

plan tests => 4;

is (Regress::test_enum_param ('value1'), 'value1');
is (Regress::test_unsigned_enum_param ('value2'), 'value2');
cmp_ok (Regress::global_get_flags_out (), '==', ['flag1', 'flag3']);

SKIP: {
  skip 'non-GType flags tests', 1
    unless (check_gi_version (0, 10, 3));

  GI::no_type_flags_in ([qw/value2/]);
  cmp_ok (GI::no_type_flags_returnv (), '==', [qw/value2/]);
}
