#! /usr/bin/env perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../../lib";

BEGIN {
    use_ok( 'LWP::Authen::OAuth2' ) || print "Bail out!\n";
}

done_testing();
