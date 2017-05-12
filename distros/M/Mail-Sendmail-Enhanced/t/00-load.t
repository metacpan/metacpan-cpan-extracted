#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mail::Sendmail::Enhanced' ) || print "Bail out!\n";
}

diag( "Testing Mail::Sendmail::Enhanced $Mail::Sendmail::Enhanced::VERSION, Perl $], $^X" );
