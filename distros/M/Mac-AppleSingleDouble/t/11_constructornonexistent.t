use Test;
BEGIN { plan tests => 2 }

use Mac::AppleSingleDouble;
ok(!eval { $adfile = new Mac::AppleSingleDouble('non_existent_file'); });
undef($adfile); # make warning "only used once" go away
ok($@, qr/^\'non_existent_file\' is not a file\!/);

