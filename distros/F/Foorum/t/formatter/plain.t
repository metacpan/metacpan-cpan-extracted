#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {

    eval { require URI::Find::UTF8 }
        or plan skip_all => 'URI::Find::UTF8 is required for this test';

    plan tests => 2;
}

use Foorum::Formatter qw/filter_format/;

my $text = <<TEXT;
hello body.

http://fayland.org/
<a href="http://fayland.org">fayland.org</a>
TEXT

my $html = filter_format($text);

like( $html, qr/\<br/,      'linebreak OK' );
like( $html, qr/\<a href=/, 'http://fayland.org/ URI::Find::UTF8 OK' );

#diag($html);
