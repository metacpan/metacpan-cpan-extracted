#!perl -T

BEGIN
{
    $ENV{LC_ALL} = 'C';

    # See: https://github.com/shlomif/html-tidy5/issues/6
    $ENV{LANG} = 'en_US.UTF-8';
};


use 5.010001;
use warnings;
use strict;

use Test::More tests => 1;

use HTML::T5;

my $version_string = HTML::T5->tidy_library_version;
like( $version_string, qr/^5.\d+\.\d+$/, 'Valid version string' );

exit 0;
