#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Record::MaxMind;

my %fields = (queries_remaining => 9999,);

my $maxmind = new_ok 'Geo::Location::IP::Record::MaxMind' => [%fields];

can_ok $maxmind, keys %fields;

cmp_ok $maxmind->queries_remaining, '==', $fields{queries_remaining},
    'queries remaining matches';

done_testing;
