#!/usr/bin/perl -w

use strict;
use Test::More tests => 71;
use Test::Exception;
use Carp;

use vars qw($used_callback);

use_ok( 'Finance::Bank::Natwest::CredentialsProvider::Callback' );

dies_ok {
    my $provider = Finance::Bank::Natwest::CredentialsProvider::Callback->new();
} 'no callback provided: expected to fail';

dies_ok {
    my $provider = Finance::Bank::Natwest::CredentialsProvider::Callback->new(
        callback => 'not a code ref' );
} 'callback parameter not a code ref: expected to fail';

dies_ok {
    my $provider = Finance::Bank::Natwest::CredentialsProvider::Callback->new(
        callback => {}, id => {} );
} 'id parameter not a simple scalar: expected to fail';

{
    my $provider = Finance::Bank::Natwest::CredentialsProvider::Callback->new(
        callback => sub{} );

    isa_ok( $provider, 'Finance::Bank::Natwest::CredentialsProvider::Callback' );

    foreach my $method (qw( get_start get_stop get_identity get_pinpass )) {
        can_ok( $provider, $method );
    }
}

my @callbacks = (
    [
        [
            [undef, { uid => '0001', dob => '010179' }, 
                    { pin => ['4','3','2','1'],
                      password => ['P','a','s','s','w','o','r','d'] } ],
            [1,     { uid => '0001', dob => '010179' },
                    { pin => ['4','3','2','1'],
                      password => ['P','a','s','s','w','o','r','d'] } ],
        ],
        sub {
            $used_callback = 1;
            return { customer_no => '0101790001', 
                     password => 'Password',
                     pin => '4321' };
        }
    ], [
        [
            [undef, { uid => '0001', dob => '010179' }, 
                    { pin => ['4','3','2','1'],
                      password => ['P','a','s','s','w','o','r','d'] } ],
            [1,     { uid => '0002', dob => '020279' },
                    { pin => ['1','2','3','4'],
                      password => ['p','a','s','s','w','o','r','D'] } ],
            [2,     { uid => '0002', dob => '020279' },
                    { pin => ['1','2','3','4'],
                      password => ['p','a','s','s','w','o','r','D'] } ],
        ],
        sub {
            $used_callback = 1;
            my $id = shift;

            return { customer_no => '0101790001',
                     password => 'Password', pin => '4321' } if !defined $id;
            return { customer_no => '0202790002',
                     password => 'passworD', pin => '1234' };
        }
    ], [
        [
            [undef, { uid => '0001', dob => '010179' }, 
                    { pin => ['4','3','2','1'],
                      password => ['P','a','s','s','w','o','r','d'] } ],
            [1,     { uid => '0002', dob => '020279' },
                    { pin => ['1','2','3','4'],
                      password => ['p','a','s','s','w','o','r','D'] } ],
            [2],
        ],
        sub {
            $used_callback = 1;
            my $id = shift;

            return { customer_no => '0101790001',
                     password => 'Password', pin => '4321' } if !defined $id;
            return { customer_no => '0202790002',
                     password => 'passworD', pin => '1234' } if $id == 1;

            croak "Invalid id, stopped";
        }
    ], [
        [ map { [$_] } 1..19 ],
        sub {
            $used_callback = 1;
            my $id = shift;

            my @invalid_details = (
                { },
                { customer_no => '0101790001' },
                { password => 'Password' },
                { pin => '4321' },
                { customer_no => '0101790001', password => 'Password' },
                { customer_no => '0101790001', pin => '4321' },
                { customer_no => '01017900010', 
                  password => 'Password', pin => '4321' },
                { customer_no => '010179000', 
                  password => 'Password', pin => '4321' },
                { customer_no => '0101790001', 
                  password => 'Password', pin => '432' },
                { customer_no => '0101790001', 
                  password => 'Password', pin => '43210' },
                { customer_no => '0101790001', 
                  password => 'Short', pin => '4321' },
                { customer_no => '0101790001', 
                  password => 'Much too long password', pin => '4321' },
                { dob => '010179', uid => '00010', 
                  password => 'Password', pin => '4321' },
                { dob => '010179', uid => '000', 
                  password => 'Password', pin => '4321' },
                { dob => '0101790', uid => '0001', 
                  password => 'Password', pin => '4321' },
                { dob => '01017', uid => '0001', 
                  password => 'Password', pin => '4321' },
                { customer_no => '01017900010', dob => '010179', uid => '00010',
                  password => 'Password', pin => '4321' },
                { customer_no => '01017900010', dob => '010179', 
                  password => 'Password', pin => '4321' },
                { customer_no => '01017900010', uid => '00010', 
                  password => 'Password', pin => '4321' }
            );

            return $invalid_details[$id];
        }
    ]
);

foreach my $callback_info (@callbacks) {
    my $provider = Finance::Bank::Natwest::CredentialsProvider::Callback->new(
        callback => $callback_info->[1] );

    for my $callback (@{$callback_info->[0]}) {
        my $callback_id = $callback->[0];
        my $callback_identity = $callback->[1];
        my $callback_pinpass = $callback->[2];

        if (!defined $callback_identity) {
            dies_ok {
                $provider->get_start( id => $callback_id );
            } 'Invalid id or invalid credentials: expected to fail';
        } else {
            $provider->get_start( id => $callback_id );

            is_deeply( $provider->get_identity(), $callback_identity,
                'Got expected identity' );

            is_deeply( $provider->get_pinpass( 
                [0..@{$callback_pinpass->{pin}}-1],
                [0..@{$callback_pinpass->{password}}-1] ),
                $callback_pinpass, 
                'Got expected pin and pass' );

            is_deeply( $provider->get_pinpass(
                [-1,0,scalar @{$callback_pinpass->{pin}}],
                [-1,0,scalar @{$callback_pinpass->{password}}] ),
                { pin => [$callback_pinpass->{pin}[-1],
                          $callback_pinpass->{pin}[0],
                          undef],
                  password => [$callback_pinpass->{password}[-1],
                               $callback_pinpass->{password}[0],
                               undef] },
                'Got expected pin and pass' );

            $provider->get_stop();

            $used_callback = 0;
            $provider->get_start( id => $callback_id );
            ok( $used_callback, 'used callback' );
            $provider->get_stop();
        }
    }

    undef $provider;
}

foreach my $callback_info (@callbacks) {
    my $provider = Finance::Bank::Natwest::CredentialsProvider::Callback->new(
        callback => $callback_info->[1], cache=>1 );

    for my $callback (@{$callback_info->[0]}) {
        my $callback_id = $callback->[0];
        my $callback_identity = $callback->[1];
        my $callback_pinpass = $callback->[2];
    
        if (defined $callback_identity) {
            $used_callback = 0;
            $provider->get_start( id => $callback_id );

            ok( $used_callback, 'used callback' );

            $provider->get_stop();

            $used_callback = 0;
            $provider->get_start( id => $callback_id );
            
            ok (!$used_callback, 'used cached values' );

            $provider->get_stop();
        }
    }

    undef $provider;
}

