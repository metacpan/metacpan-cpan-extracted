# $Id: 02quality.t,v 1.2 2002/10/02 21:28:35 cgilmore Exp $

use Test::More qw(no_plan);

# Check to see if it loads

BEGIN{ use_ok( 'I18N::AcceptLanguage' ); }

###############################################################################
# Quality tests
###############################################################################

my $t1 = I18N::AcceptLanguage->new();
ok( $t1->accepts('en-us,en;q=0.2', [( 'en-us', 'en' )]) eq 'en-us' );
ok( $t1->accepts('en-us;q=0.2, ja;q=0.9', [( 'en-us', 'ja' )]) eq 'ja' );
ok( $t1->accepts('en-gb;q=1,en;q=0.2', [( 'en-us', 'en-gb' )]) eq 'en-gb' );
ok( $t1->accepts('en-gb;q=1,en;q=0.2', [( 'en-us', 'en' )]) eq 'en' );
ok( $t1->accepts('en-gb;q=1,en;q=0.9,ja;q=0.8', [( 'en-us', 'ja' )]) eq 'en-us' );
ok( $t1->accepts('da,en-gb;q=0.8,fr-ch;q=0.7', [( 'en', 'de', 'fr', 'it' )]) eq 'en' );
