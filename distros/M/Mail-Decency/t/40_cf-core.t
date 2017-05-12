#!/usr/bin/perl

use strict;
use Test::More tests => 2;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use MIME::QuotedPrint;

BEGIN {
    use_ok( "Mail::Decency::ContentFilter" ) or die;
}
use TestContentFilter;
use TestMisc;

my $content_filter;

CREATE_POLICY: {
    eval {
        $content_filter = TestContentFilter::create();
    };
    ok( !$@ && $content_filter, "ContentFilter lodaded" ) or die( "Problem: $@" );
}



TestMisc::cleanup( $content_filter );
