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
        x   => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        y   => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
    }
);

# Calculate PSNR between following signals.
#
# x = [ 1.1, 2.2, 3.3, 4.4, 5.5 ]
# y = [ 9.9, 8.8, 7.7, 6.6, 5.5 ]
print $psnr->psnr . "\n";

# Calculate PSNR between the same signals ...but this function does not calculate it.
# This function returns string of 'same', because it occurs zero divide.
$psnr->x( [ 1, 2, 3, 4 ] );
$psnr->y( [ 1, 2, 3, 4 ] );
print $psnr->psnr . "\n";
