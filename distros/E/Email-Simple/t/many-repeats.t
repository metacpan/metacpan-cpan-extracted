#!/usr/bin/perl -w
use strict;
use Test::More tests => 4;

sub read_file { local $/; local *FH; open FH, shift or die $!; return <FH> }
use_ok("Email::Simple");
# Very basic functionality test
my $mail_text = read_file("t/test-mails/many-repeats");
my $mail = Email::Simple->new($mail_text);
isa_ok($mail, "Email::Simple");

my $body = $mail->body;

$mail->body_set($body);
is($mail->as_string, $mail_text, "Good grief, it's round-trippable");
is(Email::Simple->new($mail->as_string)->as_string, $mail_text, "Good grief, it's still round-trippable");
