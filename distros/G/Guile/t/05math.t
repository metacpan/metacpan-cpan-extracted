use Test;
BEGIN { plan tests => 5 }
use Guile;

my $five = new Guile::SCM 5;
my $six = $five + 1;
ok($six == 6 and $five == 5);

my $one = $six - $five;
ok($six == 6 and $five == 5 and $one == 1);

my $two = new Guile::SCM 2;
my $twelve = $six * $two;
ok($two == 2 and $twelve == 12);

my $three = $six / $two;
ok($three == 3);

my $four = $three;
$four += 1;
ok($four == 4);
