#!/usr/bin/perl

use strict;
use Test::More tests => 4;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestContentFilter;
use TestModule;
use TestMisc;
use YAML;

BEGIN {
    use_ok( "Mail::Decency::ContentFilter::CRM114" ) or die;
}

my $content_filter = TestContentFilter::create();
my $module;
CREATE_MODULE: {
    eval {
        my $config_ref = YAML::LoadFile( "$Bin/conf/content-filter/crm114.yml" );
        
        my $dspam_user = $ENV{ CRM114_USER } || "/etc/crm114";
        $config_ref->{ default_user } = $dspam_user;
        
        $module = Mail::Decency::ContentFilter::CRM114->new(
            server   => $content_filter,
            name     => "Test",
            config   => $config_ref,
            database => $content_filter->database,
            cache    => $content_filter->cache,
            logger   => empty_logger()
        );
    };
    ok( !$@ && $module, "CRM114 loaded" ) or die( "Problem: $@" );;
};

SKIP: {
    
    chomp( my $crm114 = $ENV{ CMD_CRM114 } || `which mailreaver.crm` || '/usr/share/crm114/mailreaver.crm' );
    skip "could not find mailreaver.crm executable. Provide via CMD_CRM114 in Env or set correct PATH", 2
        unless $crm114 && -x $crm114;
    skip "CRM114 test, enable with USE_CRM114=1 and set optional CRM114_USER for the tests (default: /etc/crm114)", 2
        unless $ENV{ USE_CRM114 };
    
    # set check command..
    $module->cmd_check( "$crm114 -u \%user\%" );
    
    
    FILTER_TEST: {
        my ( $file, $size ) = TestContentFilter::get_test_file();
        $content_filter->session_init( $file, $size );
        
        eval {
            my $res = $module->handle();
        };
        $@ && diag( "Error: $@" );
        ok(
            ! $@ && scalar @{ $content_filter->session_data->spam_details } == 1,
            "Filter result found"
        );
        
        ok(
            $content_filter->session_data->spam_details->[0] =~ /CRM114 status: (good|spam|unsure)/,
            "CRM114 filter used"
        );
    }
    
}

TestMisc::cleanup( $content_filter );
