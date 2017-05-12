#!/usr/bin/perl

use strict;
use Test::More tests => 4;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestPolicy;
use TestModule;
use TestMisc;
use YAML;

BEGIN {
    use_ok( "Mail::Decency::Policy::DNSBL" ) or die;
}


SKIP: {
    skip "Net::DNSBL::Client not installed, skipping tests", 4
        unless eval "use Net::DNSBL::Client; 1;";
    
    my $policy = TestPolicy::create();
    
    my $module;
    CREATE_MODULE: {
        eval {
            my $config_ref = YAML::LoadFile( "$Bin/conf/policy/dnsbl.yml" );
            $module = Mail::Decency::Policy::DNSBL->new(
                server   => $policy,
                name     => "Test",
                config   => $config_ref,
                database => $policy->database,
                cache    => $policy->cache,
                logger   => empty_logger()
            );
        };
        ok( !$@ && $module, "DNSBL loaded" )  or die( "Problem: $@" );;
    }
    
    
    
    
    my $attrs_ref = {
        client_address    => '127.0.0.1',
        sender_address    => 'sender@domain.tld',
        recipient_address => 'recipient@domain.tld',
    };
    
    
    # check negative
    CHECK_NEGATIVE: {
        TestPolicy::session_init( $policy, $attrs_ref );
        eval {
            $module->handle( undef, $attrs_ref );
        };
        ok_for_dunno( $policy, $@, "No hit on 127.0.0.1" );
    }
    
    # check positive
    CHECK_POSITIVE: {
        $attrs_ref->{ client_address } = '127.0.0.2';
        TestPolicy::session_init( $policy, $attrs_ref );
        eval {
            $module->handle( undef, $attrs_ref );
        };
        ok_for_reject( $policy, $@, "Always hit on 127.0.0.2" );
    }
    
    TestMisc::cleanup( $policy );
}


