# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

use utf8;

use 5.010_000;

use strict;
use warnings;

use Test2::V0;

use GS1::SyntaxEngine::FFI::GS1Encoder;

{
    my $encoder = GS1::SyntaxEngine::FFI::GS1Encoder->new();

    my $barcode = '^01070356200521631523080710230710';
    $encoder->data_str($barcode);

    my $result = $encoder->data_str;
    is( $result, $barcode, 'Data string should equal given value' );
}

done_testing;

1;
