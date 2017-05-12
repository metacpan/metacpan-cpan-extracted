# $Id: 01simple.t,v 1.3 2004/02/11 20:50:10 cgilmore Exp $

use Test::More qw(no_plan);

# Check to see if it loads

BEGIN{ use_ok( 'I18N::AcceptLanguage' ); }

###############################################################################
# Basic tests 
###############################################################################

my $t1 = I18N::AcceptLanguage->new();
ok( $t1->accepts('en', [( 'en' )]) eq 'en' );
ok( $t1->accepts('en-us', [( 'en' )]) eq 'en' );
ok( $t1->accepts('en', [( 'en-us' )]) eq 'en-us' );
ok( $t1->accepts('en-gb', [( 'en-us' )]) eq '' );
ok( $t1->accepts('ja', [( 'en' )]) eq '' );
ok( $t1->accepts('da,en-gb,fr-ch', [( 'en', 'de', 'fr', 'it' )]) eq 'en' );

###############################################################################
# Basic tests with default language 
###############################################################################

my $t2 = I18N::AcceptLanguage->new(defaultLanguage => 'ja');
ok( $t2->accepts('en', [( 'en' )]) eq 'en' );
ok( $t2->accepts('en-us', [( 'en' )]) eq 'en' );
ok( $t2->accepts('en', [( 'en-us' )]) eq 'en-us' );
ok( $t2->accepts('en-gb', [( 'en-us' )]) eq 'ja' );
ok( $t2->accepts('ja', [( 'en' )]) eq 'ja' );
ok( $t2->accepts('', [( 'en' )]) eq 'ja' );
ok( $t2->accepts('', [ ]) eq 'ja' );

###############################################################################
# Basic tests without default language 
###############################################################################

my $t3 = I18N::AcceptLanguage->new(strict => 0);
ok( $t3->accepts('en-gb', [( 'en-us' )]) eq 'en-us' );
ok( $t3->accepts('', [( 'en' )]) eq '' );
ok( $t3->accepts('', [ ]) eq '' );
