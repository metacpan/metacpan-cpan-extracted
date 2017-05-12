#!perl

use Test::More tests => 2;

BEGIN {
	use_ok( 'Email::Sample' );
}

diag( "Testing Email::Sample $Email::Sample::VERSION, Perl $], $^X" );


use Email::Sample;
my $emailgen = Email::Sample->new();
$emailgen->add_valid_domains( [ 'url.com.tw'  , 'google2.com.tw'  ] );
my @valid_emails = $emailgen->valid_emails( size => 20 );
ok( @valid_emails );


# my @invalid_emails = $emailgen->invalid_emails();

