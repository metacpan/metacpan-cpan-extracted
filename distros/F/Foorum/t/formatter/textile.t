#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {

    eval { require Text::Textile }
        or plan skip_all => 'Text::Textile is required for this test';

    plan tests => 3;
}

use Foorum::Formatter qw/filter_format/;

my $text = <<TEXT;
h1. Heading

A _simple_ demonstration of Textile markup.

* One
* Two
* Three

"More information":http://www.textism.com/tools/textile is available.
TEXT

my $html = filter_format( $text, { format => 'textile' } );

like( $html, qr/h1/, 'h1 OK' );
like( $html, qr/li/, '*,* OK' );
like( $html, qr/\<a href=/,
    '"More information":http://www.textism.com/tools/textile OK' );

#diag($html);
