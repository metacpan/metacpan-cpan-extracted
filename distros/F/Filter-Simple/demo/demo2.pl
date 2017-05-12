no warnings;

use Demo2b;

$x = 1;

use Demo2a x => 1;

$y = 2;

print  $x * $y, "\n";


no Demo2a;


$x *= 2;

print  $x * $y, "\n";

no Demo2b;

$x = 1;
$y = 2;

print  $x * $y, "\n";

$x *= 2;

print  $x * $y, "\n";
