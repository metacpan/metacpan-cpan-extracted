use strict;
use warnings;

use Test::More 0.88;

use HTML::Builder -depreciated => { -prefix => 'html_' };

is eval( "html_applet {}" ), qq{<applet></applet>}, "simple applet works";

diag html_applet( sub {} );

done_testing();
