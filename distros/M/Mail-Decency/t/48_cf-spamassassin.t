#!/usr/bin/perl

use strict;
use Test::More tests => 4;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestContentFilter;
use TestModule;
use TestMisc;
use YAML;

SKIP: {
    
    $ENV{ SPAMASSASSIN_LIB } && eval "use lib '$ENV{ SPAMASSASSIN_LIB }';";
    
    skip "Mail::SpamAssassin::Client not installed, skipping tests", 4
        unless eval "use Mail::SpamAssassin::Client; 1;";
    
    ok( eval "use Mail::Decency::ContentFilter::SpamAssassin; 1;", "Loaded Mail::Decency::ContentFilter::SpamAssassin" )
        or die "could not load: Mail::Decency::ContentFilter::SpamAssassin";
    
    
    my $content_filter = TestContentFilter::create();
    my $module;
    CREATE_MODULE: {
        eval {
            my $config_ref = YAML::LoadFile( "$Bin/conf/content-filter/spamassassin.yml" );
            
            my $user = $ENV{ SPAMASSASSIN_USER } || $ENV{ USER };
            $config_ref->{ default_user } = $user;
            
            $module = Mail::Decency::ContentFilter::SpamAssassin->new(
                server   => $content_filter,
                name     => "Test",
                config   => $config_ref,
                database => $content_filter->database,
                cache    => $content_filter->cache,
                logger   => empty_logger()
            );
        };
        ok( !$@ && $module, "SpamAsssassin loaded" ) or die( "Problem: $@" );;
    };
    
    SKIP: {
        
        skip "dspam test, enable with USE_SPAMASSASSIN=1 and set optional SPAMASSASSIN_USER for the tests (default: \$ENV{ USER })", 2
            unless $ENV{ USE_SPAMASSASSIN };
        
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
                $content_filter->session_data->spam_details->[0] =~ /SpamAssassin Status:/,
                "SpamAssassin filter used"
            );
        }
        
    }
    
    TestMisc::cleanup( $content_filter );

}
