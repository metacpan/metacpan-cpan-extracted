#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 3;


BEGIN
{
	use_ok( 'Email::ExactTarget' );
	use_ok( 'Email::ExactTarget::Subscriber' );
	use_ok( 'Email::ExactTarget::SubscriberOperations' );
}

diag( "Testing Email::ExactTarget::SubscriberOperations $Email::ExactTarget::SubscriberOperations::VERSION, Perl $], $^X" );
