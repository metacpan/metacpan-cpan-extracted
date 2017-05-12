#!/usr/bin/perl

use strict;
use Test::More tests => 6;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";

BEGIN {
    use_ok( "Mail::Decency::LogParser" ) or die;
}
use TestLogParser;
use TestMisc;

my $log_parser;
TestLogParser::init_log_file();

CREATE_LOG_PARSER: {
    eval {
        $log_parser = TestLogParser::create();
    };
    ok( !$@ && $log_parser, "LogParser lodaded" ) or die( "Problem: $@" );
}


PARSE_SENT: {
    
    my $test_log = <<'TESTLOG';
Dec 24 18:19:58 hostname postfix/smtpd[20316]: 3989C9C7D1: client=ppp-123-123-123-123.rev.somehost.com[123.123.123.123]
Dec 24 18:19:59 hostname postfix/cleanup[20352]: 3989C9C7D1: message-id=<000d01cb1216$ce9590c0$6400a8c0@refusesjh>
Dec 24 18:19:59 hostname postfix/qmgr[17618]: 3989C9C7D1: from=<sender@senderdomain.com>, size=3234, nrcpt=1 (queue active)
Dec 24 18:19:59 hostname postfix/qmgr[17618]: 3989C9C7D1: removed
Dec 24 18:19:59 hostname postfix/smtp[20353]: 3989C9C7D1: to=<recipient@recipientdomain.de>, relay=127.0.0.1[127.0.0.1]:16000, delay=4.1, delays=4/0.01/0.04/0.08, dsn=2.0.0, status=sent (250 Bye )
TESTLOG

    use Data::Dumper;
    my $parsed_ref;
    foreach my $line( split( /\n/, $test_log ) ) {
        $parsed_ref = $log_parser->parse_line( $line );
        last if $parsed_ref && $parsed_ref->{ final };
    }
    
    
    my @errors = check_parse_result( [ {
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
    } ], [ $parsed_ref ] );
    diag( "Problems: ". join( ", ", @errors ) ) if @errors;
    ok( scalar @errors == 0, "Sent: Expected parsing result" );
}


PARSE_REJECT: {
    
    my $test_log = <<'TESTLOG';
connect from unknown[123.123.123.123]
Dec 24 14:33:55 testmail postfix/smtpd[20379]: NOQUEUE: reject: RCPT from unknown[123.123.123.123]: 504 5.5.2 <hostname>: Helo command rejected: need fully-qualified hostname; from=<sender@senderdomain.com> to=<recipient@recipientdomain.de> proto=ESMTP helo=<localhost>
Dec 24 14:33:56 testmail postfix/smtpd[20379]: lost connection after DATA (0 bytes) from unknown[123.123.123.123]
TESTLOG

    use Data::Dumper;
    my $parsed_ref;
    foreach my $line( split( /\n/, $test_log ) ) {
        $parsed_ref = $log_parser->parse_line( $line );
        last if $parsed_ref && $parsed_ref->{ final };
    }
    
    my @errors = check_parse_result( [ {
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
    } ], [ $parsed_ref ] );
    diag( "Problems: ". join( ", ", @errors ) ) if @errors;
    ok( scalar @errors == 0, "Reject: Expected parsing result" );
}



PARSE_BOUNCE: {
    
    my $test_log = <<'TESTLOG';
Jun 18 08:26:54 testmail postfix/smtpd[24208]: DD99C9C7D2: client=some-reverse-hostname.domain.tld[1.2.3.4]
Jun 18 08:26:55 testmail postfix/cleanup[24211]: DD99C9C7D2: message-id=<20100618062654.DD99C9C7D2@testmail.service.frbit.de>
Jun 18 08:26:55 testmail postfix/qmgr[23843]: DD99C9C7D2: from=<sender@senderdomain.com>, size=7394, nrcpt=1 (queue active)
Jun 18 08:26:55 testmail postfix/smtpd[24208]: disconnect from some-reverse-hostname.domain.tld[1.2.3.4]
Jun 18 08:26:58 testmail postfix/smtp[24212]: DD99C9C7D2: to=<recipient@recipientdomain.tld>, relay=127.0.0.1[127.0.0.1]:16000, delay=4.2, delays=1.1/0.01/0.04/3.1, dsn=5.0.0, status=bounced (host 127.0.0.1[127.0.0.1] said: 554 Rejected (in re
ply to end of DATA command))
Jun 18 08:26:58 testmail postfix/cleanup[24211]: 4447C9C7D4: message-id=<20100618062658.4447C9C7D4@testmail.service.frbit.de>
Jun 18 08:26:58 testmail postfix/qmgr[23843]: 4447C9C7D4: from=<>, size=9353, nrcpt=1 (queue active)
Jun 18 08:26:58 testmail postfix/bounce[24219]: DD99C9C7D2: sender non-delivery notification: 4447C9C7D4
Jun 18 08:26:58 testmail postfix/qmgr[23843]: DD99C9C7D2: removed
Jun 18 08:26:58 testmail postfix/smtp[24220]: 4447C9C7D4: to=<sender@senderdomain.com>, relay=pf.service.frbit.de[123.123.123.123]:10134, delay=0.54, delays=0.01/0.01/0.43/0.09, dsn=5.7.1, status=bounced (host pf.service.frbit.de[123.123.123.123] said: 554 5.7.1 <sender@senderdomain.com>: Relay access denied (in reply to RCPT TO command))
Jun 18 08:26:58 testmail postfix/qmgr[23843]: 4447C9C7D4: removed
TESTLOG

    use Data::Dumper;
    my @parsed;
    foreach my $line( split( /\n/, $test_log ) ) {
        my $parsed_ref = $log_parser->parse_line( $line );
        delete $parsed_ref->{ prev } if defined $parsed_ref->{ prev };
        push @parsed, $parsed_ref if $parsed_ref && $parsed_ref->{ final };
    }
    pop @parsed; # last contains only removed => 1
    
    my @ok = (
        {
          'from_address' => 'sender@senderdomain.com',
          'from_domain' => 'senderdomain.com',
          'ip' => '1.2.3.4',
          'prog' => 'smtp',
          'relay_host' => '127.0.0.1',
          'rdns' => 'some-reverse-hostname.domain.tld',
          'relay_ip' => '127.0.0.1',
          'bounced' => 1,
          'to_address' => 'recipient@recipientdomain.tld',
          'size' => '7394',
          'to_domain' => 'recipientdomain.tld',
          'final' => 1,
          'id' => 'DD99C9C7D2',
          'queued' => 1
        },
        {
          'from_address' => 'sender@senderdomain.com',
          'from_domain' => 'senderdomain.com',
          'prog' => 'smtp',
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
          'queue_id' => '4447C9C7D4',
          'id' => '4447C9C7D4',
          'queued' => 1
        }
    );
    
    #print Dumper [ \@ok, \@parsed ];
    
    my @errors = check_parse_result( \@ok, \@parsed );
    diag( "Problems: ". join( ", ", @errors ) ) if @errors;
    ok( scalar @errors == 0 && scalar @parsed == 2, "Bounce: Expected parsing result" );
}





PARSE_DEFERRED: {
    
    my $test_log = <<'TESTLOG';
Dec 24 17:34:14 testmail postfix/smtpd[10004]: 34A7C9C7D9: client=unknown[123.123.123.213]
Dec 24 17:34:14 testmail postfix/cleanup[10007]: 34A7C9C7D9: message-id=<123d01cb1234$230ef5f0$6400a8c0@sender>
Dec 24 17:34:14 testmail postfix/qmgr[9847]: 34A7C9C7D9: from=<sender@senderdomain.com>, size=2646, nrcpt=1 (queue active)
Dec 24 17:34:14 testmail postfix/smtp[10008]: 34A7C9C7D9: to=<recipient@recipientdomain.de>, relay=none, delay=6, delays=6/0.01/0/0, dsn=4.4.1, status=deferred (connect to 127.0.0.1[127.0.0.1]:16000: Connection refused)
Dec 24 17:41:58 testmail postfix/qmgr[9847]: 34A7C9C7D9: from=<sender@senderdomain.com>, size=2646, nrcpt=1 (queue active)
Dec 24 17:41:59 testmail postfix/qmgr[9847]: 34A7C9C7D9: removed
Dec 24 17:41:59 testmail postfix/smtp[10261]: 34A7C9C7D9: to=<recipient@recipientdomain.de>, relay=127.0.0.1[127.0.0.1]:16000, delay=471, delays=470/0.32/0.08/0.53, dsn=2.0.0, status=sent (250 Bye )
TESTLOG

    use Data::Dumper;
    my @parsed;
    foreach my $line( split( /\n/, $test_log ) ) {
        my $parsed_ref = $log_parser->parse_line( $line );
        push @parsed, $parsed_ref if $parsed_ref && $parsed_ref->{ final };
        #last if $parsed_ref->{ deferred };
    }
    
    my @errors = check_parse_result( [ {
        'from_address' => 'sender@senderdomain.com',
        'from_domain' => 'senderdomain.com',
        'ip' => '123.123.123.213',
        'prog' => 'smtp',
        'relay_host' => 'none',
        'rdns' => 'unknown',
        'relay_ip' => '',
        'to_address' => 'recipient@recipientdomain.de',
        'size' => '2646',
        'to_domain' => 'recipientdomain.de',
        'final' => 1,
        'deferred' => 1,
        'id' => '34A7C9C7D9',
        'queued' => 1
    }, {
        'from_domain' => 'senderdomain.com',
        'ip' => '123.123.123.213',
        'prog' => 'smtp',
        'rdns' => 'unknown',
        'size' => '2646',
        'to_domain' => 'recipientdomain.de',
        'sent' => 1,
        'id' => '34A7C9C7D9',
        'from_address' => 'sender@senderdomain.com',
        'relay_host' => '127.0.0.1',
        'relay_ip' => '127.0.0.1',
        'to_address' => 'recipient@recipientdomain.de',
        'final' => 1,
        'removed' => 1,
        'queued' => 1
    } ], \@parsed );
    
    diag( "Problems: ". join( ", ", @errors ) ) if @errors;
    ok( scalar @errors == 0, "Deferred: Expected parsing result" );
}



TestMisc::cleanup( $log_parser );


sub check_parse_result {
    my ( $ok_ref, $parsed_ref ) = @_;
    my @errors = ();
    my $num = 0;
    foreach my $ref( @$ok_ref ) {
        my $p_ref = $parsed_ref->[ $num ];
        while ( my ( $k, $v ) = each %$ref ) {
            unless ( defined $p_ref->{ $k } ) {
                push @errors, "($num) undefined '$k'";
            }
            elsif ( $p_ref->{ $k } ne $v ) {
                push @errors, "($num) wrong '$k' = '$p_ref->{ $k }' (!= '$v')";
            }
            delete $p_ref->{ $k };
        }
        push @errors, "obsolete keys: ". join( ", ", keys %$p_ref )
            if scalar keys %$p_ref > 0;
        $num ++;
    }
    push @errors, 'Wrong size of parsed result (expected '. $num. ', got '. ( scalar @$parsed_ref ). ')'
        if ( $num != scalar @$parsed_ref );
    
    
    return @errors;
}
