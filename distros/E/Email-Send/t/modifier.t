#!/usr/bin/perl -w
use strict;
$^W = 1;

# Does everything load?
use Test::More tests => 5;
use Email::Send       ();
use Email::Send::Test ();

# Clear first, just in case
ok( Email::Send::Test->clear, '->clear returns true' );

my $sender = Email::Send->new({ mailer => 'Test' });
isa_ok( $sender, 'Email::Send' );

my $i = 0;
$sender->message_modifier(sub {
  my ($self, $message, $arg) = @_;
  $message->header_set('X-Whatever' => $i++);
});

my $message = <<'END_MESSAGE';
From: mom@house.example.com
To: dad@house.example.com
Subject: test message

This is the last time I clean up your socks.
END_MESSAGE

$sender->send($message); # once!
$sender->send($message); # twice!

my @emails = Email::Send::Test->emails;

is(@emails, 2, "we've sent two mails");

is($emails[0]->header('X-Whatever'), 0, "first message has X-Whatever: 0");
is($emails[1]->header('X-Whatever'), 1, "second message has X-Whatever: 1");
