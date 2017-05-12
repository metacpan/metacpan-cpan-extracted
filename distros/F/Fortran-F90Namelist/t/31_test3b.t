#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   31_test3b.t
# Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
# Date:   06-Feb-2005
# Description:
#   Part of test suite for Namelist module

use strict;
use Test::More tests => 6;
use Fortran::F90Namelist;

# 1. Object creation
my $nl = Fortran::F90Namelist->new();
isa_ok($nl, 'Fortran::F90Namelist');

## Read reference file
my $hash;
{ local $/;
  open(HASH,"< t/files/test3b.hash")
    or die "Couldn't open reference file t/files/test3b.hash";
  $hash = <HASH>;
  close(HASH);
}
my ($name,$nlists,$namelists);
eval("$hash");
die "$@\n" if ($@);
#
my $parseresp = $nl->parse(file => "t/files/test3b.nml");
# 2.+3. Result from parsing
is( defined($parseresp), 1,        'parsing');
is( $parseresp,          $name,    'parse() return value');
# 4.-6. Compare with reference values
is(       $nl->name,     $name,      'name');
is(       $nl->nslots,   $nlists,    'nslots');
is_deeply($nl->hash,     $namelists, 'data');

# End of file 31_test3b.t
