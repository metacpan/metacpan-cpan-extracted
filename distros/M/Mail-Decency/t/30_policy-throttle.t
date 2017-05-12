#!/usr/bin/perl

use strict;
use Test::More tests => 11;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestPolicy;
use TestModule;
use TestMisc;
use YAML;

BEGIN {
    use_ok( "Mail::Decency::Policy::Throttle" ) or die;
};

my $policy = TestPolicy::create();

my $module;
CREATE_MODULE: {
    my $config_ref = YAML::LoadFile( "$Bin/conf/policy/throttle.yml" );
    $module = Mail::Decency::Policy::Throttle->new(
        server   => $policy,
        name     => "Test",
        config   => $config_ref,
        database => $policy->database,
        cache    => $policy->cache,
        logger   => empty_logger()
    );
    ok( $module, "Throttle loaded" ) or die( "Problem: $@" );
}


# setup test datbase
SETUP_DATABSE: {
    TestModule::setup_database( $module );
    
    # add for bigger limit exception
    $module->database->set( throttle => sender_domain => {
        sender_domain => 'biglimit.tld',
        maximum       => 10,
        interval      => 600
    } );
    
    # add for account test
    $module->database->set( throttle => sender_domain => {
        sender_domain => 'accounttest.tld',
        maximum       => -1, # infinite
        interval      => 600,
        account       => 'some-account'
    } );
    $module->database->set( throttle => account => {
        account  => 'some-account',
        maximum  => 1,
        interval => 600,
    } );
    
    ok( 1, "Setup database" );
}


# setup test datbase
TEST_DEFAULT: {
    
    # build data for test
    my $attrs_ref = {
        sender_domain  => 'defaultsender.tld',
    };
    TestPolicy::session_init( $policy, $attrs_ref );
    
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok_for_dunno( $policy, $@, "First send passwd" );
    
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok_for_dunno( $policy, $@, "Second send passed" );
    
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok_for_reject( $policy, $@, "Third send denied" );
    
    $attrs_ref = {
        sender_domain  => 'other-sender.tld',
    };
    TestPolicy::session_init( $policy, $attrs_ref );
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok_for_dunno( $policy, $@, "Other sender pass" );
    
    
}


# setup test datbase
TEST_EXCEPTIONS: {
    
    # build data for test
    my $attrs_ref = {
        sender_domain  => 'biglimit.tld',
    };
    TestPolicy::session_init( $policy, $attrs_ref );
    eval {
        $module->handle( undef, $attrs_ref ) for ( 0 .. 9 );
    };
    ok_for_dunno( $policy, $@, "Exception for domain: pass" );
    
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok_for_reject( $policy, $@, "Exception for domain: reject" );
    
}


# setup test datbase
TEST_ACCOUNT: {
    
    # build data for test
    my $attrs_ref = {
        sender_domain  => 'accounttest.tld',
    };
    TestPolicy::session_init( $policy, $attrs_ref );
    eval {
        $module->handle( undef, $attrs_ref ) for 1;
    };
    ok_for_dunno( $policy, $@, "Account domain: pass" );
    
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok_for_reject( $policy, $@, "Account domain: reject" );
    
}




TestMisc::cleanup( $policy );

