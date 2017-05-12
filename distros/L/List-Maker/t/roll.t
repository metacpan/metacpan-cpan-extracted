use Test::More 'no_plan';

use List::Maker;

for my $n (1..10) {
    my @rolls = <1..20 : N % 2 : roll $n >;

    ok @rolls == $n =>  'Correct number rolled';
    for my $roll (@rolls) {
        ok 1 <= $roll && $roll <= 19 => 'rolled in range';
    }

    my @uniroll = <1..100:/7/:roll>;

    is scalar(@uniroll), 1 =>  'Correct single number rolled';
    ok 1 <= $uniroll[0] && $uniroll[0] <= 100 => 'rolled in range';
    ok $uniroll[0] =~ 7 => 'rolled with filter';


    my @wordroll = <cat dog fish rat :roll 2>;

    is scalar(@wordroll), 2 =>  'Correct words rolled';
    ok $wordroll[0] =~ /cat|dog|fish|rat/ => 'First word rolled right';
    ok $wordroll[1] =~ /cat|dog|fish|rat/ => 'Second word rolled right';

}
