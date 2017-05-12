use Test::More 'no_plan';

use List::Maker;

for my $n (1..10) {
    my @picks = <0..20 x 2 :pick $n>;

    ok @picks == $n =>  "Correct number ($n) picked";
    for my $pick (@picks) {
        ok 0 <= $pick && $pick <= 20 => "Picked $n in range";
        is scalar grep({ $_ == $pick } @picks), 1 => "Picked $n uniquely";
        ok $pick % 2 == 0  => "Generated $n correctly";
    }


    my @unipick = <1,3,..19 : pick>;

    is scalar(@unipick), 1 =>  "Correct single number picked from $n";
    ok 1 <= $unipick[0] && $unipick[0] <= 19 => "Uni picked $n in range";
    ok $unipick[0] % 2 => "Generated $n correctly";


    my @duopick = <^100 : pick 2>;

    is scalar(@duopick), 2 =>  "Correct two picked from $n";
    ok 0 <= $duopick[0] && $duopick[0] < 100 => "Duo picked $n first in range";
    ok 0 <= $duopick[1] && $duopick[1] < 100 => "Duo picked $n second in range";
    ok $duopick[0] != $duopick[1] => "Duo picked unique pair";

    my @seven = 1..7;
    my $monopick = <^@seven :pick>;
    ok defined($monopick) => "Monopick $n defined";
    ok 0 <= $monopick && $monopick <= 7 => "Monopick $n works";

    my @wordroll = <cat dog fish rat :pick 2>;

    is scalar(@wordroll), 2               =>  'Correct words rolled';
    ok $wordroll[0] =~ /cat|dog|fish|rat/ => 'First word rolled right';
    ok $wordroll[1] =~ /cat|dog|fish|rat/ => 'Second word rolled right';
    ok $wordroll[0] ne $wordroll[1]       => 'Picked words without replacement';

}
