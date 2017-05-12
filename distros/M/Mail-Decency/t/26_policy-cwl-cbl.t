#!/usr/bin/perl

use strict;
use Test::More tests => 8;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestPolicy;
use TestModule;
use TestMisc;
use YAML;

BEGIN {
    use_ok( "Mail::Decency::Policy::CWL" ) or die;
}

my $policy = TestPolicy::create();

my $module;
CREATE_MODULE: {
    eval {
        my $config_ref = YAML::LoadFile( "$Bin/conf/policy/cwl.yml" );
        $module = Mail::Decency::Policy::CWL->new(
            server   => $policy,
            name     => "Test",
            config   => $config_ref,
            database => $policy->database,
            cache    => $policy->cache,
            logger   => empty_logger()
        );
    };
    ok( !$@ && $module, "CWL loaded" ) or die( "Problem: $@" );
}


# setup test datbase
SETUP_DATABSE: {
    eval {
        TestModule::setup_database( $module );
    };
    ok( !$@, "Setup database" ) or die( "Problem: $@" );
}


# insert data
CREATE_RECORDS: {
    eval {
        $module->database->set( cwl => ips => {
            client_address   => '255.255.0.0',
            recipient_domain => 'dummy1.tld',
        } );
        $module->database->set( cwl => domains => {
            sender_domain    => 'dummy2.tld',
            recipient_domain => 'dummy1.tld',
        } );
        $module->database->set( cwl => addresses => {
            sender_address   => 'someone@dummy3.tld',
            recipient_domain => 'dummy1.tld',
        } );
    };
    ok( !$@, "Test records inserted" ) or die( "Problem: $@" );
}



my $attrs_ref = {
    sender_address    => 'someone@somewhere.com',
    sender_domain     => 'somewhere.com',
    recipient_address => 'test@dummy1.tld',
    recipient_domain  => 'dummy1.tld',
    client_address    => '255.255.0.1',
};

# check negative
CHECK_NEGATIVE: {
    TestPolicy::session_init( $policy, $attrs_ref );
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok_for_dunno( $policy, $@, "DUNNO for unknown" );
}


# check IP
CHECK_IP: {
    my $positive_ref = { %$attrs_ref, client_address => '255.255.0.0' };
    TestPolicy::session_init( $policy, $positive_ref );
    eval {
        $module->handle( undef, $positive_ref );
    };
    ok_for_ok( $policy, $@, "IP whitelisting" );
}



# check DOMAIN
CHECK_DOMAIN: {
    my $positive_ref = {
        %$attrs_ref,
        sender_domain  => 'dummy2.tld',
        sender_address => 'somewhere@dummy2.tld',
    };
    TestPolicy::session_init( $policy, $positive_ref );
    eval {
        $module->handle( undef, $positive_ref );
    };
    ok_for_ok( $policy, $@, "Domain whitelisting" );
}



# check ADDRESS
CHECK_ADDRESS: {
    my $positive_ref = {
        %$attrs_ref,
        sender_domain  => 'dummy3.tld',
        sender_address => 'someone@dummy3.tld'
    };
    TestPolicy::session_init( $policy, $positive_ref );
    eval {
        $module->handle( undef, $positive_ref );
    };
    ok_for_ok( $policy, $@, "Address whitelisting" );
};


TestMisc::cleanup( $policy );

