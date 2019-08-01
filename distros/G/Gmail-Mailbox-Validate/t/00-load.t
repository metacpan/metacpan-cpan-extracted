#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Gmail::Mailbox::Validate' ) || print "Bail out!\n";
}

diag( "Testing Gmail::Mailbox::Validate $Gmail::Mailbox::Validate::VERSION, Perl $], $^X" );
