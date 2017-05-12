#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use FindBin qw($Bin);
use lib grep { -d } map { "$Bin/$_" } qw(../lib ./lib ./t/lib);
use Hash::MostUtils qw(hashmap);

our @warnings;
BEGIN { $SIG{__WARN__} = sub { push @warnings, [@_] } }

SKIP: {
  () = hashmap { $b => $a } (1..10);
  if (! @warnings) {
    skip "Don't need to prove no 'used once' warnings for \$a and \$b on your version of Perl", 2;
  }
  is( scalar @warnings, 2, 'got 2 warnings' );
  my @unexpected = grep { $_ !~ qr/main::[ab].*used.*once/ } map { @$_ } @warnings;
  is( scalar @unexpected, 0, 'no unexpected warnings' );
}
