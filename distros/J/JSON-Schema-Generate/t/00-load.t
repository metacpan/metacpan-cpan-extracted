#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'JSON::Schema::Generate' ) || print "Bail out!\n";
}

diag( "Testing JSON::Schema::Generate $JSON::Schema::Generate::VERSION, Perl $], $^X" );
