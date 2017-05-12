#!/usr/bin/perl -w

use strict;

use lib 't/lib';

use Carp;
use Test::More tests => 15;
use Test::Exception;

use Mock::NatwestWebServer;
my $nws = Mock::NatwestWebServer->new();

use_ok( 'Finance::Bank::Natwest::Connection' );

for (   {},
        { credentials => 'Constant' },
        { credentials => 'UnknownCP' },
        { credentials => 'UnknownCP', credentials_options => {} }, 
        { credentials => bless {}, 'YetAnotherUnknownCP' },
        { credentials => {} },
        { credentials_options => {} } ) {
    dies_ok {
        my $nwb = Finance::Bank::Natwest::Connection->new(%{$_});
    } 'invalid credential parameters: expected to fail';
}
    
{
    my $nwb;

    ok(
        $nwb = Finance::Bank::Natwest::Connection->new(
            credentials => 'Constant', 
	    credentials_options => { customer_no => '0101790001',
	                             password => 'Password',
				     pin => '1234' }
	),
        'valid credentials - getting ::Connection to create credentials object'
    );

    isa_ok( $nwb, 'Finance::Bank::Natwest::Connection' );

    foreach my $method (qw( login post )) {
        can_ok( $nwb, $method );
    }

    is( $nws->next_call(), undef, 'nothing but new() called yet' );
    $nws->clear();
}

{
    my $creds = Finance::Bank::Natwest::CredentialsProvider::Constant->new(
        customer_no => '0101790001', password => 'Password', pin => '1234'
    );

    ok(
        my $nwb = Finance::Bank::Natwest::Connection->new(
                     credentials => $creds ), 
        'valid credentials - providing premade credentials object' 
    );

    $nws->add_account( dob => '010179', uid => '0001',
                       pin => '1234', pass => 'Password' );
    $nwb->login();
    ok( $nwb->{login_ok}, 'Logged in successfully' );
}

