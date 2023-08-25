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

    my $data_str = $encoder->data_str;
    is( $data_str, $barcode, 'Data string should equal given value' );
    my $ai_str = $encoder->ai_data_str();
    is( '(01)07035620052163(15)230807(10)230710',
        $ai_str, 'AI string not as expected' );

    $barcode = '^01070356200521631523080710230711';
    $encoder->data_str($barcode);

    $data_str = $encoder->data_str;
    is( $data_str, $data_str, 'Data string should equal given value' );
    $ai_str = $encoder->ai_data_str();
    is( '(01)07035620052163(15)230807(10)230711',
        $ai_str, 'AI string not as expected' );
}

done_testing;

1;
