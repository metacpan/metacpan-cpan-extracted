#! /usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Locale::US::CensusDivisions qw(state2division);

my @state_list = qw( AL AK AZ AR CA CO CT DC DE FL GA HI ID IL IN IA KS KY LA ME
  MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA
  RI SC SD TN TX UT VT VA WA WV WI WY );

subtest "Verify all states are accounted for" => sub {
    lives_ok {
        foreach my $state (@state_list) {
            state2division($state);
        }
    }
    'All states accounted for';
};

subtest "Check if TX is division 7" => sub {
    my $state = 'TX';
    my $division;

    lives_ok {
        $division = state2division($state);
    }
    'lives ok through division fetching';

    cmp_ok( $division, '==', 7, 'Texas correctly in 7th division' );
};

subtest "Bad state code croaks with error" => sub {
    my $state = 'FA';

    throws_ok {
        state2division($state);
    }
    qr/The state abbreviation.*not found/, 'Correct error thrown';

};

done_testing;
