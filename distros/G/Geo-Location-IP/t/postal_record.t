#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Record::Postal;

my %fields = (
    code       => 'SW1A 0AA',
    confidence => 100,
);

my $postal = new_ok 'Geo::Location::IP::Record::Postal' => [%fields];

can_ok $postal, keys %fields;

is $postal->code, $fields{code}, 'code is "SW1A 0AA"';

cmp_ok $postal->confidence, '==', $fields{confidence}, 'confidence is 100';

done_testing;
