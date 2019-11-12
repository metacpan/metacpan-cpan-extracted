use Test;
BEGIN { plan tests => 3 }
END { ok(0) unless $loaded }
use LCC ();
$loaded = 1;
ok(1);

# 02 Check if we can make the main object
my $lcc = LCC->new( {RaiseError => 1} );
ok($lcc);

# 03 Check if it is the right version
ok($lcc->version,'1.0');
