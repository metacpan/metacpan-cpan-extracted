#!/usr/bin/perl -w

use strict;
use Test::More tests => 35;
use Test::Exception;

use_ok( 'Finance::Bank::Natwest::CredentialsProvider::Constant' );

my @invalid_details = (
    { },
    { customer_no => '0101790001' },
    { password => 'Password' },
    { pin => '4321' },
    { customer_no => '0101790001', password => 'Password' },
    { customer_no => '0101790001', pin => '4321' },
    { customer_no => '01017900010', password => 'Password', pin => '4321' },
    { customer_no => '010179000', password => 'Password', pin => '4321' },
    { customer_no => '0101790001', password => 'Password', pin => '432' },
    { customer_no => '0101790001', password => 'Password', pin => '43210' },
    { customer_no => '0101790001', password => 'Short', pin => '4321' },
    { customer_no => '0101790001', password => 'Much too long password',
        pin => '4321' },
    { dob => '010179', uid => '00010', password => 'Password', pin => '4321' },
    { dob => '010179', uid => '000', password => 'Password', pin => '4321' },
    { dob => '0101790', uid => '0001', password => 'Password', pin => '4321' },
    { dob => '01017', uid => '0001', password => 'Password', pin => '4321' },
    { customer_no => '01017900010', dob => '010179', uid => '00010',
        password => 'Password', pin => '4321' },
    { customer_no => '01017900010', dob => '010179', password => 'Password',
        pin => '4321' },
    { customer_no => '01017900010', uid => '00010', password => 'Password',
        pin => '4321' }
);

my @valid_details = (
    { customer_no => '0101790001', password => 'Password', pin => '4321' },
    { dob => '010179', uid => '0001', password => 'Password', pin => '4321' }
);

{
    my $provider = Finance::Bank::Natwest::CredentialsProvider::Constant->new(
        %{$valid_details[0]}
    );

    isa_ok( $provider, 'Finance::Bank::Natwest::CredentialsProvider::Constant' );

    foreach my $method (qw( get_start get_stop get_identity get_pinpass )) {
        can_ok( $provider, $method );
    }
}

foreach my $credentials (@invalid_details) {
    dies_ok { 
        my $provider = 
            Finance::Bank::Natwest::CredentialsProvider::Constant->new(
                %{$credentials} );
    } 'invalid credentials: expected to fail';
}

foreach my $credentials (@valid_details) {
    my $provider = Finance::Bank::Natwest::CredentialsProvider::Constant->new(
        %{$credentials}
    );

    $provider->get_start();

    is_deeply( $provider->get_identity(), 
        { uid => '0001', dob => '010179' },
        'Got expected identity' );

    is_deeply( $provider->get_pinpass( [0,1,2,3], [0,1,2,3,4,5,6,7] ),
        { pin => ['4','3','2','1'],
          password => ['P','a','s','s','w','o','r','d'] },
        'Got expected pin and pass' );

    is_deeply( $provider->get_pinpass( [-1,0,4], [-1,0,8] ),
        { pin => ['1','4',undef], password => ['d','P',undef] },
        'Got expected pin and pass' );

    dies_ok { $provider->get_pinpass( 1, [0,1,2] ) } 
        'invalid password char param';
    dies_ok { $provider->get_pinpass( [0,1,2], 1 ) }
        'invalid pin digit param';

    $provider->get_stop();

    undef $provider;
}

