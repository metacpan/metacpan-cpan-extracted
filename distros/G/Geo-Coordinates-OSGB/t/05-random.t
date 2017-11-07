# Toby Thurston -- 22 Jan 2016  
#
use strict;
use warnings;
use Test::More tests => 82;

use Geo::Coordinates::OSGB qw(ll_to_grid grid_to_ll);
use Geo::Coordinates::OSGB::Grid qw(format_grid parse_grid parse_landranger_grid random_grid);

my $test_gr = [
    [ 199655, 705224 ], [ 362912, 454635 ], [ 332542, 536000 ], [ 195534, 624752 ],
    [ 477874, 479205 ], [ 341023, 427436 ], [ 262075, 656636 ], [ 277608, 610010 ],
    [ 328928, 680229 ], [ 374618, 627780 ], [ 239426, 679651 ], [ 352773, 693886 ],
    [ 217824, 690638 ], [ 405086, 642142 ], [ 302333, 725721 ], [ 230665, 638702 ],
    [ 379694, 498196 ], [ 353675, 680346 ], [ 434806, 508733 ], [ 353218, 644348 ],
    [ 240019, 627870 ], [ 399376, 644025 ], [ 216055, 683053 ], [ 404907, 659631 ],
    [ 328986, 452284 ], [ 455571, 518861 ], [ 381069, 432136 ], [ 383789, 471796 ],
    [ 244423, 720540 ], [ 245961, 640953 ], [ 383517, 510721 ], [ 360186, 476873 ],
    [ 288978, 710687 ], [ 435428, 465933 ], [ 320861, 624818 ], [ 292130, 667706 ],
    [ 429886, 485711 ], [ 262386, 718167 ], [ 290893, 690049 ], [ 397887, 652847 ],
    [ 433065, 455737 ], [ 200101, 688121 ], [ 266765, 678297 ], [ 331388, 689848 ],
    [ 408648, 501097 ], [ 249263, 693854 ], [ 369150, 528419 ], [ 347075, 485560 ],
    [ 195804, 656742 ], [ 351177, 532579 ], [ 351900, 436695 ], [ 411197, 514380 ],
    [ 176812, 643220 ], [ 363426, 440855 ], [ 389806, 503640 ], [ 283404, 687161 ],
    [ 337993, 666916 ], [ 350984, 502238 ], [ 325325, 671559 ], [ 220326, 635868 ],
    [ 229958, 628791 ], [ 170905, 680913 ], [ 168035, 713450 ], [ 285080, 643175 ],
    [ 226439, 632173 ], [ 449270, 524045 ], [ 393583, 652539 ], [ 277687, 705642 ],
    [ 178395, 624916 ], [ 209718, 621069 ], [ 393191, 511641 ], [ 372667, 439138 ],
    [ 179637, 700017 ], [ 191644, 616764 ], [ 218471, 669436 ], [ 476118, 461156 ],
    [ 307172, 691672 ], [ 220582, 691022 ], [ 353731, 441483 ], [ 192272, 713255 ],
];

my ($E, $N, $sq, $e, $n, @sheets);

for my $i (0..39) {
    ($E, $N) = @{$test_gr->[$i]};
    ($e,$n) = ll_to_grid(grid_to_ll($E, $N));
    is (sprintf("%d %d", $e+0.5, $n+0.5), 
        sprintf("%d %d", $E, $N), 
        sprintf "Round trip %s %s", $i, scalar format_grid($E, $N));

}

for my $i (40..79) {
    ($E, $N) = @{$test_gr->[$i]};
    ($sq, $e, $n, @sheets) = format_grid($E,$N, { form => 'gps', maps => 1});

    my ($ee, $nn) = parse_grid($sheets[int rand @sheets], $e, $n, {figs => 5});
    my $gr1 = format_grid($ee, $nn);
    my $gr2 = format_grid(ll_to_grid(grid_to_ll($ee, $nn)));
    is($gr1, $gr2, "GR$i: $gr1=$gr2 " . join ' ', @sheets );
}


# Now checkout the random_grid function with a list of maps
# The point here is that 118 is a Landranger sheet but 439 is not
# Also sheet 118 is not overlapped by a sheet with a lower number
# so A:118 must be first in the list returned (because it's sorted)
($e, $n) = random_grid(118, 439);
(undef, undef, undef, @sheets) = format_grid($e, $n, { maps => 1 });
ok(@sheets > 0 && $sheets[0] eq 'A:118', "@sheets");

# test that we can also ignore a random string
# sheets 84-88 all share the same lower northing
# so we are checking that the deltas fit in a 200 km x 40 km box (plus a little margin)
use Geo::Coordinates::OSGB::Maps qw/%maps/;
($e, $n) = random_grid(84,85,86,87,88,'ignoreme');
my ($lle, $lln) = @{$maps{'A:84'}->{bbox}[0]};
my $de = $e-$lle;
my $dn = $n-$lln;
ok(0 < $de && $de<202000 && 0<$dn && $dn<42000, "RR $de < 202000 $dn < 42000 " . format_grid($e,$n));
