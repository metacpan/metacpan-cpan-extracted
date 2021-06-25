#!/usr/bin/env perl
use 5.006;
use strict;
use warnings;
use Test::More;


BEGIN {
    use_ok( 'LINE::Notify::Simple' ) || print "Bail out!\n";
}

my $invalid_access_token = "invalid";
my $line = LINE::Notify::Simple->new({ access_token => $invalid_access_token });
my $res = $line->notify("test");

ok($res->is_success == 0, "invalid token response test");
done_testing;
