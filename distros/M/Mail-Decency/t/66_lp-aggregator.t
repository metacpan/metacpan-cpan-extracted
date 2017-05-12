#!/usr/bin/perl

use strict;
use Test::More tests => 6;
use FindBin qw/ $Bin /;
use YAML;
use Data::Dumper;
use lib "$Bin/lib";
use DateTime;

BEGIN {
    use_ok( "Mail::Decency::LogParser::Aggregator" ) or die;
}
use TestLogParser;
use TestMisc;
use TestModule;


TestLogParser::init_log_file();
my $log_parser = TestLogParser::create();
my $module;

LOAD_MODULE: {
    eval {
        my $config_ref = YAML::LoadFile( "$Bin/conf/log-parser/aggregator.yml" );
        
        $module = Mail::Decency::LogParser::Aggregator->new(
            server   => $log_parser,
            name     => "Test",
            config   => $config_ref,
            database => $log_parser->database,
            cache    => $log_parser->cache,
            logger   => empty_logger()
        );
    };
    ok( !$@ && $module, "Aggregator loaded" ) or die( "Problem: $@" );;
}



# setup test datbase
SETUP_DATABSE: {
    TestModule::setup_database( $module );
    ok( 1, "Setup database" );
}



ADD_REJECT: {
    
    my $reject_ref = {
        'from_domain' => 'senderdomain.com',
        'from_address' => 'sender@senderdomain.com',
        'ip' => '123.123.123.123',
        'to_address' => 'recipient@recipientdomain.de',
        'message' => 'Helo command rejected: need fully-qualified hostname',
        'host' => 'unknown',
        'to_domain' => 'recipientdomain.de',
        'final' => 1,
        'reject' => 1,
        'helo' => 'localhost',
        'code' => '504'
    };
    
    my @errors = test_db( reject => $reject_ref );
    diag( "Problems: ". join( ", ", @errors ) ) if @errors;
    ok( scalar @errors == 0, "Rejections found in database" );
};



ADD_BOUNCE: {
    
    my $bounce_ref = {
        'from_address' => 'sender@senderdomain.com',
        'from_domain' => 'senderdomain.com',
        'prog' => 'qmgr',
        'ip' => '1.2.3.4',
        'relay_host' => 'pf.service.frbit.de',
        'rdns' => 'some-reverse-hostname.domain.tld',
        'relay_ip' => '123.123.123.123',
        'bounced' => 1,
        'is_bounce' => 1,
        'to_address' => 'sender@senderdomain.com',
        'size' => '7394',
        'prev_id' => 'DD99C9C7D2',
        'to_domain' => 'senderdomain.com',
        'final' => 1,
        'removed' => 1,
        'queue_id' => '4447C9C7D4',
        'id' => '4447C9C7D4',
        'queued' => 1
    };
    
    my @errors = test_db( bounced => $bounce_ref );
    diag( "Problems: ". join( ", ", @errors ) ) if @errors;
    ok( scalar @errors == 0, "Bounces found in database" );
};



ADD_SENT: {
    
    my $sent_ref = {
        'from_address' => 'sender@senderdomain.com',
        'from_domain' => 'senderdomain.com',
        'ip' => '123.123.123.123',
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
    
    my @errors = test_db( sent => $sent_ref );
    diag( "Problems: ". join( ", ", @errors ) ) if @errors;
    ok( scalar @errors == 0, "Sent found in database" );
};



TestMisc::cleanup( $log_parser );



sub test_db {
    my ( $type, $parsed_ref ) = @_;
    
    # get now
    my $date_now = DateTime->now( time_zone => 'local' );
    
    # handle twice
    eval {
        $module->handle( $parsed_ref );
        $module->handle( $parsed_ref );
    };
    
    my @intervals = (
        [ total => 'total' ],
        map {
            [ $_ => $date_now->strftime( $_ ) ]
        } (
            'year-%Y',
            'week-%Y-%U',
            'month-%Y-%m'
        )
    );
    
    my $transfer = ( $parsed_ref->{ size } || 0 ) * 2;
    
    my @errors = ();
    foreach my $ref( @intervals ) {
        my ( $format, $interval ) = @$ref;
        foreach my $table( qw/ ip from_domain to_domain / ) {
            my $ref = $module->database->get( aggregator => $table => {
                $table   => $parsed_ref->{ $table },
                interval => $interval,
                format   => $format,
                type     => $type
            } );
            unless ( $ref ) {
                push @errors, "not found $type/$table/$interval";
            }
            else {
                push @errors, "wrong counter in $type/$table/$interval"
                    if $ref->{ counter } != 2;
                push @errors, "wrong transfer in $type/$table/$interval"
                    if $ref->{ transfer } != $transfer;
            }
        }
    }
    
    return @errors;
}


