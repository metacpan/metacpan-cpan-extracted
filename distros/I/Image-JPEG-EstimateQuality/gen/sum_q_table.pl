#!perl

use strict;
use warnings;
use POSIX qw( floor );

# from JPEG Standard, CCITT/ITU T.81 Annex K (and RFC2435)
my @base_table = qw(
    16  11  10  16  24  40  51  61
    12  12  14  19  26  58  60  55
    14  13  16  24  40  57  69  56
    14  17  22  29  51  87  80  62
    18  22  37  56  68 109 103  77
    24  35  55  64  81 104 113  92
    49  64  78  87 103 121 120 101
    72  92  95  98 112 100 103  99
);

for my $q (1 .. 100) {
    my $factor = ($q < 50) ? 50.0 / $q : (100.0 - $q) / 50.0;

    my @tbl = map { $_ > 255 ? 255 : $_ < 1 ? 1 : int($_) }
              map { floor(0.5 + $_ * $factor) }
                  @base_table;

    my $sum = 0;
    $sum += $_ for @tbl;

    printf "%5d, ", $sum;
    print "\n" if $q % 10 == 0;
}
print "\n";
