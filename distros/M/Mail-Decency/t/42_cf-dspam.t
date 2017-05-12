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
    use_ok( "Mail::Decency::ContentFilter::DSPAM" ) or die;
}

my $content_filter = TestContentFilter::create();
my $module;
CREATE_MODULE: {
    eval {
        my $config_ref = YAML::LoadFile( "$Bin/conf/content-filter/dspam.yml" );
        
        my $dspam_user = $ENV{ DSPAM_USER } || "global_shared";
        $config_ref->{ default_user } = $dspam_user;
        
        $module = Mail::Decency::ContentFilter::DSPAM->new(
            server   => $content_filter,
            name     => "Test",
            config   => $config_ref,
            database => $content_filter->database,
            cache    => $content_filter->cache,
            logger   => empty_logger()
        );
    };
    ok( !$@ && $module, "DSPAM loaded" ) or die( "Problem: $@" );;
};

SKIP: {
    
    chomp( my $dspam = $ENV{ CMD_DSPAM } || `which dspam` );
    skip "could not find dpsam executable. Provide via CMD_DSPAM in Env or set correct PATH", 2
        unless $dspam && -x $dspam;
    skip "dspam test, enable with USE_DSPAM=1 and set optional DSPAM_USER for the tests (default: global_shared)", 2
        unless $ENV{ USE_DSPAM };
    
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
            $content_filter->session_data->spam_details->[0] =~ /DSPAM result: (innocent|spam)/,
            "DSPAM filter used"
        );
    }
    
}

TestMisc::cleanup( $content_filter );
