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
        x   => [ 1, 2, 3, 4 ],
        y   => [ 1, 2, 3, 4 ],
    }
);

# Calculate MSE between following lists.
#
# x = [ 1, 2, 3, 4 ]
# y = [ 1, 2, 3, 4 ]
print $psnr->mse . "\n";

# Calculate MSE between following lists.
#
# x = [ 1.1, 2.2, 3.3, 4.4, 5.5 ]
# y = [ 9.9, 8.8, 7.7, 6.6, 5.5 ]
$psnr->x( [ 1.1, 2.2, 3.3, 4.4, 5.5 ] );
$psnr->y( [ 9.9, 8.8, 7.7, 6.6, 5.5 ] );
print $psnr->mse . "\n";
