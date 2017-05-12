use strict;

use Test;
use JavaScript::Swell;

BEGIN {
    plan tests => 2;
}

my $squish = "var i=0;if(i++){var a=-1;}";
my $swell = "var i = 0;
if (i++) {
  var a = -1;
}
";

ok(JavaScript::Swell->swell($squish), $swell);
ok(JavaScript::Swell->squish($swell), $squish);
