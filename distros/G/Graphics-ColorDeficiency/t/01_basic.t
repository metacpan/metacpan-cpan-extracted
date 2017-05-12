use Test::Simple tests => 3;

eval "use Graphics::ColorDeficiency";
ok(!@!, "load module");

eval 'require "t/color.inc";';
ok(!@!, "load inc");

ok($obj1->asHex eq '#6699CC');

undef $obj1;
