#! perl -T

use Test::More tests => 2 ; 

require_ok( 'Email::Public' );
ok( Email::Public->isPublic('foo@hotmail.com') );
