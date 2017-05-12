#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    my $has_test_longstring
        = eval 'use Test::LongString; 1;';  ## no critic (ProhibitStringyEval)
    $has_test_longstring
        or plan skip_all => 'Test::LongString is required for this test';
    plan tests => 2;
}

use Foorum::XUtils qw/tt2/;
my $tt2 = tt2();

my $var = {
    title   => 'TestTitle',
    RSS_URL => 'httpRSS_URL',
};

my $ret;
$tt2->process( 'wrapper.html', $var, \$ret );

contains_string( $ret, 'TestTitle', '[% title %] ok' );
like_string(
    $ret,
    qr/application\/rss\+xml(.*?)href\=\"httpRSS_URL\"/,
    '[% RSS_URL %] OK'
);
