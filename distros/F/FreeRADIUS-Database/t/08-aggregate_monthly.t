#!/usr/bin/perl

use warnings;
use strict;

$ENV{ FREERADIUS_DATABASE_CONFIG } = 't/freeradius_database.conf-dist';

use Test::More qw( no_plan );
use Data::Dumper;

BEGIN { use_ok('FreeRADIUS::Database') };

can_ok( 'FreeRADIUS::Database', 'aggregate_monthly' );

{ # aggregate_monthly() success return

    my $rad = FreeRADIUS::Database->new();
    my $ret = $rad->aggregate_monthly();

    is ( $ret, 0, "aggregate_monthly() returns 0 upon completion" );
}

{ # bad day / good day

    my $rad = FreeRADIUS::Database->new();

    eval { $rad->aggregate_monthly( { month => 'asdf' } ) };
    like(   $@,
            qr/must be in the form/,
            "aggregate_monthly() dies if a bad 'day' param is passed in"
        );

    my $ret = $rad->aggregate_monthly( { day => '2000-12' } );
    is( $ret, 0, "aggregate_monthly() returns 0 if a valid 'day' param is passed in" );

}

{ # with data

    my $r = FreeRADIUS::Database->new();

    # populate the db for this test, and higher-numbered ones
    
    $r->aggregate_monthly({ month => '2009-12' });
    $r->aggregate_monthly({ month => '2009-01' });
    
    my $tot_aref = $r->monthly_login_totals({
                                            username    => 'test3',
                                            nas         => '10.0.0.1',
                                            month       => '2009-12',
                                            raw         => 1,
                                        });
    isa_ok ( $tot_aref, 'ARRAY', "When record(s) can be found, monthly_login_totals() return " );
    isa_ok ( $tot_aref->[0], 'HASH', "monthly_login_totals() return element " );

    my $tot_undef = $r->monthly_login_totals({
                                            username    => 'blah',
                                            nas         => '10.0.0.1',
                                            month       => '2000-12',
                                            raw         => 1,
                                        });

    is ( $tot_undef, undef, "monthly_login_totals() returns undef if records can't be found " );
}

{ # multiple months raw

    my $r = FreeRADIUS::Database->new();

    # ensure the daily table has more than one record in a month
    # call the agg_daily script. Since we already do it in
    # a previous step, it's commented out

    #`src/utilities/aggregate_daily -d 22 -m 2009-12`;

    # populate the db
    
    $r->aggregate_monthly();

    my $raw_aref = $r->monthly_login_totals({
                                            username    => 'test3',
                                            nas         => '10.0.0.1',
                                            month       => '2009-12',
                                            raw         => 1,
                                        });
    my $raw = $raw_aref->[0];

    is ( $raw->{ upload }, 4667405, "upload is correct in agg_monthly" );
    is ( $raw->{ download }, 15370340885, "download is correct in agg_monthly" );
    is ( $raw->{ duration }, 58320, "duration is correct in agg_monthly" );
    is ( $raw->{ date }, '2009-12-00', "date is correct in agg_monthly" );
}

{ # multiple months human 

    my $r = FreeRADIUS::Database->new();

    # populate the db
    
    $r->aggregate_monthly();

    my $noraw_aref = $r->monthly_login_totals({
                                            username    => 'test3',
                                            nas         => '10.0.0.1',
                                            month       => '2009-12',
                                        });
    my $noraw = $noraw_aref->[0];

    is ( $noraw->{ upload }, '4.45', "upload is correct in agg_monthly, and selects MB properly" );
    is ( $noraw->{ download }, '14.31', "download is correct in agg_monthly, and selects GB properly" );
    is ( $noraw->{ duration }, '16.20', "duration is correct in agg_monthly" );
    is ( $noraw->{ date }, '2009-12-00', "date is correct in agg_monthly" );
}

