# $Id: 00_initialize.t,v 1.2 2006/05/03 17:04:15 judith_osdl Exp $

use strict;
use Test::More tests => 2;

BEGIN { use_ok('Linux::Bootloader'); }
BEGIN { use_ok('Linux::Bootloader::Detect'); }

diag( "Testing Linux::Bootloader $Linux::Bootloader::VERSION" );



