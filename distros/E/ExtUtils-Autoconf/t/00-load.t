#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'ExtUtils::Autoconf' );
}

diag( "Testing ExtUtils::Autoconf $ExtUtils::Autoconf::VERSION, Perl $], $^X" );
