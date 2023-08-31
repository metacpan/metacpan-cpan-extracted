# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

use utf8;

use 5.010_000;

use strict;
use warnings;

use Test2::V0;

use experimental 'try';

use GS1::SyntaxEngine::FFI::GS1Encoder;

{
    my $encoder = GS1::SyntaxEngine::FFI::GS1Encoder->new();
    try {
        $encoder->ai_data_str(' some non parseable dummy');
    }
    catch ($err) {
        is( $err->message, 'Failed to parse AI data' );
    }
}

done_testing;

1;
