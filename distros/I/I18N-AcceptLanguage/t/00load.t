# $Id: 00load.t,v 1.1 2002/09/26 22:23:33 cgilmore Exp $

use Test::More qw(no_plan);

# Check to see if it loads

BEGIN{ use_ok( 'I18N::AcceptLanguage' ); }
