use Test;
BEGIN { plan tests => 1 }
END   { ok($loaded) }
use Lingua::Slavic::Numbers;
$loaded++;
