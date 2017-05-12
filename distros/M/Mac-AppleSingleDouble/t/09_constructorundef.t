use Test;
BEGIN { plan tests => 2 }

use Mac::AppleSingleDouble;
#print "\nMaking sure various error conditions are caught...\n";
ok(!eval { $adfile = new Mac::AppleSingleDouble(); });
undef($adfile); # make warning "only used once" go away
ok($@, qr/^The constructor \(new\) requires a filename as an argument\!/);
