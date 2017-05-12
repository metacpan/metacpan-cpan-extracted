#!/usr/bin/perl -w

use strict;
use Test;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 14;
  }

use Math::BigInt::Lite;

# the "with" parameter is now ignored by these modules
use Math::BigFloat with => 'Math::BigInt::Lite';
use Math::BigRat with => 'Math::BigInt::Lite';

my $x = Math::BigFloat->new(-123);
ok ($x,-123); $x->babs(); ok ($x,123);
ok ($x->is_odd(),1);

$x = Math::BigRat->new(-123);
ok ($x,-123); $x->babs(); ok ($x,123);
ok ($x->is_odd(),1);
$x = Math::BigRat->new('5/7');
ok ($x,'5/7');

$x = Math::BigRat->new(Math::BigInt::Lite->new(123));
ok ($x,123); $x->bneg(); ok ($x,-123);
ok ($x->is_odd(),1);
ok ($x->is_one()||0,0);

$x = Math::BigRat->new(Math::BigInt::Lite->new(-123));
ok ($x,-123); $x->babs(); ok ($x,123);
ok ($x->is_odd(),1);

# done

1;
