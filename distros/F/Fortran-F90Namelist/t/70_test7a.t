#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   70_test7a.t
# Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
# Date:   09-Nov-2006
# Description:
#   Part of test suite for Namelist module
#   Tests parsing of namelist groups using Namelist::Group

use strict;
use Test::More tests => 6;
use Fortran::F90Namelist::Group;

# 1. Object creation
my $nlgrp = Fortran::F90Namelist::Group->new();
isa_ok($nlgrp, 'Fortran::F90Namelist::Group');

## Read reference file
my $hash;
{ local $/;


####
#### HERE
####

# Need to adapt to fact that parse returns just a count (probably should
# do the same with Fortran::F90Namelist->parse())

  open(HASH,"< t/files/test7a.hash")
    or die "Couldn't open reference file t/files/test7a.hash";
  $hash = <HASH>;
  close(HASH);
}
my ($namesref,$nlists,$hashref);
eval("$hash");
die "$@\n" if ($@);
#
my $parseresp = $nlgrp->parse(file => "t/files/test3a.nml");

# 2.+3. Result from parsing
is( defined($parseresp), 1,         'parsing');
is( $parseresp,          $nlists,   'parse() return value');
# 4.-6. Compare with reference values
is($nlgrp->nlists,       $nlists,   'nslots');
is_deeply($nlgrp->names, $namesref, 'names');
is_deeply($nlgrp->hash,  $hashref,  'data');

# End of file 70_test7a.t
