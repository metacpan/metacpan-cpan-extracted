
use Test::More;

use Importer::Zim ();
BEGIN { ok !$INC{'Importer/Zim/Base.pm'}, 'use zim () - +Base not loaded'; }

use Importer::Zim 'Test::More' => [];
BEGIN { ok $INC{'Importer/Zim/Base.pm'}, 'use zim - +Base loaded'; }

done_testing;
