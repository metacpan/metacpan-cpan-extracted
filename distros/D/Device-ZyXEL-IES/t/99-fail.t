#!perl -T
#===============================================================================
#
#         FILE: 99-fail.t
#
#  DESCRIPTION: Tests failures with the module
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Jesper Dalberg (jdalberg@gmail.com)
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 08/28/12 16:21:59
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 4;                      # last test to print
use Device::ZyXEL::IES;
use Data::Dumper;

my $d = Device::ZyXEL::IES->new(
  hostname => 'some-ies.example.com', 
  get_community => 'weirdness' );

my $si = $d->slotInventory();

ok($si =~ /ERROR/);

my $s = Device::ZyXEL::IES::Slot->new(
  ies => $d, cardtype => 'foo',  id => 3);

my $pi = $s->portInventory();

ok($pi =~ /ERROR/);

my $p = Device::ZyXEL::IES::Port->new(
  slot => $s,  id => 301,  adminstatus => 2 );

my $pd = $p->fetchDetails();

ok($pd =~ /ERROR/);

my $iesd = $d->fetchDetails();

ok($iesd =~ /ERROR/);

