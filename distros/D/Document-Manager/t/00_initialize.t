# $Id: 00_initialize.t,v 1.1.1.1 2005/06/11 05:36:59 bryce Exp $

use strict;
use Test::More tests => 2;

BEGIN { use_ok('Document::Repository'); }
BEGIN { use_ok('Document::Manager');    }

diag( "Testing Document::Manager $Document::Manager::VERSION" );

