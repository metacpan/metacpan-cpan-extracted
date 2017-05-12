#!/usr/bin/perl

use strict;
use Test::More tests => 6;
use FindBin qw/ $Bin /;
use YAML;
use Data::Dumper;
use lib "$Bin/lib";

BEGIN {
    use_ok( "Mail::Decency::LogParser::Stats" ) or die;
}
use TestLogParser;
use TestMisc;
use TestModule;


TestLogParser::init_log_file();
my $log_parser = TestLogParser::create();
my $module;

LOAD_MODULE: {
    eval {
        my $config_ref = YAML::LoadFile( "$Bin/conf/log-parser/stats.yml" );
        
        unlink( $_ ) for glob( "$Bin/data/log.csv.*" );
        $config_ref->{ csv_log }->{ file } = "$Bin/data/log.csv";
        $module = Mail::Decency::LogParser::Stats->new(
            server   => $log_parser,
            name     => "Test",
            config   => $config_ref,
            database => $log_parser->database,
            cache    => $log_parser->cache,
            logger   => empty_logger()
        );
    };
    ok( !$@ && $module, "Stats loaded" ) or die( "Problem: $@" );;
}




ADD_REJECT: {
    
    subtest "Reject" => sub {
        plan tests => 3;
        
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
        
        eval {
            $module->handle( $reject_ref );
            $module->handle( $reject_ref );
        };
        ok( !$@, "Reject handled" );
        
        # check cache
        ok( $module->cache->get( 'lp-stats-total_reject-code-504-total' ) == 2, "Cache counter incremented" );
        
        # csv check
        if ( -f ( my $csv = "$Bin/data/log.csv.total_reject" ) ) {
            my $line;
            eval {
                open my $fh, "<", "$Bin/data/log.csv.total_reject"
                    or die "Error opening file handle '$csv': $!";
                ( undef, $line ) = <$fh>
                    or die "Error reading file handle '$csv': $!";
                close $fh
                    or die "Error closing file handle '$csv': $!";
            };
            if ( $@ ) {
                fail( "CSV open error: $@" );
            }
            else {
                chomp $line;
                my @csv = split( /;/, $line );
                shift @csv; # time
                
                my @expected = (
                    '504',
                    'sender@senderdomain.com',
                    'senderdomain.com',
                    '123.123.123.123',
                    'Helo command rejected: need fully-qualified hostname',
                    'recipient@recipientdomain.de',
                    'recipientdomain.de'
                );
                
                my @errors = ();
                foreach my $val( @expected ) {
                    my $compare = shift @csv;
                    push @errors, "wrong ('$val' != '$compare')"
                        if $val ne $compare;
                }
                diag( "Problems: ". join( ", ", @errors ) ) if @errors;
                ok( scalar @errors == 0, "CSV data consistent" );
            }
            
        }
        else {
            ok( 0, "Could not open CSV file '$csv'" );
        }
    };
};


ADD_BOUNCE: {
    
    subtest "Bounce" => sub {
        plan tests => 3;
        
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
        
        eval {
            $module->handle( $bounce_ref );
            $module->handle( $bounce_ref );
        };
        ok( !$@, "Bounce handled" );
        
        # check cache
        ok( $module->cache->get( 'lp-stats-bounced-ip-1.2.3.4-total' ) == 2, "Cache counter incremented" );
        
        # csv check
        if ( -f ( my $csv = "$Bin/data/log.csv.bounced" ) ) {
            my $line;
            eval {
                open my $fh, "<", "$Bin/data/log.csv.bounced"
                    or die "Error opening file handle '$csv': $!";
                ( undef, $line ) = <$fh>
                    or die "Error reading file handle '$csv': $!";
                close $fh
                    or die "Error closing file handle '$csv': $!";
            };
            if ( $@ ) {
                fail( "CSV open error: $@" );
            }
            else {
                chomp $line;
                my @csv = split( /;/, $line );
                shift @csv;
                
                my @expected = (
                    'sender@senderdomain.com',
                    'senderdomain.com',
                    '1.2.3.4',
                    'sender@senderdomain.com',
                    'senderdomain.com'
                );
                
                my @errors = ();
                foreach my $val( @expected ) {
                    my $compare = shift @csv;
                    push @errors, "wrong ('$val' != '$compare')"
                        if $val ne $compare;
                }
                diag( "Problems: ". join( ", ", @errors ) ) if @errors;
                ok( scalar @errors == 0, "CSV data consistent" );
            }
            
        }
        else {
            ok( 0, "Could not open CSV file '$csv'" );
        }
    };
};


ADD_SENT: {
    
    subtest "Sent" => sub {
        plan tests => 3;
        
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
        
        eval {
            $module->handle( $sent_ref );
            $module->handle( $sent_ref );
        };
        ok( !$@, "Sent handled" );
        
        # check cache
        ok( $module->cache->get( 'lp-stats-sent-ip-123.123.123.123-total' ) == 2, "Cache counter incremented" );
        
        # csv check
        if ( -f ( my $csv = "$Bin/data/log.csv.sent" ) ) {
            my $line;
            eval {
                open my $fh, "<", "$Bin/data/log.csv.sent"
                    or die "Error opening file handle '$csv': $!";
                ( undef, $line ) = <$fh>
                    or die "Error reading file handle '$csv': $!";
                close $fh
                    or die "Error closing file handle '$csv': $!";
            };
            if ( $@ ) {
                fail( "CSV open error: $@" );
            }
            else {
                chomp $line;
                my @csv = split( /;/, $line );
                shift @csv;
                
                my @expected = (
                    'sender@senderdomain.com',
                    'senderdomain.com',
                    '123.123.123.123',
                    'recipient@recipientdomain.de',
                    'recipientdomain.de'
                );
                
                my @errors = ();
                foreach my $val( @expected ) {
                    my $compare = shift @csv;
                    push @errors, "wrong ('$val' != '$compare')"
                        if $val ne $compare;
                }
                diag( "Problems: ". join( ", ", @errors ) ) if @errors;
                ok( scalar @errors == 0, "CSV data consistent" );
            }
            
        }
        else {
            ok( 0, "Could not open CSV file '$csv'" );
        }
    };
};


ADD_DEFERRED: {
    
    subtest "Deferred" => sub {
        plan tests => 3;
        
        my $deferred_ref = {
            'from_address' => 'sender@senderdomain.com',
            'from_domain' => 'senderdomain.com',
            'ip' => '123.123.123.213',
            'prog' => 'smtp',
            'relay_host' => 'none, delay=6, delays=6/0.01/0/0, dsn=4.4.1, status=deferred (connect to 127.0.0.1',
            'rdns' => 'unknown',
            'relay_ip' => '127.0.0.1',
            'to_address' => 'recipient@recipientdomain.de',
            'size' => '2646',
            'to_domain' => 'recipientdomain.de',
            'final' => 1,
            'deferred' => 1,
            'id' => '34A7C9C7D9',
            'queued' => 1
        };
        
        eval {
            $module->handle( $deferred_ref );
            $module->handle( $deferred_ref );
        };
        ok( !$@, "Sent handled" );
        
        # check cache
        ok( $module->cache->get( 'lp-stats-deferred-ip-123.123.123.213-total' ) == 2, "Cache counter incremented" );
        
        # csv check
        if ( -f ( my $csv = "$Bin/data/log.csv.deferred" ) ) {
            my $line;
            eval {
                open my $fh, "<", "$Bin/data/log.csv.deferred"
                    or die "Error opening file handle '$csv': $!";
                ( undef, $line ) = <$fh>
                    or die "Error reading file handle '$csv': $!";
                close $fh
                    or die "Error closing file handle '$csv': $!";
            };
            if ( $@ ) {
                fail( "CSV open error: $@" );
            }
            else {
                chomp $line;
                my @csv = split( /;/, $line );
                shift @csv;
                
                my @expected = (
                    'sender@senderdomain.com',
                    'senderdomain.com',
                    '123.123.123.213',
                    'recipient@recipientdomain.de',
                    'recipientdomain.de'
                );
                
                my @errors = ();
                foreach my $val( @expected ) {
                    my $compare = shift @csv;
                    push @errors, "wrong ('$val' != '$compare')"
                        if $val ne $compare;
                }
                diag( "Problems: ". join( ", ", @errors ) ) if @errors;
                ok( scalar @errors == 0, "CSV data consistent" );
            }
            
        }
        else {
            ok( 0, "Could not open CSV file '$csv'" );
        }
    };
};



unlink( $_ ) for glob( "$Bin/data/log.csv.*" );
TestMisc::cleanup( $log_parser );
