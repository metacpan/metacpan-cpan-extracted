#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   30_test3a.t
# Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
# Date:   06-Feb-2005
# Description:
#   Part of test suite for Namelist module

use strict;
use Test::More tests => 11;
use Fortran::F90Namelist;

# 1. Object creation
my $nl = Fortran::F90Namelist->new();
isa_ok($nl, 'Fortran::F90Namelist');

## Read reference file
my ($hash1, $hash2);
{ local $/;
  #
  open(HASH,"< t/files/test3a-1.hash")
    or die "Couldn't open reference file t/files/test3a.hash";
  $hash1 = <HASH>;
  close(HASH);
  #
  open(HASH,"< t/files/test3a-2.hash")
    or die "Couldn't open reference file t/files/test3a.hash";
  $hash2 = <HASH>;
  close(HASH);
}
my ($name,$nslots,$hashref);


# A: parse just first namelist
eval("$hash1");
die "$@\n" if ($@);
my $parseresp = $nl->parse(file => "t/files/test3a.nml",
                           all  => 0);
# 2.+3. Result from parsing
is( defined($parseresp), 1,        'parsing');
is( $parseresp,          $name,    'parse() return value');
# 4.-6. Compare with reference values
is( $nl->name,           $name,    'names' );
is( $nl->nslots,         $nslots,  'nlists' );
is_deeply($nl->hash,     $hashref, 'data' );

# B: parse them all
eval("$hash2");
die "$@\n" if ($@);
$parseresp = $nl->parse(file => "t/files/test3a.nml",
                        all  => 1);
# 7.+8. Result from parsing
is( defined($parseresp), 1,        'parsing');
is( $parseresp,          $name,    'parse() return value');
# 9.-11. Compare with reference values
is( $nl->name,           $name,    'names' );
is( $nl->nslots,         $nslots,  'nlists' );
is_deeply($nl->hash,     $hashref, 'data' );


# End of file 30_test3a.t
