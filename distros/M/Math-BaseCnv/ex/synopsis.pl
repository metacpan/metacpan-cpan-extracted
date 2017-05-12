#!/usr/bin/perl
use strict;use warnings;use utf8;use v5.10;use Math::BaseCnv;

            # CoNVert     63 from base-10 (decimal) to base- 2 (binary )
my $binary__63 = cnv(     63 , 10,  2 );
            # CoNVert 111111 from base- 2 (binary ) to base-16 (HEX    )
my $HEX_____63 = cnv( 111111 ,  2, 16 );
            # CoNVert     3F from base-16 (HEX    ) to base-10 (decimal)
my $decimal_63 = cnv(    '3F', 16, 10 );
say "63 dec->bin $binary__63 bin->HEX $HEX_____63 HEX->dec $decimal_63";
