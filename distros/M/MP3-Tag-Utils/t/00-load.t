#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MP3::Tag::Utils' ) || print "Bail out!
";
}

diag( "Testing MP3::Tag::Utils $MP3::Tag::Utils::VERSION, Perl $], $^X" );
