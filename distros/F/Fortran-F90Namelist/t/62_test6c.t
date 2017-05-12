#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   62_test6c.t
# Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
# Date:   11-May-2007
# Description:
#   Part of test suite for Namelist module

use strict;
use Test::More tests => 6;
use Fortran::F90Namelist::Group;

# 1. Object creation
my $nlgrp = Fortran::F90Namelist::Group->new();
isa_ok($nlgrp, 'Fortran::F90Namelist::Group');

## Read reference file
my $hash;
{ local $/;
  my $ref_file = 't/files/test6c.hash';
  open(HASH,"< $ref_file")
    or die "Couldn't open reference file $ref_file\n";
  $hash = <HASH>;
  close(HASH);
}
my ($namesref, $nlists, $hashref);
eval("$hash");
die "$@\n" if ($@);
#
my $parseresp = $nlgrp->parse(file => "t/files/test6c.nml");
# 2.+3. Result from parsing
is( defined($parseresp), 1,         'parsing');
is( $parseresp,          $nlists,   'parse() return value');
# 4.-6. Compare with reference values
is($nlgrp->nlists,       $nlists,   'nslots');
is_deeply($nlgrp->names, $namesref, 'names');
is_deeply($nlgrp->hash,  $hashref,  'data');

# End of file 62_test6c.t
