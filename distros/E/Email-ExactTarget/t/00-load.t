#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 11;


BEGIN
{
	use_ok( 'Text::Unaccent' );
	use_ok( 'HTTP::Request' );
	use_ok( 'LWP::UserAgent' );
	use_ok( 'HTML::Entities' );
	use_ok( 'URI::Escape' );
	use_ok( 'Data::Dumper' );
	use_ok( 'Carp' );
	use_ok( 'SOAP::Lite', 0.71 );
	use_ok( 'Email::ExactTarget' );
	use_ok( 'Email::ExactTarget::Subscriber' );
	use_ok( 'Email::ExactTarget::SubscriberOperations' );
}

diag( "Testing Email::ExactTarget $Email::ExactTarget::VERSION, Perl $], $^X" );
