#!/usr/bin/perl

use warnings;
use strict;

$ENV{ FREERADIUS_DATABASE_CONFIG } = 't/freeradius_database.conf-dist';

use Test::More qw( no_plan );

BEGIN { use_ok('FreeRADIUS::Database') };

can_ok ( 'FreeRADIUS::Database', 'month_hours_used' );

{ # test for no records

    my $rad = FreeRADIUS::Database->new();
    my $ret = $rad->month_hours_used({
                                username    => 'bad_user',
                            });
    is ( $ret, undef, "Return is undef if no records are found" );
}

{ # test with month param ( and success )

    my $rad = FreeRADIUS::Database->new();

    my $ret = $rad->month_hours_used({
                                username    => 'test',
                                nas         => 'dialup',
                                month       => '2009-01',
                            });

    ok ( $ret =~ m{ \A \d+?.\d{0,2} \z }xms, "success results in a digit with a max of two decimals");
}

{ # without class param

    my $rad = FreeRADIUS::Database->new();
    my $ret = $rad->month_hours_used({
                                username    => 'test',
                                month       => '2009-01',
                            });
    ok ( $ret =~ m{ \A \d+?.\d{0,2} \z }xms, "class is set properly if not supplied");
}
