use Test;
BEGIN { plan tests => 7 }

use Games::Cards::Poker qw(:all);

ok(1);
# what needs to sort:
#  'A'..'2'
#  'As'..'Ac'
#  'AA','AKs','AK'..'A2'
#  'AAA','AAK'..'AKQs','AKQ'..'222'
#  'AAAAK','AAAAQ'..'AKQJTs','AKQJT'..'32222' # based on rank values not scores
my @hand = qw( A K J 9 Q T 7 );
my $shrt = ShortHand(SortCards(\@hand));
ok($shrt, 'AKQJT97');

@hand = Deck();
$shrt = ShortHand(SortCards(\@hand));
ok($shrt, 'AAAAKKKKQQQQJJJJTTTT99998888777766665555444433332222');

@hand = Shuffle(Deck());
$shrt = ShortHand(SortCards(\@hand));
ok($shrt, 'AAAAKKKKQQQQJJJJTTTT99998888777766665555444433332222');

@hand = qw( AA AQ AQs AKs A2 A2s K2 22 AK );
SortCards(\@hand);
my $hand = "@hand"; 
ok($hand, 'AA AKs AK AQs AQ A2s A2 K2 22');

@hand = qw( A32 AKQ 222 AAQ A32s AAK AAA AKQs );
SortCards(\@hand);
$hand = "@hand"; 
ok($hand, 'AAA AAK AAQ AKQs AKQ A32s A32 222');

@hand = qw( A5432 AKQJT 32222 AAAAQ AKQJTs A5432s AAAAK );
SortCards(\@hand);
$hand = "@hand"; 
ok($hand, 'AAAAK AAAAQ AKQJTs AKQJT A5432s A5432 32222');
