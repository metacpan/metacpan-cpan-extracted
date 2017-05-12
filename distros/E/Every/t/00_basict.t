use Test;
BEGIN { plan tests => 3 }
END   { ok($loaded) }
use Every;
$loaded++;

$count = 0;
foreach (0..200)
{
 $count++ if every(10);
}

ok($count, 20);

# this should trigger just once
foreach (0..3)
{
 $count++ if every(seconds => 3);
 sleep 1;
}

ok($count, 21);
