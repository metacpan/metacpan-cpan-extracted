use lib "$ENV{HOME}/lib/perl";
use Test::More tests=>44;
use Math::ErrorPropagation;

$x = Math::ErrorPropagation->datum(); 
ok($x->isa('Math::ErrorPropagation'), "create object");

$x->central_value(2.3); 
is($x->central_value(), 2.3, "assign/read central value"); 

$x->variance(0.5); 
is($x->variance(), 0.5, "assign/read variance"); 
is($x->sd(), sqrt(0.5), "read standard deviation"); 

$x->sd(0.5); 
is($x->sd(), 0.5, "assign/read standard deviation"); 
is($x->variance(), 0.25, "read variance"); 

$y = copy $x;
is($y->variance(), $x->variance(), "copy: variance"); 
is($y->central_value(), $x->central_value(), "copy: central value"); 

$y->variance(.2);
$y->central_value(5);

$z = $y+$x;
is($z->central_value(), 7.3, "x+y: central value");
is($z->variance(), .45, "x+y: variance");

$z = $y+2.3;
is($z->central_value(), 7.3, "y+2.3: central value");
is($z->variance(), $y->variance(), "y+2.3: variance");

$z = $x-$y;
is($z->central_value(), -2.7, "x-y: central value");
is($z->variance(), .45, "x-y: variance");

$z = 2.3-$y;
is($z->central_value(), -2.7, "2.3-y: central value");
is($z->variance(), $y->variance(), "2.3-y: variance");

$z = $x-5;
is($z->central_value(), -2.7, "x-5: central value");
is($z->variance(), $x->variance(), "x-5: variance");

$z = $x*$y;
is($z->central_value(), 11.5, "x*y: central value");
is($z->variance(), 7.308, "x*y: variance");

$z = 2.3*$y;
is($z->central_value(), 11.5, "2.3*y: central value");
is($z->variance(), 1.058, "2.3*y: variance");

$z = $x/$y;
is($z->central_value(), .46, "x/y: central value");
is($z->variance(), .0116928, "x/y: variance");

$z = 2.3/$y;
is($z->central_value(), .46, "2.3/y: central value");
is($z->variance(), .0016928, "2.3/y: variance");

$z = $x/5;
is($z->central_value(), .46, "x/5: central value");
is($z->variance(), .01, "x/5: variance");

$z = $x**$y;
is($z->central_value(), 64.363430, "x**y: central value");
is($z->variance(), 5469.21915523358, "x**y: variance");

$z = 2.3**$y;
is($z->central_value(), 64.363430, "2.3**y: central value");
is($z->variance(), 574.782575171084, "2.3**y: variance");

$z = $x**5;
is($z->central_value(), 64.363430, "x**5: central value");
is($z->variance(), 4894.4365800625, "x**5: variance");

$z = exp($x);
is($z->central_value(), exp(2.3), "exp(x): central value");
is($z->variance(), 24.8710789104834, "exp(x): variance");

$z = sin($x);
is($z->central_value(), sin(2.3), "sin(x): central value");
is($z->variance(), 0.0617138631688801, "sin(x): variance");

$z = cos($x);
is($z->central_value(), cos(2.3), "cos(x): central value");
is($z->variance(), 0.0617138631688801, "cos(x): variance");

$z = log($x);
is($z->central_value(), log(2.3), "log(x): central value");
is($z->variance(), .0472589792060492, "log(x): variance");

$z = sqrt($x);
is($z->central_value(), sqrt(2.3), "sqrt(x): central value");
is($z->variance(), .0271739130434783, "sqrt(x): variance");
