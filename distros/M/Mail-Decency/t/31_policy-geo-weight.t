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
    use_ok( "Net::DNS::Resolver" ) or die;
};


SKIP: {
    
    skip "Geo::IP not installed, skipping tests", 7 unless eval "use Geo::IP; 1;";
    ok( eval "use Mail::Decency::Policy::GeoWeight; 1;", "Loaded Mail::Decency::Policy::GeoWeight" )
        or die "could not load: Mail::Decency::Policy::GeoWeight";
    
    my $policy = TestPolicy::create();
    
    my $module;
    CREATE_MODULE: {
        my $config_ref = YAML::LoadFile( "$Bin/conf/policy/geo-weight.yml" );
        $module = Mail::Decency::Policy::GeoWeight->new(
            server   => $policy,
            name     => "Test",
            config   => $config_ref,
            database => $policy->database,
            cache    => $policy->cache,
            logger   => empty_logger()
        );
        ok( $module, "GeoWeight loaded" ) or die( "Problem: $@" );
    }
    
    # setup test datbase
    SETUP_DATABSE: {
        TestModule::setup_database( $module );
        ok( 1, "Setup database" );
    }
    
    my %ips = (
        'fr' => '213.41.120.195', # elysee.fr
        'de' => '217.79.215.140', # bundestag.de
        'us' => '72.14.221.99',   # google.com
    );
    
    # setup test datbase
    TEST_DE: {
        
        # build data for test
        my $attrs_ref = {
            client_address  => $ips{ de }
        };
        TestPolicy::session_init( $policy, $attrs_ref );
        
        my $weight_before = $policy->session_data->spam_score;
        eval {
            $module->handle( undef, $attrs_ref );
        };
        ok( ! $@ && $weight_before + 20 == $policy->session_data->spam_score, "DE recognized" );
    }
    
    
    TEST_US: {
        
        # build data for test
        my $attrs_ref = {
            client_address  => $ips{ us }
        };
        TestPolicy::session_init( $policy, $attrs_ref );
        
        my $weight_before = $policy->session_data->spam_score;
        eval {
            $module->handle( undef, $attrs_ref );
        };
        ok( ! $@ && $weight_before + 10 == $policy->session_data->spam_score, "US recognized" );
    }
    
    
    TEST_FR: {
        
        # build data for test
        my $attrs_ref = {
            client_address  => $ips{ fr }
        };
        TestPolicy::session_init( $policy, $attrs_ref );
        
        my $weight_before = $policy->session_data->spam_score;
        eval {
            $module->handle( undef, $attrs_ref );
        };
        ok( ! $@ && $weight_before - 10 == $policy->session_data->spam_score, "Other recognized" );
    }
    
    
    TEST_LOCAL: {
        
        # build data for test
        my $attrs_ref = {
            client_address  => '127.0.0.1'
        };
        TestPolicy::session_init( $policy, $attrs_ref );
        
        my $weight_before = $policy->session_data->spam_score;
        eval {
            $module->handle( undef, $attrs_ref );
        };
        ok( ! $@ && $weight_before == $policy->session_data->spam_score, "Other recognized" );
    }
    
    TestMisc::cleanup( $policy );
    
}

