#!/usr/bin/env perl
use 5.006;
use strict;
use warnings;
use Test::More;

if ( !exists $ENV{LINE_ACCESS_TOKEN} ) {
    plan( skip_all => "LINE_ACCESS_TOKEN environtment not required for installation" );
}


require_ok( 'LINE::Notify::Simple' ) || print "Bail out!\n";

my $access_token = $ENV{LINE_ACCESS_TOKEN};
my $line = LINE::Notify::Simple->new({ access_token => $access_token });
my $res = $line->notify("valid token response test");

ok($res->is_success == 1, "valid token response test");

done_testing;
