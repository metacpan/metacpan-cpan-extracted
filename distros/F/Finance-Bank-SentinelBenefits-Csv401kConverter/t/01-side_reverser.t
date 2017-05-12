use Test::More tests => 5;
use Modern::Perl;
use lib './lib';

use_ok( 'Finance::Bank::SentinelBenefits::Csv401kConverter::SideReverser' );

my $reverser = Finance::Bank::SentinelBenefits::Csv401kConverter::SideReverser->new();

is($reverser->flip('Buy'), 'ShtSell', 'Reverse of a buy should be a short sell');
is($reverser->flip('Sell'), 'Buy', 'Reverse of a sell should be a buy');
is($reverser->flip('ShtSell'), 'Buy', 'Reverser of a sell short should be a buy');
is($reverser->flip('ReinvDiv'), 'ShtSell', 'Reverse of a dividend reinvested should be a short sell');
