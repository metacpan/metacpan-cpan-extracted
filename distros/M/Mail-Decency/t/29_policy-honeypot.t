#!/usr/bin/perl

use strict;
use Test::More tests => 13;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestPolicy;
use TestModule;
use TestMisc;
use YAML;

BEGIN {
    use_ok( "Mail::Decency::Policy::Honeypot" ) or die;
};

my $policy = TestPolicy::create();

my $module;
CREATE_MODULE: {
    my $config_ref = YAML::LoadFile( "$Bin/conf/policy/honeypot.yml" );
    $module = Mail::Decency::Policy::Honeypot->new(
        server   => $policy,
        name     => "Test",
        config   => $config_ref,
        database => $policy->database,
        cache    => $policy->cache,
        logger   => empty_logger()
    );
    ok( $module, "Honeypot loaded" ) or die( "Problem: $@" );
}


# setup test datbase
SETUP_DATABSE: {
    TestModule::setup_database( $module );
    ok( 1, "Setup database" );
}


# create records
CREATE_RECORDS: {
    eval {
        $module->database->set( honeypot => addresses => {
            client_address => '192.168.1.1',
        }, {
            created        => time()
        } );
    };
    ok( !$@, "Database records created" ) or diag( "Problem: $@" );
}



# check wheter not associated sender passes
CHECK_NEGATIVE: {
    my %attrs = (
        client_address    => '192.168.1.2',
        recipient_domain  => 'recipient.tld',
        recipient_prefix  => 'someone',
        recipient_address => 'someone@recipient.tld'
    );
    TestPolicy::session_init( $policy, \%attrs );
    
    eval {
        $module->handle( undef, \%attrs );
    };
    ok_for_dunno( $policy, $@, "Unlisted passes" );
}



# check a single address which should ne listed
CHECK_ADDRESS: {
    
    # get the recipient
    my $fail_recipient = $module->config->{ addresses }->[0];
    my ( $prefix, $domain ) = split( /\@/, $fail_recipient, 2 );
    
    my %attrs = (
        client_address    => '192.168.1.3',
        recipient_domain  => $domain,
        recipient_prefix  => $prefix,
        recipient_address => $fail_recipient
    );
    TestPolicy::session_init( $policy, \%attrs );
    
    eval {
        $module->handle( undef, \%attrs );
    };
    ok_for_reject( $policy, $@, "Reject for listed recipient address" );
}



# check a listed domain
CHECK_DOMAIN: {
    # get the recipient
    my $fail_domain = $module->config->{ domains }->[0];
    
    my %attrs = (
        client_address    => '192.168.1.4',
        recipient_domain  => $fail_domain,
        recipient_prefix  => 'xxx',
        recipient_address => "xxx\@$fail_domain"
    );
    TestPolicy::session_init( $policy, \%attrs );
    
    eval {
        $module->handle( undef, \%attrs );
    };
    ok_for_reject( $policy, $@, "Reject for listed recipient domain" );
}



# check a listed domain
CHECK_DOMAIN_EXCEPTIONS: {
    
    # get the recipient
    my $fail_domain_ref  = $module->config->{ domains }->[1];
    my $fail_domain      = $fail_domain_ref->{ domain };
    my $exception_prefix = $fail_domain_ref->{ exceptions }->[0];
    my $other_prefix     = $exception_prefix. "-other";
    
    CHECK_REJECTED: {
        my %attrs = (
            client_address    => '192.168.1.5',
            recipient_domain  => $fail_domain,
            recipient_prefix  => $other_prefix,
            recipient_address => "$other_prefix\@$fail_domain"
        );
        TestPolicy::session_init( $policy, \%attrs );
        
        eval {
            $module->handle( undef, \%attrs );
        };
        ok_for_reject( $policy, $@, "Reject for listed recipient exception domain, non exception recipient" );
    }
    
    
    CHECK_PASS: {
        my %attrs = (
            client_address    => '192.168.1.6',
            recipient_domain  => $fail_domain,
            recipient_prefix  => $exception_prefix,
            recipient_address => "$exception_prefix\@$fail_domain"
        );
        TestPolicy::session_init( $policy, \%attrs );
        
        eval {
            $module->handle( undef, \%attrs );
        };
        ok_for_dunno( $policy, $@, "Pass for listed recipient exception domain, with exception recipient" );
        
    }
}







# check a listed domain
CHECK_PASS_FLAG: {
    
    # get the recipient
    my $fail_domain = $module->config->{ domains }->[0];
    
    my $config_ref = YAML::LoadFile( "$Bin/conf/policy/honeypot.yml" );
    $config_ref->{ pass_for_collection } = 1;
    my $module = Mail::Decency::Policy::Honeypot->new(
        server   => $policy,
        name     => "Test",
        config   => $config_ref,
        database => $policy->database,
        cache    => $policy->cache,
        logger   => empty_logger()
    );
    ok( $module && $module->pass_for_collection, "Honeypot with pass_for_collection loaded" );
    
    my %attrs = (
        client_address    => '192.168.1.7',
        recipient_domain  => $fail_domain,
        recipient_prefix  => 'xxx',
        recipient_address => "xxx\@$fail_domain"
    );
    eval {
        $module->handle( undef, \%attrs );
    };
    ok_for_prepend( $policy, $@, "Collected recipient domain passed flawlessy" );
    
    ok( defined $policy->session_data->has_flag( 'honey' ), "Flag passed" );
}



# check now wheter all are in database whou should be!
CHECK_RECORDS: {
    eval {
        foreach my $ip( qw/ 1 3 4 5 7 / ) {
            my $found = $module->database->get( honeypot => addresses => {
                client_address => '192.168.1.'. $ip,
            } );
            die "Not found in database: 192.168.1.$ip\n" unless $found;
        }
        foreach my $ip( qw/ 2 6 / ) {
            my $found = $module->database->get( honeypot => addresses => {
                client_address => '192.168.1.'. $ip,
            } );
            die "Found falsly in database: 192.168.1.$ip\n" if $found;
        }
    };
    ok( !$@, "Database records are valid" ) or diag( "Problem: $@" );
    
}




TestMisc::cleanup( $policy );

