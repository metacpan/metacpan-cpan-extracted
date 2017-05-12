use Test::Simple tests => 5;

require "t/color.inc";

ok($obj1->asTypicalMonochrome->asHex		eq '#939393');
ok($obj1->asAtypicalMonochrome->asHex		eq '#8A949F');
ok($obj1->asAtypicalMonochrome(0.2)->asHex	eq '#8A949F');
ok($obj1->asAtypicalMonochrome(0.5)->asHex	eq '#7C96AF');
ok($obj1->asAtypicalMonochrome(0.8)->asHex	eq '#6F97C0');
