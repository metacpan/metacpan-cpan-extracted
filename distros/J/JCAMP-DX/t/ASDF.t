#!/usr/bin/perl

use strict;
use warnings;
use JCAMP::DX::ASDF;

use Test::More tests => 13;

# The following tests were adapted from McDonald and Wilks (1988)
# Table VIIb.:

my $output = [ 1, 2, 3, 3, 2, 1, 0, -1, -2, -3 ];

is_deeply( [ JCAMP::DX::ASDF::decode_FIX( '1 2 3 3 2 1 0 -1 -2 -3' ) ], $output );
is_deeply( [ JCAMP::DX::ASDF::decode_PAC( '1+2+3+3+2+1+0-1-2-3' ) ], $output );
is_deeply( [ JCAMP::DX::ASDF::decode_PAC( '1 2 3 3 2 1 0-1-2-3' ) ], $output );
is_deeply( [ JCAMP::DX::ASDF::decode_SQZ( '1BCCBA@abc' ) ], $output );
is_deeply( [ JCAMP::DX::ASDF::decode_DIF( '1JJ%jjjjjj' ) ], $output );
is_deeply( [ JCAMP::DX::ASDF::decode_DIFDUP( '1JT%jX' ) ], $output );

is_deeply( [ JCAMP::DX::ASDF::decode( '1 2 3 3 2 1 0 -1 -2 -3' ) ], $output );
is_deeply( [ JCAMP::DX::ASDF::decode( '1+2+3+3+2+1+0-1-2-3' ) ], $output );
is_deeply( [ JCAMP::DX::ASDF::decode( '1 2 3 3 2 1 0-1-2-3' ) ], $output );
is_deeply( [ JCAMP::DX::ASDF::decode( '1BCCBA@abc' ) ], $output );
is_deeply( [ JCAMP::DX::ASDF::decode( '1JJ%jjjjjj' ) ], $output );
is_deeply( [ JCAMP::DX::ASDF::decode( '1JT%jX' ) ], $output );

# The following test was applied from Baumbach et al. (2001), although
# was initially reported in McDonald and Wilks (1988) Table VI, where it
# contained typos in at least two positions of the DIFDUP string.

is_deeply( [ JCAMP::DX::ASDF::decode_DIFDUP( '@VKT%TLkj%J%KLJ%njKjL%kL%jJULJ%kLK1%lLMNPNPRLJ0QTOJ1P' ) ],
           [ qw( 0 0 0 0 2 4 4 4 7 5 4 4 5 5 7 10 11 11 6 5 7 6 9 9 7
                 10 10 9 10 11 12 15 16 16 14 17 38 38 35 38 42 47 54
                 59 66 75 78 88 96 104 110 121 128 ) ] );
