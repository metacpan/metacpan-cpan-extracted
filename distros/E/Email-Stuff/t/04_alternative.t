#!/usr/bin/perl -w

# Load test the Email::Stuff module

use strict;
use lib ();
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		require File::Spec::Functions;
		File::Spec::Functions->import;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), 'lib') );
	}
}

use Test::More qw[no_plan];
use Email::Stuff;



#####################################################################
# Multipart/Alternate tests

use Email::Send::Test ();
my $rv = Email::Stuff->from       ( 'Adam Kennedy<adam@phase-n.com>')
                     ->to         ( 'adam@phase-n.com'              )
                     ->subject    ( 'Hello To:!'                    )
                     ->text_body  ( 'I am an emáil'                 )
                     ->html_body  ( '<b>I am a html emáil</b>'      )
                     ->using      ( 'Test'                          )
                     ->send;
ok( $rv, 'Email sent ok' );
is( scalar(Email::Send::Test->emails), 1, 'Sent one email' );
my $email  = (Email::Send::Test->emails)[0];
my $string = $email->as_string;

like( $string, qr/Adam Kennedy/,  'Email contains from name' );
like( $string, qr/phase-n/,       'Email contains to string' );
like( $string, qr/Hello/,         'Email contains subject string' );
like( $string, qr/Content-Type: multipart\/alternative/,   'Email content type' );
like( $string, qr/Content-Type: text\/plain/,   'Email content type' );
like( $string, qr/Content-Type: text\/html/,   'Email content type' );

like( ($email->subparts)[0]->body_str, qr/I am an emáil/, 'Email contains text_body' );
like( ($email->subparts)[1]->body_str, qr/<b>I am a html emáil<\/b>/, 'Email contains text_body' );

1;
