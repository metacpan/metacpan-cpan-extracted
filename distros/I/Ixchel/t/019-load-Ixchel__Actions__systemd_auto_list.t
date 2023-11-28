#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::Actions::systemd_auto_list' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::Actions::systemd_auto_list::VERSION, Perl $], $^X" );
