#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;

use Test::More qw( no_plan );

use_ok('FreeRADIUS::Database') ;
can_ok( 'FreeRADIUS::Database', 'new' );

my $test_config = 'src/conf/freeradius_database.conf-dist';

{ # isa FreeRADIUS::Database

    my $rad = FreeRADIUS::Database->new({ config => $test_config });
    isa_ok( $rad, 'FreeRADIUS::Database', "A new FreeRADIUS::Database" );

}

{ # new is inheritable

    
    package NEW;
    use base 'FreeRADIUS::Database';

    package main;

    my $rad = NEW->new({ config => $test_config });

    isa_ok( $rad, 'NEW', "new() will bless into a subclass" );
    isa_ok( $rad, 'FreeRADIUS::Database', "new() also obeys proper inheritance" );

}

{ # new() return values

    my $bad_conf_res = FreeRADIUS::Database->new( { config => 'badfile' } );
    is ( $bad_conf_res, undef, "If new() can't open the config file, the return is undef" );
    
    my $good_conf_res = FreeRADIUS::Database->new( { config => $test_config } );
    isa_ok ( $good_conf_res, 'FreeRADIUS::Database', "If _configure() can open the config file, return " );

}

{ # new() accessors

    my $rad = FreeRADIUS::Database->new({ config => $test_config });

    is( $rad->MASTER_USER(), 'radius', "_configure() properly autogens the accessors" );

}

{ # new() RAS accessors

    my $rad = FreeRADIUS::Database->new({ config => $test_config });

    my $ret = $rad->RAS();

}
