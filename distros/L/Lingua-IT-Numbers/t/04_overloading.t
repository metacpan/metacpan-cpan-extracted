use Lingua::IT::Numbers qw(number_to_it);

use Test::More tests => 8;

my $first = Lingua::IT::Numbers->new(123.11);
my $second = Lingua::IT::Numbers->new(321.22);

ok ($first eq "centoventitre virgola undici");
ok ($second eq "trecentoventuno virgola ventidue");
my $result = $first + $second;
ok ($result eq 'quattrocentoquarantaquattro virgola trentatre');
$result = $first - $second;
ok ($result eq 'meno centonovantotto virgola undici');
$result = $first * $second;
ok($result eq 'trentanovemilacinquecentoquarantacinque virgola tremilanovecentoquarantadue');
$first = Lingua::IT::Numbers->new(47.125);
$second = Lingua::IT::Numbers->new(6.5);
ok($first + 2 eq 'quarantanove virgola centoventicinque');
ok($second - 3 eq 'tre virgola cinque');
ok($first / $second eq 'sette virgola venticinque');

