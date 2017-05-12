#!/usr/bin/perl

use strict;
use Test::More tests => 6;
use Mail::Decency::Helper::Cache;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use Data::Dumper;
use YAML;


use TestMisc;
use TestPolicy;
use TestModule;
use Mail::Decency::Policy;

my $config_ref = YAML::LoadFile( "$Bin/conf/policy.yml" );
push @{ $config_ref->{ include } }, "exclusions.yml";
$ENV{ NO_CHECK_DATABASE } = 1;
my $policy = TestMisc::create_server( "Mail::Decency::Policy" => "policy", {
    include => $config_ref->{ include },
    policy  => [
        { Honeypot => "policy/honeypot.yml" }
    ]
} );


my $module= $policy->childs->[0];
eval {
    TestModule::setup_database( $_ ) for ( $module, $policy );
};
ok( !$@, "Database setup" );

# create records
CREATE_RECORDS: {
    eval {
        $policy->database->set( exclusions => policy => {
            type   => 'sender_domain',
            module => 'Honeypot',
            value  => 'ignoreme.tld'
        } );
    };
    ok( !$@, "Database records created" ) or diag( "Problem: $@" );
}

# check wheter not associated sender passes
CHECK_HONEYPOT: {
    my %attrs = (
        client_address => '192.168.1.2',
        recipient      => 'lalala@spamlover.tld',
        sender         => 'blaa@sender.tld',
    );
    TestPolicy::session_init( $policy, \%attrs );
    
    my $handler_sub = $policy->get_handlers();
    
    my $action_ref;
    eval {
        $action_ref = $handler_sub->( undef, \%attrs );
    };
    ok( $action_ref && $action_ref->{ action } =~ /^REJECT /, "Reject non excluded" );
}

# check wheter not associated sender passes
CHECK_CONFIG: {
    my %attrs = (
        client_address => '192.168.1.2',
        recipient      => 'lalala@spamlover.tld',
        sender         => 'blaa@senderdont.tld',
    );
    TestPolicy::session_init( $policy, \%attrs );
    
    my $handler_sub = $policy->get_handlers();
    
    my $action_ref;
    eval {
        $action_ref = $handler_sub->( undef, \%attrs );
    };
    ok( $action_ref && $action_ref->{ action } =~ /^PREPEND /, "Exclude via config" );
}

# check wheter not associated sender passes
CHECK_DATABASE: {
    my %attrs = (
        client_address => '192.168.1.2',
        recipient      => 'lalala@spamlover.tld',
        sender         => 'blaa@ignoreme.tld',
    );
    TestPolicy::session_init( $policy, \%attrs );
    
    my $handler_sub = $policy->get_handlers();
    
    my $action_ref;
    eval {
        $action_ref = $handler_sub->( undef, \%attrs );
    };
    ok( $action_ref && $action_ref->{ action } =~ /^PREPEND /, "Exclude via database" );
}

# check wheter not associated sender passes
CHECK_FILE: {
    my %attrs = (
        client_address => '192.168.1.2',
        recipient      => 'lalala@spamlover.tld',
        sender         => 'blaa@fromfile.tld',
    );
    TestPolicy::session_init( $policy, \%attrs );
    
    my $handler_sub = $policy->get_handlers();
    
    my $action_ref;
    eval {
        $action_ref = $handler_sub->( undef, \%attrs );
    };
    ok( $action_ref && $action_ref->{ action } =~ /^PREPEND /, "Exclude via file" );
}



TestMisc::cleanup( $policy );



