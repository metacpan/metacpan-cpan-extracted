# Copyright (C) 2004  Joshua Hoblitt
#
# $Id: 01_load.t,v 1.2 2004/07/18 19:36:35 jhoblitt Exp $

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { use_ok( 'HTTP::Range' ); }
