use Test;
BEGIN { plan tests => 1 }
END   { ok($loaded) }
use Lingua::FR::Numbers;
$loaded++;
