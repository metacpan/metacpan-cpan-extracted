#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Mail::Milter::Authentication::Extra' ) || print "Bail out! ";
    use_ok( 'Mail::Milter::Authentication::Handler::SpamAssassin' ) || print "Bail out! ";
    use_ok( 'Mail::Milter::Authentication::Handler::UserDB' ) || print "Bail out! ";
    use_ok( 'Mail::Milter::Authentication::Handler::UserDB::Hash' ) || print "Bail out! ";
}

diag( "Testing Mail::Milter::Authentication::Extra $Mail::Milter::Authentication::Extra::VERSION, Perl $], $^X" );

