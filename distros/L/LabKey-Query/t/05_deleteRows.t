
use Test::More tests => 2;

BEGIN { use_ok( 'LabKey::Query' ); }

ok (LabKey::Query->can('deleteRows'));
