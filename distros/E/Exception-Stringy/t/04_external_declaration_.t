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

use Test::More tests => 3;

use FindBin qw($Bin);
use lib "$Bin/tlib";

use ExceptionDeclaration;

eval { throw_exception("test1", field1 => 42) };
my $e = $@;
ok( $e->$xisa('Some::Exception'), "exception is of right type" );
like( $e->$xmessage(), qr/^test1/, "message is ok" );
is( $e->$xfield('field1'), 42, "field has correct value" );
