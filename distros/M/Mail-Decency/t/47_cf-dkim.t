#!/usr/bin/perl

use strict;
use Test::More tests => 2;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestContentFilter;
use TestModule;
use TestMisc;
use YAML;

BEGIN {
    use_ok( "Mail::Decency::ContentFilter::DKIM" ) or die;
}

my $content_filter = TestContentFilter::create();
my $module;
CREATE_MODULE: {
    eval {
        my $config_ref = YAML::LoadFile( "$Bin/conf/content-filter/dkim.yml" );
        
        $module = Mail::Decency::ContentFilter::DKIM->new(
            server   => $content_filter,
            name     => "Test",
            config   => $config_ref,
            database => $content_filter->database,
            cache    => $content_filter->cache,
            logger   => empty_logger()
        );
    };
    ok( !$@ && $module, "DKIM loaded" ) or die( "Problem: $@" );;
};


# @@@@ TODO @@@@@
#
#           Write a test
#
# @@@@ TODO @@@@@


TestMisc::cleanup( $content_filter );
