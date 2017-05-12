#!/usr/bin/perl

use strict;
use Test::More tests => 4;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestContentFilter;
use TestModule;
use TestMisc;
use YAML;
use File::Temp qw/ tempfile /;


SKIP: {
    
    skip "ClamAV::Client not installed, skipping tests", 4 unless eval "use ClamAV::Client; 1;";
    ok( eval "use Mail::Decency::ContentFilter::ClamAV; 1;", "Mail::Decency::ContentFilter::ClamAV Loaded" )
        or die "could not load: Mail::Decency::ContentFilter::ClamAV";
    
    my $content_filter = TestContentFilter::create();
    my $module;
    CREATE_MODULE: {
        eval {
            my $config_ref = YAML::LoadFile( "$Bin/conf/content-filter/clamav.yml" );
            
            my $clamav_path = $ENV{ CLAMAV_PATH } || '/var/run/clamav/clamd.ctl';
            $config_ref->{ path } = $clamav_path;
            
            $module = Mail::Decency::ContentFilter::ClamAV->new(
                server   => $content_filter,
                name     => "Test",
                config   => $config_ref,
                database => $content_filter->database,
                cache    => $content_filter->cache,
                logger   => empty_logger()
            );
        };
        ok( !$@ && $module, "ClamAV loaded" ) or die( "Problem: $@" );;
    };
    
    SKIP: {
        
        skip "Require LWP::UserAgent to get EICAR (dummy virus)", 2
            unless eval "use LWP::UserAgent; 1;";
        
        skip "ClamAV test, enable with USE_CLAMAV=1 and set optional CLAMAV_PATH for the tests (default: /var/run/clamav/clamd.ctl)", 2
            unless $ENV{ USE_CLAMAV };
        
        my ( $th, $eicar_file ) = tempfile( "$Bin/data/eicar-XXXXXX", UNLINK => 0 );
        GET_EICAR: {
            
            my ( $file, $size ) = TestContentFilter::get_test_file();
            $content_filter->session_init( $file, $size );
            
            my $lwp = LWP::UserAgent->new;
            my $req = HTTP::Request->new( GET => 'http://www.eicar.org/download/eicar.com.txt' );
            my $res = $lwp->request( $req );
            
            if ( $res->is_success ) {
                print $th $res->decoded_content;
                ok( 1, "Download EICAR" );
                close $th;
            }
            else {
                ok( 0, "Download EICAR" );
                unlink( $eicar_file );
                die "No EICAR, no test\n";
            }
        }
        
        
        FILTER_TEST: {
            
            # add eicar
            $content_filter->session_data->mime->attach(
                Path     => $eicar_file,
                Type     => "application/octet-stream",
                Encoding => "base64"
            );
            $content_filter->session_data->write_mime;
            
            eval {
                my $res = $module->handle();
            };
            
            ok(
                $@
                && $content_filter->session_data->virus
                && $content_filter->session_data->virus eq "Eicar-Test-Signature",
                "ClamAV found virus"
            );
        }
        
        unlink( $eicar_file );
        
    }
    
    TestMisc::cleanup( $content_filter );
    
}
