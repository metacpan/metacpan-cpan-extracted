use strict;
use Test;
BEGIN { plan tests => 2 }

use Dunce::time ':WARN';

my $t1 = time;
my $t2 = time + 100_000_000;

my $warning;
$SIG{__WARN__} = sub {
    $warning .= shift;
};

my @str_compared = sort $t1, $t2;
ok($warning);
ok("@str_compared", "$t2 $t1");
