use Test::Simple tests => 9;

require "t/color.inc";

ok($obj1->asProtanomaly->asHex		eq '#7595C9');
ok($obj1->asDeuteranomaly->asHex	eq '#7395CC');
ok($obj1->asTritanomaly->asHex		eq '#609CBB');

ok($obj1->asProtanomaly(0.2)->asHex	eq '#6C97CB');
ok($obj1->asDeuteranomaly(0.2)->asHex	eq '#6B97CC');
ok($obj1->asTritanomaly(0.2)->asHex	eq '#639AC5');

ok($obj1->asProtanomaly(0.8)->asHex	eq '#7E94C8');
ok($obj1->asDeuteranomaly(0.8)->asHex	eq '#7A94CC');
ok($obj1->asTritanomaly(0.8)->asHex	eq '#5C9DB1');
