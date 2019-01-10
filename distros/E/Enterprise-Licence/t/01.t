use Test::More;

use Enterprise::Licence::Generate;
use Enterprise::Licence::Validate;

my $sec = 'ab3yq34s1£f';
my $cust = 'mycus';
my $key = Enterprise::Licence::Generate->new({ secret => $sec })->generate($cust, { years => 99 });
my @valid = Enterprise::Licence::Validate->new({ secret => $sec })->valid($key, $cust);
is($valid[0], 1);

$key = Enterprise::Licence::Generate->new({ secret => $sec })->generate($cust, { seconds => 1 });
sleep 1;
@valid = Enterprise::Licence::Validate->new({ secret => $sec })->valid($key, $cust);
is($valid[0], 0);
is($valid[1], 1);

done_testing();
