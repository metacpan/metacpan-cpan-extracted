# banner test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

#~ use Test::Output;
use IO::Capture::Stdout ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Debug::Mixin ; 

# load without debugger, 'use'ing module banners && Debug::Mixin banner  NOT shown
	# except modules forcing banner display
	
# load with debugger, Debug::Mixin banner shown
# load with debugger, 'use'ing module banners && Debug::Mixin banner shown
