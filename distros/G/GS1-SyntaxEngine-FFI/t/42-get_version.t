# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

use utf8;

use 5.010_000;

use strict;
use warnings;

use Test2::V0;

use GS1::SyntaxEngine::FFI::GS1Encoder;

{
    my $encoder = GS1::SyntaxEngine::FFI::GS1Encoder->new();
    my $version = $encoder->version;

    like( $version, qr/20\d{2}$/sxm, 'Version matches' );
}

done_testing;

1;
