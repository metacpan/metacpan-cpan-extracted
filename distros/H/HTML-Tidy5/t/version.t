#!perl -T

use 5.010001;
use warnings;
use strict;

use Test::More tests => 1;

use HTML::Tidy5;

my $version_string = HTML::Tidy5->tidy_library_version;
like( $version_string, qr/^5.\d+\.\d+$/, 'Valid version string' );

exit 0;
