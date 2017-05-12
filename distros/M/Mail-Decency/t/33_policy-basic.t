#!/usr/bin/perl

use strict;
use Test::More tests => 8;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestPolicy;
use TestModule;
use TestMisc;
use YAML;
use Data::Dumper;

BEGIN {
    use_ok( "Mail::Decency::Policy::Basic" ) or die;
};

my $policy = TestPolicy::create();

my $module;
CREATE_MODULE: {
    my $config_ref = YAML::LoadFile( "$Bin/conf/policy/basic.yml" );
    $module = Mail::Decency::Policy::Basic->new(
        server   => $policy,
        name     => "Test",
        config   => $config_ref,
        database => $policy->database,
        cache    => $policy->cache,
        logger   => empty_logger()
    );
    ok( $module, "Basic loaded" ) or die( "Problem: $@" );
}

my ( $mx_ok, $mx_ip );

eval {
    ( $mx_ok ) =
        map { $_->exchange }
        Net::DNS::Resolver->new->query( 'gmx.net', 'MX' )->answer
    ;
    ( $mx_ip ) =
        map { $_->address }
        Net::DNS::Resolver->new->query( $mx_ok, 'A' )->answer
    ;
};
ok( !$@ && $mx_ip, "Resolved testing address" ) or die( "Problem: $@" );

# build data for test
my %attrs = (
    helo_name         => 'gmx.net',
    client_name       => 'gmx.net',
    client_address    => $mx_ip,
    sender_address    => 'sender@gmx.net',
    sender_domain     => 'gmx.net',
    recipient_address => 'ulrich.kautz@googlemail.com',
    recipient_domain  => 'googlemail.com'
);


# setup test datbase
TEST_CORRECT: {
    
    my $attrs_ref = { %attrs };
    TestPolicy::session_init( $policy, $attrs_ref );
    
    $policy->session_data->spam_score( 0 );
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok( ! $@ && $policy->session_data->spam_score == 0, "Correct sender, no spamscore" );
}


# setup test datbase
TEST_HELO: {
    
    my $attrs_ref = {
        %attrs,
        helo_name => 'gmx', # correct, but not fqdn and invalid
    };
    TestPolicy::session_init( $policy, $attrs_ref );
    
    $policy->session_data->spam_score( 0 );
    eval {
        $module->handle( undef, $attrs_ref );
    };
    my @details = @{ $policy->session_data->spam_details };
    ok( $policy->session_data->spam_score == -10
        && $details[0] eq 'Module: Test; Score: -5; Helo hostname is not in FQDN'
        && $details[1] eq 'Module: Test; Score: -5; Helo hostname is unknown'
        && scalar @details == 3, "No FQDN, Unknown"
    );
    
    
    $attrs_ref = {
        %attrs,
        helo_name => '???', # correct, but not fqdn and invalid
    };
    TestPolicy::session_init( $policy, $attrs_ref );
    
    $policy->session_data->spam_score( 0 );
    eval {
        $module->handle( undef, $attrs_ref );
    };
    @details = @{ $policy->session_data->spam_details };
    #print "HERE ". Dumper( [ $policy->session_data->spam_score, @details ] );
    ok( $policy->session_data->spam_score == -15
        && $details[0] eq 'Module: Test; Score: -5; Helo hostname is invalid'
        && $details[1] eq 'Module: Test; Score: -5; Helo hostname is not in FQDN'
        && $details[2] eq 'Module: Test; Score: -5; Helo hostname is unknown'
        && scalar @details == 4, "Helo is invalid"
    );
}


# setup test datbase
TEST_FQDN_OTHER: {
    
    my $attrs_ref = {
        %attrs,
        recipient_address => 'bla@asd',
        sender_address    => 'blub@???'
    };
    TestPolicy::session_init( $policy, $attrs_ref );
    
    $policy->session_data->spam_score( 0 );
    eval {
        $module->handle( undef, $attrs_ref );
    };
    my @details = @{ $policy->session_data->spam_details };
    #print "HERE ". Dumper( [ $policy->session_data->spam_score, @details ] );
    ok( $policy->session_data->spam_score == -10
        && $details[0] eq 'Module: Test; Score: -5; Recipient address is not in FQDN'
        && $details[1] eq 'Module: Test; Score: -5; Sender address is not in FQDN'
        && scalar @details == 3, "Sender and recipient address not FQDN"
    );
}


# setup test datbase
TEST_UNKNOWN_OTHER: {
    
    my $attrs_ref = {
        %attrs,
        sender_domain    => 'sender-'. time(). '.tld',
        recipient_domain => 'recipient-'. time(). '.tld'
    };
    TestPolicy::session_init( $policy, $attrs_ref );
    
    $policy->session_data->spam_score( 0 );
    eval {
        $module->handle( undef, $attrs_ref );
    };
    my @details = @{ $policy->session_data->spam_details };
    #print "HERE ". Dumper( [ $policy->session_data->spam_score, @details ] );
    ok( $policy->session_data->spam_score == -10
        && $details[0] eq 'Module: Test; Score: -5; Recipient domain is unknown'
        && $details[1] eq 'Module: Test; Score: -5; Sender domain is unknown'
        && scalar @details == 3, "Sender and recipient domains unknown"
    );
}




TestMisc::cleanup( $policy );

