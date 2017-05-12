#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   60_test6a.t
# Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
# Date:   06-Feb-2005
# Description:
#   Part of test suite for Namelist module

use strict;
use Test::More tests => 8;
use Fortran::F90Namelist;

# 1. Object creation
my $nl = Fortran::F90Namelist->new();
isa_ok($nl, 'Fortran::F90Namelist');

## Read reference file
my $hash;
{ local $/;
  my $ref_file = 't/files/test6a.hash';
  open(HASH,"< $ref_file")
    or die "Couldn't open reference file $ref_file\n";
  $hash = <HASH>;
  close(HASH);
}
my ($name,$nslots,$slotsref,$hashref);
eval("$hash");
die "$@\n" if ($@);
#
# 2. Try parsing without `broken' flag (should fail)
my $parseresp = eval { $nl->parse(file => "t/files/test6a.nml") };
isnt(defined($parseresp), 0,         'parsing strictly');
#
# 3. Parse using `broken'
$parseresp = $nl->parse(file => "t/files/test6a.nml", broken => 1);
# 3.+4. Result from parsing
is( defined($parseresp),  1,         'parsing');
is( $parseresp,           $name,     'parse() return value');
# 5.-8. Compare with reference values
is(       $nl->name,      $name,     'name');
is(       $nl->nslots,    $nslots,   'nslots');
is_deeply($nl->slots,     $slotsref, 'slots');
is_deeply($nl->hash,      $hashref,  'data');


# End of file 60_test6a.t
