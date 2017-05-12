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
    use_ok( "Net::DNS::Resolver" ) or die;
};

SKIP: {
    
    skip "Mail::SPF not installed, skipping tests", 5 unless eval "use Mail::SPF; 1;";
    ok( eval "use Mail::Decency::Policy::SPF; 1;", "Mail::Decency::Policy::SPF Loaded" )
        or die "could not load: Mail::Decency::Policy::SPF Loaded";
    
    my $policy = TestPolicy::create();
    
    my $module;
    CREATE_MODULE: {
        eval {
            my $config_ref = YAML::LoadFile( "$Bin/conf/policy/spf.yml" );
            $module = Mail::Decency::Policy::SPF->new(
                server   => $policy,
                name     => "Test",
                config   => $config_ref,
                database => $policy->database,
                cache    => $policy->cache,
                logger   => empty_logger()
            );
        };
        ok( !$@ && $module, "SPF loaded" )  or die( "Problem: $@" );;
    }
    
    
    # get us a test ip
    my $valid_ip;
    RETREIVE_IP: {
        eval {
            my $dns = Net::DNS::Resolver->new;
            my $res = $dns->query( "gmx.com", "TXT" );
            ( $valid_ip ) =
                map {
                    my ( $ip ) = $_ =~ /ip4:(\d+\.\d+\.\d+\.\d+)/;
                    $ip;
                }
                map {
                    $_->rdatastr 
                } $res->answer
            ;
        };
        ok( !$@ && $valid_ip, "Retreive Test IP from gmx.." ) or die( "Problem: $@" );;
    };
    
    
    
    # build data for test
    my $attrs_ref = {
        client_address => '192.168.0.255',
        sender_domain  => 'gmx.com',
        sender_address => 'someone-'. time(). '@gmx.com'
    };
    
    # test negative
    CHECK_NEGATIVE: {
        TestPolicy::session_init( $policy, $attrs_ref );
        eval {
            $module->handle( undef, $attrs_ref );
        };
        ok_for_reject( $policy, $@, "Hit for invalid IP" );
    }
    
    # test positive
    CHECK_POSTIVE: {
        $attrs_ref->{ client_address } = $valid_ip;
        TestPolicy::session_init( $policy, $attrs_ref );
        eval {
            $module->handle( undef, $attrs_ref );
        };
        ok_for_dunno( $policy, $@, "Pass for valid IP" );
    }
    
    TestMisc::cleanup( $policy );
}


