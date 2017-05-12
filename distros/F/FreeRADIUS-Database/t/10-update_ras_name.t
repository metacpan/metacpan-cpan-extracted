#!/usr/bin/perl

use warnings;
use strict;

$ENV{ FREERADIUS_DATABASE_CONFIG } = 't/freeradius_database.conf-dist';

use Test::More qw( no_plan );
use DateTime;
use Data::Dumper;

use_ok('FreeRADIUS::Database');
can_ok( 'FreeRADIUS::Database', 'update_ras_name' );

$ENV{ FREERADIUS_DATABASE_CONFIG } = 't/freeradius_database.conf-dist';

{  
    my $r = FreeRADIUS::Database->new();
    
    my $date    = DateTime->new(
                            time_zone   => $r->TIMEZONE(),
                            year        => 2009,
                            month       => 02,
                            day         => 02,
                        );

    my $day = $date->ymd();
    
    my $ret = $r->update_ras_name({ day => $day });

    is ( $ret, 0, "update_ras_name() returns 0 upon completion" );
}
