use Test;
BEGIN { plan tests => 5 }

use Guile;

# try applying a procedure
my $arg1 = new Guile::SCM 10;
my $arg2 = new Guile::SCM 20;

# using the Guile supplied calling mechanism
my $add = Guile::lookup("+");
my $result = Guile::call($add, $arg1, $arg2);
ok($result == 30);

# and our auto-lookup
$result = Guile::call('+', $arg1, $arg2);
ok($result == 30);

$result = Guile::apply($add, [$arg1, $arg2]);
ok($result == 30);

# and try codulation
$result = $add->($arg1, $arg2);
ok($result == 30);

# try it with implicit SCMs
my $result2 = Guile::call($add, 10, 20);
ok(Guile::number_p($result2) and $result2 == 30);
