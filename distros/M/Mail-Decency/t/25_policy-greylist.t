#!/usr/bin/perl

use strict;
use Test::More tests => 5;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestPolicy;
use TestModule;
use TestMisc;
use YAML;

BEGIN {
    use_ok( "Mail::Decency::Policy::Greylist" ) or die;
}

my $policy = TestPolicy::create();

my $module;
CREATE_MODULE: {
    eval {
        my $config_ref = YAML::LoadFile( "$Bin/conf/policy/greylist.yml" );
        $config_ref->{ min_interval } = 1;
        $module = Mail::Decency::Policy::Greylist->new(
            server   => $policy,
            name     => "Test",
            config   => $config_ref,
            database => $policy->database,
            cache    => $policy->cache,
            logger   => empty_logger()
        );
    };
    ok( !$@ && $module, "Greylisting loaded" ) or die( "Problem: $@" );;
};



# setup test datbase
SETUP_DATABSE: {
    TestModule::setup_database( $module );
    ok( 1, "Setup database" );
}




my $sender    = 'sender-'. time(). '@dummy1.tld';
my $recipient = 'recipient-'. time(). '@dummy2.tld';

# those simulate postfix attributes
my $attrs_ref = {
    client_address    => '255.255.0.0',
    sender_address    => $sender,
    recipient_address => $recipient,
    sender_domain     => 'dummy1.tld'
};

# first pass: should throw Mail::Decency::Core::Exception::Reject
FIRST_PASS: {
    TestPolicy::session_init( $policy, $attrs_ref );
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok_for_reject( $policy, $@, "First pass: reject" );
}

# wait a second until we are allowed to pass
sleep 1;

# second pass: should throw no erro but allow
SECOND_PASS: {
    TestPolicy::session_init( $policy, $attrs_ref );
    eval {
        $module->handle( undef, $attrs_ref );
    };
    ok_for_dunno( $policy, $@, "Second pass: passed" );
};



TestMisc::cleanup( $policy );

