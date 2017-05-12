#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
	use_ok( 'Log::Log4perl' );
	use_ok( 'FTN::Bit_flags' );
}

Log::Log4perl -> easy_init( $Log::Log4perl::INFO );

my $attribute = FTN::Bit_flags -> new( { abbr => 'PVT',
					 name => 'PRIVATE',
				       },
				       { abbr => 'CRA',
					 name => 'CRASH',
				       },
				       { abbr => 'RCV',
					 name => 'READ',
				       },
				       { abbr => 'SNT',
					 name => 'SENT',
				       },
				       { abbr => 'FIL',
					 name => 'FILEATT',
				       },
				       { name => 'TRANSIT',
				       },
				       { name => 'ORPHAN',
				       },
				       { abbr => 'K/S',
					 name => 'KILL',
				       },
				       { name => 'LOCAL',
				       },
				       { abbr => 'HLD',
					 name => 'HOLD',
				       },
				       { abbr => 'XX2',
				       },
				       { abbr => 'FRQ',
					 abbr => 'FREQ',
				       },
				       { abbr => 'RRQ',
					 name => 'Receipt REQ',
				       },
				       { abbr => 'CPT',
				       },
				       { abbr => 'ARQ',
				       },
				       { abbr => 'URQ',
				       },
				     );

$attribute -> set_from_number( 22 );

is( join( ', ', $attribute -> list_of_set ),
    'CRA, RCV, FIL',
    'list of set'
  );

ok( ! $attribute -> is_set( 'PVT' ), 'private message' );

$attribute -> set( 'LOCAL', 'CRASH' );

$attribute -> clear( 'K/S' );

is( $attribute -> as_number,
    278,
    'result after messing with it'
  );

my $bit_flags = FTN::Bit_flags -> new( { abbr => 'flag 1' },
				       { name => 'second lowest bit' },
				       { abbr => 'flag 2',
					 name => 'flag numeric mask is 4'
				       }
				     );

$bit_flags -> set_from_number( 3 );

$bit_flags -> clear_all;

$bit_flags -> set( 'second lowest bit', 'flag 2' );

$bit_flags -> clear( 'second lowest bit' );

ok( ! $bit_flags -> is_set( 'second lowest bit' ), 'second lowest bit' );

is( $bit_flags -> as_number, 4, 'as_number' );

is( join( ' ', $bit_flags -> list_of_set ),
    'flag 2',
    'list of set'
  );

is( join( ' ', $bit_flags -> list_of_set( 'name' ) ),
    'flag numeric mask is 4',
    "list of set( 'name' )"
  );
