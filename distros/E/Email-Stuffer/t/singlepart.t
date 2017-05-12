#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More qw[no_plan];
use Email::Stuffer;
use Email::Sender::Transport::Test ();

#####################################################################
# Single Part tests

my $test = Email::Sender::Transport::Test->new;

{
  # Single part text/plain
  my $rv = Email::Stuffer->from       ( 'Adam Kennedy<adam@phase-n.com>')
                         ->to         ( 'adam@phase-n.com'              )
                         ->subject    ( 'Hello To:!'                    )
                         ->text_body  ( 'I am an emáil'                 )
                         ->transport  ( $test                           )
                         ->send;
  ok( $rv, 'Email sent ok' );
  is( $test->delivery_count, 1, 'Sent one email' );
  my $email = $test->shift_deliveries->{email};
  my $string = $email->as_string;

  like( $string, qr/Adam Kennedy/,  'Email contains from name' );
  like( $string, qr/phase-n/,       'Email contains to string' );
  like( $string, qr/Hello/,         'Email contains subject string' );
  like( $string, qr/Content-Type: text\/plain/,   'Email content type' );

  like(
    $email->object->body_str,
    qr/I am an emáil/,
    'Email contains text_body',
  );
}

{
  # Single part html/text
  my $rv = Email::Stuffer->from       ( 'Adam Kennedy<adam@phase-n.com>')
                         ->to         ( 'adam@phase-n.com'              )
                         ->subject    ( 'Hello To:!'                    )
                         ->html_body  ( '<b>I am a html email</b>'      )
                         ->transport  ( $test                           )
                         ->send;
  ok( $rv, 'Email sent ok' );
  is( $test->delivery_count, 1, 'Sent another email' );
  my $email  = $test->shift_deliveries->{email};
  my $string = $email->as_string;

  like( $string, qr/Adam Kennedy/,  'Email contains from name' );
  like( $string, qr/phase-n/,       'Email contains to string' );
  like( $string, qr/Hello/,         'Email contains subject string' );
  like( $string, qr/<b>I am a html email<\/b>/, 'Email contains text_body' );
  like( $string, qr/Content-Type: text\/html/,   'Email content type' );
}

1;
