#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ixchel::Actions::systemd_journald_conf' ) || print "Bail out!\n";
}

diag( "Testing Ixchel $Ixchel::Actions::systemd_journald_conf::VERSION, Perl $], $^X" );
