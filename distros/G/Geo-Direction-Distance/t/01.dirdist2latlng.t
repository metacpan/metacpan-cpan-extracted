use strict;
use Test::Base;
plan tests => 4 * blocks;

use Geo::Direction::Distance;

run {
    my $block       = shift;
    my ($flat,$flng,$tlat,$tlng)  = split(/\n/,$block->input);
    my ($dir,$dist)               = split(/\n/,$block->expected);

    my ($cdir,$cdist) = latlng2dirdist($flat,$flng,$tlat,$tlng);

    is sprintf("%.3f",$cdir), sprintf("%.3f",$dir);
    is sprintf("%.3f",$cdist),sprintf("%.3f",$dist);

    my ($clat,$clng) = dirdist2latlng($flat,$flng,$cdir,$cdist);

    is sprintf("%.3f",$clat), sprintf("%.3f",$tlat);
    is sprintf("%.3f",$clng), sprintf("%.3f",$tlng);
};

__END__
===
--- input
35.6568030555556
139.669577222222
40.6039741666667
141.025839444444
--- expected
11.8035750044903
561836.657134336

===
--- input
32.616085
131.183760555556
28.1941283333333
129.329414444444
--- expected
200.451325769781
521565.019881702
