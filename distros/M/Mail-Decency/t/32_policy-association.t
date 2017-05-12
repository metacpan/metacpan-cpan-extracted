#!/usr/bin/perl

use strict;
use Test::More tests => 6;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestPolicy;
use TestModule;
use TestMisc;
use YAML;

BEGIN {
    use_ok( "Mail::Decency::Policy::Association" ) or die;
    use_ok( "Net::DNS::Resolver" ) or die;
};

my $policy = TestPolicy::create();

my $module;
CREATE_MODULE: {
    my $config_ref = YAML::LoadFile( "$Bin/conf/policy/association.yml" );
    $module = Mail::Decency::Policy::Association->new(
        server   => $policy,
        name     => "Test",
        config   => $config_ref,
        database => $policy->database,
        cache    => $policy->cache,
        logger   => empty_logger()
    );
    ok( $module, "Association loaded" ) or die( "Problem: $@" );
}

# setup test datbase
TEST_MX: {
    
    my ( $mx_ok ) =
        map { $_->exchange }
        Net::DNS::Resolver->new->query( 'gmx.net', 'MX' )->answer
    ;
    my ( $mx_ip ) =
        map { $_->address }
        Net::DNS::Resolver->new->query( $mx_ok, 'A' )->answer
    ;
    
    # build data for test
    my $attrs_ref = {
        client_address  => $mx_ip,
        sender_domain   => 'gmx.net'
    };
    TestPolicy::session_init( $policy, $attrs_ref );
    
    my $weight_before = $policy->session_data->spam_score;
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok( ! $@ && $weight_before < $policy->session_data->spam_score, "MX recognized" );
}

# setup test datbase
TEST_A: {
    
    my ( $a_ip ) =
        map { $_->address }
        Net::DNS::Resolver->new->query( 'gmx.net', 'A' )->answer
    ;
    # build data for test
    my $attrs_ref = {
        client_address  => $a_ip,
        sender_domain   => 'gmx.net'
    };
    TestPolicy::session_init( $policy, $attrs_ref );
    
    my $weight_before = $policy->session_data->spam_score;
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok( ! $@ && $weight_before < $policy->session_data->spam_score, "A recognized" );
}



# setup test datbase
TEST_WRONG_A: {
    
    my ( $a_ip ) =
        map { $_->address }
        Net::DNS::Resolver->new->query( 'google.com', 'A' )->answer
    ;
    # build data for test
    my $attrs_ref = {
        client_address  => $a_ip,
        sender_domain   => 'gmx.net'
    };
    TestPolicy::session_init( $policy, $attrs_ref );
    
    my $weight_before = $policy->session_data->spam_score;
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok( $weight_before > $policy->session_data->spam_score, "Wrong IP recognized" );
}




TestMisc::cleanup( $policy );

