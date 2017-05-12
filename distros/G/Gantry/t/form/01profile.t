use strict;
use Test::More tests => 2;

use Gantry::Utils::CRUDHelp;
use Gantry::Plugins::AutoCRUD;

#-----------------------------------------------------------------
#	basic (no constraints)
#-----------------------------------------------------------------

my $profile = Gantry::Utils::CRUDHelp::form_profile( [
	{ name => 'first',  optional => 1 },
	{ name => 'second', optional => 1 },
	{ name => 'third',  required => 1 },
	{ name => 'fourth', required => 1 },
] );

is_deeply( $profile,
	{ required => [ 'third', 'fourth' ],
	  optional => [ 'first', 'second' ],
	},
	'optional and required'
);

#-----------------------------------------------------------------
#	with constraints
#-----------------------------------------------------------------

$profile = Gantry::Utils::CRUDHelp::form_profile( [
	{ name => 'third',  required => 1, constraint => qr/^\d+$/ },
	{ name => 'fourth', required => 1 },
] );

is_deeply( $profile,
	{ required => [ 'third', 'fourth' ],
	  constraint_methods => { third => qr/^\d+$/ },
	},
	'with constraint'
);

