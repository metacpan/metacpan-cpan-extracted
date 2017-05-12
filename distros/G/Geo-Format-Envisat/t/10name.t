#!/usr/bin/perl
# translate name into MPH

use warnings;
use strict;

use lib '../lib', 'lib';
use Geo::Format::Envisat qw/envisat_mph_from_name/;

use Test::More tests => 1;

use Data::Dumper;
$Data::Dumper::Sortkeys =
   sub {[sort {lc($a) cmp lc($b) || $a cmp $b} keys %{$_[0]}] };

my $n1 = '/abc/ASA_IMG_1PNDPA20080903_100725_000000152071_00423_34044_1202.N1';
#warn Dumper envisat_mph_from_name($n1);

is_deeply(envisat_mph_from_name($n1),
{
          ABS_ORBIT => '+34044',
          abs_orbit => 34044,
          CYCLE => '+071',
          cycle => 71,
          duration => 15,
          originator_id => 'DPA',
          PHASE => '2',
          phase => '2',
          PROC_STAGE => 'N',
          proc_stage => 'Near Real Time',
          product_file_counter => '1202',
          PRODUCT_ID => 'ASA_IMG_1P',
          product_id => 'ASA_IMG_1P',
          REL_ORBIT => '+00423',
          rel_orbit => 423,
          satellite => 'Envisat',
          satellite_id => 'N1',
          SENSING_START => '03-SEP-2008 10:07:25.000000',
          sensing_start => 1220436445,
          sensing_start_iso => '2008-09-03T10:07:25Z',
          start_day => '20080903',
          start_time => '100725',
        }
);
