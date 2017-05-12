#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw( no_plan );

use_ok('FreeRADIUS::Database') ;
can_ok( 'FreeRADIUS::Database', 'date' );

$ENV{ FREERADIUS_DATABASE_CONFIG } = 't/freeradius_database.conf-dist';

{ #date bad param

    my $rad = FreeRADIUS::Database->new();

    eval { $rad->date( { get => 'that' } ) };

    like( $@, qr/parameter must be/, "date() dies if the get param is incorrect" );
}

{ # date() 
    
    my $rad = FreeRADIUS::Database->new();

    my $ret = $rad->date();
    
    isa_ok( $ret, 'DateTime', "calling date() with no params, return" );
}

{ # date() get param

    my $rad = FreeRADIUS::Database->new();
    my $ret = $rad->date({ get => 'month' });
    ok( $ret =~ m{ \A \d{4}-\d{2} \z }xms, "called with get=>month works out ok" );
}

{ # timezone checks

    my $rad = FreeRADIUS::Database->new();

    $rad->TIMEZONE( 0 );
    eval { my $ret = $rad->date({ get => 'month' }) };
    isnt ( $@, undef, "If the timezone isn't set correctly, we die" );
}


