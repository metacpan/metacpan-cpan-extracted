# $Id: 03wildcard.t,v 1.1 2002/09/26 22:23:33 cgilmore Exp $

use Test::More qw(no_plan);

# Check to see if it loads

BEGIN{ use_ok( 'I18N::AcceptLanguage' ); }

###############################################################################
# Wildcard tests 
###############################################################################

my $t1 = I18N::AcceptLanguage->new();
ok( $t1->accepts('en,*', [( 'en', 'fr' )]) eq 'en' );
ok( $t1->accepts('en-us,*', [( 'en', 'fr' )]) eq 'en' );
ok( $t1->accepts('en,*', [( 'en-us' )]) eq 'en-us' );
ok( $t1->accepts('en-gb,*', [( 'en-us' )]) eq 'en-us' );
ok( $t1->accepts('ja,*', [( 'en' )]) eq 'en' );
