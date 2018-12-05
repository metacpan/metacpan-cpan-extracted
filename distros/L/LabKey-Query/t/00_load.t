# -*- perl -*-

# t/00_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'LabKey::Query' ); }

ok (LabKey::Query->can('selectRows'));


