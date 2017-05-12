#!/usr/bin/perl

use strict;
use Test::More tests => 5;
use FindBin qw/ $Bin /;
use YAML;
use Data::Dumper;
use lib "$Bin/lib";
use DateTime;

use TestLogParser;
use TestMisc;
use TestModule;

SKIP: {
    
    skip "Geo::IP not installed, skipping tests", 5 unless eval "use Geo::IP; 1;";
    ok( eval "use Mail::Decency::LogParser::GeoSource; 1;", "Loaded Mail::Decency::LogParser::GeoSource" )
        or die "could not load: Mail::Decency::LogParser::GeoSource";
    
    
    TestLogParser::init_log_file();
    my $log_parser = TestLogParser::create();
    my $module;
    
    LOAD_MODULE: {
        eval {
            my $config_ref = YAML::LoadFile( "$Bin/conf/log-parser/geo-source.yml" );
            
            $module = Mail::Decency::LogParser::GeoSource->new(
                server   => $log_parser,
                name     => "Test",
                config   => $config_ref,
                database => $log_parser->database,
                cache    => $log_parser->cache,
                logger   => empty_logger()
            );
        };
        ok( !$@ && $module, "GeoSource loaded" ) or die( "Problem: $@" );;
    }
    
    
    
    # setup test datbase
    SETUP_DATABSE: {
        TestModule::setup_database( $module );
        ok( 1, "Setup database" );
    }
    
    
    
    TEST_REJECT: {
        
        subtest "Reject" => sub {
            plan tests  => 3;
            
            my $reject_ref = {
                'from_domain' => 'senderdomain.com',
                'from_address' => 'sender@senderdomain.com',
                'ip' => '81.91.170.12', # denic.de .. for DE country
                'to_address' => 'recipient@recipientdomain.de',
                'message' => 'Helo command rejected: need fully-qualified hostname',
                'host' => 'unknown',
                'to_domain' => 'recipientdomain.de',
                'final' => 1,
                'reject' => 1,
                'helo' => 'localhost',
                'code' => '504'
            };
            
            eval {
                $module->handle( $reject_ref );
            };
            
            my @all = $module->database->search( geo => source => {
                type => 'reject',
            } );
            my $count = scalar @all;
            ok( $count == 16, "Found all entries" );
            ok( scalar ( grep { $_->{ country } eq "DE" } @all ) == $count, "Correct countries" );
            
            my $count_sender    = grep { $_->{ from_domain } eq 'senderdomain.com' } @all;
            my $count_recipient = grep { $_->{ to_domain } eq 'recipientdomain.de' } @all;
            ok( $count_sender == $count_recipient && $count_sender == 8, "Correct distribution" );
        };
        
    };
    
    
    
    TEST_SENT: {
        
        subtest "Sent" => sub {
            plan tests  => 3;
            
            
            my $sent_ref = {
                'from_address' => 'sender@senderdomain.com',
                'from_domain' => 'senderdomain.com',
                'ip' => '192.0.32.9', # internic.net .. for US country
                'prog' => 'smtp',
                'relay_host' => '127.0.0.1',
                'rdns' => 'ppp-123-123-123-123.rev.somehost.com',
                'relay_ip' => '127.0.0.1',
                'to_address' => 'recipient@recipientdomain.de',
                'size' => '3234',
                'to_domain' => 'recipientdomain.de',
                'final' => 1,
                'removed' => 1,
                'sent' => 1,
                'id' => '3989C9C7D1',
                'queued' => 1
            };
            
            eval {
                $module->handle( $sent_ref );
            };
            
            my @all = $module->database->search( geo => source => {
                type => 'sent',
            } );
            my $count = scalar @all;
            ok( $count == 16, "Found all entries" );
            ok( scalar ( grep { $_->{ country } eq "US" } @all ) == $count, "Correct countries" );
            
            my $count_sender    = grep { $_->{ from_domain } eq 'senderdomain.com' } @all;
            my $count_recipient = grep { $_->{ to_domain } eq 'recipientdomain.de' } @all;
            ok( $count_sender == $count_recipient && $count_sender == 8, "Correct distribution" );
        };
        
    };
    
    
    TestMisc::cleanup( $log_parser );

}




