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
    use_ok( "Mail::Decency::ContentFilter::Razor" ) or die;
}

my $content_filter = TestContentFilter::create();
my $module;
CREATE_MODULE: {
    eval {
        my $config_ref = YAML::LoadFile( "$Bin/conf/content-filter/razor.yml" );
        
        $module = Mail::Decency::ContentFilter::Razor->new(
            server   => $content_filter,
            name     => "Test",
            config   => $config_ref,
            database => $content_filter->database,
            cache    => $content_filter->cache,
            logger   => empty_logger()
        );
    };
    ok( !$@ && $module, "Razor loaded" ) or die( "Problem: $@" );;
};

SKIP: {
    
    skip "RAZOR test, enable with USE_RAZOR=1 and set optional CMD_RAZOR for the tests (default: /usr/bin/razor-check)", 2
        unless $ENV{ USE_RAZOR };
    
    chomp( my $razor = $ENV{ CMD_RAZOR } || `which razor-check` || '/usr/bin/razor-check' );
    skip "could not find mailreaver.crm executable. Provide via CMD_RAZOR in Env or set correct PATH", 2
        unless $razor && -x $razor;
    
    # set check command..
    $module->cmd_check( "$razor \%file\%" );
    
    
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
            $content_filter->session_data->spam_details->[0] =~ /Razor: This is (HAM|SPAM)/,
            "Razor filter used"
        );
    }
}

TestMisc::cleanup( $content_filter );
