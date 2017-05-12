use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }
use Digest::CRC;
use Math::Random::MT;
use File::Fingerprint::Huge;
$loaded++;
