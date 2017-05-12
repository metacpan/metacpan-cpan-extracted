#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mail::Maildir::Is::A' ) || print "Bail out!
";
}

diag( "Testing Mail::Maildir::Is::A $Mail::Maildir::Is::A::VERSION, Perl $], $^X" );
