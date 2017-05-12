#!/usr/bin/perl -w

# Load test the Email::Stuff module

# use utf8;
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
# Single Part tests

# Single part text/plain
use Email::Send::Test ();
my $rv = Email::Stuff->from       ( 'Adam Kennedy<adam@phase-n.com>')
                     ->to         ( 'adam@phase-n.com'              )
                     ->subject    ( 'Hello To:!'                    )
                     ->text_body  ( 'I am an emáil'                 )
                     ->using      ( 'Test'                          )
                     ->send;
ok( $rv, 'Email sent ok' );
is( scalar(Email::Send::Test->emails), 1, 'Sent one email' );
my $email = (Email::Send::Test->emails)[0]->as_string;

like( $email, qr/Adam Kennedy/,  'Email contains from name' );
like( $email, qr/phase-n/,       'Email contains to string' );
like( $email, qr/Hello/,         'Email contains subject string' );
like( $email, qr/Content-Type: text\/plain/,   'Email content type' );

like(
  (Email::Send::Test->emails)[0]->body_str,
  qr/I am an emáil/,
  'Email contains text_body'
);


# Single part html/text
use Email::Send::Test ();
my $rv2 = Email::Stuff->from       ( 'Adam Kennedy<adam@phase-n.com>')
                      ->to         ( 'adam@phase-n.com'              )
                      ->subject    ( 'Hello To:!'                    )
                      ->html_body  ( '<b>I am a html email</b>'      )
                      ->using      ( 'Test'                          )
                      ->send;
ok( $rv2, 'Email sent ok' );
is( scalar(Email::Send::Test->emails), 2, 'Sent another email' );
$email = (Email::Send::Test->emails)[1]->as_string;

like( $email, qr/Adam Kennedy/,  'Email contains from name' );
like( $email, qr/phase-n/,       'Email contains to string' );
like( $email, qr/Hello/,         'Email contains subject string' );
like( $email, qr/<b>I am a html email<\/b>/, 'Email contains text_body' );
like( $email, qr/Content-Type: text\/html/,   'Email content type' );



1;
