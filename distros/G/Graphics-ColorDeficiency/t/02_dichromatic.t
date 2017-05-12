use Test::Simple tests => 3;

require "t/color.inc";

ok($obj1->asProtanopia->asHex eq '#8593C7');
ok($obj1->asDeutanopia->asHex eq '#8093CD');
ok($obj1->asTritanopia->asHex eq '#5A9FAB');
