#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.012000;
use FindBin;
use lib ("$FindBin::Bin/../lib");
use Math::PSNR;

my $psnr = Math::PSNR->new(
    {
        bpp => 8,
        x   => {
            r => [ 1, 2, 3, 4, 5 ],
            g => [ 1, 2, 3, 4, 5 ],
            b => [ 1, 2, 3, 4, 5 ],
        },
        y => {
            r => [ 1, 2, 3, 4, 5 ],
            g => [ 1, 2, 3, 4, 5 ],
            b => [ 1, 2, 3, 4, 5 ],
        },
    }
);

# Calculate PSNR between the same signals... but this function does not calculate it.
# This functin returns string of 'same', because it occurs zero divide.
#
# x = {
#     r => [ 1, 2, 3, 4, 5 ],
#     g => [ 1, 2, 3, 4, 5 ],
#     b => [ 1, 2, 3, 4, 5 ],
# }
# y = {
#     r => [ 1, 2, 3, 4, 5 ],
#     g => [ 1, 2, 3, 4, 5 ],
#     b => [ 1, 2, 3, 4, 5 ],
# }
print $psnr->psnr_rgb . "\n";

# Calculate PSNR between following hash.
#
# x = {
#     r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
#     g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
#     b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
# }
# y = {
#     r => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
#     g => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
#     b => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
# }
$psnr->x(
    {
        r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
    }
);
$psnr->y(
    {
        r => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
        g => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
        b => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
    }
);
print $psnr->psnr_rgb . "\n";
