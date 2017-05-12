use Test;
BEGIN { plan tests => 1 }
END   { ok($loaded) }
use Finance::Bank::LaPoste;
$loaded++;
