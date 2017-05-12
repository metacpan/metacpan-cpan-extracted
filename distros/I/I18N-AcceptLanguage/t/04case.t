# $Id: 04case.t,v 1.1 2002/11/14 16:57:43 cgilmore Exp $

use Test::More qw(no_plan);

# Check to see if it loads

BEGIN{ use_ok( 'I18N::AcceptLanguage' ); }

###############################################################################
# Basic tests 
###############################################################################

my $t1 = I18N::AcceptLanguage->new();
ok( $t1->accepts('en-US', [( 'en-us' )]) eq 'en-us' );
ok( $t1->accepts('en-us', [( 'en-US' )]) eq 'en-US' );
