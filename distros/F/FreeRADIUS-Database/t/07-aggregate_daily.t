#!/usr/bin/perl

use warnings;
use strict;

$ENV{ FREERADIUS_DATABASE_CONFIG } = 't/freeradius_database.conf-dist';

use Test::More qw( no_plan );
use Data::Dumper;

BEGIN { use_ok('FreeRADIUS::Database') };

can_ok( 'FreeRADIUS::Database', 'aggregate_daily' );

{ # aggregate_daily() success return

    my $rad = FreeRADIUS::Database->new();
    my $ret = $rad->aggregate_daily();

    is ( $ret, 0, "aggregate_daily() returns 0 upon completion" );
}

{ # bad day / good day

    my $rad = FreeRADIUS::Database->new();
    
    eval { $rad->aggregate_daily( { day => 'asdf' } ) };
    like(   $@,
            qr/must be in the form/,
            "aggregate_daily() dies if a bad 'day' param is passed in"
        );

    my $ret = $rad->aggregate_daily( { day => '2000-12-16' } );
    is( $ret, 0, "aggregate_daily() returns 0 if a valid 'day' param is passed in" );

}

{ # daily_login_totals()

    my $r = FreeRADIUS::Database->new();
    
    my $no_record = $r->daily_login_totals({
                                        username    => 'blah',
                                        nas         => 'none',
                                        day         => '2000-01-01',
                                    });
    
    is ( $no_record, undef, "daily_login_totals() properly returns undef if no record is found" );
}

{ # math works properly

    # the math data being used to corroborate the accuracy of the
    # calculations are taken directly from the test schema file
    # and calculated manually as a baseline

    my $r = FreeRADIUS::Database->new();
    
    # single entry

    $r->aggregate_daily({ day => '2009-01-01' });
    
    # populate the daily table with worthwhile info

    for my $day_to_populate( 1..21 ) {
        if ( $day_to_populate < 10 ) {
            $day_to_populate = "0" . $day_to_populate;
        }
        my $day_param = "2009-12-$day_to_populate";

        $r->aggregate_daily({ day => $day_param });
    }

    my $single_raw = $r->daily_login_totals({
                                        username    => 'test',
                                        nas         => 'dialup',
                                        day         => '2009-01-01',
                                        raw         => 1,
                                    });

    is ( $single_raw->{ upload },   1745,           "raw-single: daily_login_totals() has upload correct" ); 
    is ( $single_raw->{ download }, 2093,           "raw-single: daily_login_totals() has download correct" ); 
    is ( $single_raw->{ duration }, 561 ,           "raw-single: daily_login_totals() has duration correct" ); 
    is ( $single_raw->{ date },     '2009-01-01',   "raw-single: daily_login_totals() sets the proper date" ); 

    my $single = $r->daily_login_totals({
                                        username    => 'test',
                                        nas         => 'dialup',
                                        day         => '2009-01-01',
                                    });

    is ( $single->{ upload },   '0.00',         "human-single: daily_login_totals() has upload correct" ); 
    is ( $single->{ download }, '0.00',         "human-single: daily_login_totals() has download correct" ); 
    is ( $single->{ duration }, '0.16',         "human-single: daily_login_totals() has duration correct" ); 
    is ( $single->{ date },     '2009-01-01',   "human-single: daily_login_totals() sets the proper date" ); 

    my $mult_raw = $r->daily_login_totals({
                                        username    => 'test3',
                                        nas         => '10.0.0.1',
                                        day         => '2009-12-16',
                                        raw         => 1,
                                    });

    is ( $mult_raw->{ upload },   1906962,      "raw-multi: daily_login_totals() has upload correct" ); 
    is ( $mult_raw->{ download }, 7684136354,   "raw-multi: daily_login_totals() has download correct" ); 
    is ( $mult_raw->{ duration }, 23328,        "raw-multi: daily_login_totals() has duration correct" ); 
    is ( $mult_raw->{ date },     '2009-12-16', "raw-multi: daily_login_totals() sets the proper date" ); 

    my $mult = $r->daily_login_totals({
                                        username    => 'test3',
                                        nas         => '10.0.0.1',
                                        day         => '2009-12-16',
                                    });

    is ( $mult->{ upload },     '1.82',         "human-multi: daily_login_totals() has upload correct" ); 
    is ( $mult->{ download },   '7328.16',      "human-multi: daily_login_totals() has download correct" ); 
    is ( $mult->{ duration },   '6.48',         "human-multi: daily_login_totals() has duration correct" ); 
    is ( $mult->{ date },       '2009-12-16',   "human-multi: daily_login_totals() sets the proper date" ); 

    
}

