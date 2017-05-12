use Test;
BEGIN { plan tests => 2 }

use Mac::AppleSingleDouble;
ok(!eval { $adfile = new Mac::AppleSingleDouble(''); });
undef($adfile); # make warning "only used once" go away
ok($@, qr/^\'\' is not a file\!/);
