#!perl
#
# This file is part of Exception-Stringy
#
# This software is Copyright (c) 2014 by Damien Krotkine.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#

use strict;
use warnings;

use Test::More tests => 6;

use FindBin qw($Bin);
use lib "$Bin/tlib";

use Exception::Stringy;

use User1;
use User2;

eval { User1::test_user1() };
my $e = $@;

ok( $e->$xisa('Some::Exception'), "exception is of right type" );
like( $e->$xmessage(), qr/^user1/, "message is ok" );
is( $e->$xfield('field1'), 1, "field has correct value" );

eval { User2::test_user2() };
$e = $@;

ok( $e->$xisa('Some::Exception'), "exception is of right type" );
like( $e->$xmessage(), qr/^user2/, "message is ok" );
is( $e->$xfield('field2'), 1, "field has correct value" );
