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
    use_ok( "Mail::Decency::ContentFilter::Bogofilter" ) or die;
}

my $content_filter = TestContentFilter::create();
my $module;
CREATE_MODULE: {
    eval {
        my $config_ref = YAML::LoadFile( "$Bin/conf/content-filter/dspam.yml" );
        
        my $dspam_user = $ENV{ DSPAM_USER } || "global_shared";
        $config_ref->{ default_user } = $dspam_user;
        
        $module = Mail::Decency::ContentFilter::Bogofilter->new(
            server   => $content_filter,
            name     => "Test",
            config   => $config_ref,
            database => $content_filter->database,
            cache    => $content_filter->cache,
            logger   => empty_logger()
        );
    };
    ok( !$@ && $module, "Bogofilter loaded" ) or die( "Problem: $@" );;
};

SKIP: {
    
    chomp( my $bogofilter = $ENV{ CMD_BOGOFILTER } || `which bogofilter` );
    skip "could not find bogofilter executable. Provide via CMD_BOGOFILTER in Env or set correct PATH", 2
        unless $bogofilter && -x $bogofilter;
    skip "BOGOFILTER test, enable with USE_BOGOFILTER=1 and set optional BOGOFILTER_USER for the tests (default: global_shared)", 2
        unless $ENV{ USE_BOGOFILTER };
    
    # set check command..
    $module->cmd_check( "$bogofilter --user-config-file \%user\% -U -I \%file\% -v" );
    
    
    FILTER_TEST: {
        my ( $file, $size ) = TestContentFilter::get_test_file();
        $content_filter->session_init( $file, $size );
        
        eval {
            my $res = $module->handle();
        };
        
        ok(
            ! $@ && scalar @{ $content_filter->session_data->spam_details } == 1,
            "Filter result found"
        );
        
        ok(
            $content_filter->session_data->spam_details->[0] =~ /Bogofilter status: (ham|spam|unsure)/,
            "Bogofilter filter used"
        );
    }
    
}

TestMisc::cleanup( $content_filter );
